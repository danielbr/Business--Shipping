Message Loading [xps-query] usertag...
Require Module Business::Ship::USPS
Require Module Business::Ship::UPS
UserTag  xps-query  Order mode
UserTag  xps-query  Addattr
UserTag  xps-query  Documentation <<EOD
=head1 NAME

[xps-query] - Business::Ship Interface for Interchange.

Copyright (c) 2003 Kavod Technologies, and Dan Browning. 
All rights reserved. This program is free software; you can 
redistribute it and/or modify it under the GPL license.

=head1 AUTHOR 

	Dan Browning
	<db@kavod.com>
	http://www.kavodtechnologies.com
	
=head1 SYNOPSIS

TODO: [ups-query] will make compatibility level calls to xps.

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
 	- TODO: URL for documentation.

 * Copy the xps-query.tag file into one of these directories:
	- interchange/usertags (IC 4.8.x)
	- interchange/code/UserTags (IC 4.9.x)

 * Add any shipping methods that are needed
	- to catalog/products/shipping.asc
	- (The defaults that come with Interchange will work,
	  but they will not use the new software ).
   
Note that "XPS" is used to denote fields that can be used for UPS or USPS.

UPS_ACCESSKEY	FJ28AWJN328A3	Shipping 
UPS_USER_ID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	Daily Pickup	Shipping

or

USPS_USER_ID	349234KAVOD3243	Shipping
USPS_PASSWORD	awji2398r2	Shipping

XPS_TO_COUNTRY_FIELD	country	Shipping
XPS_TO_ZIP_FIELD	zip	Shipping
XPS_FROM_COUNTRY	US	Shipping
XPS_FROM_ZIP	98682	Shipping

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
 
=cut
EOD
UserTag  xps-query  Routine <<EOR
use Business::Ship::UPS;
use Business::Ship::USPS;
sub {
 	my ( $mode, $opt ) = @_;
	
	# We pass the options mostly unmodifed to the underlying library, so here we
	# take out anything that might confuse it.
	delete $opt->{ 'reparse' };
	delete $opt->{ 'mode' }; 	
	
	# TODO: handle unpassed mode and weight in a better fashion (with Log(), etc.). 
	unless ( $mode and $opt->{weight} ) {
		Log ( "mode and weight required" );
		return ( undef );
	}
	
	# Business::Ship takes a hash anyway, we might as well deref it now.
	my %opt = %$opt;

	my %defaults = (
		# TODO: handle errors manually, instead of with croak.
		'event_handlers'	=> ({ 'debug' => undef, 'error' => undef }),
		'tx_type'			=> 'rate',
		'user_id'			=> $Variable->{"${mode}_USER_ID"},
		'password'			=> $Variable->{"${mode}_PASSWORD"},
		'to_country'		=> $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } or 'country' },
		'to_zip'			=> $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } or 'zip' },
		'from_country'		=> $Values->{ $Variable->{ XPS_FROM_COUNTRY } or 'US' },
		'from_zip'			=> $Values->{ $Variable->{ XPS_FROM_ZIP } },
	);
	
	for ( %defaults ) {
		$opt{ $_ } ||= $defaults{ $_ } if $defaults{ $_ }; 
	}

	my $shipment = new Business::Ship::USPS; #$mode
	
	::logDebug( "calling Business::Ship::${mode} with: " ); for ( keys %opt ) { ::logDebug( "\'$_\' => \'$opt{$_}\'" ); }
	
	$shipment->submit( %opt ) or ( Log $shipment->error() and return ( undef ) );
	
	return $shipment->get_price( $opt{ 'service' } );
}
EOR
