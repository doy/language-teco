#!perl -T
use strict;
use warnings;
use Test::More tests => 9;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("5j");
is($te->pointer, 5, "buffer position after absolute positioning");
$te->execute("bj");
is($te->pointer, 0,
   "buffer position after moving to the beginning of the buffer");
$te->execute("zj");
is($te->pointer, length $buftext,
   "buffer position after moving to the end of the buffer");
$te->execute("5j");
$te->execute("-.d");
is($te->pointer, 0,
   "buffer position after deleting everything before the pointer");
is($te->buffer, "is\nan initial buffer",
   "buffer contents after deleting everything before the pointer");
$te->execute("1,6d");
is($te->buffer, "iinitial buffer",
   "buffer contents after deleting an absolute range");
$te->execute("b,.d");
is($te->buffer, "initial buffer",
   "buffer contents after deleting from the beginning to the current position");
$te->execute("5j");
$te->execute(".,zd");
is($te->buffer, "initi",
   "buffer contents after deleting from the current position to the end");
$te->execute("hd");
is($te->buffer, "",
   "buffer contents after deleting the entire buffer (position 'h')");
