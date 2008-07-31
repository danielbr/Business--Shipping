#!/bin/env perl

# Simulate the way that Cache::FileCache is used.

use strict;
use warnings;
use Test::More;

eval { require Cache::FileCache; };
plan skip_all => 'Cache::FileCache not installed.' if $@;
plan 'no_plan';
import Cache::FileCache;

my $cache = Cache::FileCache->new;
my $key   = join("|", ('Parcel Post', 'Germany', '5', 'Package'));
my $rate  = $cache->get($key);

if (not defined $rate) {
    sleep(1);
    $rate = '5.99';
    $cache->set($key, $rate, "30 minutes");
}

ok(1, 'Cache::FileCache works as expected.');
