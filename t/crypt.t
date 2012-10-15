use Test::More tests => 5;
use strict;
use Crypt::DNASequence;

BEGIN { use_ok('Crypt::DNASequence') }


my $text = "hello world!";
is(Crypt::DNASequence->decrypt(Crypt::DNASequence->encrypt($text)), $text);
is(Crypt::DNASequence->decrypt(Crypt::DNASequence->encrypt($text)), $text);
is(Crypt::DNASequence->decrypt(Crypt::DNASequence->encrypt($text)), $text);
is(Crypt::DNASequence->decrypt(Crypt::DNASequence->encrypt($text)), $text);
