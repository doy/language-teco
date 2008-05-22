#!perl -T
use strict;
use warnings;
use Test::More tests => 8;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("10j");
$te->execute("d");
is($te->buffer, "this is\naninitial buffer",
   "buffer contents after deleting a character forwards");
is($te->pointer, 10,
   "buffer position after deleting a character forwards");
$te->execute("-d");
is($te->buffer, "this is\nainitial buffer",
   "buffer contents after deleting a character backwards");
is($te->pointer, 9,
   "buffer position after deleting a character backwards");
$te->execute("16j");
$te->execute("3d");
is($te->buffer, "this is\nainitialffer",
   "buffer contents after deleting several characters forwards");
is($te->pointer, 16,
   "buffer position after deleting several characters forwards");
$te->execute("-11d");
is($te->buffer, "this ffer",
   "buffer contents after deleting several characters backwards");
is($te->pointer, 5,
   "buffer position after deleting several characters backwards");
