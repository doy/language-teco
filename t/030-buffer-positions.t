#!perl -T
use strict;
use warnings;
use Test::More tests => 9;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("5j");
is($te->pointer, 5);
$te->execute("bj");
is($te->pointer, 0);
$te->execute("zj");
is($te->pointer, length $buftext);
$te->execute("5j");
$te->execute("-.d");
is($te->pointer, 0);
is($te->buffer, "is\nan initial buffer");
$te->execute("1,6d");
is($te->buffer, "iinitial buffer");
$te->execute("b,.d");
is($te->buffer, "initial buffer");
$te->execute("5j");
$te->execute(".,zd");
is($te->buffer, "initi");
$te->execute("hd");
is($te->buffer, "");
