# Copyright (c) 2003 Kavod Technologies, Dan Browning. 
# All rights reserved. 

package Business::Shipping::RateRequest::Offline;


=head1 NAME

Business::Shipping::RateRequest::Offline - Abstract class for cost calculation.

=head1 VERSION

$Rev$      $Date$

=head1 DESCRIPTION

This doesn't have very much to it.  It just disables the cache feature, and has
a few miscellaneous functions.

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Rev$=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest' );
use Business::Shipping::RateRequest;
use Business::Shipping::Shipment;
use Business::Shipping::Package;
use Business::Shipping::Logging;
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

__END__

=back

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
