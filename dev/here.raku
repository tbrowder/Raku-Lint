#!/usr/bin/env raku

my $line = q:to/HERE/;
one two three
  HERE

say $line;

my $line2 = q:to/HERE/;
  one two three

  four
  HERE

say $line2;


