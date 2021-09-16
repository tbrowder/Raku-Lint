use Test;

use Raku::Lint;

plan 9;

my @opts = [
    "", 
    "-v", "--v", "-verbose", "--verbose", 
    "-d", "--d", "-debug", "--debug",
];

for @opts -> $o {
    lives-ok { 
        shell "raku -Ilib ./bin/raku-lint $o ./t/data/raku-lint-test-script.raku > /dev/null"; 
    }, "test option(s): '$o'"
}
