#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
is($te->execute("5j.="), "5\n", "move + print position");
is($te->execute("iblah\e0t"), "this blah", "insert + print part of the buffer");
