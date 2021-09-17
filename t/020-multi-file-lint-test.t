use Test;

use Raku::Lint;

plan 4;

my %h = set <
    ./t/data/f0.raku
    ./t/data/f1.raku
    ./t/data/f2.raku
    ./t/data/f3.raku
>;
my $fil-args = %h.keys.join(" ");

my $ostr;
my %ifils;

%ifils = %h;
lives-ok {
    $ostr = lint :%ifils;
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
