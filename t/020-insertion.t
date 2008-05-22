#!perl -T
use strict;
use warnings;
use Test::More tests => 6;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new;
$te->execute("i$buftext\e");
is($te->buffer, $buftext);
is($te->pointer, length $buftext);
$te->execute("4j");
$te->execute("65i");
is($te->buffer, substr($buftext, 0, 4) . chr(65) . substr($buftext, 4));
is($te->pointer, 5);
$te->execute("10c");
$te->execute("i12345\e");
is($te->buffer, "thisA is\nan ini12345tial buffer");
is($te->pointer, 20);
