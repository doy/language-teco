#!perl
package Language::TECO;
use strict;
use warnings;
use Language::TECO::Buffer;

sub new {
    return bless { buffer => Language::TECO::Buffer->new }, shift;
}

sub execute {
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

