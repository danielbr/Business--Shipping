# $Id: USPS.pm,v 1.8 2004/03/03 04:07:51 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Package::USPS;

=head1 NAME

Business::Shipping::Package::USPS

=head1 VERSION

$Revision: 1.8 $      $Date: 2004/03/03 04:07:51 $

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use vars qw( $VERSION );
use base ( 'Business::Shipping::Package' );
use Business::Shipping::Debug;

=item * container

Default 'None'. 

=item * size

Default 'Regular'.

=item * machinable

Default 'False'.

=item * mail_type

Default 'Package'.

=item * pounds

=item * ounces

=cut
use Business::Shipping::CustomMethodMaker
    new_with_init => 'new',
    new_hash_init => 'hash_init',
    grouped_fields_inherit => [
        optional => [ 'container', 'size', 'machinable', 'mail_type', 'pounds', 'ounces' ],
        
        # Note that we use 'weight' as the unique value, which should convert from pounds/ounces.
        unique => [ 'container', 'size', 'machinable', 'mail_type' ]
    ];

use constant INSTANCE_DEFAULTS => (
    container    => 'None',
    size        => 'Regular',
    machinable    => 'False',
    mail_type    => 'Package',
    ounces        => 0,
);
 
sub init
{
    my $self   = shift;
    my %values = ( INSTANCE_DEFAULTS, @_ );
    $self->hash_init( %values );
    return;
}

=item * weight

Overrides the standard weight definition so that it can correctly set pounds &
ounces.

=cut
sub weight
{
    trace '()';
    my ( $self, $in_weight ) = @_;
    
    if ( $in_weight ) {
        
        if ( $in_weight < 1.00 ) {
            # Minimum one pound for USPS.
            $in_weight = 1.00;
        }
        
        my ( $pounds, $ounces ) = $self->weight_to_imperial( $in_weight );
        
        $self->pounds( $pounds ) if $pounds;
        $self->ounces( $ounces ) if $ounces;
    }
    
    my $out_weight = $self->imperial_to_weight( $self->pounds(), $self->ounces() );
    
    # Convert back to 'weight' (i.e. one number) when returning.
    return $out_weight;
}

=item * weight_to_imperial

Converts fractional pounds to pounds + ounces.

=cut
sub weight_to_imperial
{
    my ( $self, $in_weight ) = @_;
    
    my $pounds = $self->_round_up( $in_weight );
    my $remainder = $pounds - $in_weight;
    
    # For some weights (e.g. 2.4), this is necessary.
    $remainder = -$remainder if $remainder < 0;
    
    my $ounces;
    if ( $remainder ) {
        $ounces = $remainder * 16;
        $ounces = sprintf( "%1.0f", $ounces );
    }
    
    return ( $pounds, $ounces );
}

=item * weight_to_imperial

Converts pounds + ounces to fractional weight.

=cut
sub imperial_to_weight
{
    my ( $self, $pounds, $ounces ) = @_;
    
    my $fractional_pounds = sprintf( "%1.0f", $self->ounces() / 16 );
    
    return ( $pounds + $fractional_pounds );
}

=item * _round_up

=cut
sub _round_up
{
    my ( $self, $f ) = @_;
    
    return undef unless defined $f;
    
    return sprintf( "%1.0f", $f );
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
