# Business::Shipping::RateRequest::Online::USPS - Abstract class for shipping cost rating.
# 
# $Id: USPS.pm,v 1.3 2003/08/07 22:45:47 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::RateRequest::Online::USPS;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@ISA = ( 'Business::Shipping::RateRequest::Online' );


use Business::Shipping::RateRequest::Online;
use Business::Shipping::Debug;
use Business::Shipping::Package::USPS;
use XML::Simple 2.05;
use XML::DOM;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	boolean => [ 'domestic' ];
	
use constant INSTANCE_DEFAULTS => (
	'prod_url'		=> 'http://production.shippingapis.com/ShippingAPI.dll',
	'test_url'		=> 'http://testing.shippingapis.com/ShippingAPItest.dll',
	'domestic'		=> 1,
);
 
sub init
{
	#trace '( ' . uneval( @_ ) . ' )';
	my $self   		= shift;
	my %values 		= ( INSTANCE_DEFAULTS, @_ );
	$self->hash_init( %values );
	return;
}

#
# Map to default_package
#
foreach my $attribute ( 'ounces', 'pounds', 'container', 'size', 'machinable', 'mail_type' ) {
	eval "sub $attribute { return shift->default_package->$attribute( \@_ ); }"
}

#sub ounces { return shift->default_package( @_ ); }
#sub pounds { return shift->default_package( @_ ); }
#sub container { return shift->default_package->container( @_ ); }



# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	trace( '()' );
	my $self = shift;
	
	# Note: The XML::Simple hash-tree-based generation method wont work with USPS,
	# because they enforce the order of their parameters (unlike UPS).
	#
	my $rateReqDoc = XML::DOM::Document->new(); 
	my $rateReqEl = $rateReqDoc->createElement( 
		$self->domestic() ? 'RateRequest' : 'IntlRateRequest' 
	);
	
	$rateReqEl->setAttribute('USERID', $self->user_id() ); 
	$rateReqEl->setAttribute('PASSWORD', $self->password() ); 
	$rateReqDoc->appendChild($rateReqEl);
	
	my $package_count = 0;
	
	die "No packages defined internally." unless ref $self->shipment->packages();
	foreach my $package ( @{ $self->shipment->packages() } ) {

		my $id;
		$id = $package->id();
		$id = $package_count++ unless $id;
		my $packageEl = $rateReqDoc->createElement('Package'); 
		$packageEl->setAttribute('ID', $id); 
		$rateReqEl->appendChild($packageEl); 

		# TODO: Get rid of this bug workaround.
		# When using xps-query, and you call UPS, then USPS on the same
		# page, then the USPS::Package will not get the 'service', 'to_zip', or 'from_zip' values
		# BUT, they are still in $self.  How can that be, if it is supposed to be aliased to the\
		# package?  Worse, how come it only occurs when UPS is first called?
		#for ( 'service', 'from_zip', 'to_zip' ) {
		#	$package->$_( $self->$_() ) unless $package->$_();
		#}
		
		if ( $self->domestic() ) {
			my $serviceEl = $rateReqDoc->createElement('Service'); 
			my $serviceText = $rateReqDoc->createTextNode( $self->shipment->service() ); 
			$serviceEl->appendChild($serviceText); 
			$packageEl->appendChild($serviceEl);
		
			my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination'); 
			my $zipOrigText = $rateReqDoc->createTextNode( $self->shipment->from_zip()); 
			$zipOrigEl->appendChild($zipOrigText); 
			$packageEl->appendChild($zipOrigEl); 
			
			my $zipDestEl = $rateReqDoc->createElement('ZipDestination');
			my $zipDestText = $rateReqDoc->createTextNode( $self->shipment->to_zip()); 
			$zipDestEl->appendChild($zipDestText); 
			$packageEl->appendChild($zipDestEl); 
		}
		
		my $poundsEl = $rateReqDoc->createElement('Pounds'); 
		my $poundsText = $rateReqDoc->createTextNode( $package->pounds() );
		$poundsEl->appendChild($poundsText); 
		$packageEl->appendChild($poundsEl); 
		
		my $ouncesEl = $rateReqDoc->createElement('Ounces'); 
		my $ouncesText = $rateReqDoc->createTextNode( $package->ounces() ); 
		$ouncesEl->appendChild($ouncesText); 
		$packageEl->appendChild($ouncesEl);
		
		if ( $self->domestic() ) {
			my $containerEl = $rateReqDoc->createElement('Container'); 
			my $containerText = $rateReqDoc->createTextNode( $package->container() ); 
			$containerEl->appendChild($containerText); 
			$packageEl->appendChild($containerEl); 
			
			my $oversizeEl = $rateReqDoc->createElement('Size'); 
			my $oversizeText = $rateReqDoc->createTextNode( $package->size() ); 
			$oversizeEl->appendChild($oversizeText); 
			$packageEl->appendChild($oversizeEl); 
			
			my $machineEl = $rateReqDoc->createElement('Machinable'); 
			my $machineText = $rateReqDoc->createTextNode( $package->machinable() ); 
			$machineEl->appendChild($machineText); 
			$packageEl->appendChild($machineEl);
		}
		else {
			my $mailTypeEl = $rateReqDoc->createElement('MailType'); 
			my $mailTypeText = $rateReqDoc->createTextNode( $package->mail_type() ); 
			$mailTypeEl->appendChild($mailTypeText); 
			$packageEl->appendChild($mailTypeEl); 
			
			my $countryEl = $rateReqDoc->createElement('Country'); 
			my $countryText = $rateReqDoc->createTextNode( $self->shipment->to_country() ); 
			$countryEl->appendChild($countryText); 
			$packageEl->appendChild($countryEl);
		}
	
	} #/foreach package
	my $request_xml = $rateReqDoc->toString();
	
	# We only do this to provide a pretty, formatted XML doc for the debug. 
	my $request_xml_tree = XML::Simple::XMLin( $request_xml, KeepRoot => 1, ForceArray => 1 );
	
	#
	# Large debug
	#
	debug3( XML::Simple::XMLout( $request_xml_tree, KeepRoot => 1 ) );
	#
	
	return ( $request_xml );
}

sub _gen_request
{
	my ( $self ) = shift;
	trace( 'called' );
	
	my $request = $self->SUPER::_gen_request();
	# This is how USPS slightly varies from Business::Shipping
	my $new_content = 'API=' . ( $self->domestic() ? 'Rate' : 'IntlRate' ) . '&XML=' . $request->content();
	$request->content( $new_content );
	$request->header( 'content-length' => length( $request->content() ) );
	#
	# Large debug
	#
	#debug( 'HTTP Request: ' . $request->as_string() );
	#
	return ( $request );
}

sub _massage_values
{
	my $self = shift;
	#$self->_set_pounds_ounces();
	$self->_domestic_or_intl();
	
	# Round up if United States... international can have less than 1 pound.
	if ( $self->to_country() and $self->to_country() =~ /(USA?)|(United States)/ ) {
		foreach my $package ( @{ $self->shipment->packages() } ) {
			$package->pounds( 1 ) if ( $package->pounds() < 1 );
		}
	}
	
	# TODO: If some packages don't have a to_zip, from_zip, etc., then map from teh default assignment. 
	# Should it be done at the Package level?
	return;
}

sub _handle_response
{
	trace '()';
	my $self = shift;
	
	my $response_tree = XML::Simple::XMLin( 
		$self->response()->content(), 
		ForceArray => 0, 
		KeepRoot => 0 
	);
	
	# TODO: Handle multiple packages errors.
	# (this doesn't seem to handle multiple packagess errors very well)
	if ( $response_tree->{Error} or $response_tree->{Package}->{Error} ) {
		my $error = $response_tree->{Package}->{Error};
		$error ||= $response_tree->{Error};
		my $error_number 		= $error->{Number};
		my $error_source 		= $error->{Source};
		my $error_description	= $error->{Description};
		$self->error( "$error_source: $error_description ($error_number)" );
		return( undef );
	}
	
	#
	# This is a "large" debug.
	#
	debug3( 'response = ' . $self->response->content );
	#
	
	#
	# TODO: Get the pricing routines to work for multi-packages (not just
	# the default_package()
	#
	if ( $self->domestic() ) {
		#
		# Domestic *doesn't* tell you the price of all services for that package
		#
		
		my $charges = $response_tree->{Package}->{Postage};
		if ( ! $charges ) { $self->error( 'charges are 0, error out' ); return $self->clear_is_success(); }
		debug( 'Setting charges to ' . $charges );
		my $packages = [ { 'charges' => $charges, }, ];
		my $results = { $self->shipment->shipper() => $packages };
		$self->results( $results );
		
	}
	else {
		#
		# International *does* tell you the price of all services for each package
		#
		
		foreach my $service ( @{ $response_tree->{Package}->{Service} } ) {
			debug( "Charges for $service->{SvcDescription} service = " . $service->{Postage} );
			
			# BUG: you can't check if the service descriptions match, because many countries use
			# different descriptions for the same service.  So we try to match by description
			# *or* by mail_type.  (There are probably many services with the same mail_type, how 
			# do we handle those?  We could just get them based on index number (maybe all "zero" 
			# is the cheapest ground service, or...?
			if	(
					( $self->mail_type()	and $self->mail_type()	=~ $service->{ MailType } 		)
				or	( $self->service() 		and $self->service 		=~ $service->{SvcDescription} 	)
				) {
					
				my $charges = $service->{ 'Postage' };
				if ( ! $charges ) { $self->error( 'charges are 0, error out' ); return $self->clear_is_success(); }
				debug( 'Setting charges to ' . $service->{Postage} );
				my $packages = [ { 'charges' => $charges, }, ];
				my $results = { $self->shipment->shipper() => $packages };
				$self->results( $results );
				
			}
			else {
				my $error_msg = "The requested service (" . $self->service() 
						. ") did not match the service that was available for that country: "
						. $service->{SvcDescription};
				
				print STDERR $error_msg;
				$self->error( $error_msg );
			}
		}
	}
	trace 'returning success';
	return $self->is_success( 1 );
}

sub _set_pounds_ounces
{
	my $self = shift;
	unless( $self->pounds() ) {
		$self->pounds( $self->weight() );
	}
	
	# 'pounds' cannot be a fraction.
	# TODO: Calculate 'ounces' from a fractional pound.
	return;
}

# Decide if we are domestic or international for this run...
sub _domestic_or_intl
{
	trace '()';
	
	my $self = shift;
	
	if ( $self->shipment->to_country() and $self->shipment->to_country() !~ /(US)|(United States)/) {
		$self->clear_domestic();
	}
	else {
		$self->set_domestic();
	}
	debug( $self->domestic() ? 'Domestic' : 'International' );
	return;
}

# TODO: see if any of the following is useful information... 
#
#		'alias_to_default_package' => {
#			service 	=> undef,
#			pounds		=> undef,
#			ounces		=> 0,
#			container	=> 'None',
#			size		=> 'Regular',
#			machinable	=> 'False',
#			mail_type	=> 'Package',
#			from_zip	=> undef,
#			to_zip		=> undef,
#			to_country	=> undef,
#		},
#
#
#		'unique_values' => {
#			pickup_type				=> undef,
#			from_country			=> undef,
#			from_zip				=> undef,
#			to_residential			=> undef,
#			to_country				=> undef,
#			to_zip					=> undef,
#			service					=> undef,
#		},
#
#
#
# TODO: Remove (legacy)
# 
# This is to redirect calls to the package level (so that
# people who wont ever ship multiple packages don't have to
# deal with the complexity of it.
sub build_subs_packages
{
	my $self = shift;
    foreach( @_ ) {
		unless ( $self->can( $_ ) ) {
			eval "sub $_ { my \$self = shift; if(\@_) { \$self->{'packages'}->[0]->$_( shift ); } return \$self->{'packages'}->[0]->$_(); }";
		}
    }
	return;
}



=pod

 * Domestic Service types:
 	EXPRESS
	Priority
	Parcel
	Library
	BPM
	Media

 * International Service types:
 
	'Global Express Guaranteed Document Service',
	'Global Express Guaranteed Non-Document Service',
	'Global Express Mail (EMS)',
	'Global Priority Mail - Flat-rate Envelope (large)',
	'Global Priority Mail - Flat-rate Envelope (small)',
	'Global Priority Mail - Variable Weight Envelope (single)',
	'Airmail Letter Post',
	'Airmail Parcel Post',
	'Economy (Surface) Letter Post',
	'Economy (Surface) Parcel Post',


=cut

=head1 SEE ALSO

	http://www.uspswebtools.com/

=head1 AUTHOR

	Dan Browning <db@kavod.com>
	Kavod Technologies
	http://www.kavod.com

=head1 COPYRIGHT

	Copyright (c) 2003 Kavod Technologies, Dan Browning, and Kevin Old.
	All rights reserved. This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=cut

=head1 NAME

Business::Shipping::USPS - A USPS module 

Documentation forthcoming.

 * Register for the API here:
 
http://www.uspsprioritymail.com/et_regcert.html

 * You will need to call or e-mail to active the account for "Production" usage
 * Otherwise, it will only work with special test queries.

#TODO: Utilize $self->_metadata( 'optionname' ) and $self->initialize(), like UPS. 
 
=cut


1;

