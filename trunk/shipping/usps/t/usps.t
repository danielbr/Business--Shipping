#!/usr/bin/perl

print "Testing USPS...\n\n";

use Business::Ship;
use Data::Dumper;

my $shipment = new Business::Ship( 'USPS' );


$shipment->set(
	'event_handlers' => ({ 'debug' => 'STDOUT' }),
	'user_id' 		=> $ENV{USPS_USER_ID},
	'password' 		=> $ENV{USPS_PASSWORD},
	'tx_type' 		=> 'rate', 
	'test_mode'		=> 1,
);

my %test_request_1 = (qw/
	test_mode	1
	service		EXPRESS
	from_zip	20770
	to_zip		20852
	weight		10
/);

my %test_request_2 = (qw/
	test_mode	1
	service		Priority
	from_zip	20770
	to_zip		90210
	pounds		5
	ounces		1
	container	0-1096
	size		Regular
	machinable	False
/);

$shipment->set( %test_request_2 );
	
=pod
$shipment->set(
	'event_handlers' => ({ 'debug' => 'STDOUT' }),
	'user_id' 		=> $ENV{USPS_USER_ID},
	'password' 		=> $ENV{USPS_PASSWORD},
	'tx_type' 		=> 'rate',
	'test_mode'		=> 0,
	'service'		=> 'BPM',
	'weight'		=> 3,
	'from_zip'		=> '98682',
	'to_zip'		=> '98270',
);
=cut

$shipment->submit();

$shipment->success() or die "Error = " .  $shipment->error_msg();

print "total_charges = " . $shipment->total_charges();
#$shipment->set(
#	'event_handlers' => ({ 'debug' => 'croak' })
#);

#print "shipment = " . Dumper( $shipment );


print "\n";

1;

=pod

Test rate requests from USPS...

Valid Test Request #1
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service> EXPRESS</Service><ZipOrigination>20770</ZipOrigination><ZipDestination>20852</ZipDestination><Pounds>10</Pounds><Ounces>0</Ounces><Container>None</Container><Size>REGULAR</Size><Machinable></Machinable></Package></RateRequest>
Valid Test Request #2
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID= "xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service>Priority</Service>
<ZipOrigination>20770</ZipOrigination><ZipDestination>90210</ZipDestination><Pounds>5</Pounds><Ounces>1</Ounces><Container>0-1096</Container><Size>
REGULAR</Size><Machinable></Machinable></Package></RateRequest>
Valid Test Request #3
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID=
"xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service>Parcel</Service>
<ZipOrigination>20770</ZipOrigination><ZipDestination>90210</ZipDestination><Pounds>10</Pounds><Ounces>0</Ounces><Container>None</Container><Size>Regular</Size><Machinable>True</Machinable></Package></RateRequest>
Valid Test Request #4
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID=
"xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service>Parcel</Service>
<ZipOrigination>20770</ZipOrigination><ZipDestination>90210</ZipDestination><Pounds>10</Pounds><Ounces>0</Ounces><Container>None</Container><Size>Regular</Size><Machinable>False</Machinable></Package></RateRequest>
Valid Test Request #5
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID="xxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service>Parcel
</Service><ZipOrigination>20770</ZipOrigination><ZipDestination>09007</ZipDestination><Pounds>10</Pounds><Ounces>0</Ounces><Container>None</Container><Size>Regular</Size><Machinable>False</Machinable></Package></RateRequest>
Valid Test Request #6
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID="xxxxxx" PASSWORD="xxxxxxx"><Package ID="0"><Service>Priority
</Service><ZipOrigination>20770</ZipOrigination><ZipDestination>09021</ZipDestination><Pounds>5</Pounds><Ounces>1</Ounces><Container>None</Container><Size>Regular</Size><Machinable>False</Machinable></Package></

=cut
