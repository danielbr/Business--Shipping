#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Carp;
use Business::Shipping;
use constant CLOSE_ENOUGH_PERCENT   => 10;

my %user = (
        user_id    => $ENV{ UPS_USER_ID },
        password   => $ENV{ UPS_PASSWORD },
        access_key => $ENV{ UPS_ACCESS_KEY },
);

my %test;
my $this_test_desc;
sub test
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        from_state => 'Washington',    
        shipper    => 'Offline::UPS',
        cache      => 0,
    );
    
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

sub test_online
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        shipper    => 'Online::UPS',
        cache      => 0,
        %user
    );
    
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

sub close_enough
{
    my ( $n1, $n2 ) = @_;
    
    my ( $greater, $lesser ) = $n1 > $n2 ? ( $n1, $n2 ) : ( $n2, $n1 );
    my $percentage_of_difference = $lesser / $greater;
    
    return 1 if ( $percentage_of_difference <= ( CLOSE_ENOUGH_PERCENT * .10 ) );
    return 0;
}


my $shipment;
my $shipment_online;

my $ups_online_msg = 'UPS: we need the username, password, and access license key';
###########################################################################
##  Domestic Single-package API
###########################################################################

my %one_da_light_us = (
    service        => '1DA',
    weight         => '3.45',
    from_zip       => '98682',
    to_residential => '0',
    to_zip         => '98270',
);

$shipment = test( %one_da_light_us );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "offline 1DA light close: " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %one_da_light_us );
    ok( $shipment_online->total_charges(),        'UPS domestic single-package API total_charges > 0' );
    print "online 1DA light close: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_heavy_far_us = (
    service            => 'GNDRES',
    weight            => '45.00',
    from_zip        => '98682',
    to_residential    => '',
    to_zip            => '22182',
);

$shipment = test( %ground_res_heavy_far_us );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, heavy, far: " . $shipment->total_charges() . "\n";


SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %ground_res_heavy_far_us );
    ok( $shipment_online->total_charges(),        'UPS domestic single-package API total_charges > 0' );
    print "Online: GNDRES, heavy, far: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_light_far_us = (
    service            => 'GNDRES',
    weight            => '3.00',
    from_zip        => '98682',
    to_residential    => '',
    to_zip            => '22182',
);

$shipment = test( %ground_res_light_far_us );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, light, far: " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %ground_res_light_far_us );
    ok( $shipment_online->total_charges(),        'UPS domestic single-package API total_charges > 0' );
    print "Online: GNDRES, light, far: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_light_close_us = (
    service            => 'GNDRES',
    weight            => '3.00',
    from_zip        => '98682',
    to_residential    => '',
    to_zip            => '98270',
);

$shipment = test( %ground_res_light_close_us );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, light, close: " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %ground_res_light_close_us );
    ok( $shipment_online->total_charges(),        'UPS domestic single-package API total_charges > 0' );
    print "Online: GNDRES, light, close: " . $shipment_online->total_charges() . "\n";
}

my %ground_res_medium_close_us = (
    service            => 'GNDRES',
    weight            => '22.50',
    from_zip        => '98682',
    to_residential    => '1',
    to_zip            => '22182',
);

$shipment = test( %ground_res_medium_close_us );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, medium, close, residential: " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %ground_res_medium_close_us );
    ok( $shipment_online->total_charges(),        'UPS domestic single-package API total_charges > 0' );
    print "Online: GNDRES, medium, close, residential: " . $shipment_online->total_charges() . "\n";
}


my %ground_res_medium_close_us_98075 = (
    service            => 'GNDRES',
    weight            => '22.50',
    from_zip        => '98682',
    to_residential    => '1',
    to_zip            => '98075',
);

$shipment = test( %ground_res_medium_close_us_98075 );
ok( $shipment->total_charges(),        'UPS domestic single-package API total_charges > 0' );
print "Offline: GNDRES, medium, close, residential: " . $shipment->total_charges() . "\n";


###########################################################################
##  International
###########################################################################
%test = (
    from_state  => 'Washington',
    from_zip    => '98682',
    service     => 'XPD',
    weight      => 20,
    to_country  => 'GB',
    to_zip      => 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),        'UPS offline intl to gb' );
print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),        'UPS intl to gb' );
    print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

%test = (
    from_state    => 'Washington',
    from_zip    => '98682',
    service        => 'XPR',
    weight        => 20,
    to_country    => 'GB',
    to_zip        => 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),        'UPS offline express to gb' );
print "Offline: intl express to gb " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),        'UPS intl to gb' );
    print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

%test = (
    from_state    => 'Washington',
    from_zip    => '98682',
    service        => 'XDM',
    weight        => 20,
    to_country    => 'GB',
    to_zip        => 'RH98AX',
);

$shipment = test( %test );
ok( $shipment->total_charges(),        'UPS express plus intl to gb' );
print "Offline: intl to gb " . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),        'UPS intl to gb' );
    print "Online: intl to gb: " . $shipment_online->total_charges() . "\n";
}

%test = (
        shipper =>      'Offline::UPS',
        service =>      'XPR',
        to_country =>   'CA',
        weight =>       '0.5',
        to_zip =>       'M1V 2Z9',
);
$this_test_desc = "0.5 XPR to Canada M1V: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";




###########################################################################
##  Hawaii / Alaska
###########################################################################

  
%test = (
    service        => '2DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '96826',
);
$this_test_desc = "Hawaii 2DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc );
    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() . "\n";
}




my $rr = Business::Shipping->rate_request( shipper => 'Offline::UPS' );

$rr->submit(
    service        => '1DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '96826',
    
) or die $rr->user_error();

print "Hawaii 2DA (alternate calling method):" . $rr->total_charges() . "\n";
ok( $rr->total_charges, "Hawaii 2DA (alternate calling method):" );





%test = (
    service        => '1DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '96826',
);
$this_test_desc = "Hawaii 1DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );
}

%test = (
    service        => '2DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '99501',
);
$this_test_desc = "Alaska 2DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );
}

%test = (
    service        => '1DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '99501',
);
$this_test_desc = "Alaska 1DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );
}


###################
##  Mexico 
###################

%test = (
    from_zip    => '98682',
    from_state    => 'Washington',
    service        => 'XPD',
    weight        => 2.25,
    to_country    => 'MX',
    to_zip        => '06400',
);
$this_test_desc = "Mexico XPD: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );    
}


###################
##  NetherLands 
###################

%test = (
        from_zip =>      '98682',
        from_state =>    'Washington',
        service =>       'XPD',
        to_country =>    'NL',
        weight =>        '12.75',
);
$this_test_desc = "Netherlands XPD: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

###################
##  Israel 
###################

%test = (
        from_zip =>     '98682',
        from_state =>   'Washington',
        shipper =>      'Offline::UPS',
        service =>      'XPR',
        to_country =>   'IL',
        weight =>       '1.75',
        to_zip =>       '034296',
);
$this_test_desc = "Israel XPR: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";

SKIP: {
    skip( $ups_online_msg, 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );

    $shipment_online = test_online( %test );
    ok( $shipment_online->total_charges(),    "UPS Online: " . $this_test_desc . $shipment_online->total_charges() );    
}

########################################################################
##  Make sure that it handles zip+4 zip codes correctly (by throwing
##  away the +4.
########################################################################
%test = (
        from_country =>         'US',
        to_country =>           'US',
        from_state =>           'WA',
        service =>              '2DA',
        to_residential =>       '1',
        from_zip =>             '98682',
        weight =>               '4.25',
        to_zip =>               '96720-1749',
);
$this_test_desc = "Zip+4: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";


my %r1 = (
    from_city      => 'Vancouver',
    from_zip       => '98682',
    
    to_city        => 'Enterprise',
    to_zip         => '36330',
    to_residential => 1,
    
    weight         => 2.75,
    service        => 'GNDRES',
);

my $rr_off = Business::Shipping->rate_request( shipper => 'Offline::UPS', %r1 );
$rr_off->submit or die $rr_off->user_error();

my $rr_on = Business::Shipping->rate_request( shipper => 'Online::UPS', %r1, %user );
$rr_on->submit or die $rr_on->user_error();

ok( close_enough( $rr_off->total_charges(), $rr_on->total_charges() ),
    'UPS Offline and Online are close enough for GNDRES, light, far' 
  );

#TODO: {
#      local $TODO = "Not yet implmented.";
#
#}; #/end TODO

1;
