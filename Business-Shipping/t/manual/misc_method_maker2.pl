#!/bin/perl

use Business::Shipping;

my $bs2 = Business::Shipping->new;
my $Optional = $bs2->Optional;
print "Optional = \'$Optional\'\n";

use Business::Shipping::RateRequest;

my $bs3 = Business::Shipping::RateRequest->new;
my $Required = $bs3->Required;
print "Required = \'$Required\'\n";


