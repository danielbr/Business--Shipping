UserTag usps-query Order mode origin zip weight country
UserTag usps-query Routine <<EOR
sub {
	my ( $mode, $origin, $zip, $weight, $country) = @_;
        BEGIN {
	       eval {
	                require XML::DOM;
	                import XML::DOM;
	                require LWP::UserAgent;
	                import LWP::UserAgent;
	       };
	};

        $origin         = $::Variable->{UPS_ORIGIN}
	                                if ! $origin;
	$country        = $::Values->{$::Variable->{UPS_COUNTRY_FIELD}}
					if ! $country;
	$zip            = $::Values->{$::Variable->{UPS_POSTCODE_FIELD}}
	                                if ! $zip;

	$country = uc $country;


	my $b_service = "BPM";
	my $b_fromZip = $origin;
	my $b_toZip = $zip;
	my $b_pounds;

	if($weight < '1') {
		$b_pounds = 1;
	} else {
		$b_pounds = $weight;
	}
	
	my $b_ounces = "0";

	#Build request XML
	my $rateReqDoc = new XML::DOM::Document;
	
	#Add RateRequest
	my $rateReqEl = $rateReqDoc->createElement('RateRequest');
	$rateReqEl->setAttribute('USERID', ''); 
	$rateReqEl->setAttribute('PASSWORD', '');
	$rateReqDoc->appendChild($rateReqEl);

	my $packageEl = $rateReqDoc->createElement('Package');
	$packageEl->setAttribute('ID', '0');
	$rateReqEl->appendChild($packageEl);
	my $serviceEl = $rateReqDoc->createElement('Service');
	my $serviceText = $rateReqDoc->createTextNode($b_service);
	$serviceEl->appendChild($serviceText);
	$packageEl->appendChild($serviceEl);
	my $zipOrigEl = $rateReqDoc->createElement('ZipOrigination');
	my $zipOrigText = $rateReqDoc->createTextNode($b_fromZip);
	$zipOrigEl->appendChild($zipOrigText);
	$packageEl->appendChild($zipOrigEl);
	my $zipDestEl = $rateReqDoc->createElement('ZipDestination');
	my $zipDestText = $rateReqDoc->createTextNode($b_toZip);
	$zipDestEl->appendChild($zipDestText);
	$packageEl->appendChild($zipDestEl);
	my $poundsEl = $rateReqDoc->createElement('Pounds');
	my $poundsText = $rateReqDoc->createTextNode($b_pounds);
	$poundsEl->appendChild($poundsText);
	$packageEl->appendChild($poundsEl);
	my $ouncesEl = $rateReqDoc->createElement('Ounces');
	my $ouncesText = $rateReqDoc->createTextNode($b_ounces);
	$ouncesEl->appendChild($ouncesText);
	$packageEl->appendChild($ouncesEl);
	my $containerEl = $rateReqDoc->createElement('Container');
	my $containerText = $rateReqDoc->createTextNode('NONE');
	$containerEl->appendChild($containerText);
	$packageEl->appendChild($containerEl);
	my $oversizeEl = $rateReqDoc->createElement('Size');
	my $oversizeText = $rateReqDoc->createTextNode('Regular');
	$oversizeEl->appendChild($oversizeText);
	$packageEl->appendChild($oversizeEl);
	my $machineEl = $rateReqDoc->createElement('Machinable');
	my $machineText = $rateReqDoc->createTextNode('False');
	$machineEl->appendChild($machineText);
	$packageEl->appendChild($machineEl);
#Testing URL
#http://testing.shippingapis.com/shippingapitest.dll
	my $ua = new LWP::UserAgent;
	my $req = new HTTP::Request 'POST', 'http://production.shippingapis.com/ShippingAPI.dll';
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('API=Rate&XML=' . $rateReqDoc->toString);

	my $response = $ua->request($req);
	my $resp;

	if ($response->is_success) {

	        $resp = $response->content;

	} else {
		return "No content returned";
	}


		my $parser = new XML::DOM::Parser;
		my $rateRespDoc = $parser->parse($resp);


		if($rateRespDoc->getElementsByTagName('Error')) {
			::logGlobal("received back: " . $rateRespDoc->toString);
			#return "Error returned look in log";
		}

		my $packageList = $rateRespDoc->getElementsByTagName('Package');
	
		my $packageNode = $packageList->item(0);
		my $tmpList = $packageNode->getElementsByTagName('Postage');
		my $postage = $tmpList->item(0)->getFirstChild->getNodeValue;

		return $postage;

}
EOR

