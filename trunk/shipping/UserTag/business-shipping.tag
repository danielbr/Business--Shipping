# [business-shipping] - Interchange Usertag for Business::Shipping
#
# $Id: business-shipping.tag,v 1.10 2004/01/21 23:00:36 db-ship Exp $
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
#
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 
ifndef BUSINESS_SHIPPING
Variable BUSINESS_SHIPPING	 1 
Message -i Loading [business-shipping] usertag...
Require Module Business::Shipping
UserTag  business-shipping  Order					shipper
UserTag  business-shipping  AttrAlias 		mode	shipper
UserTag  business-shipping  AttrAlias 		carrier	shipper
UserTag  business-shipping  Addattr
UserTag  business-shipping  Documentation 	<<EOD
=head1 NAME

[business-shipping] - Interchange Usertag for Business::Shipping

=head1 AUTHOR 

	Dan Browning
	<db@kavod.com>
	http://www.kavodtechnologies.com
	
=head1 SYNOPSIS

[business-shipping 
	shipper='Offline::UPS'
	service='GNDRES'
	from_zip='98682'
	to_zip='98270'
	weight='5.00'
]
	
=head1 REQUIRED MODULES

 Archive::Zip (any)
 Bundle::DBD::CSV (any)
 Cache::FileCache (any)
 Class::MethodMaker (any)
 Config::IniFiles (any)
 Crypt::SSLeay (any)
 Data::Dumper (any)
 Devel::Required (0.03)
 Error (any)
 LWP::UserAgent (any)
 Math::BaseCnv (any)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 INSTALLATION

Here is a general outline for installing [business-shipping] in Interchange.

 * Follow the instructions for installing Business::Shipping.
    - (http://www.kavod.com/Business-Shipping/latest/doc/INSTALL.html)
 
 * Copy the business-shipping.tag file into one of these directories:
	- interchange/usertags (IC 4.8.x)
	- interchange/code/UserTags (IC 4.9+)

 * Add any shipping methods that are needed to catalog/products/shipping.asc
 
 * Add the following Interchange variables to provide default information.
   These can be added by copying/pasting into the variable.txt file, then
   restarting Interchange.
   
   Note that "XPS" is used to denote fields that can be used for UPS or USPS.

XPS_FROM_COUNTRY	US	Shipping
XPS_FROM_STATE	Washington	Shipping
XPS_FROM_ZIP	98682	Shipping
XPS_TO_COUNTRY_FIELD	country	Shipping
XPS_TO_ZIP_FIELD	zip	Shipping
UPS_ACCESS_KEY	FJ28AWJN328A3	Shipping 
UPS_USER_ID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	Daily Pickup	Shipping
USPS_USER_ID	143264KAVOD7241	Shipping
USPS_PASSWORD	awji2398r2	Shipping

 * Sample shipping.asc entry:

UPS_GROUND: UPS Ground
	criteria	[criteria-intl]
	min			0
	max			150
	cost		f [business-shipping mode="Offline::UPS" service="GNDRES" weight="@@TOTAL@@"]

=head1 UPGRADE from [ups-query]

See the replacement [ups-query] usertag in this directory.  
Untested, so please report any bugs. 

=cut
EOD
UserTag  business-shipping  Routine <<EOR
use Business::Shipping;

sub {
 	my ( $shipper, $opt ) = @_;
	
	my $debug = delete $opt->{ debug } || 0;
	::logDebug( "[business-shipping " . uneval( $opt ) ) if $debug;
	my $try_limit = delete $opt->{ 'try_limit' } || 2;
	
	unless ( $shipper and $opt->{weight} and $opt->{ 'service' }) {
		Log ( "mode, weight, and service required" );
		return;
	}
	
	#
	# We pass the options mostly unmodifed to the underlying library, so here we
	# take out anything Interchange-specific that isn't necessary with a hash
	# slice.
	#
	delete @{ $opt }{ 'reparse', 'mode', 'hide' };
	
	#
	# Business::Shipping takes a hash.
	#
	my %opt = %$opt;

	my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' };
	
	#
	# STDOUT goes to the IC debug files (usually '/tmp/debug')
	# STDERR goes to the global error log (usually 'interchange/error.log').
	#
	# Defaults: Cache enabled.  Log errors only.
	#	
	
	my $defaults = {
		'all' => {
			'user_id'			=> $Variable->{ "${shipper}_USER_ID" },
			'password'			=> $Variable->{ "${shipper}_PASSWORD" },
			'to_country'		=> $Values->{ 
				$Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' 
			},
			'to_zip'			=> $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } || 'zip' },
			'from_country'		=> $Variable->{ XPS_FROM_COUNTRY },
			'from_zip'			=> $Variable->{ XPS_FROM_ZIP },
			'event_handlers'	=> {
					'error' => 'STDERR',
					'debug' => ( $debug ? 'STDOUT' : undef ),
					'trace' => undef,
					'debug3' => undef,
			},
			'cache'				=> ( defined $opt{ cache } ? $opt{ cache } : 1 ),
		},
		'Online::USPS' => {
			'to_country' => $Tag->data( 
				'country', 
				'name', 
				$Variable->{ XPS_TO_COUNTRY_FIELD } || 'country'
			)
		},
		'Online::UPS' => {
			'access_key'		=> ( $Variable->{ "${shipper}_ACCESS_KEY" } || undef ),
		},
		'Offline::UPS' => { 
			'from_state'		=> $Variable->{ XPS_FROM_STATE },
			'cache'				=> 0,
		},
	};
	
	print STDERR $defaults;
	
	#
	# Apply all of the above defaults.  Sorting the hash keys causes 'all' to
	# be applied first, which allows each shipper to override the default.
	# For example, Online::USPS overrides the to_country method.
	#
	foreach my $shipper_key ( sort keys %$defaults ) {
		if ( $shipper_key eq $shipper or $shipper_key eq 'all' ) {
			my $shipper_defaults = $defaults->{ $shipper_key };
			
			for ( keys %$shipper_defaults ) {
				my $value = $shipper_defaults->{ $_ };
				$opt{ $_ } ||= $value if ( $_ and defined $value );
			}
		}
	}
	
	my $rate_request;
	eval {
		$rate_request = Business::Shipping->rate_request( 'shipper' => $shipper );
	};
	 
	if ( ! defined $rate_request or $@ ) {
		Log( "[business-shipping] failure when calling Business::Shipping->new(): $@ " );
		return;
	}
	
	::logDebug( "calling Business::Shipping::RateRequest::${shipper}->submit( " . uneval( \%opt ) . " )" ) if $debug;
	$rate_request->init( %opt );
	my $tries = 0;
	my $success;
	#
	# Retry the connection if you get one of these errors.  
	# They usually indicate a problem on the shipper's server.
	#
	my @retry_errors = (
		'HTTP Error. Status line: 500',
		'HTTP Error. Status line: 500 Server Error',		
		'HTTP Error. Status line: 500 read timeout',
		'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
		'HTTP Error. Status line: 500 Connect failed:',
		'HTTP Error. Status line: 500 Can\'t connect to production.shippingapis.com:80',
	);
	
	for ( my $tries = 1; $tries <= $try_limit; $tries++ ) {
		my $submit_results;
		eval {
			$submit_results = $rate_request->submit();
		};
		
		if ( $submit_results and ! $@ ) {
			#
			# Success, no more retries
			#
			$success = 1;
			last;
		}
		else {
			Log( "Try $tries: error: " . $rate_request->error() . "$@" );
			for ( @retry_errors ) {
				if ( $rate_request->error() =~ /$_/ ) {
					Log( 'Error was on server, trying again...' );
				}
			}
		}
	}
	return unless $success;
	
	my $charges;
	
	#
	# get_charges() should be implemented for all shippers in the future.
	# For now, we just fall back on total_charges()
	#
	$charges ||= $rate_request->total_charges();
	
	print STDERR "Charges are now $charges!";

	#
	# This is a debugging / support tool.  Set the XPS_GEN_INCIDENTS and
	# SYSTEMS_SUPPORT_EMAIL variables to enable.
	#
	if ( ! $charges or $charges !~ /\d+/) {
		if ( $Variable->{ 'XPS_GEN_INCIDENTS' } ) {
			my $variables = uneval( \%opt ); 
			my $error = $rate_request->error();
			
			#
			# Ignore errors if [incident] is not there, or misbehaves.
			#
			eval {
				$Tag->incident("[business-shipping]: $shipper error: $error. \n Options were: $variables");
			};
			$@ = '';
		}
	}
	::logDebug( "[business-shipping] returning " . uneval( $charges ) ) if $debug;
	
	return $charges;
}
EOR
Message ...done.
endif
