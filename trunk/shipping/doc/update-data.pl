#!/usr/bin/perl

#
# update-data.pl
#
# Download new data for offline tables.
# May need to be run as 'root' on your system, if the support files
# are in a location accessible only to 'root'.
#

use strict;
use warnings;
use diagnostics;

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request( 
	shipper		=> 'Offline::UPS', 
);

$rate_request->auto_update( 1 );
$rate_request->do_update();

1;
__END__

