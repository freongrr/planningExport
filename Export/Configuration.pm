package Export::Configuration;

use strict;
use Data::Dumper;

use constant CONFIG_PATH => $ENV{'HOME'}.'/.config/planningExport/';

use fields qw(file _content);

sub new {
    my ($class, $file) = @_;

    die "Missing file name" unless($file);

    my $self = fields::new($class);
    $self->{file} = CONFIG_PATH . $file;
    $self->{_content} = $self->_read();

    return $self;
}

sub file {
    my ($self, $file) = @_;
    return $self->{file};
}

sub _read {
    my ($self) = @_;

    my $directory = CONFIG_PATH;
    `mkdir $directory` unless (-e $directory);

    my $file = $self->file();
    open FILE, "<$file";
    my $content = join('', <FILE>);
    close FILE;

    my $configuation;
    eval $content;

    $self->{_content} = $configuation ? $configuation : {};
}

sub get {
    my ($self, $name) = @_;
    return $self->{_content}->{$name};
}

sub set {
    my ($self, $name, $value) = @_;
    $self->{_content}->{$name} = $value;
}

sub push {
    my ($self, $name, $value) = @_;
    push @{ $self->{_content}->{$name} }, $value;
}

sub put {
    my ($self, $name, $key, $value) = @_;
    $self->{_content}->{$name}->{$key} = $value;
}

sub save {
    my ($self) = @_;

    my $content = Data::Dumper->Dump([$self->{_content}], ["configuation"]);

    my $file = $self->file();
    open FILE, ">$file";
    print FILE $content."\n";
    close FILE;
}

1;
