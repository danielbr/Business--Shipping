#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;
use Carp;

sub test
{
    my ( %args ) = @_;
    my $shipment = new Business::Shipping( 
        'shipper' => 'UPS',
        'user_id'        => $ENV{ UPS_USER_ID },
        'password'        => $ENV{ UPS_PASSWORD },
        'access_key'    => $ENV{ UPS_ACCESS_KEY }, 
        'cache_enabled'    => 0,
        'event_handlers' => ({ 
            #'debug' => 'STDOUT', 
            #'trace' => 'STDOUT', 
            #'error' => 'STDOUT', 
        }),
    );
    die $@ if $@;
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

    my $shipment;
    
=pod
    #
    # Several domestic tests on the "Test" server.
    #
    $shipment = test(
        'test_mode'    => 1,
        'service'    => 'EXPRESS',
        'from_zip'    => '20770',
        'to_zip'    => '20852',
        'weight'    => 10,
    );
=cut
    
    #
    # Several International tests on the "Test" server.
    #
    $shipment = test(
        'pickup_type'         => 'daily pickup',
        'from_zip'            => '98682',
        'from_country'        => 'US',
        'to_country'        => 'US',    
        'service'            => '1DA',
        'to_residential'    => '1',
        'to_zip'            => '98270',
        'weight'            => '3.45',
        'packaging'         =>  '02',
    );
    print $shipment->total_charges();
