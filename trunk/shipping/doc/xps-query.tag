Message Loading [xps-query] usertag...
Require Module Business::Shipping
UserTag  xps-query  Order mode
UserTag  xps-query  Addattr
UserTag  xps-query  Documentation <<EOD
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: xps-query.tag,v 1.3 2003/06/05 05:24:12 db-ship Exp $

=head1 NAME

[xps-query] - Live rate lookup for UPS and USPS (using Business::Shipping)

=head1 AUTHOR 

	Dan Browning
	<db@kavod.com>
	http://www.kavodtechnologies.com
	
=head1 SYNOPSIS

[xps-query 
	mode="USPS"
	service="Airmail Parcel Post"
	weight="4"
	to_country="Albania"
]

[xps-query
	mode="UPS"
	service="GNDRES"
	from_zip="98682"
	to_zip="98270"
	to_residential=1
	weight="3.5"
]
	
=head1 INSTALLATION

Here is a general outline of the installation in interchange.

 * Follow installation instructions for Business::Shipping
    - http://www.kavod.com/Business-Shipping
 
 * Copy the xps-query.tag file into one of these directories:
	- interchange/usertags (IC 4.8.x)
	- interchange/code/UserTags (IC 4.9.x)

 * Add any shipping methods that are needed to catalog/products/shipping.asc
   (The defaults that come with Interchange will work, but they will not use
   the new software ).
   
Note that "XPS" is used to denote fields that can be used for UPS or USPS.

UPS_ACCESS_KEY	FJ28AWJN328A3	Shipping 
UPS_USER_ID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	Daily Pickup	Shipping

-or-

USPS_USER_ID	349234KAVOD3243	Shipping
USPS_PASSWORD	awji2398r2	Shipping

XPS_FROM_COUNTRY	US	Shipping
XPS_FROM_ZIP	98682	Shipping
XPS_TO_COUNTRY_FIELD	country	Shipping
XPS_TO_ZIP_FIELD	zip	Shipping

 * USPS International Service types:
 
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

 * Sample shipping.asc entry:

USPS_AIRMAIL_POST: USPS International
	criteria	[criteria-intl]
	
	min			0
	max			4
	cost		f [xps-query mode="USPS" service="Airmail Parcel Post" weight="@@TOTAL@@"]
	
	min			4
	max			999999
	cost		f [xps-query mode="USPS" service="Airmail Parcel Post" weight="@@TOTAL@@"]
 
=cut
EOD
UserTag  xps-query  Routine <<EOR
use Business::Shipping;
sub {
 	my ( $mode, $opt ) = @_;
	
	::logDebug( "[xps-query " . uneval( $opt ) );
	 
	unless ( $mode and $opt->{weight} and $opt->{ 'service' }) {
		Log ( "mode, weight, and service required" );
		return ( undef );
	}
	
	# We pass the options mostly unmodifed to the underlying library, so here we
	# take out anything that might confuse it.
	delete $opt->{ 'reparse' };
	delete $opt->{ 'mode' };
	delete $opt->{ 'hide' };
	
	# Business::Shipping takes a hash anyway, we might as well deref it now.
	my %opt = %$opt;

	my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' };
	if ( $to_country_default ) {
		if ( $mode eq 'USPS' ) {
			$to_country_default = $Tag->data( 'country', 'name', $to_country_default );
		}
		elsif ( $mode eq 'UPS' ) {
			# Leave the country as a code
		}
	}

	my %defaults = (
		
		# For interchange, STDOUT will cause it to go to the IC debug.
		'event_handlers'	=> ({ 
			#'debug' => undef, 
			#'error' => 'STDERR', 
			#'trace' => undef,
			'debug' => 'STDOUT', 
			'error' => 'STDOUT', 
			'trace' => 'STDOUT', 
		}),
		#'tx_type'			=> 'rate',
		
		'user_id'			=> $Variable->{ "${mode}_USER_ID" },
		'password'			=> $Variable->{ "${mode}_PASSWORD" },
		'to_country'		=> $to_country_default,
		'to_zip'			=> $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } || 'zip' },
		'from_country'		=> $Variable->{ XPS_FROM_COUNTRY },
		'from_zip'			=> $Variable->{ XPS_FROM_ZIP },
	);
	
	# This must be done manually, because of the non-true (0) value.
	$opt{ 'cache_enabled' } ||= 0;
	
	# UPS extras.
	$defaults{ 'access_key' } = $Variable->{ "${mode}_ACCESS_KEY" } if ( $Variable->{ "${mode}_ACCESS_KEY" } );
	
	for ( %defaults ) {
		$opt{ $_ } ||= $defaults{ $_ } if defined $defaults{ $_ }; 
	}

	my $shipment = Business::Shipping->new( 'shipper' => $mode );
	 
	unless ( defined $shipment ) {
		Log( "[xps-query] failure when calling Business::Shipping->new(): $@ " ) if $@;
		return undef;
	}
	
	::logDebug( "calling Business::Shipping::${mode}->submit( " . uneval( \%opt ) . " )" );
	
	$shipment->submit( %opt ) or ( Log $shipment->error() and return undef );
	my $charges = $shipment->get_charges( $opt{ 'service' } );
	$charges ||= $shipment->total_charges();
	
	::logDebug( "[xps-query] returning" . uneval( $charges ) );
	
	return $charges;
}
EOR
