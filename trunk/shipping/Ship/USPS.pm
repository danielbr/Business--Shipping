# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: USPS.pm,v 1.3 2003/06/04 20:18:55 db-ship Exp $

package Business::Shipping::USPS;
use strict;
use warnings;

=head1 NAME

Business::Shipping::USPS - A USPS module 

Documentation forthcoming.

 * Register for the API here:
 
http://www.uspsprioritymail.com/et_regcert.html

 * You will need to call or e-mail to active the account for "Production" usage
 * Otherwise, it will only work with special test queries.

#TODO: Utilize $self->_metadata( 'optionname' ) and $self->initialize(), like UPS. 
 
=cut

use vars qw(@ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping;
use Business::Shipping::USPS::Package;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use XML::Simple 2.05;
use XML::DOM;
use Data::Dumper;

@ISA = qw( Business::Shipping );

sub new
{
	my($class, %args) = @_;	
	my $self = $class->SUPER::new();
	bless( $self, $class );
	return $self->initialize( %args );
}


sub _metadata
{
	my ( $self, $desired ) = @_;
	
	my $values = { 
		'internal' => {
			'ua'					=> LWP::UserAgent->new(),
			'xs'					=> XML::Simple->new( ForceArray => 1, KeepRoot => 1 ),
			'packages'				=> [ Business::Shipping::USPS::Package->new() ],
			'package_subclass_name'	=> 'USPS::Package',
			'intl'					=> undef,
			'domestic'				=> undef,
		},
		'required' => {
			# Everything is either in Business::Shipping, or in Business::Shipping::USPS::Package
		},
		'parent_defaults' => {
			'test_url'		=> 'http://testing.shippingapis.com/ShippingAPItest.dll',
			'prod_url'		=> 'http://production.shippingapis.com/ShippingAPI.dll',
		},
		# TODO: automatically pull in the values from Ship::USPS::Package, map whatever is used.
		'alias_to_default_package' => {
			pounds		=> undef,
			ounces		=> 0,
			container	=> 'None',
			size		=> 'Regular',
			machinable	=> 'False',
			mail_type	=> 'Package',
			service 	=> undef,
			from_zip	=> undef,
			to_zip		=> undef,
			to_country	=> undef,
		},
		'optional'		=> {
			#none.
			from_country	=> 'US',  # (to|from)_country are required, but they have defaults, so...?
		},
		'unique_values' => {
			pickup_type				=> undef,
			from_country			=> undef,
			from_zip				=> undef,
			to_residential			=> undef,
			to_country				=> undef,
			to_zip					=> undef,
			service					=> undef,
		},
	};
	
	my %result = %{ $values->{ $desired } };
	return wantarray ? keys( %result ) : \%result;
}


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

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml
{
	my $self = shift;
	$self->trace( 'called' );
	
	# Note: The XML::Simple hash-tree-based generation method wont work with USPS,
	# because they enforce the order of their parameters (unlike UPS).
	
	my $rateReqDoc = new XML::DOM::Document; 
	my $rateReqEl = $rateReqDoc->createElement( 
		$self->domestic() ? 'RateRequest' : 'IntlRateRequest' 
	);
	
	$rateReqEl->setAttribute('USERID', $self->user_id() ); 
	$rateReqEl->setAttribute('PASSWORD', $self->password() ); 
	$rateReqDoc->appendChild($rateReqEl);
	
	my $package_count = 0;
	
	die "No packages defined internally." unless ref $self->packages();
	foreach my $package ( @{$self->packages()} ) {

		my $id;
		$id = $package->id();
		$id = $package_count++ unless $id;
		my $packageEl = $rateReqDoc->createElement('Package'); 
		$packageEl->setAttribute('ID', $id); 
		$rateReqEl->appendChild($packageEl); 
		
		if ( $self->domestic() ) {
			my $serviceEl = $rateReqDoc->createElement('Service'); 
			my $serviceText = $rateReqDoc->createTextNode( $package->service() ); 
			$serviceEl->appendChild($serviceText); 
			$packageEl->appendChild($serviceEl);
		
			my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination'); 
			my $zipOrigText = $rateReqDoc->createTextNode( $package->from_zip()); 
			$zipOrigEl->appendChild($zipOrigText); 
			$packageEl->appendChild($zipOrigEl); 
			
			my $zipDestEl = $rateReqDoc->createElement('ZipDestination'); 
			my $zipDestText = $rateReqDoc->createTextNode( $package->to_zip()); 
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
			my $countryText = $rateReqDoc->createTextNode( $package->to_country() ); 
			$countryEl->appendChild($countryText); 
			$packageEl->appendChild($countryEl);
		}
	
	} #/foreach package
	my $request_xml = $rateReqDoc->toString();
	
	my $request_xml_tree = $self->{xs}->XMLin( $request_xml, KeepRoot => 1, ForceArray => 1 );
	$self->debug( $self->{xs}->XMLout( $request_xml_tree ) );
	
	return ( $request_xml );
}

sub _gen_request
{
	my ( $self ) = shift;
	$self->trace( 'called' );
	
	my $request = $self->SUPER::_gen_request();
	# This is how USPS slightly varies from Business::Shipping
	my $new_content = 'API=' . ( $self->domestic() ? 'Rate' : 'IntlRate' ) . '&XML=' . $request->content();
	$request->content( $new_content );
	$request->header( 'content-length' => length( $request->content() ) );
	$self->debug( 'HTTP Request: ' . $request->as_string() );
	return ( $request );
}

sub _massage_values
{
	my $self = shift;
	#$self->_set_pounds_ounces();
	$self->_domestic_or_intl();
	
	# TODO: If some packages don't have a to_zip, from_zip, etc., then map from teh default assignment. 
	# Should it be done at the Package level?
	return;
}

sub _handle_response
{
	my $self = shift;
	$self->trace( 'called.' );
	
	my $response_tree = $self->{xs}->XMLin( 
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
	
	$self->response_tree( $response_tree );
	
	if ( $self->domestic() ) {
		$self->total_charges( $response_tree->{Package}->{Postage} );
		$self->default_package()->set_price( $self->service(), $response_tree->{Package}->{Postage} );
	}
	elsif ( $self->intl() ) {
		# TODO: Sum the get_charges( $service ) for all packages to return to total_charges
		$self->total_charges( $response_tree->{Package}->{Service}->[0]->{Postage} );
		foreach my $service ( @{ $response_tree->{Package}->{Service} } ) {
			$self->debug( " Postage = " . $service->{Postage} );
			# TODO: store the prices using $self->package_id( $id )->set_charges( $service->{Postage} )
			$self->packages()->[0]->set_price( $service->{SvcDescription}, $service->{Postage} );
		}
	}
	
	return $self->is_success( 1 );
}

# Do nothing, this is just to support the interface, but we're always from US.
sub from_country { return; }

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
	my $self = shift;
	
	if ( $self->to_country() and $self->to_country() !~ /(US)|(United States)/) {
		$self->intl( 1 );
		$self->domestic( 0 );
	}
	else {
		$self->intl( 0 );
		$self->domestic( 1 );
	}
	$self->debug( $self->domestic() ? 'Domestic' : 'International' );
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

1;
