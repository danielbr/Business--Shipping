ifndef BUSINESS_SHIPPING
Variable BUSINESS_SHIPPING	 1 # Ensures that [business-shipping] is only included once.
Message -i Loading [business-shipping] usertag from Business::Shipping module...
Require Module Business::Shipping
UserTag  business-shipping  Order					shipper
UserTag  business-shipping  AttrAlias 		mode	shipper
UserTag  business-shipping  AttrAlias 		carrier	shipper
UserTag  business-shipping  Addattr
UserTag  business-shipping  Documentation 	<<EOD
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: business-shipping.tag,v 1.6 2003/12/22 03:48:11 db-ship Exp $

=head1 NAME

[business-shipping] - Live rate lookup for UPS and USPS (using Business::Shipping)

=head1 AUTHOR 

	Dan Browning
	<db@kavod.com>
	http://www.kavodtechnologies.com
	
=head1 SYNOPSIS

[business-shipping 
	mode="USPS"
	service="Airmail Parcel Post"
	weight="4"
	to_country="Albania"
]

[business-shipping
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
 
 * Copy the business-shipping.tag file into one of these directories:
	- interchange/usertags (IC 4.8.x)
	- interchange/code/UserTags (IC 4.9.x)

 * Add any shipping methods that are needed to catalog/products/shipping.asc
   (The defaults that come with Interchange will work, but they will not use
   the new software).
   
Note that "XPS" is used to denote fields that can be used for UPS or USPS.

UPS_ACCESS_KEY	FJ28AWJN328A3	Shipping 
UPS_USER_ID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	Daily Pickup	Shipping

-or-

USPS_USER_ID	143264KAVOD7241	Shipping
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
	cost		f [business-shipping mode="USPS" service="Airmail Parcel Post" weight="@@TOTAL@@"]
	
	min			4
	max			999999
	cost		f [business-shipping mode="USPS" service="Airmail Parcel Post" weight="@@TOTAL@@"]

=head1 UPGRADE from [ups-query]

See the replacement [ups-query] usertag in this directory.

=cut
EOD
UserTag  business-shipping  Routine <<EOR

use Business::Shipping;

sub {
 	my ( $shipper, $opt ) = @_;
	
	my $debug = delete $opt->{ debug } || 1;
	
	::logDebug( "[business-shipping " . uneval( $opt ) ) if $debug;
	 
	unless ( $shipper and $opt->{weight} and $opt->{ 'service' }) {
		Log ( "mode, weight, and service required" );
		return ( undef );
	}
	
	# We pass the options mostly unmodifed to the underlying library, so here we
	# take out anything that might confuse it.
	delete $opt->{ 'reparse' };
	delete $opt->{ 'mode' };
	delete $opt->{ 'hide' };
	
	my $try_limit = delete $opt->{ 'try_limit' };
	$try_limit ||= 2;
	
	# Business::Shipping takes a hash anyway, we might as well deref it now.
	my %opt = %$opt;

	my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' };
	if ( $to_country_default ) {
		if ( $shipper eq 'USPS' ) {
			$to_country_default = $Tag->data( 'country', 'name', $to_country_default );
		}
		elsif ( $shipper eq 'UPS' ) {
			# Leave the country as a code
		}
	}

	#
	# For interchange, STDOUT will cause it to go to the IC debug.
	#
	my %event_handlers;
	if ( $debug ) {
		%event_handlers = ({
			'debug' => 'STDERR',
			'debug3' => 'STDERR',
			'trace' => 'STDERR',
			'error' => 'STDERR', 
		});
	}
	else {
		%event_handlers = ({
			'debug' => undef,
			'debug3' => undef,
			'trace' => undef, 
			'error' => 'STDERR', 
		});
	}
		
	my %defaults = (
		%event_handlers, 
		'user_id'			=> $Variable->{ "${shipper}_USER_ID" },
		'password'			=> $Variable->{ "${shipper}_PASSWORD" },
		'to_country'		=> $to_country_default,
		'to_zip'			=> $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } || 'zip' },
		'from_country'		=> $Variable->{ XPS_FROM_COUNTRY },
		'from_zip'			=> $Variable->{ XPS_FROM_ZIP },
	);
	
	# Cache enabled by default.
	if ( not defined $opt{ 'cache' } ) { $opt{ 'cache' } = 1; }
	
	if ( $shipper eq 'UPS' ) {
		$defaults{ 'access_key' } = $Variable->{ "${shipper}_ACCESS_KEY" } if ( $Variable->{ "${shipper}_ACCESS_KEY" } );
	}
	
	for ( %defaults ) {
		$opt{ $_ } ||= $defaults{ $_ } if ( $_ and defined $defaults{ $_ } ); 
	}
	
	my $rate_request;
	eval {
		$rate_request = Business::Shipping->rate_request( 'shipper' => $shipper );
	};
	 
	if ( ! defined $rate_request or $@ ) {
		Log( "[business-shipping] failure when calling Business::Shipping->new(): $@ " ) if $@;
		return undef;
	}
	
	::logDebug( "calling Business::Shipping::RateRequest::${shipper}->submit( " . uneval( \%opt ) . " )" ) if $debug;
	
	$rate_request->init( %opt );
	
	my $tries = 0;
	my $success;
	for ( my $tries = 1; $tries <= $try_limit; $tries++ ) {
		my $submit_results;
		eval {
			$submit_results = $rate_request->submit();
		};
		
		if ( $submit_results and ! $@ ) {
			# Success, no more retries
			$success = 1;
			last;
		}
		else {
			Log( "Try $tries: " . $rate_request->error() . "$@" );
			
			for (	
					'HTTP Error. Status line: 500',
					'HTTP Error. Status line: 500 Server Error',		
					'HTTP Error. Status line: 500 read timeout',
					'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
					'HTTP Error. Status line: 500 Connect failed:',
					'HTTP Error. Status line: 500 Can\'t connect to production.shippingapis.com:80',
				) {
				
				if ( $rate_request->error() =~ /$_/ ) {
					Log( 'Error was on server, trying again...' );
				}
			}
		}
	}
	return undef unless $success;
	
	my $charges;
	
	#my $charges = $rate_request->get_charges( $opt{ 'service' } );
	#$charges = $rate_request->total_charges();
	
	# get_charges() *should* be implemented for all use cases, in the future.
	# For now, we just fall back on total_charges()
	$charges ||= $rate_request->total_charges();
	
	if ( ! $charges ) {
		# This is a debugging / support tool.  Set the XPS_GEN_INCIDENTS and
		# SYSTEMS_SUPPORT_EMAIL variables to enable.
		if ( $Variable->{ 'XPS_GEN_INCIDENTS' } ) {
			
			my $variables = uneval( \%opt ); 
			my $error = $rate_request->error();
			
			# Not everyone has [incident], avoid errors.
			eval {
				$Tag->incident("[business-shipping]: $shipper error: $error. \n Options were: $variables");
			};
			
			# Catch exception
			my $eval_error = $@;
		}
	}
	
	::logDebug( "[business-shipping] returning " . uneval( $charges ) ) if $debug;
	
	return $charges;
}
EOR
Message ...done.
endif
