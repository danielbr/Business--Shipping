# $Id: UPS.pm,v 1.6 2004/03/03 03:36:32 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment::UPS;

=head1 NAME

Business::Shipping::RateRequest::Online::UPS - Estimates shipping cost online

=head1 VERSION

$Revision: 1.6 $      $Date: 2004/03/03 03:36:32 $

=head1 DESCRIPTION

See Business::Shipping POD for usage information.

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment' );

=item * to_residential

=cut
use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
    grouped_fields_inherit => [
		optional => [ 'to_residential' ],
		unique => [ 'to_residential' ],
		required => [ 'from_zip' ],
	];

#
# Why is this 'shipper' default needed for Shipping::Shipment::UPS?
#
use constant INSTANCE_DEFAULTS => (
	shipper => 'UPS',
);
 
sub init
{
	my $self   = shift;
	my %values = ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
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