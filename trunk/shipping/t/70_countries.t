use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use Data::Dumper;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::RateRequest::Online::UPS;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;

my $ups_online_rate_request = Business::Shipping::RateRequest::Online::UPS->new();
ok( defined $ups_online_rate_request, 'Business::Shipping::RateRequest::Online::UPS->new() worked' );


my @countries = (
    'Afghanistan',
);

