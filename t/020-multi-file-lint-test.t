use Test;

use Raku::Lint;
use File::Temp;

plan 5;

my %h = set <
    ./t/data/f0.raku
    ./t/data/f1.raku
    ./t/data/f2.raku
    ./t/data/f3.raku
>;
my $fil-args = %h.keys.join(" ");
my $idir = "./t/data";
my $ostr;
my @ifils;

@ifils = %h.keys;

my ($ifil, $fh) = tempfile;
$fh.say($_) for @ifils;
$fh.close;

lives-ok {
    $ostr = lint @ifils;
}, "handle multiple files";

lives-ok {
    shell "raku -Ilib ./bin/raku-lint $fil-args > /dev/null";
}, "handle multiple files";

lives-ok {
    shell "raku -Ilib ./bin/raku-lint -v $fil-args > /dev/null";
}, "handle multiple files and an option";

lives-ok {
    shell "raku -Ilib ./bin/raku-lint $fil-args -v > /dev/null";
}, "handle multiple files and an option in any position";

lives-ok {
    shell "raku -Ilib ./bin/raku-lint $fil-args -v --file=$ifil --dir=$idir > /dev/null";

}, "handle multiple files and an option in any position";
