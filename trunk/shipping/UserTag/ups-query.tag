Message Loading [ups-query] usertag...
# "Order" is kept for compatibility, new options go in the Addattr hash		  
UserTag  ups-query  Order  mode origin zip weight country
UserTag  ups-query  AttrAlias	origin_zip	origin
UserTag  ups-query  AttrAlias	destin_zip	zip
UserTag  ups-query  Addattr
UserTag  ups-query  Documentation <<EOD
=head1 NAME

[ups-query] - Business::UPSTools Interface for Interchange.

Copyright (c) 2003 Kavod Technologies, Dan Browning, 
	Payment Online Inc., and others.
  
All rights reserved. This program is free software; you can 
redistribute it and/or modify it under the GPL license.

=head1 MAINTAINER

	Current Volunteer Maintainer:
	Dan Browning
	<db@kavod.com>
	http://www.kavodtechnologies.com
	
	This module in based on work by Payment Online Inc.
	
=head1 SYNOPSIS

[ups-query 
	mode="GNDRES"
	origin="98682"
	zip="98270"
	weight="3.5"
	country="US"
	]
	
=head1 INSTALLATION

Here is a general outline of the installation in interchange.

 * Install all the necessary perl modules:
	- (Bundle::LWP Bundle::XML Crypt::SSLeay)

 * Sign up for UPS XML Access
	- Add Access ID and code using Admin UI

 * Copy the UPSTools.pm file into
	- interchange/lib/Business directory

 * Copy the ups-query.tag file into
	- interchange/usertags (depends on IC version)

 * Add any shipping methods that are needed
	- to catalog/products/shipping.asc
	- (The defaults that come with Interchange are fine)

 * Need to write instructions for getting access information…

To utilize the new Business::UPSTools module, you might try the following
installation steps:

These CPAN Perl Modules are needed:
 * Bundle::LWP
 * XML::Simple
 
You can install them with this command:

C<perl -MCPAN -e 'install Bundle::LWP XML::Simple'>

You will also need to get a User Id, Password, and Access Key from UPS.
 
 * Read about it online:
 
http://www.ec.ups.com/ecommerce/gettools/gtools_intro.html 
 
 * Sign up here:
 
https://www.ups.com/servlet/registration?loc=en_US_EC
 
 * When you recieve your information from UPS, you can enter into IC
   via catalog variables.  You can add these to your products/variables.txt
   file, like the following example, or you can add them using the Admin UI.
   
UPS_ACCESSKEY	FJ28AWJN328A3	Shipping 
UPS_USERID	userid	Shipping
UPS_PASSWORD	mypassword	Shipping
UPS_PICKUPTYPE	06	Shipping

 * Pickup Type Codes:

01 Daily Pickup 
03 Customer Counter 
06 One Time Pickup 
07 On Call Air 
19 Letter Center 
20 Air Service Center 

=cut
EOD
UserTag  ups-query  Routine <<EOR
use Business::UPS;
use Business::Ship::UPS;
sub {
 	my( $mode, $origin, $zip, $weight, $country, $opt) = @_;
	
	#::logDebug("calling ups-query with mode=$mode, origin=$origin, zip=$zip, weight=$weight, country=$country" . uneval( $opt ) );
	 
	my $packaging_type	=	$opt->{packaging_type};
	my $residential		=	$opt->{residential};
	my $access_key		=	$::Variable->{UPS_ACCESSKEY};
	my $ups_userid		=	$::Variable->{UPS_USERID};
	my $ups_password 	=	$::Variable->{UPS_PASSWORD};
	my $pickup_type 	=	$::Variable->{UPS_PICKUPTYPE};
	$origin				||=	$::Variable->{UPS_ORIGIN};
	$country 			||=	$::Values->{ ( $::Variable->{UPS_COUNTRY_FIELD}  or 'country' ) };
	$zip 				||=	$::Values->{ ( $::Variable->{UPS_POSTCODE_FIELD} or 'zip'     ) };
	$opt->{city}		||=	$::Values->{ ( $::Variable->{UPS_CITY_FIELD}     or 'city'    ) };
	$country 			= 	uc $country;
	
	return unless ( $zip and $mode and $weight and $origin );
	
	# Is the passed mode alpha ('1DA') or numeric ('02')?
	my $alpha = 1 unless ( $mode =~ /\d\d/ );
	
	my %default_package_map = (
		qw/
			1DM	02
			1DML	01
			1DA	02
			1DAL	01
			2DM	02
			2DA	02
			2DML	01
			2DAL	01
			3DS	02
			GNDCOM	02
			GNDRES	02
			XPR	02
			UPSSTD	02
			XDM	02
			XPRL	01
			XDML	01
			XPD	02
		/
	);

	# Automatically assign a package type if none given, for backwards compatibility.
	if ( $alpha and $default_package_map{$mode} ) {
		$packaging_type ||= $default_package_map{$mode};
	} else {
		$packaging_type ||= "02";
	}
	
	my %mode_map = (
		qw/
			1DM	14
			1DML	14
			1DA	01
			1DAL	01
			2DM	59
			2DA	02
			2DML	59
			2DAL	02
			3DS	12
			GNDCOM	03
			GNDRES	03
			XPR	07
			XDM	54
			UPSSTD	11
			XPRL	07
			XDML	54
			XPD	08
		/
	);
	
	# Map names to codes for backward compatibility.
	$mode = $mode_map{$mode}		if $alpha;
	
	# For the ones we're certain about, set to default of residential.
	$residential	||= 1			if $mode == $mode_map{GNDRES};
	$residential	||= 0			if $mode == $mode_map{GNDCOM};
	$residential	||= 1;
	
	# UPS requires weight is at least 0.1 pounds.
	$weight			= 0.1 			if $weight < 0.1;

	# In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
	$country eq 'US' and $zip =~ /^(\d{5})/ and $zip = $1;
	
	# UPS prefers 'GB' instead of 'UK'
	$country = 'GB' if $country eq 'UK';

	# Performance Enhancement:
	# Check the cache to see if exact same call already performed for this session.
	my $cache_key = join "|", ($mode, $origin, $zip, $weight, $country, $packaging_type, $residential, $pickup_type);
	return $Vend::Session->{'ups_query_cache'}{$cache_key}
		if $Vend::Session->{'ups_query_cache'}{$cache_key};

	if ($access_key && $ups_userid && $ups_password) {
		my %ups_opts = (
			access_license_number => $access_key,
			user_id => $ups_userid,
			password => $ups_password,
			pickup_type_code => $pickup_type,
			shipper_country_code => 'US',
			shipper_postal_code => $origin,
			ship_to_residential_address => $residential,
			ship_to_country_code => $country,
			ship_to_postal_code => $zip,
			service_code => $mode,
			packaging_type_code =>  $packaging_type,
			weight => $weight,
			event_handler_error => '',
		);
		my $ups = new Business::Ship::UPS;
		#::logDebug("calling Business::UPSTools with: " . uneval( %ups_opts ) );
		$ups->run_query( %ups_opts ) or my $error = $ups->error();
		#::logDebug("received back: " . join("|", $status, $descript, $rate));
		if( $error ) {
			$Vend::Session->{ship_message} .= " $mode: $error";
			#Log( "$mode: $error" );
			return 0;
		}
		my $amount = $ups->get_total_charges();
		$Vend::Session->{'ups_query_cache'}{$cache_key} = $amount;
		return $amount;
	}
	else {
		#::logDebug("calling Business::UPS::getUPS with: " . join("|", $mode, $origin, $zip, $weight, $country));
		my ($shipping, $zone, $error) =
			Business::UPS::getUPS( $mode, $origin, $zip, $weight, $country);
		#::logDebug("received back: " . join("|", $shipping, $zone, $error));
        if( $error ) {
			$Vend::Session->{ship_message} .= " $mode: $error";
			return 0;
		}
		$Vend::Session->{'ups_query_cache'}{$cache_key} = $shipping;
		return $shipping;
	}
}
EOR

