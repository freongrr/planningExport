#!/usr/bin/perl
use strict;

use Getopt::Long;
use Pod::Usage;

require Export::Configuration;
require Export::FrontEnd;
require Export::Bridge;
require Export::Planner::Hamster;
require Export::Connector::JIRA;

use constant HAMSTER_DB =>
    $ENV{'HOME'}.'/.local/share/hamster-applet/hamster.db';

eval {
    my $database     = HAMSTER_DB;
    my $jiraUrl      = undef;
    my $jiraUsername = undef;
    my $jiraPassword = undef;
    my $fromDate     = undef;
    my $toDate       = undef;
    my $help         = 0;
    my $man          = 0;

    if (!GetOptions(
        'database|d=s' => \$database,
        'jira|j=s'     => \$jiraUrl,
        'username|u=s' => \$jiraUsername,
        'password|p=s' => \$jiraPassword,
        'from|f=s'     => \$fromDate,
        'to|t=s'       => \$toDate,
        'help|?'       => \$help,
        'man'          => \$man)) {
        pod2usage(2);
    } elsif ($help) {
        pod2usage(1);
    } elsif ($man) {
        pod2usage(-exitstatus => 0, -verbose => 2);
    }

    my $config = new Export::Configuration('hamsterToJIRA');

    my $bridge = new Export::Bridge();
    $bridge->config($config);

    my $hamster = new Export::Planner::Hamster();
    $hamster->database($database);
    $bridge->planner($hamster);

    # Prompt for the starting date if it is missing
    unless ($fromDate) {
        my $lastDate = $config->get('lastExportedDate');
        $fromDate = Export::FrontEnd->prompt("Export from:", $lastDate);
    }

    my $tasks = $bridge->pendingTasks($fromDate, $toDate);

    if (Export::FrontEnd->confirmExport($tasks, $fromDate, $toDate)) {
        # Prompt for missing connection details
        unless ($jiraUrl) {
            my $lastUrl = $config->get('url');
            $jiraUrl = Export::FrontEnd->prompt("JIRA URL:", $lastUrl);
        }

        unless ($jiraUsername && $jiraPassword) {
            ($jiraUsername, $jiraPassword) =
                Export::FrontEnd->promptPassword("Login to JIRA");
        }

        my $jira = new Export::Connector::JIRA();
        $jira->config($config);
        $jira->url($jiraUrl);
        $jira->username($jiraUsername);
        $jira->password($jiraPassword);
        $bridge->connector($jira);

        $bridge->exportTasks($tasks);
    }
};
if ($@) {
    Export::FrontEnd->alert("ERROR: $@");
}

# TODO : documentation
