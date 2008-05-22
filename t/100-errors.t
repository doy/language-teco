#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Language::TECO;

my @test_cmds = qw/j c d/;
plan tests => @test_cmds * 6;

my $buftext = "this is\nan initial buffer";
my $te = Language::TECO->new($buftext);
$te->execute("5j");
for my $cmd (@test_cmds) {
    throws_ok { $te->execute("100$cmd") } qr/Pointer off page/,
              "moving the pointer off the end of the buffer ($cmd)";
    is($te->pointer, 5);
    is($te->buffer, $buftext);
    throws_ok { $te->execute("-100$cmd") } qr/Pointer off page/,
              "moving the pointer off the beginning of the buffer ($cmd)";
    is($te->pointer, 5);
    is($te->buffer, $buftext);
}
