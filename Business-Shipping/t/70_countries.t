use strict;
use warnings;
use Test::More;
use Carp;
use Data::Dumper;
use Business::Shipping;
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Online' );
plan 'no_plan';

my $ups_online_rate_request = Business::Shipping->rate_request( shipper => 'UPS_Online' );
ok( defined $ups_online_rate_request, 'Business::Shipping->rate_request( shipper => \'UPS_Online\' ) worked' );

my @countries = (
    'Afghanistan',
);

