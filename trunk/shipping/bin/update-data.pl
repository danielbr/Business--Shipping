#!/usr/bin/perl

=head1 NAME

update-data.pl - Updates data tables for Business::Shipping.

=head1 VERSION

$Rev$

=head1 SYNOPSIS

perl bin/update-data.pl --debug=0

=head1 DESCRIPTION

Downloads new data for offline tables.  May need to be run as 'root' on your
system, if the support files are in a location accessible only to 'root'.

=head2 Command-line arguments

=over 4

=item * --debug=<1|0>  -d<1|0>

Enable debug, trace, and error logging to STDERR.

=back

=head1 AUTHOR

 Dan Browning         <db@kavod.com>
 Kavod Technologies   http://www.kavod.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.

=cut

use strict;
use warnings;
use diagnostics;

use Business::Shipping;
use Getopt::Mixed;

our $opt_d;
Getopt::Mixed::getOptions( 'd:i debug>d t:i' );

my %rr_params;
if ( $opt_d ) {
    %rr_params = (
        %rr_params,
        event_handlers => {
            debug    => 'STDERR',
            trace    => 'STDERR',
            error    => 'croak',
        }
    );
}

my $rate_request = Business::Shipping->rate_request( 
    shipper    => "Offline::UPS",
    %rr_params,
);

$rate_request->auto_update();


1;
__END__
