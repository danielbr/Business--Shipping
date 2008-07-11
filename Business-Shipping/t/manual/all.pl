#!/usr/local/perl/bin/perl

use strict;
use warnings;

use Business::Shipping;

my $rate_requests = Business::Shipping->rate_requests(
    shippers 	=> ['USPS_Online', 'UPS_Online'],
    to_zip 		=> 98682,
    from_zip	=> 10010,
    weight      => 5.5,
);

my $results = $rate_requests->execute() or die $rate_requests->error();

foreach my $shipper ( $results->shippers() ) {
    print "Shipper Name: $shipper->{name}\n";
    
    foreach my $service ( $shipper->services() ) {
        print "  Service: $service->{name}\n";
        print "  Price:   $service->{total_charges}\n";
    }
}
