#!perl

use strict;
use warnings;
use Carp;
use Test::More 'no_plan';

use_ok( 'Business::Shipping' => { preload => 'All' } );

