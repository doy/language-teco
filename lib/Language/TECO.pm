#!perl
package Language::TECO;
use strict;
use warnings;
use Language::TECO::Buffer;

sub new {
    my $class = shift;
    my $initial_buffer = shift;
    my $object = { buffer => Language::TECO::Buffer->new($initial_buffer) };
    bless $object, $class;
    $object->reset;
    return $object;
}

sub buffer  { shift->{buffer}->{buffer}  }
sub pointer { shift->{buffer}->{pointer} }

sub reset {
    my $self = shift;

    $self->{command} = '';
    $self->{current_num} = 'n1';
    $self->{n1} = undef;
    $self->{n2} = undef;
    $self->{at} = 0;
    $self->{colon} = 0;
    $self->{negate} = 0;
}

sub num {
    my $self = shift;
    my $num = shift;

    if (defined $num) {
        if ($self->{negate}) {
            $num = -$num;
            $self->{negate} = 0;
        }
        $self->{$self->{current_num}} = $num;
    }
    else {
        if (wantarray) {
            return ($self->{n1}, $self->{n2});
        }
        else {
            return $self->{$self->{current_num}};
        }
    }
}

sub cmd {
    my $self = shift;
    my $code = shift;

    $self->{current_num} = 'n1';

    $code->($self);

    $self->reset;
}

sub cmd_with_string {
    my $self = shift;
    my $code = shift;

    return $self->cmd(sub {
        my $self = shift;
        my $str = '';

        if ($self->{at}) {
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

    while ($self->{command}) {
        $_ = substr($self->{command}, 0, 1, '');
        if (/[0-9]/) {
            my $num = $self->num || 0;
            $self->num($num * 10 + $_);
        }
        elsif (/-/) {
            $self->{negate} = 1;
        }
        elsif (/b/i) {
            $self->num(0);
        }
        elsif (/z/i) {
            $self->num(length $self->{buffer}->{buffer});
        }
        elsif (/\./) {
            $self->num($self->{buffer}->{pointer});
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
            $self->{current_num} = 'n2';
        }
        elsif (/:/) {
            $self->{colon} = 1;
        }
        elsif (/@/) {
            $self->{at} = 1;
        }
        elsif (/i/i) {
            if (defined $self->num) {
                $self->cmd(sub {
                    my $self = shift;
                    $self->{buffer}->insert(chr($self->num))
                });
            }
            else {
                $self->cmd_with_string(sub {
                    my $self = shift;
                    $self->{buffer}->insert(shift);
                });
            }
        }
        elsif (/d/i) {
            if (defined $self->{n2}) {
                $self->push_cmd('k');
                redo;
            }
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->{buffer}->delete($self->num);
            });
        }
        elsif (/j/i) {
            if (!defined $self->num) {
                $self->num(0);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->{buffer}->set($self->num);
            });
        }
        elsif (/c/i) {
            if (!defined $self->num) {
                $self->num(1);
            }
            $self->cmd(sub {
                my $self = shift;
                $self->{buffer}->offset($self->num);
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
        elsif (/t/i) {
            $self->cmd(sub {
                my $self = shift;
                if (defined $self->{n2}) {
                    $self->{buffer}->print(($self->num));
                }
                else {
                    if (!defined $self->num) {
                        $self->num(1);
                    }
                    my $num = $self->num;
                    if ($num > 0) {
                        my $regex = "(?:.*(?:\n|\$)){$num}";
                        pos $self->{buffer}->{buffer} = $self->{buffer}->{pointer};
                        $self->{buffer}->{buffer} =~ /$regex/g;
                        $self->{buffer}->print($self->{buffer}->{pointer},
                                               $+[0]);
                    }
                    else {
                        $num = -$num;
                        my $rev = reverse $self->{buffer}->{buffer};
                        my $regex = ".*?(?:\n.*?){$num}(?=\n|\$)";
                        pos $rev = length($self->{buffer}->{buffer}) - $self->{buffer}->{pointer};
                        $rev =~ /$regex/sg;
                        $self->{buffer}->print(length($self->{buffer}->{buffer}) - $+[0], $self->{buffer}->{pointer});
                    }
                }
            });
        }
    }
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

