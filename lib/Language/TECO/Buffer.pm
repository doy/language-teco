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

sub curpos { shift->{pointer} }

sub endpos { length shift->{buffer} }

sub buffer {
    my $self = shift;
    my ($start, $end) = @_;
    $start = 0 if !defined $start || $start < 0;
    $end = $self->endpos if !defined $end || $end > $self->endpos;
    ($start, $end) = ($end, $start) if $start > $end;
    return substr $self->{buffer}, $start, $end - $start;
}

sub set {
    my $self = shift;
    my $pointer = shift;
    die "Pointer off page\n" if $pointer < 0 || $pointer > $self->endpos;
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
    substr($self->{buffer}, $self->curpos, 0) = $text;
    $self->offset(length $text);
    return;
}

sub delete {
    my $self = shift;
    my ($start, $end) = @_;
    ($start, $end) = ($end, $start) if $start > $end;

    die "Pointer off page\n" if $start < 0 || $end > $self->endpos;
    substr($self->{buffer}, $start, $end - $start) = '';
    $self->set($start);
    return;
}

sub get_line_offset {
    my $self = shift;
    my $num = shift;

    if ($num > 0) {
        pos $self->{buffer} = $self->curpos;
        $self->{buffer} =~ /(?:.*(?:\n|$)){0,$num}/g;
        return ($-[0], $+[0]) if wantarray;
        return $+[0];
    }
    else {
        $num = -$num;
        my $rev = reverse $self->buffer;
        my $len = $self->endpos;
        pos $rev = $len - $self->curpos;
        $rev =~ /.*?(?:\n.*?){0,$num}(?=\n|$)/g;
        return ($len - $+[0], $len - $-[0]) if wantarray;
        return $len - $+[0];
    }
}

1;
