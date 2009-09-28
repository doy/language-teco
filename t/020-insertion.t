#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new;
$te->execute("i$buftext\e");
is($te->buffer, $buftext, "buffer contents after inserting a string");
is($te->pointer, length $buftext, "buffer position after inserting a string");
$te->execute("4j");
$te->execute("65i");
is($te->buffer, "thisA is\nan initial buffer",
   "buffer contents after inserting an ascii code");
is($te->pointer, 5, "buffer position after inserting an ascii character");
$te->execute("10c");
$te->execute("i12345\e");
is($te->buffer, "thisA is\nan ini12345tial buffer",
   "buffer contents after inserting a string in the middle of the buffer");
is($te->pointer, 20,
   "buffer position after inserting a string in the middle of the buffer");
