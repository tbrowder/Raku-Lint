#!/usr/bin/env raku

my @a = 1, 2;
my @b = 3, 4;

my @c;
@c.append: @a;
@c.append: @b;

my @d;
@d.push: @a;
@d.push: @b;

say "Appending to \@c:";
say @c.raku;


say "Pushing to \@d:";
say @d.raku;
