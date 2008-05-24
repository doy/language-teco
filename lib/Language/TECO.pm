#!perl
package Language::TECO;
use strict;
use warnings;
use Language::TECO::Buffer;
use base 'Class::Accessor::Fast';
Language::TECO->mk_accessors qw/at colon negate current_num/;
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
sub has_range { defined shift->{n2}    }

sub reset {
    my $self = shift;

    $self->{current_num} = 'n1';
    $self->{n1}          = undef;
    $self->{n2}          = undef;
    $self->{at}          = 0;
    $self->{colon}       = 0;
    $self->{negate}      = 0;
}

sub num {
    my $self = shift;
    my $num = shift;

    if (defined $num) {
        if ($self->negate) {
            $num = -$num;
            $self->negate(0);
        }
        $self->{$self->current_num} = $num;
    }
    else {
        if (wantarray && $self->has_range) {
            return ($self->{n1}, $self->{n2});
        }
        else {
            return $self->{$self->current_num};
        }
    }
}

sub cmd {
    my $self = shift;
    my $code = shift;

    $self->current_num('n1');

    $code->($self);

    $self->reset;
}

sub cmd_with_string {
    my $self = shift;
    my $code = shift;

    return $self->cmd(sub {
        my $self = shift;
        my $str = '';

        if ($self->at) {
            $self->{command} =~ s/(.)(.*?)\1//s;
            $str = $2;
        }
        else {
            $self->{command} =~ s/(.*?)\e//s;
            $str = $1;
        }

        $code->($self, $str);
    });
}

sub push_cmd {
    my $self = shift;
    my $to_push = shift;
    $self->{command} = $to_push . $self->{command};
}

sub execute {
    my $self = shift;
    $self->{command} = shift;
    my $ret = '';

    while ($self->{command}) {
        $_ = substr($self->{command}, 0, 1, '');
        if (/[0-9]/) {
            my $num = $self->num || 0;
            $_ = -$_ if $num < 0;
            $self->num($num * 10 + $_);
        }
        elsif (/-/) {
            $self->negate(1);
        }
        elsif (/b/i) {
            $self->num(0);
        }
        elsif (/z/i) {
            $self->num($self->buflen);
        }
        elsif (/\./) {
            $self->num($self->pointer);
        }
        elsif (/h/i) {
            $self->push_cmd('b,z');
            redo;
        }
        elsif (/\cy/) {
            $self->push_cmd(".+\cs,.");
            redo;
        }
        elsif (/,/) {
            $self->current_num('n2');
        }
        elsif (/:/) {
            $self->colon(1);
        }
        elsif (/@/) {
            $self->at(1);
        }
        elsif (/i/i) {
            if (defined $self->num) {
                $self->cmd(sub {
                    my $self = shift;
                    $self->buf->insert(chr($self->num))
                });
            }
            else {
                $self->cmd_with_string(sub {
                    my $self = shift;
                    $self->buf->insert(shift);
                });
            }
        }
        elsif (/d/i) {
            if ($self->has_range) {
                $self->push_cmd('k');
                redo;
            }
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->buf->delete($self->pointer, $self->pointer + $self->num);
            });
        }
        elsif (/k/i) {
            $self->cmd(sub {
                my $self = shift;
                if ($self->has_range) {
                    $self->buf->delete($self->num);
                }
                else {
                    if (!defined $self->num) {
                        $self->num(1);
                    }
                    my $num = $self->num;
                    $self->buf->delete($self->buf->get_line_offset($num));
                }
            });
        }
        elsif (/j/i) {
            if (!defined $self->num) {
                $self->num(0);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->buf->set($self->num);
            });
        }
        elsif (/c/i) {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->buf->offset($self->num);
            });
        }
        elsif (/r/i) {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->num(-$self->num);
            $self->push_cmd('c');
            redo;
        }
        elsif (/l/i) {
            $self->cmd(sub {
                my $self = shift;
                if (!defined $self->num) {
                    $self->num(1);
                }
                $self->buf->set(scalar $self->buf->get_line_offset($self->num));
            });
        }
        elsif (/=/i) {
            $self->cmd(sub {
                my $self = shift;
                my $fmt = ($self->{command} =~ s/^=//) ? "%o%s" : "%d%s";
                $ret .= sprintf $fmt, $self->num, $self->colon ? "" : "\n";
            });
        }
        elsif (/t/i) {
            $self->cmd(sub {
                my $self = shift;
                if ($self->has_range) {
                    $ret .= $self->buffer($self->num);
                }
                else {
                    if (!defined $self->num) {
                        $self->num(1);
                    }
                    my $num = $self->num;
                    $ret .= $self->buffer($self->buf->get_line_offset($num));
                }
            });
        }
    }

    return $ret;
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

