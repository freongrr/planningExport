package Export::Connector;

use strict;

sub connect {
    my ($self) = @_;
    die 'Please implement '.ref($self).'::connect';
}

sub exportTask {
    my ($self, $task) = @_;
    die 'Please implement '.ref($self).'::exportTask';
}

1;

