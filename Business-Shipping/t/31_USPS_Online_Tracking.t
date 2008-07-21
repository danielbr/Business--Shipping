use strict;
use warnings;

use Test::More;
use Carp;
use Business::Shipping;

#plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'USPS_Online' );
plan skip_all => 'No credentials' unless $ENV{ USPS_USER_ID } and $ENV{ USPS_PASSWORD };
plan 'no_plan';

use Business::Shipping::USPS_Online::Tracking;

my $tracker = Business::Shipping::USPS_Online::Tracking->new();

$tracker->init(
    test_mode => 1,
        user_id        => $ENV{ USPS_USER_ID },
        password       => $ENV{ USPS_PASSWORD },
);

$tracker->tracking_ids('EJ958083578US', 'EJ958083578US');

$tracker->submit() || logdie $tracker->user_error();
my $hash = $tracker->results();

use Data::Dumper;
print Data::Dumper->Dump([$hash]);

1;
