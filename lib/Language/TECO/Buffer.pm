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
    die 'Pointer off page' if $pointer < 0 || $pointer > length $self->{buffer};
    $self->{pointer} = $pointer;
    return;
}

sub offset {
    my $self = shift;
    $self->set($self->{pointer} + shift);
    return;
}

sub insert {
    my $self = shift;
    my $text = shift;
    substr($self->{buffer}, $self->{pointer}, 0) = $text;
    $self->offset(length $text);
    return;
}

sub delete {
    my $self = shift;
    my $length;
    if (@_ > 1) {
        my $pos = shift;
        $self->set($pos);
        $length = shift() - $pos;
    }
    else {
        $length = shift;
    }

    if ($length < 0) {
        $length = -$length;
        $self->offset(-$length);
    }
    die "Pointer off page"
        if $self->{pointer} + $length > length $self->{buffer};
    substr($self->{buffer}, $self->{pointer}, $length) = '';
    return;
}

sub endpos { length shift->{buffer} }

sub curpos { shift->{pointer} }

sub print {
    my $self = shift;
    my ($start, $end) = @_;
    return substr $self->{buffer}, $start, $end - $start;
}

sub get_line_offset {
    my $self = shift;
    my $num = shift;

    if ($num > 0) {
        pos $self->{buffer} = $self->{pointer};
        $self->{buffer} =~ /(?:.*(?:\n|$)){$num}/g;
        return ($-[0], $+[0]) if wantarray;
        return $+[0];
    }
    else {
        $num = -$num;
        my $rev = reverse $self->{buffer};
        my $len = length $self->{buffer};
        pos $rev = $len - $self->{pointer};
        $rev =~ /.*?(?:\n.*?){$num}(?=\n|$)/g;
        return ($len - $+[0], $len - $-[0]) if wantarray;
        return $len - $+[0];
    }
}

1;
