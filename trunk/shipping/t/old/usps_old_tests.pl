#!/usr/bin/perl

print "Testing USPS...\n\n";

use Business::Shipping::USPS;
use Business::Shipping::UPS;
use Data::Dumper;

my $shipment = new Business::Shipping( 'shipper' => 'USPS' );

#my $shipment = new Business::Shipping::USPS;


### Test
# try calling enw with parameters

my $shipment3 = new Business::Shipping( 
    'user_id'         => $ENV{USPS_USER_ID},
    'password'         => $ENV{USPS_PASSWORD},
    'tx_type'         => 'rate', 
    'test_mode'        => 0,
);

$shipment->set( 'event_handlers' => ({ 
    'debug' => 'STDOUT', 
    'trace' => 'STDOUT', 
    'error' => 'STDOUT', 
    })
);
$shipment->set(
    'user_id'         => $ENV{USPS_USER_ID},
    'password'         => $ENV{USPS_PASSWORD},
    'tx_type'         => 'rate', 
    'test_mode'        => 0,
);

#mail_type: "package", "postcards or aerogrammes", "matter for the blind", "envelope"
$shipment->set( %intl_request_1 );
# Testing alternate method:

$shipment->set(
        weight        => 0.2,
        ounces        => 0,
        mail_type    => 'Package',
        to_country    => 'Great Britain',
);

#print Dumper( $shipment );

$shipment->submit() or die $shipment->user_error();
print "0.2 weight: " . $shipment->get_charges('Airmail Parcel Post') . "\n";

exit;

$shipment->set(
        weight        => 5.6,
        ounces        => 0,
        mail_type    => 'Package',
        to_country    => 'Great Britain',
);

my @countries_to_test = (
    'Great Britain',
    'Canada',
    'New Zealand',
    'Australia',
);

foreach my $country ( @countries_to_test ) {
    $shipment->submit( 'to_country' => $country );
    print "$country = " . $shipment->default_package()->get_charges( 'Airmail Parcel Post' ) . "\n";
    
}

#$shipment->add_package(
#        weight        => 5.6,
#        ounces        => 0,
#        mail_type    => 'Package',
#        to_country    => 'Germany',
#);

my %test_request_1 = (qw/
    test_mode    1
    service        EXPRESS
    from_zip    20770
    to_zip        20852
    weight        10
/);

my %test_request_2 = (qw/
    test_mode    1
    service        Priority
    from_zip    20770
    to_zip        90210
    pounds        5
    ounces        1
    container    0-1096
    size        Regular
    machinable    False
/);


my %intl_request_2 = (qw/
    test_mode    1
    pounds        0
    ounces        1
    mail_type    Postcards or Aerogrammes
    to_country    Algeria
/);

my %intl_production_request_1 = (
    test_mode    => 0,
    pounds        => 1,
    ounces        => 1,
    mail_type    => 'Package',
    to_country    => 'France',
);

#$shipment->set( %intl_request_1 );
    
=pod
$shipment->set(
    'event_handlers' => ({ 'debug' => 'STDOUT' }),
    'user_id'         => $ENV{USPS_USER_ID},
    'password'         => $ENV{USPS_PASSWORD},
    'tx_type'         => 'rate',
    'test_mode'        => 0,
    'service'        => 'BPM',
    'weight'        => 3,
    'from_zip'        => '98682',
    'to_zip'        => '98270',
);
=cut

$shipment->submit();

$shipment->is_success() or die "Error = " .  $shipment->user_error_msg();

#print Dumper( $shipment->response_tree() );

print "Airmail Parcel Post = " . $shipment->packages()->[0]->get_charges( 'Airmail Parcel Post' ) . "\n";

#print Dumper ($shipment->packages());

#print "total_charges = " . $shipment->total_charges();
#$shipment->set(
#    'event_handlers' => ({ 'debug' => 'croak' })
#);

#print "shipment = " . Dumper( $shipment );


print "\n";

1;

=pod

International Test rate requests from USPS...

Valid Test Request #1
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">< Package ID="0"><Pounds>2</Pounds><Ounces>0</Ounces><MailType>Package</MailType><Country>Albania</Country></Package></IntlRateRequest>

Request #1 in better form:
<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">
    < Package ID="0">
        <Pounds>2</Pounds>
        <Ounces>0</Ounces>
        <MailType>Package</MailType>
        <Country>Albania</Country>
    </Package>
</IntlRateRequest>


Response #1:
<?xml version="1.0" ?>
<IntlRateResponse>
    <Package ID="0">
        <Prohibitions>Currency of the Albanian State Bank (Banknotes in lek). Extravagant clothes and other articles contrary to Albanians' taste. Items sent by political emigres.</Prohibitions>
        <Restrictions>Hunting arms require an import permit. Medicines for personal use are admitted provided the addressee has a medical certificate.</Restrictions>
        International Rates Calculator API 13
        USPS Web Tool Kit User�s Guide <Observations>1. Letter packages may not contain dutiable articles. 2. Parcel post service extends only to: Berat Konispol Milot Bilisht Korce Peqin</Observations>
        <CustomsForms>Postal Union Mail (LC/AO): PS Form 2976 or 2976-A (see 123.61) Parcel Post: PS Form 2976-A inside 2976-E (envelope)</CustomsForms>
        <ExpressMail>Country Code AL Reciprocal Service Name EMS Required Customs Form/Endorsement 1. For correspondence and business papers: PS Form 2976, Customs - CN 22 (Old C 1) and Sender's Declaration (green label). Endorse item clearly next to mailing label as BUSINESS PAPERS.</ExpressMail>
        <AreasServed>Tirana.</AreasServed>
        <Service ID="0">
        <Pounds>2</Pounds>
        <Ounces>0</Ounces>
        <MailType>Package</MailType>
        <Country>ALBANIA</Country>
        <Postage>87</Postage>
        <SvcCommitments>See Service Guide</SvcCommitments>
        <SvcDescription>Global Express Guaranteed (GXG) Document Service</SvcDescription>
        <MaxDimensions>Max. length 46", depth 35", height 46" and max. girth 108"</MaxDimensions>
        <MaxWeight>22</MaxWeight>
        </Service>
        <Service ID="1">
        <Pounds>2</Pounds>
        <Ounces>0</Ounces>
        <MailType>Package</MailType>
        <Country>ALBANIA</Country>
        <Postage>96</Postage>
        <SvcCommitments>See Service Guide</SvcCommitments>
        <SvcDescription>Global Express Guaranteed (GXG) Non-Document Service</SvcDescription>
        <MaxDimensions>Max. length 46", depth 35", height 46" and max. girth 108"</MaxDimensions>
        <MaxWeight>22</MaxWeight>
        </Service>
    </Package>
</IntlRateResponse>


Valid Test Request #2
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">< Package ID="0"><Pounds>0</Pounds><Ounces>1</Ounces><MailType>Postcards or Aerogrammes</MailType><Country>Algeria</Country></Package></IntlRateRequest>

Pre-defined Error Request #1: �Invalid Weight for Pounds�
The pre-defined error in this request is using non- numeric input for <Pounds>.
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">< Package ID="0"><Pounds>two</Pounds><Ounces>0</Ounces><MailType>Package</MailType><Country>Albania</Country></Package></IntlRateRequest>
Pre-defined Error Request #2: �Invalid Weight for Ounces�
The pre-defined error in this request is using non- numeric input for <Ounces>.
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">< Package ID="0"><Pounds>2</Pounds><Ounces>zero</Ounces><MailType>Package</MailType><Country>Albania</Country></Package></IntlRateRequest>
Error Request #3: �No Weight Entered�
The pre-defined error in this request is leaving the inputs for both <Pounds> and <Ounces> empty.
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Pounds>0</Pounds><Ounces>0</Ounces><MailType>Package</MailType><Country>Albania</Country></Package></IntlRateRequest>
Pre-defined Error Request #4: �Invalid Mail Type�
The pre-defined error in this request is using input other than: �package,� �postcards or aerogrammes,� �matter for the blind,� or �envelope� for <MailType>.
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">< Package ID="0"><Pounds>2</Pounds><Ounces>2</Ounces><MailType>Express</MailType><Country>Albania</Country></Package></IntlRateRequest>
Pre-defined Error Request #5: �Invalid Country�
The pre-defined error in this request is using invalid input for <Country>. (This error was created for testing purposes only.)
http://SERVERNAME/ShippingAPITest.dll?API=IntlRate&XML=<IntlRateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Pounds>2</Pounds><Ounces>2</Ounces><MailType>Package</MailType><Country>Alabama</Country></Package></IntlRateRequest>

Domestic Test rate requests from USPS...

Valid Test Request #1
Http://SERVERNAME/ShippingAPITest.dll?API=Rate&XML=<RateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx"><Package ID="0"><Service> EXPRESS</Service><ZipOrigination>20770</ZipOrigination><ZipDestination>20852</ZipDestination><Pounds>10</Pounds><Ounces>0</Ounces><Container>None</Container><Size>REGULAR</Size><Machinable></Machinable></Package></RateRequest>

Valid Test Request #1 Pretty XML:
<RateRequest USERID="xxxxxxxx" PASSWORD="xxxxxxxx">
    <Package ID="0">
        <Service> EXPRESS</Service>
        <ZipOrigination>20770</ZipOrigination>
        <ZipDestination>20852</ZipDestination>
        <Pounds>10</Pounds>
        <Ounces>0</Ounces>
        <Container>None</Container>
        <Size>REGULAR</Size>
        <Machinable></Machinable>
    </Package>
</RateRequest>



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
