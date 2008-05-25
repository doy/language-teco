#!perl
package Language::TECO;
use strict;
use warnings;
use Language::TECO::Buffer;
use base 'Class::Accessor::Fast';
Language::TECO->mk_accessors qw/num at colon negate want_num ret/;
Language::TECO->mk_ro_accessors qw/buf/;

sub new {
    my $class = shift;
    my $initial_buffer = shift;
    my $object = { buf => Language::TECO::Buffer->new($initial_buffer) };
    bless $object, $class;
    $object->reset;
    return $object;
}

sub buffer    { shift->buf->buffer(@_) }
sub pointer   { shift->buf->curpos     }
sub buflen    { shift->buf->endpos     }
sub has_range { defined shift->{num2}    }

sub reset {
    my $self = shift;

    $self->{num}         = undef;
    $self->{num2}        = undef;

    $self->{at}          = 0;
    $self->{colon}       = 0;
    $self->{negate}      = 0;

    $self->{want_num}    = 1;
}

sub ret {
    my $self = shift;
    $_[0] = $self->{ret} . $_[0] if (@_);
    return $self->_ret_accessor(@_);
}

sub clear_ret { shift->{ret} = '' }

sub num {
    my $self = shift;
    if (@_ && $self->negate) {
        @_ = (-$_[0]);
        $self->negate(0);
    }
    if (wantarray && $self->has_range) {
        return ($self->{num2}, $self->_num_accessor(@_));
    }
    return $self->_num_accessor(@_);
}

sub shift_num {
    my $self = shift;
    $self->{num2} = $self->{num};
    $self->{num} = undef;
}

sub get_string {
    my $self = shift;
    my $command = shift;
    my $str;

    if ($self->at) {
        $command =~ s/(.)(.*?)\1//s;
        $str = $2;
    }
    else {
        $command =~ s/(.*?)\e//s;
        $str = $1;
    }

    return ($str, $command);
}

sub try_num {
    my $self = shift;
    my $command = shift;

    $self->want_num(0);
    if ($command =~ s/^([0-9]+)//) {
        $self->num($1);
    }
    elsif ($command =~ s/^-//) {
        $self->negate(1);
        $self->want_num(1);
    }
    elsif ($command =~ s/^b//i) {
        $self->num(0);
    }
    elsif ($command =~ s/^z//i) {
        $self->num($self->buflen);
    }
    elsif ($command =~ s/^\.//) {
        $self->num($self->pointer);
    }
    elsif ($command =~ s/^h//i) {
        $command = 'b,z'.$command;
        $self->want_num(1);
    }
    elsif ($command =~ s/^\cy//) {
        $command = ".+\cs,.".$command;
        $self->want_num(1);
    }

    return $command;
}

sub try_cmd {
    my $self = shift;
    my $command = shift;

    my $need_reset = 1;
    if ($command =~ s/^,//) {
        $self->shift_num;
        $self->want_num(1);
        $need_reset = 0;
    }
    elsif ($command =~ s/^://) {
        $self->colon(1);
        $need_reset = 0;
    }
    elsif ($command =~ s/^@//) {
        $self->at(1);
        $need_reset = 0;
    }
    elsif ($command =~ s/^i//i) {
        if (defined $self->num) {
            $self->buf->insert(chr($self->num))
        }
        else {
            my $str;
            ($str, $command) = $self->get_string($command);
            $self->buf->insert($str);
        }
    }
    elsif ($command =~ s/^d//i) {
        if ($self->has_range) {
            $command = 'k'.$command;
            $need_reset = 0;
        }
        else {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->buf->delete($self->pointer, $self->pointer + $self->num);
        }
    }
    elsif ($command =~ s/^k//i) {
        if ($self->has_range) {
            $self->buf->delete($self->num);
        }
        else {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->buf->delete($self->buf->get_line_offset(scalar $self->num));
        }
    }
    elsif ($command =~ s/^j//i) {
        if (!defined $self->num) {
            $self->num(0);
        }
        $self->buf->set($self->num);
    }
    elsif ($command =~ s/^c//i) {
        if (!defined $self->num) {
            $self->num(1);
        }
        $self->buf->offset($self->num);
    }
    elsif ($command =~ s/^r//i) {
        if (!defined $self->num) {
            $self->num(1);
        }
        $self->num(-$self->num);
        $command = 'c'.$command;
        $need_reset = 0;
    }
    elsif ($command =~ s/^l//i) {
        if (!defined $self->num) {
            $self->num(1);
        }
        $self->buf->set(scalar $self->buf->get_line_offset(scalar $self->num));
    }
    elsif ($command =~ s/^=//) {
        my $fmt = ($command =~ s/^=//) ? "%o%s" : "%d%s";
        $self->ret(sprintf $fmt, $self->num, $self->colon ? "" : "\n");
    }
    elsif ($command =~ s/^t//i) {
        if ($self->has_range) {
            $self->ret($self->buffer($self->num));
        }
        else {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->ret($self->buffer($self->buf->get_line_offset(scalar $self->num)));
        }
    }

    $self->reset if $need_reset;

    return $command;
}

sub execute {
    my $self = shift;
    my $command = shift;
    $self->clear_ret;

    while ($command) {
        if ($self->want_num) {
            $command = $self->try_num($command);
            next;
        }
        $command = $self->try_cmd($command);
    }

    return $self->ret;
}

=head1 NAME

Language::TECO - ???

=head1 VERSION

Version 0.01 released ???

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Language::TECO;
    do_stuff();

=head1 DESCRIPTION



=head1 SEE ALSO

L<Foo::Bar>

=head1 AUTHOR

Jesse Luehrs, C<< <jluehrs2 at uiuc.edu> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-language-teco at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Language-TECO>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Language::TECO

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Language-TECO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Language-TECO>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Language-TECO>

=item * Search CPAN

L<http://search.cpan.org/dist/Language-TECO>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Jesse Luehrs.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

