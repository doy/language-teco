#!perl -T
use strict;
use warnings;
use Test::More tests => 8;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("10j");
$te->execute("d");
is($te->buffer, "this is\naninitial buffer");
is($te->pointer, 10);
$te->execute("-d");
is($te->buffer, "this is\nainitial buffer");
is($te->pointer, 9);
$te->execute("16j");
$te->execute("3d");
is($te->buffer, "this is\nainitialffer");
is($te->pointer, 16);
$te->execute("-11d");
is($te->buffer, "this ffer");
is($te->pointer, 5);
