Message Loading [xps-query] usertag...
Require Module Business::Ship
UserTag  xps-query  Order mode
UserTag  xps-query  Addattr
UserTag  xps-query  Documentation <<EOD
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: xps-query.tag,v 1.5 2003/05/31 22:39:49 db-ship Exp $

=head1 NAME

[xps-query] - Live rate lookup for UPS and USPS (using Business::Ship)

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
	weight="3.5"
]
	
=head1 INSTALLATION

Here is a general outline of the installation in interchange.

 * Follow installation instructions for Business::Ship
    - http://www.kavod.com/Business-Ship
 
 * Copy the xps-query.tag file into one of these directories:
	- interchange/usertags (IC 4.8.x)
	- interchange/code/UserTags (IC 4.9.x)

 * Add any shipping methods that are needed to catalog/products/shipping.asc
   (The defaults that come with Interchange will work, but they will not use
   the new software ).
   
Note that "XPS" is used to denote fields that can be used for UPS or USPS.

UPS_ACCESSKEY	FJ28AWJN328A3	Shipping 
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
use Business::Ship;
sub {
 	my ( $mode, $opt ) = @_;
	
	::logDebug( "[xps-query mode=$mode " . uneval( $opt ) );
	
	# TODO: handle unpassed mode and weight in a better fashion (with Log(), etc.). 
	unless ( $mode and $opt->{weight} ) {
		Log ( "mode and weight required" );
		return ( undef );
	}
	
	# We pass the options mostly unmodifed to the underlying library, so here we
	# take out anything that might confuse it.
	delete $opt->{ 'reparse' };
	delete $opt->{ 'mode' };
	
	# Business::Ship takes a hash anyway, we might as well deref it now.
	my %opt = %$opt;

	my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } or 'country' };
	if ( $to_country_default ) {
		if ( $mode eq 'USPS' ) {
			$to_country_default = $Tag->data( 'country', 'name', $to_country_default );
		}
		elsif ( $mode eq 'UPS' ) {
			# Leave the country as a code
		}
	}

	my %defaults = (
		'event_handlers'	=> ({ 
			#'debug' => 'STDOUT', 
			#'error' => 'STDOUT', 
			#'trace' => 'STDOUT', 
		}),
		'tx_type'			=> 'rate',
		'user_id'			=> $Variable->{ "${mode}_USER_ID" },
		'password'			=> $Variable->{ "${mode}_PASSWORD" },
		'to_country'		=> $to_country_default,
		'to_zip'			=> $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } or 'zip' },
		'from_country'		=> $Variable->{ XPS_FROM_COUNTRY },
		'from_zip'			=> $Variable->{ XPS_FROM_ZIP },
	);
	
	# UPS extras.
	$defaults{ 'access_key' } = $Variable->{ "${mode}_ACCESS_KEY" } if $Variable->{ "${mode}_ACCESS_KEY" };

	$opt{ 'cache_enabled' } = 0;
	
	for ( %defaults ) {
		$opt{ $_ } ||= $defaults{ $_ } if $defaults{ $_ }; 
	}

	my $shipment = new Business::Ship( 'shipper' => $mode );
	
	Log( "[xps-query]: $@ " ) and return undef if $@;
	
	my @opt_description;
	for ( keys %opt ) {
		push @opt_description, "$_ => $opt{$_}";
	}
	my $opt_description = join( ', ', @opt_description );
	
	::logDebug( "calling Business::Ship::${mode}->submit( $opt_description )" );
	
	$shipment->submit( %opt ) or ( Log $shipment->error() and return undef );
	
	my $charges = $shipment->get_charges( $opt{ 'service' } );
	$charges ||= $shipment->total_charges();
	
	Log( "[xps-query] returning zero for shipping charges." ) if ( $charges == 0 );
	
	::logDebug( "[xps-query] returning $charges" );
	
	return $charges;
}
EOR
