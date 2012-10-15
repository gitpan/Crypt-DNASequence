package Crypt::DNASequence;

use strict;

our $VERSION = '0.1';

my $keys = [['00', '11', '01', '10'],
            ['00', '11', '10', '01'],
            ['00', '01', '11', '10'],
            ['00', '01', '10', '11'],
            ['00', '10', '11', '01'],
            ['00', '10', '01', '11'],
            ['11', '00', '01', '10'],
            ['11', '00', '10', '01'],
            ['11', '01', '00', '10'],
            ['11', '01', '10', '00'],
            ['11', '10', '00', '01'],
            ['11', '10', '01', '00'],
            ['01', '00', '10', '11'],
            ['01', '00', '11', '10'],
            ['01', '10', '00', '11'],
            ['01', '10', '11', '00'],
            ['01', '11', '00', '10'],
            ['01', '11', '10', '00'],
            ['10', '00', '01', '11'],
            ['10', '00', '11', '01'],
            ['10', '01', '00', '11'],
            ['10', '01', '11', '00'],
            ['10', '11', '00', '01'],
            ['10', '11', '01', '00']];

sub encrypt {
    my $class = shift;
    my $text = shift;
    $text = $text;
    
    my $dict = initial_dict();

    my @letters = split "", $text;
    my @binary_str = map { my $a = sprintf "%b", ord($_); 
                       '0' x (8 - length($a)) . $a } @letters;
    
    my $str = join "", map { look_in_dict($_, $dict) } @binary_str;
    
    my $first_letter = substr($str, 0, 1);
    my $number_of_a = grep {$_ eq $first_letter} split "", $str;
    my $key_index = $number_of_a % scalar(@$keys);
    my @key_letters = map {$dict->{$_}} @{$keys->[$key_index]};
    
    $str = "$key_letters[0]$key_letters[1]$str$key_letters[2]$key_letters[3]";
    
    return fasta_format($str);
}

sub decrypt {
    my $class = shift;
    my $text = shift;
    $text =~s/\s*//sg;

    my $tag = substr($text, 0, 2).substr($text, -2, 2);
    my @letters = split "", $tag;
    
    $text = substr($text, 2, length($text) - 4);
    my $first_letter = substr($text, 0, 1);
    my $number_of_a = grep {$_ eq $first_letter} split "", $text;
    my $key_index = $number_of_a % scalar(@$keys);
    
    my $dict = {$letters[0] => $keys->[$key_index]->[0],
                $letters[1] => $keys->[$key_index]->[1],
                $letters[2] => $keys->[$key_index]->[2],
                $letters[3] => $keys->[$key_index]->[3]};
    my $str = "";
    for(my $i = 0; $i < length($text) - 1; $i += 4) {
        my $s = substr($text, $i, 4);
        my $bi = join "", map {$dict->{$_}} split "", $s;
        $str .= chr(oct("0b$bi"));
    }
    return $str;
}

sub look_in_dict {
    my $b = shift;
    my $dict = shift;
    
    my @di = $b =~/(\d\d)/g;
    return join "", map {$dict->{$_}} @di;

}

sub initial_dict {
    
    if(rand() < 0.5) {
        return { _random_assign(['00', '11'], ['A', 'T']),
                 _random_assign(['10', '01'], ['C', 'G'])
                };
    }
    else {
        return { _random_assign(['00', '11'], ['C', 'G']),
                 _random_assign(['10', '01'], ['A', 'T'])
                };
    }
}

sub _random_assign {
    my $key = shift;
    my $value = shift;
    
    if(rand() < 0.5) {
        return ($key->[0] => $value->[0],
                $key->[1] => $value->[1]);
    }
    else {
        return ($key->[1] => $value->[0],
                $key->[0] => $value->[1]);
    }
}

sub fasta_format {
    my $seq = shift;
    
    my $new = "";
    
    my $l = 0;
    while($l + 70 <= length($seq)) {
        $new .= substr($seq, $l, 70). "\n";
        $l += 70;
    }
    if($l < length($seq)) {
        $new .= substr($seq, $l)."\n";
    }
    
    return $new;
}

__END__

=pod

=head1 NAME

Crypt::DNASequence - Encrypt and decrypt strings to DNA Sequences

=head1 SYNOPSIS

  use Crypt::DNASequence;
  
  my $text = "hello world!";
  my $encrypted = Crypt::DNASequence->encrypt($text);
  print $encypted."\n";
  
  my $decrypted = Crypt::DNASequence->decrypt($encrypted);
  print $decrypted."\n";

=head1 DESCRIPTION

The module is naiive and just for fun. It transforms text strings into DNA sequences. A DNA sequence
is composed of four nucleotides which are represented as A, T, C, G. If we transform 
"abcdefghijklmnopqistuvwxyzABCDEFGHIJKLMNOPQISTUVWXYZ", the corresponding sequence would be:

  GTCGACCGAGCGATCGCACGCCCGCGCGCTCGGACGGCCGGGCGGTCGTACGTCCGTGCGTTCTAACTAC
  CGGCCTATCTCACTCCCTCGCTCTCTGACTGCCTGGCAACCAAGCAATCACACACCCACGCACTCAGACA
  GCCAGGCAGTCATACATCCATGCATTCCAACCACCAGCCCATCCCACCCCCCCGCCCTCCGACCGCCCGG
  AC

or

  CAGCTGGCTCGCTAGCGTGCGGGCGCGCGAGCCTGCCGGCCCGCCAGCATGCAGGCACGCAAGATTGATG
  GCCGGATAGAGTGAGGGAGCGAGAGACTGACGGACCGTTGGTTCGTTAGTGTGTGGGTGCGTGAGTCTGT
  CGGTCCGTCAGTATGTAGGTACGTAAGGTTGGTGGTCGGGTAGGGTGGGGGGGCGGGAGGCTGGCGGGCC
  TG
  
The transformation is not unique due to a random mapping, but all the transformed sequences can be 
decrypted correctly to the origin string.

=head1 ALGORITHM

The algorithm behind the module is simple. Two binary bits are used to represent a nucleotide such as '00' for A, '01' for C. 
If you have some knowledge of molecular biology, you would know that A only matches to T and C only matches to G.
So if '00' is choosen to be A, then '11' should be used to represent 'T'. In the module, the correspondence between binary bits
and nucleotides are applied randomly. The information of the correspondence dictionary is also stored in the finnal sequence.

Here is the procedure for encryption. 1. Split a string into a set of letters or charactors. 2. For each letter, convert to
its binary form and transform to ATCG every two bits using a randomly generated dictionary. The dictionary may looks like:

  $dict = { '00' => 'A',
            '11' => 'T',
            '01' => 'C',
            '10' => 'G' };

3. Join the A, T, G, C as a single sequence. 4. Find the first nucleotide of the sequence. 5, Find the number of the first nucleotide
in the sequence. 6. There is a database storing all arrangements of '00', '11', '01', '10'. 7. Calculate the index value from
the number of the first nucleotide by mod calculation. 8. Retrieve the arrangement with the index value, map them to the dictionary and get four nucleotides. E.g. the first nucleotide of the sequence is G. The number of G in the sequence is 40. The number of all arrangement
in the database is 24. Then we calculate the index value by 40 % 24 = 16. Then the 16th arrangement is retrieved and may looks like
['01', '11', '10', '00']. The four items in the array are mapped to the dictionary to be four nucleotides such as CTGA. Note this information
can be used in the decryption procedure.
9. Put the first two nucleotides at the begining of the sequence and the last two nucleotides at the end of the sequence. 10. That
is the finnal seuqence.

Here is the procedure for decryption. 1. Extract the first two and the last two nucleotides fromt the sequence. E.g. CT and GA. 
2. Count the number of the first nucleotide in the real sequence, e.g., 40 for G. 3. Use this number to calculate the index in the 
arrangement database, e.g., 16. 4. find the dictionary, i.e. a dictionary is generated from the 16th arrangement ['01', '11', '10', '00'] and
CTGA. 5. Translate the DNA sequence according the dictionary into binary bit form and finnaly to the orgin format.

=head2 Subroutines

=over 4

=item C<Crypt::DNASequence->encrypt($string)>

encrypt the string to DNA sequence

=item C<Crypt::DNASequence->decrypt($encrypted)>

decrypt the DNA sequence to the origin string
               
=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
