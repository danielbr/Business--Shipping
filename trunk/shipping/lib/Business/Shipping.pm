# Business::Shipping - Shipping related API's
#
# $Id: Shipping.pm,v 1.7 2003/11/12 21:41:23 db-ship Exp $
#
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
#
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Carp;
use Business::Shipping::Debug;
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields => [
		optional => [ 'tx_type' ]
	],
	get_set => [ 'error_msg' ];

sub error
{
	my ( $self, $msg ) = @_;
	
	if ( defined $msg ) {
		$self->error_msg( $msg );
		Business::Shipping::Debug::log_error( $msg );
	}
	
	return $self->error_msg();
}

sub event_handlers
{
	my $self = shift;
	my $event_handlers = shift;
	%Business::Shipping::Debug::event_handlers = %$event_handlers;
	return;
}

sub validate
{
	trace( '()' );
	my ( $self ) = shift;
	
	my @required = $self->required();
	my @optional = $self->optional();
	
	debug( "\n\trequired = " . join (', ', @required ) . "\n\t" 
		. "optional = " . join (', ', @optional ) );
	
	my @missing;
	foreach my $required_field ( @required ) {
		#debug( "Testing $required_field..." );
		if ( ! $self->$required_field() ) {
			push @missing, $required_field;
		}
		#debug( "...done." );
	}
	
	if ( @missing ) {
		$self->error( "Missing required argument " . join ", ", @missing );
		debug( "returning undef" );
		return undef;
	}
	else {
		debug( "returning success" );
		return 1;
	}
}
	
sub rate_request
{
	my $class = shift;
	my ( %opt ) = @_;
	not $opt{ 'shipper' } and Carp::croak( "shipper required" ) and return undef;
	
	my $package				= Business::Shipping->new_subclass( 'Package::' 			. $opt{ 'shipper' } );
	my $shipment 			= Business::Shipping->new_subclass( 'Shipment::' 			. $opt{ 'shipper' } );
	my $new_rate_request	= Business::Shipping->new_subclass( 'RateRequest::Online::' . $opt{ 'shipper' } );
	$shipment->packages_push( $package );
	$new_rate_request->shipment( $shipment );
	
	# init(), in turn, automatically delegates certain options to Shipment and Package.
	$new_rate_request->init( %opt ); 
	
	return ( $new_rate_request );
}

sub new_subclass
{
	my $class = shift;
	my $subclass = shift;
	my $new_class = $class . '::' . $subclass;
	
	my ( %opt ) = @_;
	
	if ( not defined &$new_class ) {
		#debug "$new_class not defined, going to import it.\n";
		eval "require $new_class";
		Carp::croak( "unknown class (require) $new_class ($@)" ) if $@;
		eval "import $new_class";
		Carp::croak( "import error $new_class ($@)" ) if $@;
	}
	else {
		#debug "$new_class already defined\n";
	}
	
	my $new_sub_object = eval "$new_class->new()";
	return $new_sub_object;	
}

1;

__END__

=head1 NAME

Business::Shipping - API for shipping-related tasks

=head1 SYNOPSIS

Example usage for a rating request:

	use Business::Shipping;
	
	my $rate_request = Business::Shipping->rate_request(
		shipper 		=> 'UPS',
		user_id 		=> '',		
		password 		=> '',
		service 		=> 'GNDRES',
		from_zip		=> '98682',
		to_zip			=> '98270',
		weight			=> 5.00,
	};
	
	$rate_request->submit() or die $shipping->error();
	
	print $rate_request->total_charges();

=head1 ABSTRACT

Business::Shipping is an API for shipping-related tasks.

Currently, the only implemented task is shipping cost calculation, but tracking, 
availability, and other services are planned for future addition.

UPS and USPS have been implemented so far, but FedEX and perhaps others are 
planned for future support.

=head1 MULTI-PACKAGE API

 $shipment->set(
	user_id		=> '',
	password	=> '',
	from_zip	=> '',
	to_zip		=> '',
 );

 $shipment->add_package(
	id		=> '0',
	weight		=> '',
 );

 $shipment->add_package(
	id		=> '1',
	weight		=> '',
 );

 $shipment->submit() or print $shipment->error();

 print $shipment->package('0')->get_charges( 'Airmail Parcel Post' );
 print $shipment->package('1')->get_charges( 'Airmail Parcel Post' );
 print $shipment->get_total_price( 'Airmail Parcel Post' );

=head1 ERROR/DEBUG HANDLING

The 'event_handlers' argument takes a hashref telling Business::Shipping what to do
for error, debug, trace, and the like.  The value can be one of four options:

 * 'STDERR'
 * 'STDOUT'
 * 'carp'
 * 'croak'

For example:

 $shipment->set( 
	'event_handlers' => ({ 
		'debug' => undef,
		'trace' => undef,
		'error' => 'croak',
	})
 );
 
The default is 'STDERR' for error handling, and nothing for debug/trace handling.
Note that you can still access error messages even with no handler, by accessing
the return values of methods.  For example:

 $shipment->set( %values ) or print $shipment->error();
	
However, if you don't save the error value before the next call, it could be
overwritten by a new error.

=cut

