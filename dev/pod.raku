#!/usr/bin/env raku

#=================
# top level parent
=begin pod
=begin pod
 =begin comment
=end comment
 =end comment
=end pod
=end pod

#=================
# top level parent
# items can nest
 =begin item
=begin item
=end item
 =end item

#=================
# top level parent
# pod can nest
   =begin pod

# paras can nest
=begin para
=begin para
=end para
=end para

# spurious end
#=end para

# spurious begin
=begin para


# comments cannot nest
 =begin comment
=begin comment
 =end comment

   =end pod

for $=pod -> $p {
    say "=== NAME";
    say $p.^name;
    say $p.contents;
}

=finish

my $line  = "=begin   item";
my $line2 = "    =begin   item#";
my $line3 = "  =begin   item :caption<t> #";

my ($indent, $typename);
for $line, $line2, $line3 -> $line {
    say "Input line: |$line|";
    if $line ~~ /^ (\h*) '=' begin \h+ (<alpha><alnum>+) \h*/ {
        $indent   = ~$0;
        $typename = ~$1;
    }
    say "  indent:   '$indent'";
    say "  typename: '$typename'";
}


=finish

my $a = 78;

=begin code

=end code

  =begin comment
comment

  one

# =begin comment

    two 

 =end comment

    three

  =end comment
#comment

#=end comment

for $=pod -> $p {
    say "=== NAME";
    say $p.^name;
    say $p.contents;
}


