# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: Package.pm,v 1.2 2003/06/24 22:59:57 db-ship Exp $

package Business::Shipping::USPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Package;
use Data::Dumper;
@ISA = qw( Business::Shipping::Package );
	
my %options_defaults = (
	service		=> undef,
	ounces		=> 0,
	container	=> 'None',
	size		=> 'Regular',
	machinable	=> 'False',
	mail_type	=> 'Package',
	from_zip	=> undef,
	from_country	=> undef,
);


sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my %args = @_;
	my $self = $class->SUPER::new();
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	$self->set( %args );
	
	bless( $self, $class );
	
	# Initilize the "manual" data items:
	$self->to_zip( undef );
	$self->to_country( undef );
	
	return $self;
}


sub to_zip
{
	my $self = shift;
	
	if ( @_ ) {
		my $to_zip = shift;
		
		# Need to throw away the "plus four" of zip+four.
		$to_zip =~ /{\d,5}/ if $to_zip;
		
		$self->{ 'to_zip' } = $to_zip;
	}
	
	return $self->{ 'to_zip' };
}


sub from_country
{
	# Do absolutely nothing -- USPS is always from US.
	return;
}


sub to_country
{
	my $self = shift;	
	if ( @_ ) {
		my $new_to_country = shift;
		$new_to_country = $self->_country_name_translator( $new_to_country );
		$self->{ 'to_country' } = $new_to_country;
	} 
	return $self->{ 'to_country' };
}

# Translate common usages (Great Britain) into the USPS proper name
# (Great Britain and Northern Ireland).
sub _country_name_translator
{
	my ( $self, $country ) = @_;
	my %country_translator = (
		'Great Britain' => 'Great Britain and Northern Ireland',
		'United Kingdom' => 'Great Britain and Northern Ireland',
		'France, Metropolitan' => 'France',
	);
	if ( $country and $country_translator{ $country } ) {
		return $country_translator{ $country };
	}
	else {
		return $country;
	}
}


# Alias pounds to 'weight'
sub pounds { return shift->weight( @_ ) }


sub weight
{
	my $self = shift;
	$self->{'pounds'} = $self->_round_up( shift ) if @_;
	
	# Round up if United States... international can have less than 1 pound.
	# TODO: Move intl() and domestic() functions into Business::Shipping::USPS.  For Ship::USPS, alias
	# them to the default package.
	if ( $self->to_country() and $self->to_country() =~ /(USA?)|(United States)/ ) {
		$self->{ 'pounds' } = 1 if $self->{ 'pounds' } < 1;
	}
	
	return $self->{'pounds'};
}


sub _round_up
{
	my ( $self, $f ) = @_;
	return undef unless defined $f; 
	return sprintf( "%1.0f", $f );
}


sub get_unique_values
{
	my $self = shift;
	my @unique_keys = $self->get_unique_keys();
	my @unique_values;
	foreach my $key ( @unique_keys ) {
		push( @unique_values, $self->$key() );
	}
	
	return @unique_values;
}


sub get_unique_keys
{
	my $self = shift;
	my @unique_keys;
	push @unique_keys, ( 
		'service', 'pounds', 'ounces', 'container', 
		'size', 'machinable', 'mail_type', 'to_country',
	);
	return( @unique_keys );
}
1;
