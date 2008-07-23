use strict;
use warnings;

use Test::More;
use Carp;
use Business::Shipping;

#plan skip_all => 'Required modules not installed' 
#    unless Business::Shipping::Config::calc_req_mod( 'UPS_Online' );
plan skip_all => 'No credentials' 
    unless $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY };
#plan skip_all => 'SLOW_TESTS is not set, skipping.' unless $ENV{SLOW_TESTS};
plan 'no_plan';


use_ok('Business::Shipping::UPS_Online::Tracking');
use Scalar::Util qw(blessed);
my $tracker = Business::Shipping::UPS_Online::Tracking->new();
is(blessed($tracker), 'Business::Shipping::UPS_Online::Tracking',
    'Get new Tracking object');

$tracker->init(
    test_mode => 1,
    user_id        => $ENV{ UPS_USER_ID },
    password       => $ENV{ UPS_PASSWORD },
    access_key     => $ENV{ UPS_ACCESS_KEY },
);



=pod

# The results hash will contain this type of information

{
  # Date the package was picked up
  pickup_date => '...',


  # Scheduled delivery date (YYYYMMDD)
  scheduled_delivery_date => '...',

  # Scheduled delivery time (HHMMSS)
  scheduled_delivery_time => '...',

  # Rescheduled delivery date (YYYYMMDD)
  rescheduled_delivery_date => '...',

  # Rescheduled delivery time (HHMMSS)
  rescheduled_delivery_time => '...',


  # Shipment method code and description for package
  service_code => '...',
  service_description => '...',

  
  # Summary will contain the latest activity entry, a copy of activity->[0]
  summary => { },
  # Activity of the package in transit, newest entries first.
  activity => [
  {
    # Address information of the activity 
    address => {
       city => '...',
       state => '...',
       zip => '...',
       country => '...',
       description => '...',
       code => '...',
       signedforbyname => '...',
    },

    # Code of activity
    status_code => '...',
    status_description => '...',
    
    # Date of activity (YYYYMMDD)
    date => '...',
    # Time of activity (HHMMSS)
    time => '...',
  }
 
  ],
}

=cut

$tracker->tracking_ids('1Z12345E0291980793');

$tracker->submit() || logdie $tracker->user_error();
my $hash = $tracker->results();

use Data::Dumper;
print Data::Dumper->Dump($hash);

is(ref($hash), 'HASH', 'Got results hash.');

#is(ref($hash->{EJ958083578US}), 'HASH', 'Test tracking id in results.');
#is(ref($hash->{EJ958083578US}{summary}), 'HASH', 'Has summary');
#is($hash->{EJ958083578US}{summary}{status_description}, 'DELIVERED', 
#    'Test tracking number status description is delivered.');
