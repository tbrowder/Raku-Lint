use v6;
use Test;

use Raku::Lint;
use Proc::Easy;

plan 4;

my $s = q:to/HERE/;
Normal end.
  begin comment: 4
  begin pod: 1
  end comment: 4
  end pod: 1
open:  8
close: 2

HERE

my $ostr;
# need some small test files to test output with
{
    lives-ok {
        $ostr = run-command "./bin/raku-lint ./t/data/raku-lint-test-script.raku", :out;
    }
    is $ostr, $s;
}
{
    lives-ok {
        $ostr = run-command "./bin/raku-lint -v ./t/data/raku-lint-test-script.raku", :out;
    }
    is $ostr, $s;
}
