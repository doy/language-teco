package Language::TECO::Buffer;
use Moose;
use namespace::autoclean;

has _buffer => (
    traits   => ['String'],
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    init_arg => 'buffer',
    handles  => {
        _substr_buffer => 'substr',
        endpos         => 'length',
    },
);

has curpos => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    trigger => sub {
        my $self = shift;
        my ($curpos, $oldpos) = @_;
        # XXX: ick, do this better
        if ($curpos < 0 || $curpos > $self->endpos) {
            $self->curpos($oldpos);
            die "Pointer off page\n";
        }
    },
    handles => {
        set    => 'set',
        offset => 'inc',
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    shift if !defined($_[0]);
    unshift @_, 'buffer' if @_ % 2 == 1;
    return $class->$orig(@_);
};

around qw(set offset) => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    return;
};

sub buffer {
    my $self = shift;
    my ($start, $end) = @_;
    $start = 0             if !defined $start || $start < 0;
    $end   = $self->endpos if !defined $end   || $end > $self->endpos;
    ($start, $end) = ($end, $start) if $start > $end;
    return $self->_substr_buffer($start, $end - $start);
}

sub insert {
    my $self = shift;
    my ($text) = @_;
    $self->_substr_buffer($self->curpos, 0, $text);
    $self->offset(length $text);
    return;
}

sub delete {
    my $self = shift;
    my ($start, $end) = @_;
    ($start, $end) = ($end, $start) if $start > $end;

    die "Pointer off page\n" if $start < 0 || $end > $self->endpos;
    $self->_substr_buffer($start, $end - $start, '');
    $self->set($start);
    return;
}

sub get_line_offset {
    my $self = shift;
    my $num = shift;

    # XXX: what in the world was i thinking... clean this up
    if ($num > 0) {
        my $buffer = $self->buffer;
        pos $buffer = $self->curpos;
        $buffer =~ /(?:.*(?:\n|$)){0,$num}/g;
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

__PACKAGE__->meta->make_immutable;

1;
