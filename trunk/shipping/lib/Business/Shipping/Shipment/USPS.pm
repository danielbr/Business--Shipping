# $Id: USPS.pm,v 1.9 2004/03/03 04:07:52 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment::USPS;

=head1 NAME

usiness::Shipping::Shipment::USPS

=head1 VERSION

$Revision: 1.9 $      $Date: 2004/03/03 04:07:52 $

=head1 DESCRIPTION

See Business::Shipping POD for usage information.

=head1 TODO

Move the country translator data into configuration.

=over 4 METHODS

=cut

$VERSION = do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::Shipment' );
use Business::Shipping::Debug;
use Business::Shipping::Config;
use Business::Shipping::Package;
use Business::Shipping::CustomMethodMaker
    new_with_init => 'new',
    new_hash_init => 'hash_init';

use constant INSTANCE_DEFAULTS => (
    shipper => 'USPS',
    from_country => 'US',
);
 
sub init
{
    my $self   = shift;
    my %values = ( INSTANCE_DEFAULTS, @_ );
    $self->hash_init( %values );
    return;
}

=item * from_country

Always returns 'US'.

=cut
sub from_country { return 'US'; }

=item * to_country( $to_country ) 

Uses the name translaters of Shipping::Shipment::to_country(), then applies its
own translations.  The former may not be necessary, but the latter is.

=cut
sub to_country
{
    trace '( ' . uneval( \@_ ) . ' )';
    my ( $self, $to_country ) = @_;    
    
    if ( defined $to_country ) {
        #
        # Apply any Shipping::Shipment conversions, then apply our own.
        #
        $to_country = $self->SUPER::to_country( $to_country );
        my $countries = $self->config_to_hash(
            cfg()->{ usps_information }->{ usps_country_name_translations }
        );
        $to_country = $countries->{ $to_country } || $to_country; 
        
        debug3( "setting to_country to \'$to_country\'" );
        $self->{ to_country } = $to_country;
    } 
    debug3( "SUPER::to_country now is " . ( $self->SUPER::to_country() || '' ) );
    
    return $self->{ to_country };
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