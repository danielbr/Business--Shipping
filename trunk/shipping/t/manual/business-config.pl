#!/usr/bin/perl
#
# Test Business::Shipping::Config
#

use strict;
use warnings;
use diagnostics;

use Business::Shipping::Config;

my $cfg_obj  = cfg_obj();
print cfg()->{Database}{DSN} . "\n";
print $cfg_obj->val( 'Database', 'DSN' ) . "\n";
