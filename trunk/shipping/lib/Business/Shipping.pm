# Business::Shipping - Shipping related API's
#
# $Id: Shipping.pm,v 1.10 2004/01/03 03:11:19 db-ship Exp $
#
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
#
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

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
	trace '()';
	my ( $self ) = shift;
	
	my @required = $self->required();
	my @optional = $self->optional();
	
	debug( "required = " . join (', ', @required ) ); 
	debug3( "optional = " . join (', ', @optional ) );	
	
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
		debug3( "returning success" );
		return 1;
	}
}
	
sub rate_request
{
	my $class = shift;
	my ( %opt ) = @_;
	not $opt{ shipper } and Carp::croak( "shipper required" ) and return undef;

	#
	# This was made to support the specification of 'Offline::UPS'
	#
	my $full_shipper;
	if ( $opt{ shipper } =~ /::/ ) {
		$full_shipper = $opt{ shipper };
		my @shipper_components = split( '::', $opt{ shipper } );	
		$opt{ shipper } = pop @shipper_components;
		
	}
	else {
		$full_shipper = "Online::" . $opt{ shipper };
	}
		
	my $package				= Business::Shipping->new_subclass( 'Package::' 			. $opt{ 'shipper' } );
	my $shipment 			= Business::Shipping->new_subclass( 'Shipment::' 			. $opt{ 'shipper' } );
	
	my $subclass = 'RateRequest::' . $full_shipper;
	my $new_rate_request;
	eval {
		$new_rate_request = Business::Shipping->new_subclass( $subclass );
	};
	die $@ if $@;
	
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
		#Carp::croak( "unknown class (require) $new_class ($@)" ) if $@;
		die( "unknown class (require) $new_class ($@)" ) if $@;
		eval "import $new_class";
		#Carp::croak( "import error $new_class ($@)" ) if $@;
		die( "import error $new_class ($@)" ) if $@;
	}
	else {
		#debug "$new_class already defined\n";
		die( "$new_class already defined\n" );
	}
	
	my $new_sub_object = eval "$new_class->new()";
	return $new_sub_object;	
}

1;

__END__

=head1 NAME

Business::Shipping - API for shipping-related tasks

=head1 REQUIRED MODULES

 Archive::Zip (any)
 Bundle::DBD::CSV (any)
 Cache::FileCache (any)
 Class::MethodMaker (any)
 Config::IniFiles (any)
 Crypt::SSLeay (any)
 Data::Dumper (any)
 Devel::Required (0.02)
 Error (any)
 LWP::UserAgent (any)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 SYNOPSIS

Example usage for a rating request:

	use Business::Shipping;
	
	my $rate_request = Business::Shipping->rate_request(
		shipper 		=> 'Offline::UPS',
		service 		=> 'GNDRES',
		from_zip		=> '98682',
		to_zip			=> '98270',
		weight			=> 5.00,
	);
	
	$rate_request->submit() or die $rate_request->error();
	
	print $rate_request->total_charges();

=head1 ABSTRACT

Business::Shipping is an API for shipping-related tasks.

=head2 Shipping Tasks Implemented at this time:

 * Shipping cost calculation
 * Tracking, availability, and other services are planned for future addition.

=head2 Shipping Vendors Implemented at this time:

 * Online UPS (using the Internet and UPS servers)
 * Offline UPS (using tables stored locally)
 * Online USPS
 * Offline FedEX and USPS are planned for support in the future.

=head1 CLASS METHODS

=head2 rate_request()

This method is used to request shipping rate information from online providers
or offline tables.  A hash is accepted as input with the following key values:

=over 4

=item * shipper

The name of the shipper to use. Must correspond to a module by the name of:
C<Business::Shipping::RateRequest::SHIPPER>.  For example, "Offline::UPS".

=item * user_id

A user_id, if required by the provider. Online::USPS and Online::UPS require
this, while Offline::UPS does not.

=item * password

A password,  if required by the provider. Online::USPS and Online::UPS require
this, while Offline::UPS does not.

=item * service

A valid service name for the provider. See the corresponding module 
documentation for a list of services compatible with the shipper.

=item * from_zip

The origin zipcode.

=item * from_state

The origin state.  Required for Offline::UPS.

=item * to_zip

The destination zipcode.

=item * to_country

The destination country.  Required for international shipments only.

=item * weight

Weight of the shipment, in pounds, as a decimal number.

=item * test_mode

If true, connects to a test server instead of a live server, if possible. 
Defaults to 0.

=back

An object is returned if the operation is successful, or 'undef' otherwise.

=head1 MULTI-PACKAGE API

=head2 Online::UPS Example

 use Business::Shipping;
 use Business::Shipping::Shipment::UPS;
 
 my $shipment = Business::Shipping::Shipment::UPS->new();
 
 $shipment->init(
	from_zip	=> '98682',
	to_zip		=> '98270',
	service		=> 'GNDRES',
	#
	# user_id, etc. needed here.
	#
 );

 $shipment->add_package(
	id		=> '0',
	weight		=> 5,
 );

 $shipment->add_package(
	id		=> '1',
	weight		=> 3,
 );
 
 my $rate_request = Business::Shipping::rate_request( shipper => 'Online::UPS' );
 #
 # Add the shipment to the rate request.
 #
 $rate_request->shipment( $shipment );
 $rate_request->submit() or print $rate_request->error();

 print $rate_request->package('0')->get_charges( 'GNDRES' );
 print $rate_request->package('1')->get_charges( 'GNDRES' );
 print $rate_request->get_total_price( 'GNDRES' );

=head1 ERROR/DEBUG HANDLING

The 'event_handlers' argument takes a hashref telling Business::Shipping what to do
for error, debug, trace, and the like.  The value can be one of four options:

 * 'STDERR'
 * 'STDOUT'
 * 'carp'
 * 'croak'

For example:

 $rate_request->init( 
	'event_handlers' => ({ 
		'error' => 'STDOUT',
		'debug' => undef,
		'trace' => undef,
		'debug3' => undef,
	})
 );
 
The default is 'STDERR' for error handling, and nothing for debug/trace 
handling.  The option 'debug3' adds additional debugging messages that are not 
included in the normal 'debug'.  Note that you can still access error messages
even without an 'error' handler, by accessing the return values of methods.  For 
example:

 $rate_request->init( %values ) or print $rate_request->error();
	
However, if you don't save the error value before the next call, it could be
overwritten by a new error.

=cut
