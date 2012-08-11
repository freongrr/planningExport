package Export::Planner;

use strict;

sub tasks {
    my ($self, $fromDate, $toDate) = @_;
    die 'Please implement '.ref($self).'::tasks()';
}

1;
