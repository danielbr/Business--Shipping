# Business::Shipping::Shipment - Abstract class
# 
# $Id: Shipment.pm,v 1.4 2004/01/21 22:39:52 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Shipment;

$VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping' );
use Business::Shipping::Debug;
use Business::Shipping::Config;
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	get_set => [ 'current_package_index', ],
	grouped_fields_inherit => [
		'required' => [
			'service',
			'from_zip',
			'shipper',	# *NEEDS* to be set, at least to some default.
		],
		'optional' => [ 
			'from_country',
			'to_country',
			'to_zip',
			'from_city',
			'to_city',
		],
		'unique' => [
			'service',
			'from_zip',
			'from_country',
			'to_zip',
			'from_city',
			'to_city',
		],
	],
	object_list => [ 
		'Business::Shipping::Package' => {
			'slot'		=> 'packages',
		},
	];
	
=item Business::Shipping::Shipment

=over 4 METHODS

=cut

# Forward the weight to the current package.
sub weight { return shift->current_package->weight( @_ ); }

# Returns the weight of all packages within the shipment.
sub total_weight
{
	my $self = shift;
	
	my $total_weight;
	foreach my $package ( @{ $self->packages() } ) {
		$total_weight += $package->weight();
	}
	return $total_weight;
}

no warnings 'redefine';
=item * to_country()

to_country must be overridden to transform from various forms (alternate
spellings of the full name, abbreviatations, alternate abbreviations) into
the full name that we use internally.

May be overridden by subclasses to provide their own spelling ("UK" vs 
"GB", etc.).

=cut
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
use warnings;

=item * to_country_abbrev()

Returns the abbreviated form of 'to_country'.

=cut
sub to_country_abbrev
{
	my ( $self ) = @_;
	
	my $country_abbrevs = $self->config_to_hash( 
		cfg()->{ ups_information }->{ country_to_abbrev } 
	);
	
	return $country_abbrevs->{ $self->to_country } or $self->to_country;
}

no warnings 'redefine';
=item * from_country()

=cut
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


=item * from_state( $from_state )

 $from_state   New from_state value. 

=cut
sub from_state
{
	my ( $self, $from_state ) = @_;
	
	if ( defined $from_state ) {
		
		#
		# Conversions
		#
		# abbrev_to_state
	}
	$self->{ from_state } = $from_state if defined $from_state;
	
	return $self->{ from_state };
}

=item * from_state_abbrev()

Returns the abbreviated form of 'from_state'.

=cut
sub from_state_abbrev
{
	my ( $self ) = @_;
	
	my $state_abbrevs = $self->config_to_hash( 
		cfg()->{ ups_information }->{ state_to_abbrev } 
	);
	
	return $state_abbrevs->{ $self->from_state } or $self->from_state;
}

=item * current_package()

The Shipment object keeps an index of which package object is the current
package (i.e. which package we are working on right now).  This just returns
the corresponding package object, creating one if it doesn't exist. 

=cut
sub current_package {
	my ( $self ) = @_;
	
	my $current_package_index = $self->current_package_index || 0;
	if ( not defined $self->packages_index( $current_package_index ) ) {
		debug( 'Current package (index: $current_package_index) not defined yet, creating one...' );
		$self->packages_push( Business::Shipping::Package->new( id => $current_package_index ) );
	}
	
	return $self->packages_index( $current_package_index ); 
}

sub default_package {
	
	my $self = shift;
	
	if ( not defined $self->packages_index( 0 ) ) {
		debug( 'No default package defined yet, creating one...' );
		$self->packages_push( Business::Shipping::Package->new() );
	}
	
	return $self->packages_index( 0 ); 
}

=item * domestic_or_ca()

Returns 1 if the to_country value for this shipment is domestic (United
States) or Canada.

=cut
sub domestic_or_ca
{
	my ( $self ) = @_;
	
	return 1 if not $self->to_country;
	return 1 if $self->to_country eq 'Canada' or $self->domestic;
	return 0;
}

=item * intl()

 - uses to_country() value to calculate.

 - returns 1/0 (true/false)

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

 - returns the opposite of intl()
 
=cut
sub domestic { return ( not shift->intl ); }


=item * from_canada()
 
=cut
sub from_canada
{
	my ( $self ) = @_;
	
	if ( $self->from_country ) {
		if ( $self->from_country =~ /(CA)|(Canada)/i ) {
			return 1;
		}
	}
	
	return 0;
}

=item * to_canada()

Some people (UPS) treat Canada special, so we do too.

=cut
sub to_canada
{
	my ( $self ) = @_;
	
	if ( $self->to_country ) {
		if ( $self->to_country =~ /(CA)|(Canada)/i ) {
			return 1;
		}
	}
	
	return 0;
}


=item * from_ak_or_hi()

Alaska and Hawaii are treated specially by many shippers.

=cut
sub from_ak_or_hi
{
	my ( $self ) = @_;
	return unless $self->from_state;
	
	if ( $self->from_state =~ /(AK)|(HI)/i ) {
		return 1;
	}
	
	return 0;
}

1;