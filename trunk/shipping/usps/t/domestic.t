#!/usr/bin/perl

require 'main.t';

print test_domestic(
	'user_id' => '539KAVOD6731',
	'from_zip' => '98682',
	'to_country' => 'United States',
	'service' => 'Priority',
	'to_zip' => '96826',
	'from_country' => 'US',
	'password' => '900QZ55LW201',
	'pounds' => '2',
	'tx_type' => 'rate',
);
