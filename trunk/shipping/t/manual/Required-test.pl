#!/usr/bin/perl

use strict;
use warnings;
use Business::Shipping;

#my $rr = Business::Shipping->rate_request( shipper => 'Online::UPS' );
my $rr = Business::Shipping->rate_request( shipper => 'Online::USPS' );

$rr->event_handlers(
    {
        debug  => 'STDOUT',
        #debug3 => 'STDOUT',
        #trace  => 'STDOUT',
        #error  => 'STDOUT',
    }
);

print STDOUT "Before, Shipment::USPS object was: " . $rr->shipment . "\n";
my @Required = $rr->get_grouped_attrs( 'Required' );
print STDOUT "Required = " . join( ', ', @Required )  . "\n";

