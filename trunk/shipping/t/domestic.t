#!/usr/bin/perl

require 'main.t';

print test_domestic(
	'from_zip' => '98682',
	'to_country' => 'United States',
	'service' => 'Priority',
	'to_zip' => '96826',
	'from_country' => 'US',
	'pounds' => '2',
	'tx_type' => 'rate',
);
