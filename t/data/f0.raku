#!/usr/bin/env raku

  =begin pod

  =begin comment

  =end comment

  =begin comment

    =begin comment

    =end comment

  =end comment

  =begin comment

  =end comment

  =end pod

my $fh = open 'f1', :rw;

my $fh2 = open 'f2', :a;

my $fh3 = open 'f3', :rw, :r;

my $fh4 = open 'f4', :r;

my $p = Proc.new: :err, :out;

my $p2 = Proc.new: :err;

my $p3 = Proc.new: :out;

my $p4 = Proc.new;

my $p5 = Proc.new: :out, :err;

$p.out.close;

$p5.out.spurt(:close);

foreach 

# Perl heredoc
my $s=<<"HERE";
fg
HERE

my $r = qq:heredoc/HERE/;
hfc
 HERE

my $t = qq:to/HERE/;
gufsd
 HERE  

my $u = qq:to/HERE2/;
gufsd
 HERE2 

my $w = g:to/HERE3/;
d
n ng bg
  HERE3

# unclosed heredoc:
my $u = qq:to/HERE/;
gufsd
 HERE  



