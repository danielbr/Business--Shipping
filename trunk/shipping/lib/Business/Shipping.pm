# Business::Shipping - Shipping related API's
#
# $Id: Shipping.pm,v 1.18 2004/02/15 19:41:18 db-ship Exp $
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
#
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping;

=head1 NAME

Business::Shipping - API for shipping-related tasks

=head1 SYNOPSIS

Example rate request:

	use Business::Shipping;
	
	my $rate_request = Business::Shipping->rate_request(
		shipper 	=> 'Offline::UPS',
		service 	=> 'GNDRES',
		from_zip	=> '98682',
		to_zip		=> '98270',
		weight		=>  5.00,
	);	
	
	$rate_request->submit() or die $rate_request->error();
	
	print $rate_request->total_charges();

=head1 ABSTRACT

Business::Shipping is an API for shipping-related tasks.

=head2 Shipping tasks implemented at this time

 * UPS shipment cost calculation using UPS Online WebTools
 * UPS shipment cost calculation using offline tables 
 * USPS shipment cost calculation using USPS Online WebTools
 * UPS shipment tracking
 * USPS shipment tracking 

=head2 Shipping tasks planned for future addition

 * USPS zip code lookup
 * USPS address verification
 * USPS shipment cost estimation via offline tables 
 * FedEX shipment cost estimation

=head1 REQUIRED MODULES

 Archive::Zip (any)
 Bundle::DBD::CSV (any)
 Cache::FileCache (any)
 Class::MethodMaker (any)
 Clone (any)
 Config::IniFiles (any)
 Crypt::SSLeay (any)
 Data::Dumper (any)
 Devel::Required (0.03)
 Error (any)
 Getopt::Mixed (any)
 LWP::UserAgent (any)
 Math::BaseCnv (any)
 Scalar::Util (1.10)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 INSTALLATION

See the INSTALL file for more information.

C<perl -MCPAN -e 'install Bundle::Business::Shipping'>
 
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
 $rate_request->submit() or ie $rate_request->error();

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

 $rate_request->event_handlers(
 	{ 
		'error' => 'STDERR',
		'debug' => 'STDERR',
		'trace' => undef,
		'debug3' => undef,
	}
 );
 
The default is 'STDERR' for error handling, and nothing for debug/trace 
handling.  The option 'debug3' adds additional debugging messages that are not 
included in the normal 'debug'.  Note that you can still access error messages
even without an 'error' handler, by accessing the return values of methods.  For 
example:

 $rate_request->init( %values ) or print $rate_request->error();
	
However, if you don't save the error value before the next call, it could be
overwritten by a new error.

=head1 CLASS METHODS

=cut

$VERSION = do { my @r=(q$Revision: 1.18 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
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
	my ( $self, $event_handlers ) = @_;
	%Business::Shipping::Debug::event_handlers = %$event_handlers if defined $event_handlers;
	return \%Business::Shipping::Debug::event_handlers;
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
		if ( ! $self->$required_field() ) {
			push @missing, $required_field;
		}
	}
	
	if ( @missing ) {
		$self->error( "Missing required argument " . join ", ", @missing );
		$self->invalid( 1 );
		return;
	}
	else {
		return 1;
	}
}

=head2 rate_request()

This method is used to request shipping rate information from online providers
or offline tables.  A hash is accepted as input with the following key values:

=over 4

=item * shipper

The name of the shipper to use. Must correspond to a module by the name of:
C<Business::Shipping::RateRequest::SHIPPER>.  For example, C<Offline::UPS>.

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

=back 

=cut
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
		#
		# Clear previous errors
		#
		$@ = '';
		
		eval "require $new_class";
		Carp::croak( "Error when trying to require $new_class: \n\t$@" ) if $@;
		
		eval "import $new_class";
		Carp::croak( "Error when trying to import $new_class: $@" ) if $@;
	}
	
	my $new_sub_object = eval "$new_class->new()";
	return $new_sub_object;	
}

sub config_to_hash			{ return &Business::Shipping::Config::config_to_hash; 			}
sub config_to_ary_of_hashes	{ return &Business::Shipping::Config::config_to_ary_of_hashes;	}

=head1 AUTHOR

 Dan Browning         <db@kavod.com>
 Kavod Technologies   http://www.kavod.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.

=cut

1;
