# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: Package.pm,v 1.1 2003/06/04 21:41:09 db-ship Exp $

package Business::Shipping::UPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Package;
use Data::Dumper;
@ISA = qw( Business::Shipping::Package );

# Compared to USPS, UPS doesn't carry much data at the Package level.	
my %options_defaults = (
	packaging	=> undef,
);

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = $class->SUPER::new();
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	$self->set( @_ );
	#$self->compatibility_map( %compatibility_map );
	bless( $self, $class );
	
	return $self;
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
		'weight', 'packaging',
	);
	return( @unique_keys );
}
1;
