package Export::Planner::Hamster;

use strict;

use base qw(Export::Planner);
use fields qw(database);

require Export::Task;

sub new {
    my ($class) = @_;
    return fields::new($class);
}

sub database {
    my ($self, $database) = @_;
    if (defined($database)) {
        $self->{database} = $database;
    }
    return $self->{database};
}

sub tasks {
    my ($self, $fromDate, $toDate) = @_;

    my $sql = "
        SELECT strftime('%Y-%m-%d', f.start_time) AS date,
               strftime('%H:%M', f.start_time) AS start,
               strftime('%s', f.end_time) - strftime('%s', f.start_time),
               a.name,
               c.name,
               f.id,
               replace(f.description, x'0A', ' ')
          FROM facts f
               INNER JOIN activities a ON a.id = f.activity_id
               LEFT JOIN categories c ON c.id=a.category_id
         WHERE f.end_time IS NOT NULL";
    if ($fromDate) { $sql .= "
           AND start_time >= '".$fromDate." 00:00'"; }
    if ($toDate) { $sql .= "
           AND start_time <=  '".$toDate." 23:59'"; }
    $sql .= "
      ORDER BY f.end_time, f.id";

    my $tasks = [];

    foreach my $row ($self->_fetch($sql)) {
        # print "DEBUG: $row\n";

        my ($date, $start, $time, $activity, $category, $factId, $description)
            = split(/\|/, $row);

        $time = $time / 3600.00;

        # TODO : why am I doing that?
        $activity =~ s/^[\s\-]+(\w)/$1/;
        $activity =~ s/(\w)[\s\-]+$/$1/;

        # Remove the final dot
        $description =~ s/([^\.])\.$/$1/go;

        my $task = new Export::Task();
        $task->id($factId);
        $task->date($date);
        $task->start($start);
        $task->time($time);
        $task->name($activity);
        $task->category($category);
        $task->description($description);

        push @$tasks, $task;
    }

    return $tasks;
}

sub _fetch {
    my ($self, $sql) = @_;

    my $command = "sqlite3 ".$self->database()." \"$sql;\"";

    my $output = `$command`;
    my @rows = split('\n', $output);

    return @rows;
}

1;
