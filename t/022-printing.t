#!perl -T
use strict;
use warnings;
use Test::More;
use Language::TECO;

my %tests = (
    0 => ["", "", "", "this is\n", "this is\nan initial buffer"],
    3 => ["thi", "thi", "thi", "s is\n", "s is\nan initial buffer"],
    7 => ["this is", "this is", "this is", "\n", "\nan initial buffer"],
    8 => ["this is\n", "this is\n", "", "an initial buffer", "an initial buffer"],
   10 => ["this is\nan", "this is\nan", "an", " initial buffer", " initial buffer"],
   25 => ["this is\nan initial buffer", "this is\nan initial buffer", "an initial buffer", "", ""],
);
plan tests => 1 + map { @{ $tests{$_} } } keys %tests;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
for my $pos (keys %tests) {
    $te->execute("${pos}j");
    for my $arg (-2..2) {
        is($te->execute("${arg}t"), $tests{$pos}[$arg + 2],
           "\"${arg}t\" at position $pos");
    }
}
is($te->execute("ht"), "this is\nan initial buffer",
   "ht prints the whole buffer");
