package Export::FrontEnd;

use strict;

my $g_zenity = undef;

sub _zenity {
    my ($class) = @_;
    unless (defined($g_zenity)) {
        `zenity 2> /dev/null`;
        $g_zenity = ($? >> 8 == 255 && $ENV{'DISPLAY'}) ? 1 : 0;
    }
    return $g_zenity;
}

sub alert {
    my ($class, $message) = @_;

    if (_zenity()) {
        $message =~ s/&/&amp;/go;
        $message =~ s/</&lt;/go;
        $message =~ s/>/&gt;/go;
        $message =~ s/"/&quot;/go;
        `zenity --warning --text=\"$message\"`;
    } else {
        print STDERR $message."\n";
    }
}

sub prompt {
    my ($self, $message, $default) = @_;

    if (_zenity()) {
        $message =~ s/&/&amp;/go;
        $message =~ s/</&lt;/go;
        $message =~ s/>/&gt;/go;
        $message =~ s/"/&quot;/go;

        my $choice = `zenity --entry --entry-text="$default" --text="$message" --title="Export" --width=400`;
        chomp($choice);
        return $choice;
    } else {
        print "$message [$default] ";
        my $choice = <STDIN>;
        chomp($choice);
        if ($choice =~ /^\s*$/) {
            $choice = $default;
        }
        return $choice;
    }
}

sub promptPassword {
    my ($self, $text) = @_;

    my ($username, $password);
    if (_zenity()) {
        my $values = `zenity --username --password --title="$text" 2> /dev/null`;
        ($username, $password) = split(/\|/, $values);
    } else {
        print "$text\n";
        print "  Username: ";
        $username = <STDIN>;
        chomp($username);
        eval {
            require Term::ReadKey;
            Term::ReadKey::ReadMode(4);
            print "  Password: ";
            $password = <STDIN>;
            chomp($password);
            Term::ReadKey::ReadMode(0);
            print "\n";
        }; if ($@) {
            print STDERR "[WARN] You need Term::ReadKey to input the"
                ."password from the command line\n";
        }
    }
    return ($username, $password);
}

sub confirmExport {
    my ($class, $tasks, $fromDate, $toDate) = @_;

    if (_zenity()) {
        my @lines;

        foreach my $task (@$tasks) {
            my $activity = $task->name();
            if (length($activity) > 60) {
                $activity = substr($activity, 0, 57).'...';
            }

            push @lines, 'TRUE';
            push @lines, $task->date();
            push @lines, $task->category();
            push @lines, $activity;
            push @lines, _formatTime($task->time());
        }

        my $output = join("\n", @lines);

        my $prompt = "Do you really want to export these values?";
        my $title = "Activity between ".($fromDate ? $fromDate : "the start").
            " and ".($toDate ? $toDate : "today");

        my $choice = `echo "$output" | zenity --list --checklist --column="Export" --column="Date" --column="Category" --column="Activity" --column="Time" --hide-column=1 --text="$prompt" --title="$title" --width=800 --height=500`;

        return $choice ? 1 : 0;
    } else {
        my @table;
        push @table, ['Date', 'Category', 'Activity', 'Time'];

        foreach my $task (@$tasks) {
            push @table, [
                $task->date(),
                $task->category(),
                $task->name(),
                _formatTime($task->time()),
            ];
        }

        print "The following activity between ".
            ($fromDate ? $fromDate : "the start")." and ".
            ($toDate ? $toDate : "today")." can be exported:\n";
        _printTable(\@table);

        print "Do you really want to export these values? [y/N] ";
        my $choice = <STDIN>;
        chomp($choice);

        return lc($choice) eq 'y' ? 1 : 0;
    }
}

sub _formatTime {
    my ($time, $factor) = @_;

    $factor = 0.1 unless (defined($factor));

    my $lpart = int($time);
    my $rpart = ($time - $lpart);

    $rpart = $rpart / $factor;
    $rpart = sprintf( "%.0f", int($rpart + .5 * ($rpart <=> 0)) );
    $rpart = $rpart * 100 * $factor;

    if ($rpart >= 100) {
        $lpart += 1;
        $rpart = 0;
    }

   return sprintf("%d.%02d", $lpart, $rpart);
}

sub _printTable {
    my ($table) = @_;

    my $output = '';

    my $widths = [];
    foreach my $row (@$table) {
        for (my $i=0; $i<scalar(@$row); $i++) {
            my $width = length($row->[$i]);
            if (!defined($widths->[$i]) || $width > $widths->[$i]) {
                $widths->[$i] = $width;
            }
        }
    }

    foreach my $row (@$table) {
        my $buffer = [];
        for (my $i=0; $i<scalar(@$row); $i++) {
            my $width = length($row->[$i]);
            my $maxWidth = $widths->[$i];

            print ' ';
            print $row->[$i];
            print ' ' x ( $maxWidth - $width );
            print ' ';
        }
        print "\n";
    }
}

1;
