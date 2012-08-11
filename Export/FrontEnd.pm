package Export::FrontEnd;

use strict;

sub alert {
    my ($class, $message) = @_;
    print STDERR $message."\n";
}

sub promptFromDate {
    my ($self, $lastDate) = @_;

    # TODO
    return $lastDate;
}

sub promptPassword {
    my ($self) = @_;

    # TODO
    return (undef, undef);
}

sub confirmExport {
    my ($class, $tasks, $fromDate, $toDate) = @_;

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
