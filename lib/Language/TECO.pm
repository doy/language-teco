package Language::TECO;
use Moose;
use Moose::Util::TypeConstraints;

# XXX: move this elsewhere eventually
subtype 'Buffer', as 'Language::TECO::Buffer';
coerce  'Buffer', from 'Str',
    via { require Language::TECO::Buffer; Language::TECO::Buffer->new($_) };

has num => (
    is        => 'rw',
    isa       => 'Int',
    lazy      => 1,
    default   => sub { die "num is unset!" },
    clearer   => '_clear_num',
    predicate => 'has_num',
);

has num2 => (
    is        => 'rw',
    isa       => 'Int',
    lazy      => 1,
    default   => sub { die "num2 is unset!" },
    clearer   => '_clear_num2',
    predicate => 'has_range',
);

has at => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    clearer => '_clear_at',
);

has colon => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    clearer => '_clear_colon',
);

has negate => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
    clearer => '_clear_negate',
);

has _ret => (
    traits  => ['String'],
    is      => 'rw',
    isa     => 'Str',
    default => '',
    lazy    => 1,
    clearer => 'clear_ret',
    handles => {
        _append_ret => 'append',
    },
);

has buf => (
    is      => 'ro',
    isa     => 'Buffer',
    coerce  => 1,
    default => sub {
        require Language::TECO::Buffer;
        Language::TECO::Buffer->new;
    },
    handles => {
        buffer  => 'buffer',
        pointer => 'curpos',
        buflen  => 'endpos',
    }
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    unshift @_, 'buf' if @_ % 2 == 1;
    return $class->$orig(@_);
};

sub reset {
    my $self = shift;

    for my $attr (qw(num num2 at colon negate)) {
        my $method = "_clear_$attr";
        $self->$method;
    }
}

# XXX: is this really what i want? can i make this more sane?
sub ret {
    my $self = shift;
    return $self->_ret unless @_;
    return $self->_append_ret(shift);
}

around num => sub {
    my $orig = shift;
    my $self = shift;
    if (@_ && $self->negate) {
        @_ = (-$_[0]);
        $self->negate(0);
    }
    my $ret = $self->$orig(@_);
    $ret = 0 unless defined $ret;
    if (wantarray && $self->has_range) {
        return ($self->num2, $ret);
    }
    return $ret;
};

sub shift_num {
    my $self = shift;
    $self->num2($self->num);
    $self->_clear_num;
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
    my ($num, $command, $negate) = @_;
    my $num2;

    if ($command =~ s/^([0-9]+)//) {
        return $self->try_num($1, $command);
    }
    elsif ($command =~ s/^\+//) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) + $num2 : undef, $command);
    }
    elsif ($command =~ s/^-//) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) - $num2 : undef, $command, 1);
    }
    elsif ($command =~ s/^\*//) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) * $num2 : undef, $command);
    }
    elsif ($command =~ s/^\///) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) / $num2 : undef, $command);
    }
    elsif ($command =~ s/^&//) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) & $num2 : undef, $command);
    }
    elsif ($command =~ s/^#//) {
        ($num2, $command) = $self->try_num(undef, $command);
        return $self->try_num(defined $num2 ? ($num || 0) | $num2 : undef, $command);
    }
    elsif ($command =~ s/^b//i) {
        return $self->try_num(0, $command);
    }
    elsif ($command =~ s/^z//i) {
        return $self->try_num($self->buflen, $command);
    }
    elsif ($command =~ s/^\.//) {
        return $self->try_num($self->pointer, $command);
    }
    elsif ($command =~ s/^h//i) {
        return $self->try_num($num, 'b,z'.$command);
    }
    elsif ($command =~ s/^\cy//) {
        return $self->try_num($num, ".+\cs,.".$command);
    }
    else {
        return ($num, $command, $negate);
    }
}

sub try_cmd {
    my $self = shift;
    my $command = shift;

    my $need_reset = 1;
    if ($command =~ s/^,//) {
        $self->shift_num;
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
        if ($self->has_num) {
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
            if (!$self->has_num) {
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
            if (!$self->has_num) {
                $self->num(1);
            }
            $self->buf->delete($self->buf->get_line_offset(scalar $self->num));
        }
    }
    elsif ($command =~ s/^j//i) {
        if (!$self->has_num) {
            $self->num(0);
        }
        $self->buf->set($self->num);
    }
    elsif ($command =~ s/^c//i) {
        if (!$self->has_num) {
            $self->num(1);
        }
        $self->buf->offset($self->num);
    }
    elsif ($command =~ s/^r//i) {
        if (!$self->has_num) {
            $self->num(1);
        }
        $self->num(-$self->num);
        $command = $self->try_cmd('c'.$command);
    }
    elsif ($command =~ s/^l//i) {
        if (!$self->has_num) {
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
            if (!$self->has_num) {
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
    $self->reset;

    while ($command) {
        my ($num, $negate);
        ($num, $command, $negate) = $self->try_num(undef, $command);
        if (defined $num) {
            $self->num($num);
        }
        elsif ($negate) {
            $self->negate(1);
        }
        my $new_command = $self->try_cmd($command);
        substr($new_command, 0, 1, '') if $new_command eq $command;
        $command = $new_command;
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

