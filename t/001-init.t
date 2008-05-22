#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
use Language::TECO;

my $te = Language::TECO->new;
isa_ok($te, 'Language::TECO');
is($te->buffer, '');
is($te->pointer, 0);

my $buftext = "this is\nan initial buffer";
my $buf_te = Language::TECO->new($buftext);
is($buf_te->buffer, $buftext);
is($buf_te->pointer, 0);
