#!/usr/bin/perl

use strict;
use warnings;
use Business::Shipping;
use Test::More 'no_plan';
use Carp;

my $rr_shop = Business::Shipping->rate_request( 
    service        => 'shop',    
    shipper        => 'UPS_Online',
    from_zip       => '98682',
    to_zip         => '98270',
    weight         => 5.00,
    user_id        => $ENV{ UPS_USER_ID },
    password       => $ENV{ UPS_PASSWORD },
    access_key     => $ENV{ UPS_ACCESS_KEY },
    
	cod            => 1,
	cod_funds_code => 0,
	cod_value      => 400.00,
);

ok( defined $rr_shop, 'Business::Shipping->rate_request returned an object.' );

$rr_shop->go() or die $rr_shop->user_error();

my $results = $rr_shop->results;

foreach my $shipper ( @$results ) {
    print "Shipper: $shipper->{name}\n\n";
    foreach my $rate ( @{ $shipper->{ rates } } ) {
        print "  Service:  $rate->{name}\n";
        print "  Charges:  $rate->{charges_formatted}\n";
        print "  Delivery: $rate->{deliv_date_formatted}\n" if $rate->{ deliv_date_formatted };
        print "\n";
    }
}

