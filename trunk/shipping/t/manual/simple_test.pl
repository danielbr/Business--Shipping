#! perl

use Business::Shipping;

my $rate_request = Business::Shipping->rate_request(
	shipper 		=> 'UPS',
	user_id 		=> $ENV{UPS_USER_ID},		
	password 		=> $ENV{UPS_PASSWORD},
	access_key		=> $ENV{UPS_ACCESS_KEY},
	service 		=> 'GNDRES',
	from_zip		=> '98682',
	to_zip			=> '98270',
	weight			=> 5.00,
);

$rate_request->submit() or die $rate_request->error();

print $rate_request->total_charges();
