#!/usr/bin/perl

use strict;
use warnings;
use Business::Shipping;

my $rr = Business::Shipping->rate_request( shipper => 'Online::UPS' );

$rr->event_handlers(
    {
        #debug  => 'STDOUT',
        #debug3 => 'STDOUT',
        #trace  => 'STDOUT',
        #error  => 'STDOUT',
    }
);
my @Unique = $rr->get_grouped_attrs( 'Unique' );
print STDOUT "Unique = " . join( ',', @Unique )  . "\n";


