#!/usr/bin/perl

use Business::Shipping;
use Business::Shipping::Shipment;
use Business::Shipping::Shipment::UPS;
use Business::Shipping::Package;
use Business::Shipping::Package::UPS;
use Business::Shipping::RateRequest;
use Business::Shipping::RateRequest::Online;
use Business::Shipping::UPS_Online::RateRequest;

my $rate_request = Business::Shipping::UPS_Online::RateRequest->new();

$rate_request->to_zip( '98270' );

