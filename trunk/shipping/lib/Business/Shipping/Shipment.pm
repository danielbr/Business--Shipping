# Business::Shipping::Shipment - Abstract class
# 
# $Id: Shipment.pm,v 1.9 2004/03/08 17:13:55 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment;

$VERSION = do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

=head1 NAME

Business::Shipping::Shipment - Abstract class

=head1 VERSION

$Revision: 1.9 $      $Date: 2004/03/08 17:13:55 $

=head1 DESCRIPTION

Abstract Class: real implementations are done in subclasses.

Shipments have a source, a destination, packages, and other attributes.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use base ( 'Business::Shipping' );
use Business::Shipping::Debug;
use Business::Shipping::Config;

=item * service

=item * from_country

=item * from_state

=item * from_zip

=item * from_city

=item * to_country

=item * to_zip

=item * to_city

=item * packages

Has-A: Object list: Business::Shipping::Package.

=cut
use Class::MethodMaker 2.0
    [
      new    => [ { -hash => 1, -init => 'this_init' }, 'new' ],
      scalar => [ qw/ current_package_index service from_country from_zip
                      from_city  to_country to_zip to_city / 
                ],
      #
      # Let it be defined in non-abstract classes only?
      #
      array  => [ { -type => 'Business::Shipping::Package' }, 'packages' ],
      scalar => [ { -static => 1, -default => 'default_package=>Business::Shipping::Package' }, 'Has_a' ],
      scalar => [ { -static => 1, 
                    -default => 'from_country, to_country, to_zip, from_city, to_city' 
                  },
                  'Optional' 
                ],
      scalar => [ { -static => 1, 
                    -default => 'service, from_zip, from_country, to_zip, from_city, to_city' 
                  },
                  'Unique' 
                ]
    ];

sub this_init { }

=item * weight

Forward the weight to the current package.

=cut
sub weight { return shift->current_package->weight( @_ ); }

=item * total_weight

Returns the weight of all packages within the shipment.

=cut
sub total_weight
{
    my $self = shift;
    
    my $total_weight;
    foreach my $package ( @{ $self->packages() } ) {
        $total_weight += $package->weight();
    }
    return $total_weight;
}

=item * to_zip( $to_zip )

Throw away the "four" from zip+four.  

Redefines the MethodMaker implementation of this attribute.

=cut
no warnings 'redefine';
sub to_zip
{
    my $self = shift;
    
    if ( $_[ 0 ] ) {
        my $to_zip = shift;
        
        #
        # U.S. only: need to throw away the "plus four" of zip+four.
        #
        if ( $self->domestic and $to_zip and length( $to_zip ) > 5 ) {
            $to_zip = substr( $to_zip, 0, 5 );
        }
        
        $self->{ 'to_zip' } = $to_zip;
    }
    
    return $self->{ 'to_zip' };
}
use warnings; # end 'redefine'


=item * to_country()

to_country must be overridden to transform from various forms (alternate
spellings of the full name, abbreviatations, alternate abbreviations) into
the full name that we use internally.

May be overridden by subclasses to provide their own spelling ("UK" vs 
"GB", etc.).  

Redefines the MethodMaker implementation of this attribute.

=cut
no warnings 'redefine';
sub to_country
{
    my ( $self, $to_country ) = @_;
    
    if ( defined $to_country ) {
        my $abbrevs = $self->config_to_hash( cfg()->{ ups_information }->{ abbrev_to_country } );
        $to_country = $abbrevs->{ $to_country } || $to_country;
    }
    $self->{ to_country } = $to_country if defined $to_country;
    
    return $self->{ to_country };
}
use warnings; # end 'redefine'

=item * to_country_abbrev()

Returns the abbreviated form of 'to_country'.

Redefines the MethodMaker implementation of this attribute.

=cut
sub to_country_abbrev
{
    my ( $self ) = @_;
    
    my $country_abbrevs = $self->config_to_hash( 
        cfg()->{ ups_information }->{ country_to_abbrev } 
    );
    
    return $country_abbrevs->{ $self->to_country } or $self->to_country;
}


=item * from_country()

Redefines the MethodMaker implementation of this attribute.

=cut
no warnings 'redefine';
sub from_country
{
    my ( $self, $from_country ) = @_;
    
    if ( defined $from_country ) {
        my $abbrevs = $self->config_to_hash( cfg()->{ ups_information }->{ abbrev_to_country } );
        $from_country = $abbrevs->{ $from_country } || $from_country;
    }
    $self->{ from_country } = $from_country if defined $from_country;
    
    return $self->{ from_country };
}
use warnings;


=item * from_country_abbrev()

=cut
sub from_country_abbrev
{
    my ( $self ) = @_;
    return unless $self->from_country;
    
    my $countries = $self->config_to_hash( cfg()->{ ups_information }->{ country_to_abbrev } );
    my $from_country_abbrev = $countries->{ $self->from_country };
    
    return $from_country_abbrev;
}

=item * current_package()

The Shipment object keeps an index of which package object is the current
package (i.e. which package we are working on right now).  This just returns
the corresponding package object, creating one if it doesn't exist.

Not completely impemented yet.

=cut
sub current_package {
    my ( $self ) = @_;
    
    my $current_package_index = $self->current_package_index || 0;
    if ( not defined $self->packages_index( $current_package_index ) ) {
        debug( 'Current package (index: $current_package_index) not defined yet, creating one...' );
        $self->packages_push( eval "Business::Shipping::Package::" . $self->shipper . "->new" );
    }
    
    return $self->packages_index( $current_package_index ); 
}

#
# TODO: default_package(): remove?
#
sub default_package {
    
    my $self = shift;
    
    if ( not defined $self->packages_index( 0 ) ) {
        debug( 'No default package defined yet, creating one...' );
        #
        # The only time that $shipper is undefined is probably when using 
        # ClassAttribs, since it polls the abstract classes ("Shipment").
        #
        my $shipper = $self->shipper || $self->determine_shipper_from_self;
        $shipper  ||= $shipper ? "::" . $self->shipper : '';
        #debug( "shipper = " . $self->shipper );
        $self->packages_push( eval "Business::Shipping::Package" . $shipper . "->new" );
    }
    else {
        #debug( 'Package already defined, using it.');
    }
    
    return $self->packages_index( 0 ); 
}

=item * domestic_or_ca()

Returns 1 (true) if the to_country value for this shipment is domestic (United
States) or Canada.

Returns 1 if to_country is not set.

=cut
sub domestic_or_ca
{
    my ( $self ) = @_;
    
    return 1 if not $self->to_country;
    return 1 if $self->to_canada or $self->domestic;
    return 0;
}

=item * intl()

Uses to_country() value to determine if the order is International (non-US).

Returns 1 or 0 (true or false).

=cut
sub intl
{
    my ( $self ) = @_;

    if ( $self->to_country ) {
        if ( $self->to_country !~ /(US)|(United States)/) {
            return 1;
        }
    }
    
    return 0;
}

=item * domestic()

Returns the opposite of $self->intl
 
=cut
sub domestic
{ 
    my ( $self ) = @_;

    if ( $self->intl ) {
        return 0;
    }
    
    return 1;
}


=item * to_canada()

UPS treats Canada differently.

=cut
sub from_canada
{
    my ( $self ) = @_;
    
    if ( $self->from_country ) {
        if ( $self->from_country =~ /^((CA)|(Canada))$/i ) {
            return 1;
        }
    }
    
    return 0;
}

=item * to_canada()

UPS treats Canada differently.

=cut
sub to_canada
{
    my ( $self ) = @_;
    
    if ( $self->to_country ) {
        if ( $self->to_country =~ /^((CA)|(Canada))$/i ) {
            return 1;
        }
    }
    
    return 0;
}

=item * from_ak_or_hi()

Alaska and Hawaii are treated differently by many shippers.

=cut
sub to_ak_or_hi
{
    my ( $self ) = @_;

    return unless $self->to_zip;
    
    my @ak_hi_zip_config_params = ( 
        qw/ 
        hi_special_zipcodes_124_224
        hi_special_zipcodes_126_226
        ak_special_zipcodes_124_224
        ak_special_zipcodes_126_226
        /
    );
    
    for ( @ak_hi_zip_config_params ) {
        my $zips = cfg()->{ ups_information }->{ $_ };
        my $to_zip = $self->to_zip;
        if ( $zips =~ /$to_zip/ ) { 
            return 1;
        }
    }
    
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