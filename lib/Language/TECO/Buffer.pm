#!/usr/bin/perl
use strict;
use warnings;
package Language::TECO::Buffer;

sub new {
    my $class = shift;
    my $initial_buffer = shift;
    $initial_buffer = '' unless defined $initial_buffer;
    return bless { buffer => $initial_buffer, pointer => 0 }, $class;
}

sub set {
    my $self = shift;
    my $pointer = shift;
    return if $pointer < 0 || $pointer > length $self->{buffer};
    $self->{pointer} = $pointer;
}

sub offset {
    my $self = shift;
    $self->set($self->{pointer} + shift);
}

sub insert {
    my $self = shift;
    my $text = shift;
    substr($self->{buffer}, $self->{pointer}, 0) = $text;
    $self->offset(length $text);
}

sub delete {
    my $self = shift;
    my $length = shift;
    if ($length < 0) {
        $length = -$length;
        $self->{pointer} -= $length;
    }
    substr($self->{buffer}, $self->{pointer}, $length) = '';
}

sub endpos { length shift->{buffer} }

sub curpos { shift->{pointer} }

sub print {
    my $self = shift;
    my ($start, $end) = @_;
    print substr $self->{buffer}, $start, $end - $start;
}

1;
