#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Carp;

use Business::Shipping;
my $t = Business::Shipping->rate_request( shipper => 'Offline::Template' );

ok( 1, 'no tests yet' );

1;