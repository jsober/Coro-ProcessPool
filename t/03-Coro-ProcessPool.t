use strict;
use warnings;
use List::Util qw(shuffle);
use Coro;
use Test::More;

BEGIN { use AnyEvent::Impl::Perl }

my $class = 'Coro::ProcessPool';

use_ok($class) or BAIL_OUT;

my $pool = new_ok($class, [ max_reqs => 5 ]);
ok($pool->{max_procs} > 0, "max procs set automatically ($pool->{max_procs})");

my $doubler = sub { $_[0] * 2 };

subtest 'process' => sub {
    my $count = 20;
    my @threads;
    my %result;

    foreach my $i (shuffle 1 .. $count) {
        my $thread = async {
            my $n = shift;
            $result{$n} = $pool->process($doubler, [ $n ]);
        } $i;

        push @threads, $thread;
    }

    $_->join foreach @threads;

    foreach my $i (1 .. $count) {
        is($result{$i}, $i * 2, 'expected result');
    }
};

subtest 'map' => sub {
    my @numbers  = 1 .. 100;
    my @actual   = $pool->map($doubler, @numbers);
    my @expected = map { $_ * 2 } @numbers;
    is_deeply(\@actual, \@expected);
};

subtest 'defer' => sub {
    my $count = 20;
    my %result;

    foreach my $i (shuffle 1 .. $count) {
        $result{$i} = $pool->defer($doubler, [$i]);
    }

    foreach my $i (1 .. $count) {
        is($result{$i}->(), $i * 2, 'expected result');
    }
};

$pool->shutdown;

done_testing;
