use strict;
use warnings;
use Carp;
use Test::More;
use Business::Shipping;

plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'USPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Offline' );
plan 'no_plan';

use_ok( 'Business::Shipping' => { preload => 'All' } );
