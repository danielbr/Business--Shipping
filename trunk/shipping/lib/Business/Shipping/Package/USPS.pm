# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Package::USPS;

=head1 NAME

Business::Shipping::Package::USPS

=head1 VERSION

$Rev$      $Date$

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use vars qw( $VERSION );
use base ( 'Business::Shipping::Package' );
use Business::Shipping::Logging;
use Business::Shipping::Util;

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

use Class::MethodMaker 2.0
    [
      new    => [ { -hash => 1, -init => 'this_init' }, 'new' ],
      scalar => [ { -default => 'None'    }, 'container'  ],
      scalar => [ { -default => 'Regular' }, 'size'       ],
      scalar => [ { -default => 'False'   }, 'machinable' ],
      scalar => [ { -default => 'Package' }, 'mail_type'  ],
      scalar => [ { -default => '0.00'    }, 'ounces'     ],
      scalar => [ { -default => '0.00'    }, 'pounds'     ],
      scalar => [ 
                  { 
                    -static => 1, 
                    -default => 'container, size, machinable, mail_type, pounds, '
                              . 'ounces'  
                  }, 
                  'Optional' 
                ], 
      # Note that we use 'weight' as the unique value (specified in Parent), 
      # which should convert automatically from pounds/ounces during uniqueness
      # calculations.
      scalar => [ 
                  { 
                    -static => 1, 
                    -default => 'container, size, machinable, mail_type' 
                  }, 
                  'Unique' 
                ]
    ];
    
sub this_init { $_[ 0 ]->shipper( 'USPS' ); }

=item * Required()

We use a hand-written "Required()" method for this class, because we require one
of the following: pounds, ounces, or weight.  It doesn't matter which one it is,
but if none of them are defined, then we pick 'weight' to Require.

=cut

sub Required
{
    my ( $self ) = @_;
    
    for ( qw( weight pounds ounces ) ) {
        if ( $self->$_ ) {
            return '';
        }
    }
    
    return 'weight';
}

=item * weight

Overrides the standard weight definition so that it can correctly set pounds &
ounces.

=cut

sub weight
{
    my ( $self, $in_weight ) = @_;
    trace( '(' . uneval( \@_ ) . ')' );
    
    if ( $in_weight ) {
        
        if ( $in_weight < 1.00 ) {
            # Minimum one pound for USPS.
            $in_weight = 1.00;
        }
        
        $self->set_lbs_oz( $in_weight );
    }
    # Convert back to 'weight' (i.e. one number) when returning.
    my $out_weight = $self->lbs_oz_to_weight;
    
    return $out_weight;
}

=item * set_lbs_oz

Set pounds and ounces.  Converts from fractional pounds.

=cut

sub set_lbs_oz
{
    my ( $self, $in_weight ) = @_;
    
    my $pounds = 0;
    my $ounces = 0;
    
    $pounds = $self->_round_up( $in_weight );
    my $remainder = $pounds - $in_weight;
    # For some weights (e.g. 2.4), this is necessary.
    $remainder = -$remainder if $remainder < 0;
    if ( $remainder ) {
        $ounces = $remainder * 16;
        $ounces = sprintf( "%1.0f", $ounces );
    }
    $self->pounds( $pounds );
    $self->ounces( $ounces );
    
    return;
}

=item * lbs_oz_to_weight

Converts pounds + ounces to fractional weight.  Returns weight.

=cut

sub lbs_oz_to_weight
{
    my ( $self ) = @_;
    
    trace '()';
    
    my $pounds = $self->pounds || 0;
    my $ounces = $self->ounces || 0;
    my $fractional_pounds = $ounces ? sprintf( "%1.0f", $ounces / 16 ) : 0;
    my $weight = ( $pounds + $fractional_pounds );
    
    return $weight;
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
