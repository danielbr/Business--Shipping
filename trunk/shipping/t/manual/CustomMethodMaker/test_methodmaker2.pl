#!/usr/bin/perl

use strict;
use warnings;

use TopLevel;
use TopLevel::Medium;
use TopLevel::Medium::Low;

my $low = new TopLevel::Medium::Low;
my $med = new TopLevel::Medium;
my $high = new TopLevel;


print "low required = " . join( ', ', $low->required() ) . "\n";
