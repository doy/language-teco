#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Language::TECO;

my %tests = (
    "15="    => "15\n",
    "15=="   => "17\n",
    "15:="   => "15",
    "15:=="  => "17",
    "-15="   => "-15\n",
    "-15=="  => "37777777761\n",
    "-15:="  => "-15",
    "-15:==" => "37777777761",
    "b="     => "0\n",
);
plan tests => 3 + keys %tests;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
for my $test (keys %tests) {
    is($te->execute($test), $tests{$test}, "\"$test\"");
}
is($te->execute(".:="), 0, "current position");
$te->execute("5j");
is($te->execute(".:="), 5, "current position");
is($te->execute("z:="), 25, "end of buffer");
