#!perl -T
use strict;
use warnings;
use Test::More tests => 4;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("5j");
is($te->pointer, 5);
$te->execute("2c");
is($te->pointer, 7);
$te->execute("r");
is($te->pointer, 6);
$te->execute("1l");
is($te->pointer, 8);
