use Test;

use Raku::Lint;

plan 2;

my $default-out = q:to/HERE/;
  begin comment: 4
  begin pod: 1
  end comment: 4
  end pod: 1
open:  8
close: 2
HERE

my $verbose-out = q:to/HERE/;
== Linting file './t/data/raku-lint-test-script.raku'...
line 3: =begin pod
  a 'begin' type
line 5: =begin comment
  a 'begin' type
line 7: =end comment
  an 'end' type
line 9: =begin comment
  a 'begin' type
line 11: =begin comment
  a 'begin' type
line 13: =end comment
  an 'end' type
line 15: =end comment
  an 'end' type
line 17: =begin comment
  a 'begin' type
line 19: =end comment
  an 'end' type
line 21: =end pod
  an 'end' type
line 23: open
  an 'open' type
line 25: open
  an 'open' type
line 27: open
  an 'open' type
line 29: open
  an 'open' type
line 31: :err
  an 'open' type
line 33: :err
  an 'open' type
line 35: :out
  an 'open' type
line 39: :out
  an 'open' type
line 41: close
  a 'close' type
line 43: :close
  a 'close' type
  begin comment: 4
  begin pod: 1
  end comment: 4
  end pod: 1
open:  8
close: 2
HERE

# need some small test files to test output with

my %h = set <
    ./t/data/raku-lint-test-script.raku
>;
my $ostr;
my %ifils;

%ifils = %h;
$ostr = lint :%ifils;
is $ostr, $default-out, "default output";


%ifils = %h;
$ostr = lint :%ifils, :verbose(1);
is $ostr, $verbose-out, "verbose output";
