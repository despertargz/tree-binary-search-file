use strict;
use warnings;
use v5.10;
use lib '/';
use Tree::Binary::Search::File;
use Benchmark ':all';
use Time::HiRes qw(gettimeofday);
use LinearSearch;
use Test::More;

#autoflush STDOUT 1;

my $final = 10; 
for (1..$final) {
    build_hash($_);
}

exit(1);
#my $bft = Tree::Binary::Search::File->new("/tmp/test_bst-blah");
#my $hash = { key1 => 'value1', key2 => 'value2' };
#
#$bft->write_file($hash);
#
#
#$bft = Tree::Binary::Search::File->new("/tmp/test_bst-blah");
#my $v = $bft->get("key1");
#use Data::Dumper;
#print Dumper($v);
#
#my $v = $bft->get("key2");
#print Dumper($v);
#exit(1);


my $n = 2;
my $results = {};
my $iterations = 21;

sub build_hash {
    my $n = shift;

    my $hash = {};
    foreach (1..$n) {
        my $padding = '';
        my $r = rand(10);
        #my $padding = "_" x ($r + 1);
        $padding = "_" x $n;
        say $padding;
        $hash->{"Key$_"} = $padding . "Value$_";
    }

    my $bft = Tree::Binary::Search::File->new("/tmp/test_bst-$n");
    $bft->write_file($hash);

    $bft = Tree::Binary::Search::File->new("/tmp/test_bst-$n");
    foreach (1..$n) {
        print "on $n\n";
        my $v = $bft->get("Key$_");
        my $m = $v =~ /Value$_/;
        ok $m, 'match ' . $_ . ' of ' . $n;
    }
}

foreach (1..$iterations) {
    #say("test #$_/100 - $n");
    my $hash = build_hash($n);

    print Dumper($hash);

    my $linear_file = "/tmp/linear-$n";
    my $ls = LinearSearch::write($linear_file, $hash);
    my $linear_time = linear($n);

    my $time = build($_, $n);

    say "$n, $time, $linear_time";

    $results->{$n} = $time;
    #say "ratio: " . $time / $n;
    #say "";
    $n *= 2;
}


sub linear {
    my $n = shift;
    my $linear_file = "/tmp/linear-$n";
    my $start = gettimeofday;
    my $v = LinearSearch::get($linear_file, "Key$n");
    my $end = gettimeofday;
    return $end - $start;
}

sub build {
    my $i = shift;
    my $n = shift;

    my $start = gettimeofday;
    my $bft = Tree::Binary::Search::File->new("/tmp/test_bst-$n");
    my $o = $bft->get("Key1"); 
    use Data::Dumper;
    print Dumper($o);
    my $end = gettimeofday;

    my $result = $end - $start;

    use Test::More;
    my $match = $o =~ /Value1/;
    ok $match, 'match!';

    return $result;
}
