#!/usr/bin/perl

use Business::Ship::Package;
use Business::Ship::USPS::Package;


my $package = new Business::Ship::Package;


my $usps_package = new Business::Ship::USPS::Package;

use Data::Dumper;
print Dumper( $usps_package );
