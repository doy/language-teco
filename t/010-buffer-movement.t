#!perl -T
use strict;
use warnings;
use Test::More tests => 4;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("5j");
is($te->pointer, 5, "position after 'j' command");
$te->execute("2c");
is($te->pointer, 7, "position after 'c' command");
$te->execute("r");
is($te->pointer, 6, "position after 'r' command");
$te->execute("1l");
is($te->pointer, 8, "position after 'l' command");
