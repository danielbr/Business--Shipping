# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment::UPS;

=head1 NAME

Business::Shipping::Shipment::UPS

=head1 VERSION

$Rev$      $Date$

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Rev$=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment' );
use Business::Shipping::Config;

=item * to_residential

Defaults to true.

=cut

use Class::MethodMaker 2.0
    [ 
      new    => [ { -hash => 1, -init => 'this_init' },  'new' ],
      scalar => [ { default => 1 }, 'to_residential' ],
      scalar => [ 'from_state', '_service' ],
      #
      # We need this offline boolean to know if from_state is required.
      #
      scalar => [ 'offline' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Optional' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Unique' ],
      array  => [ { -type => 'Business::Shipping::Package::UPS' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'packages=>Business::Shipping::Package::UPS' }, 'Has_a' ],
    ];

sub this_init
{
    $_[ 0 ]->shipper(      'UPS' );
    return;
}

sub packaging { shift->package0->packaging( @_ ) }
sub weight    { shift->package0->weight( @_ )    }
sub service
{
    my ( $self, $service ) = @_;
    
    return $self->_service unless $service;
    
    # TODO: This is where the mode_map stuff goes.
    $self->_service( $service );
    
    return $service;
}

sub massage_values 
{
    my ( $self ) = @_;


    # Check each package for a package type and assign one if none given.
    my %default_package_map = (
        qw/
        1DM    02
        1DML   01
        1DA    02
        1DAL   01
        1DP    02
        2DM    02
        2DA    02
        2DML   01
        2DAL   01
        3DS    02
        GNDCOM 02
        GNDRES 02
        XPR    02
        UPSSTD 02
        XDM    02
        XPRL   01
        XDML   01
        XPD    02
        /
    );

    foreach my $package ( $self->packages ) {
        if ( not $package->packaging ) {
            if ( $default_package_map{ $self->service() } ) {
                $package->packaging( $default_package_map{ $self->service() } );
            } else {
                $package->packaging( '02' );
            }
        }
    }
    
    # UPS requires weight is at least 0.1 pounds.
    foreach my $package ( $self->packages ) {
        $package->weight( 0.1 ) if ( not $package->weight() or $package->weight() < 0.1 );
    }

    # In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
    $self->to_country( 'US' ) if not $self->to_country();
    if ( $self->to_zip() ) { 
        $self->to_zip() =~ /^(\d{5})/ and $self->to_zip( $1 );
    }
    
    # UPS prefers 'GB' instead of 'UK'
    $self->to_country( 'GB' ) if $self->to_country() eq 'UK';
    
}

=item * Required()

from_state only required for Offline international orders.

=cut

sub Required
{
    return 'service, from_state' if $_[ 0 ]->to_canada and $_[ 0 ]->offline;
    return 'service, from_zip, from_state' if $_[ 0 ]->intl and $_[ 0 ]->offline;
    return 'service, from_zip';
}
    

=item * from_state_abbrev()

Returns the abbreviated form of 'from_state'.

=cut

sub from_state_abbrev
{
    my ( $self ) = @_;
    
    my $state_abbrevs = config_to_hash( 
        cfg()->{ ups_information }->{ state_to_abbrev } 
    );
    
    return $state_abbrevs->{ $self->from_state } or $self->from_state;
}

=item * from_ak_or_hi()

Alaska and Hawaii are treated differently by many shippers.

=cut

sub from_ak_or_hi
{
    my ( $self ) = @_;
    
    return unless $self->from_state;
    if ( $self->from_state =~ /^(AK|HI)$/i ) {
        return 1;
    }
    
    return 0;
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