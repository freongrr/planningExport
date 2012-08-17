package Export::Task;

use strict;
use fields qw(id date start time name category description);
use overload fallback => 1, '""' => sub {$_[0]->toString()};

sub new {
    my ($class) = @_;
    return fields::new($class);
}

sub id {
    my ($self, $id) = @_;
    if (defined($id)) {
        $self->{id} = $id;
    }
    return $self->{id};
}

# Date formatted as YYYY-MM-DD
sub date {
    my ($self, $date) = @_;
    if (defined($date)) {
        $self->{date} = $date;
    }
    return $self->{date};
}

# Start time formatted as HH:MM
sub start {
    my ($self, $start) = @_;
    if (defined($start)) {
        $self->{start} = $start;
    }
    return $self->{start};
}

sub time {
    my ($self, $time) = @_;
    if (defined($time)) {
        $self->{time} = $time;
    }
    return $self->{time};
}

sub name {
    my ($self, $name) = @_;
    if (defined($name)) {
        $self->{name} = $name;
    }
    return $self->{name};
}

sub category {
    my ($self, $category) = @_;
    if (defined($category)) {
        $self->{category} = $category;
    }
    return $self->{category};
}

sub description {
    my ($self, $description) = @_;
    if (defined($description)) {
        $self->{description} = $description;
    }
    return $self->{description};
}

sub toString {
    my ($self) = @_;
    return 'Task '.$self->id.': '.$self->name;
}

1;
