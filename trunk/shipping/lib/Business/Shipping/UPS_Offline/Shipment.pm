package Business::Shipping::UPS_Offline::Shipment;

=head1 NAME

Business::Shipping::UPS_Offline::Shipment

=head1 VERSION

$Rev: 158 $

=head1 METHODS

=over 4

=item * disable_hundredweight( )

If true, don't estimate the hundredweight rate even if it would otherwise be possible.

=item * hundredweight_margin( $percent )

If the shipment weight is only $percent (default 10%) higher than the required amount to qualify for 
hundredweight shipping, then do not calculate hundredweight.  This is to guard against the chance that the 
actual shipment weight turns out to be lower than what is used for estimation, resulting in failed eligibility
for hundredweight rates and a much higher rate than estimated.

=cut

$VERSION = do { my $r = q$Rev: 158 $; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment::UPS' );
use Business::Shipping::Config;
use Business::Shipping::Logging;

use Class::MethodMaker 2.0
    [ 
      new    => 'new',
      scalar => [ 'from_state' ],
      scalar => [ { -default => 150 }, 'max_weight' ],
      scalar => [ 'disable_hundredweight' ],
      scalar => [ { -default => '10' }, 'hundredweight_margin' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Optional' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Unique' ],
      array  => [ { -type => 'Business::Shipping::UPS_Offline::Package',
                    -default_ctor => 'new' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'packages=>Business::Shipping::UPS_Offline::Package' }, 'Has_a' ],
    ];

=item * Required()

from_state only required for Offline international orders.

=cut

sub Required
{
    return 'service, from_state'           if $_[ 0 ]->to_canada;
    return 'service, from_zip, from_state' if $_[ 0 ]->intl;
    return 'service, from_zip';
}

sub use_hundred_weight
{
    my ( $self ) = @_;

    return if $self->disable_hundredweight;
    
    if ( @{ $self->packages } > 1 ) {
        my $hundred_weight_qualification;
        
        #my %hundred_weight_info = (
            
        my @airborn_100 = qw/ 1da 1dasaver 2da 2dam /;
        my @ground_200  = qw/ gndres gndcom 3ds /;
        
        my $airborn_min = 100 + ( 100 * $self->hundredweight_margin * 0.01 );
        my $ground_min  = 200 + ( 100 * $self->hundredweight_margin * 0.01 );
        
        #debug "ground minimum = $ground_min, current weight = " . $self->weight . ", service = " . $self->service;
        
        if ( 
             (
               grep( $_ eq lc $self->service, @airborn_100 ) 
               and $self->weight > $airborn_min 
             )
             or
             (
               grep( $_ eq lc $self->service, @ground_200 )
               and $self->weight > $ground_min
             )
           )
        {
            return 1;
        }
    }
    
    return;
}

sub get_hundredweight_table
{
    my ( $self, $table ) = @_;
    
    # TODO: Need to map the remaining tables.
    my %table_map = qw/
        gndcom gndcwt
        gndres gndcwt  
        1da 1dacwt
        2da 2dacwt
        3ds 3dscwt
    /;
    
    return $table_map{ $table } || $table;
}

sub cwt_is_per
{
    my ( $self ) = @_;
    
    # TODO: Complete list of services (move to config as well)
    
    my @airborn = qw/ 1da 1dasaver 2da 2dam /;
    my @ground  = qw/ gndres gndcom 3ds /;
    
    return 'pound'         if grep( $_ eq lc $self->service, @airborn );
    return 'hundredweight' if grep( $_ eq lc $self->service, @ground );
    error "could not determine is_per type.  service = " . $self->service;
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