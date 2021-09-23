#!/usr/bin/env raku

my @lines = 
"     some text",
"  ",
"",
"a",
;

for @lines -> $line {
    say "line: |$line| (nchars: {$line.chars}";
    my ($indent, $nchars) = indent $line;
    say "  indent: |$indent| (nchars: $nchars";
}


sub indent($s --> List) {
    my $indent = '';
    if $s ~~ /^ (\h*) / {
        $indent = ~$0;
    }
    $indent, $indent.chars
} # sub indent


