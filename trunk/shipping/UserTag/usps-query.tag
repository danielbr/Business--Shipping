Message Loading [xps-query] usertag...
UserTag  xps-query  Addattr
UserTag  xps-query  Documentation <<EOD
=head1 NAME

[usps-query] - Business::Ship Interface for Interchange.

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
#use Business::Ship::UPS;
use Business::Ship::USPS;
sub {
 	my( $opt ) = @_;
	
	if ( $opt->{mode} eq 'UPS' ) {
	
	}
	elsif ( $opt->{'mode'} eq 'USPS' ) {
		my $shipment = new Business::Ship::USPS;
		$shipment->set(
			'user_id' 		=> $ENV{USPS_USER_ID},
			'password' 		=> $ENV{USPS_PASSWORD},
			'tx_type' 		=> 'rate',
		);
		$shipment->add_package(
			pounds		=> $opt->{'weight'},
			mail_type	=> 'Package',
			to_country	=> $opt->{'to_country'},
		);
		$shipment->submit(); #TODO: handle errors
		return $shipment->get_price( $opt->{'service'} );
	}
}
EOR

