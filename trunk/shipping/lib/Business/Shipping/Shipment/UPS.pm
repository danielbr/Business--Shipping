# $Id: UPS.pm,v 1.10 2004/06/24 03:09:25 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment::UPS;

=head1 NAME

Business::Shipping::Shipment::UPS

=head1 VERSION

$Revision: 1.10 $      $Date: 2004/06/24 03:09:25 $

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

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
      scalar => [ 'from_state' ],
      #
      # We need this offline boolean to know if from_state is required.
      #
      scalar => [ 'offline' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Optional' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Unique' ],
      array  => [ { -type => 'Business::Shipping::Package::UPS' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'default_package=>Business::Shipping::Package::UPS' }, 'Has_a' ],
    ];

sub this_init
{
    $_[ 0 ]->shipper(      'UPS' );
    return;
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