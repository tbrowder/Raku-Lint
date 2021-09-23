my $line = "one two three";

say "Line in: '$line'";

if $line ~~ / two / {
    $line = paste $/;
}

say "Line out: '$line'";

sub paste(Match $m) {
    $m.prematch ~ " " ~ $m.postmatch
}

