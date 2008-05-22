#!perl -T
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Language::TECO;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
throws_ok { $te->execute("100j") } qr/Pointer off page/,
          'moving the pointer off the end of the buffer';
throws_ok { $te->execute("-10j") } qr/Pointer off page/,
          'moving the pointer off the end of the buffer';
