# Business::Shipping::RateRequest::Offline
#
# $Id: Offline.pm,v 1.8 2004/03/08 17:13:56 danb Exp $
#
# Copyright (c) 2003 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
#

package Business::Shipping::RateRequest::Offline;

=head1 DESCRIPTION

Business::Shipping::RateRequest::Offline doesn't have very much to it.  It just
disables the cache feature, and has a few miscellaneous function.

=cut

$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest' );
use Business::Shipping::RateRequest;
use Business::Shipping::Shipment;
use Business::Shipping::Package;
use Business::Shipping::Debug;
use Class::MethodMaker 2.0 [ new => [ qw/ -hash new / ] ];
    
# We don't have online things to request.
sub perform_action {}

=item * cache()

Cache always disabled for Offline lookups: they are so fast already, the disk I/O
of a running a cache is not worth it.

=cut
sub cache { return 0; }

=item * make_three( $zip )

 $zip   Input to shorten/lengthen.  Usually a zip code.
 
Shorten to three digits.  If the input doesn't have leading zeros, add them.

=cut
sub make_three 
{
    my ( $self, $zip ) = @_;
    return unless $zip;
    trace( '( ' . ( $zip ? $zip : 'undef' ) . ' )' );
    
    $zip = substr( $zip, 0, 3 );
    while ( length( $zip ) < 3 ) {
        $zip = "0$zip";
    }
    
    return $zip;
}

1;
