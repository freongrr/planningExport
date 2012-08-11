package Export::Connector::JIRA;

use strict;
use base qw(Export::Connector);
use fields qw(config url username password _agent);

use constant ISSUE_CODE => qr/^([a-zA-Z]{2,}-\d+)/;
use constant MONTHS => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dev'];

require Export::FrontEnd;

require LWP::UserAgent;
require HTTP::Cookies;

sub new {
    my ($class) = @_;

    my $cookieJar = new HTTP::Cookies(autosave => 1);
    my $agent = new LWP::UserAgent();
    $agent->cookie_jar($cookieJar);

    my $self = fields::new($class);
    $self->{_agent} = $agent;
    return $self;
}

sub config {
    my ($self, $config) = @_;
    if (defined($config)) {
        $self->{config} = $config;
    }
    return $self->{config};
}

sub url {
    my ($self, $url) = @_;
    if (defined($url)) {
        $url =~ s!/$!!o;
        $self->{url} = $url;
    }
    return $self->{url};
}

sub username {
    my ($self, $username) = @_;
    if (defined($username)) {
        $self->{username} = $username;
    }
    return $self->{username};
}

sub password {
    my ($self, $password) = @_;
    if (defined($password)) {
        $self->{password} = $password;
    }
    return $self->{password};
}

sub connect {
    my ($self) = @_;

    my $url = $self->url() || die "Missing url";

    my $username = $self->username();
    my $password = $self->password();

    unless ($self->username() && $self->password) {
        ($username, $password) = Export::FrontEnd->promptPassword();

        unless ($username && $password) {
            die "Missing username and/or password";
        }

        $self->username($username);
        $self->password($password);
    }

    my $response = $self->{_agent}->get(
        $url . '/rest/gadget/1.0/login'
            .'?os_cookie=true'
            .'&os_username=' . $username
            .'&os_password=' . $password);

    unless ($response->code == 200) {
        die "Could not connect to JIRA";
    }

    unless ($response->content =~ /loginSucceeded":true/o) {
        die "Authentication failed";
    }
}

sub exportTask {
    my ($self, $task) = @_;

    unless ($task->id) {
        die "Can't export task without id";
    }

    # Extract the issue code
    my $issueCode = undef;
    if ($task->id =~ ISSUE_CODE) {
        $issueCode = $1;
    } elsif ($task->name =~ ISSUE_CODE) {
        $issueCode = $1;
    } elsif ($task->category =~ ISSUE_CODE) {
        $issueCode = $1;
    } elsif ($task->description =~ ISSUE_CODE) {
        $issueCode = $1;
    }

    unless ($issueCode) {
        die "Can't export task without issue code";
    }

    # Convert to JIRA issue id
    my $issueId = $self->_issueId($issueCode);

    unless ($issueId) {
        die "Can't find JIRA issue id for $issueCode";
    }

    my $date = _formatDate($task->date);
    my $time = _formatTime($task->time);
    my $description = $task->description;

    $self->_logWork($issueId, $date, $time, $description);
}

sub _issueId {
    my ($self, $issueCode) = @_;

    my $url = $self->url() || die "Missing url";

    my $issueIdCache = $self->config()->get('issueIdCache');

    my $issueId = $issueIdCache->{$issueCode};
    unless ($issueId) {
        my $response = $self->{_agent}->get($url . '/browse/' . $issueCode);

        if ($response->content =~ /CreateWorklog!default.jspa\?id=(\d+)/o) {
            $issueId = $1;

            # add to the id cache
            $self->config()->put('issueIdCache', $issueCode, $issueId);
        }
    }

    return $issueId;
}

sub _logWork {
    my ($self, $issueId, $date, $time, $comment) = @_;

    die "Missing issue id" unless ($issueId);
    die "Missing date" unless ($date);
    die "Missing time" unless ($time);

    my $url = $self->url() || die "Missing url";

    print "EXPORT: '$issueId', '$date', '$time', '$comment'\n";

    my $response = $self->{_agent}->get(
        $url . '/secure/CreateWorklog!default.jspa?id=' . $issueId);

    my $content = $response->content;
    $content =~ s/\n+/ /go;
    $content =~ s/\s+/ /go;

    if ($content =~ /name="atl_token" value="([^"]+)"/o) {
        my $token = $1;

        my $postResponse = $self->{_agent}->post(
            $url . '/secure/CreateWorklog.jspa',
            Content_Type => 'application/x-www-form-urlencoded',
            Content => { 'Log'            => 'Log',
                         'id'             => $issueId,
                         'alt_token'      => $token,
                         'startDate'      => $date,
                         'timeLogged'     => $time,
                         'comment'        => $comment,
                         'adjustEstimate' => 'auto', });

        if ($postResponse->code != 302) {
            die "Failed to log work";
        }
    }
}

sub _formatDate {
    my ($date) = @_;

    my $year = substr($date, 0, 4);
    my $month = substr($date, 5, 2);
    my $day = substr($date, 8, 2);

    $date = ($day * 1).'/';
    $date .= MONTHS->[$month - 1].'/';
    $date .= ($year - 2000).' 08:00 AM';

    return $date;
}

sub _formatTime {
    my ($time, $factor) = @_;
    return Export::FrontEnd::_formatTime($time, $factor).'h';
}

1;

