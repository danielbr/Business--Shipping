#!/usr/bin/perl

#
# TODO: This test is acting as if it was always 1 pound.
#
# This probably means that the cache isn't working correctly.
#
# That is probably due to the changes in Unique().
#
#

use strict;
use warnings;
use testlib;

my $rr = test_ol_usps(
    event_handlers => {
        debug => 'STDERR',
    },
        'test_mode'  => 1,
        'pounds'     => 0,
        'ounces'     => 1,
        'mail_type'  => 'Postcards or Aerogrammes',
        'to_country' => 'Algeria',
);

$rr->submit() or die $rr->error();
ok( $rr->total_charges, 'Online::USPS International does not require certain fields.' );
 


