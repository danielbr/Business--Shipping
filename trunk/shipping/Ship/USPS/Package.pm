# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: Package.pm,v 1.1 2003/05/31 22:39:49 db-ship Exp $

package Business::Ship::USPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Ship::Package;
use Data::Dumper;
@ISA = qw( Business::Ship::Package );
	
my %options_defaults = (
	service		=> undef,
	ounces		=> 0,
	container	=> 'None',
	size		=> 'Regular',
	machinable	=> 'False',
	mail_type	=> 'Package',
	from_zip	=> undef,
	to_zip		=> undef,
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
	
	return $self;
}

sub from_country
{
	# Do absolutely nothing -- USPS is always from US.
	return;
}


# Alias weight to pounds?
# For now, just round weight up to the next pound. :-(
# TODO: calculate correct ounces.
sub weight
{
	my $self = shift;
	$self->{'pounds'} = $self->_round_up( shift ) if @_;
	
	# USPS requires at least one pound.
	if ( defined $self->{'pounds'} ) {
		$self->{'pounds'} = 1 if $self->{'pounds'} < 1;
	}
	
	return $self->{'pounds'};
}

# Alias pounds to 'weight'
sub pounds { return shift->weight( @_ ) }

sub _round_up
{
	my $self = shift;
	my $f = shift;
	if ( $f ) {
		return ( sprintf( "%1.0f", $f ) );
	}
	else {
		return ( undef );
	}
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
