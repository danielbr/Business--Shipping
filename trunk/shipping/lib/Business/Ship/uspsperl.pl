#!/usr/bin/perl -w
#

use XML::DOM;
use LWP::UserAgent;

$b_service = "BPM";
$b_fromZip = "29708";
$b_toZip = "28278";
$b_pounds = "1";
$b_ounces = "0";

#Build request XML
$rateReqDoc = new XML::DOM::Document; 
$rateReqEl = $rateReqDoc->createElement('RateRequest'); 
$rateReqEl->setAttribute('USERID', $ENV{USPS_USER_ID}); 
$rateReqEl->setAttribute('PASSWORD', $ENV{USPS_PASSWORD}); 
$rateReqDoc->appendChild($rateReqEl); 
$packageEl = $rateReqDoc->createElement('Package'); 
$packageEl->setAttribute('ID', '0'); 
$rateReqEl->appendChild($packageEl); 
$serviceEl = $rateReqDoc->createElement('Service'); 
$serviceText = $rateReqDoc->createTextNode($b_service); 
$serviceEl->appendChild($serviceText); 
$packageEl->appendChild($serviceEl); 
$zipOrigEl = $rateReqDoc->createElement('ZipOrigination'); 
$zipOrigText = $rateReqDoc->createTextNode($b_fromZip); 
$zipOrigEl->appendChild($zipOrigText); 
$packageEl->appendChild($zipOrigEl); 
$zipDestEl = $rateReqDoc->createElement('ZipDestination'); 
$zipDestText = $rateReqDoc->createTextNode($b_toZip); 
$zipDestEl->appendChild($zipDestText); 
$packageEl->appendChild($zipDestEl); 
$poundsEl = $rateReqDoc->createElement('Pounds'); 
$poundsText = $rateReqDoc->createTextNode($b_pounds);
$poundsEl->appendChild($poundsText); 
$packageEl->appendChild($poundsEl); 
$ouncesEl = $rateReqDoc->createElement('Ounces'); 
$ouncesText = $rateReqDoc->createTextNode($b_ounces); 
$ouncesEl->appendChild($ouncesText); 
$packageEl->appendChild($ouncesEl); 
$containerEl = $rateReqDoc->createElement('Container'); 
$containerText = $rateReqDoc->createTextNode('NONE'); 
$containerEl->appendChild($containerText); 
$packageEl->appendChild($containerEl); 
$oversizeEl = $rateReqDoc->createElement('Size'); 
$oversizeText = $rateReqDoc->createTextNode('Regular'); 
$oversizeEl->appendChild($oversizeText); 
$packageEl->appendChild($oversizeEl); 
$machineEl = $rateReqDoc->createElement('Machinable'); 
$machineText = $rateReqDoc->createTextNode('False'); 
$machineEl->appendChild($machineText); 
$packageEl->appendChild($machineEl); 

#$req = new HTTP::Request 'POST', 'http://testing.shippingapis.com/ShippingAPItest.dll'; 
#$req = new HTTP::Request 'POST', 'http://production.shippingapis.com/ShippingAPI.dll'; 

print "content-type: text/html\n\n"; 
print $htmlBegin; 
$ua = new LWP::UserAgent; 
$req = new HTTP::Request 'POST', 'http://production.shippingapis.com/ShippingAPI.dll'; 
$req->content_type('application/x-www-form-urlencoded'); 
$req->content('API=Rate&XML=' . $rateReqDoc->toString); 

print $rateReqDoc->toString();
$response = $ua->request($req); 
if ($response->is_success) { 
	$resp = $response->content; 
} else { 
	print "<p>There was an error processing your requestKO</p>\n"; 
	print $htmlEnd; 
	exit 0; 
}


$parser = new XML::DOM::Parser; 
$rateRespDoc = $parser->parse($resp); 
#if ($rateRespDoc->getDocumentElement->getNodeName eq 'Error') { 
#if ($rateRespDoc->getElementsByTagName('Error')) { 
#	print "<p>There was an error processing your requestERROR</p>\n"; 
#print $rateRespDoc->toString;
#	print $htmlEnd; 
#	exit 0; 
#} 

$packageList = $rateRespDoc->getElementsByTagName('Package'); 
$n = $packageList->getLength; 

print $rateRespDoc->toString;

print "N is: $n\n";
for ($i = 0; $i < $n; $i++) { 
	$packageNode = $packageList->item($i); 
	$tmpList = $packageNode->getElementsByTagName('ZipOrigination'); 
	$m = $tmpList->getLength; 
	print "M is: $m\n";
	if ($m == 1) { 
		$zipOrig = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$zipOrig = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple ZipOrigination tags in Package tag-->\n"; 
	} else { 
		$zipOrig = ''; 
		print "<!-- No ZipOrigination tag -->\n"; 
	} 

	$tmpList = $packageNode->getElementsByTagName('ZipDestination'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$zipDest = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$zipDest = $tmpList->item(0)->getFirstChild->getNodeValue; 
	print "<!-- XML Error: multiple ZipDestination tags in Package tag-->\n"; 
	} else { 
		$zipDest = ''; 
		print "<!-- No ZipDestination tag -->\n"; 
	} 

	$tmpList = $packageNode->getElementsByTagName('Service'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$service = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$service = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple Service tags in Package tag-->\n"; 
	} else { 
		$service = ''; 
		print "<!-- No Service tag -->\n"; 
	} 

	$tmpList = $packageNode->getElementsByTagName('Pounds'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$pounds = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$pounds = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple Pounds tags in Package tag-->\n"; 
	} else { 
		$pounds = ''; 
		print "<!-- No Pounds tag -->\n"; 
	} 
	
	$tmpList = $packageNode->getElementsByTagName('Ounces'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$ounces = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) {
		$ounces = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple Ounces tags in Package tag-->\n"; 
	} else { 
		$ounces = ''; 
		print "<!-- No Ounces tag -->\n"; 
	} 

	$tmpList = $packageNode->getElementsByTagName('Postage'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$postage = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$postage = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple Postage tags in Package tag-->\n"; 
	} else { 
		$postage = ''; 
		print "<!-- No Postage tag -->\n"; 
	} 

	$tmpList = $packageNode->getElementsByTagName('RestrictionCodes'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$restcodes = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$restcodes = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple RestrictionCodes tags in Package tag-->\n"; 
	} else { 
		$restcodes = ''; 
		print "<!-- No RestrictionCodes tag -->\n"; 
	}
	
	$tmpList = $packageNode->getElementsByTagName('RestrictionDescription'); 
	$m = $tmpList->getLength; 
	if ($m == 1) { 
		$restdesc = $tmpList->item(0)->getFirstChild->getNodeValue; 
	} elsif ($m > 1) { 
		$restdesc = $tmpList->item(0)->getFirstChild->getNodeValue; 
		print "<!-- XML Error: multiple RestrictionDescription tags in Package tag-->\n"; 
	} else { 
		$restdesc = ''; 
		print "<!-- No RestrictionDescription tag -->\n"; 
		print " <P>\n"; 
		print " "; 
		print "Sending your package weighing " . ${pounds} . " pounds "; 
		print "and " . ${ounces} . " ounces from ZIP code " . ${zipOrig}; 
		print " to ZIP Code " . ${zipDest} . " by " . ${service} . " Mail "; 
		print "will cost: <BR>\n"; 
		print " "; 
		print '<FONT SIZE="+1" COLOR="#CC0000">$' . ${postage} . "</FONT>\n"; 
		print " </P>\n"; 
} 
}
print $htmlEnd;

