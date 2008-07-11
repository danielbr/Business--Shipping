use strict;
use warnings;

use Carp;
use Business::Shipping;

Business::Shipping->log_level( 'debug' );

sub test
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        shipper    => 'UPS_Offline',
        cache      => 0,
    );
    
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

my %test;
my $this_test_desc;
my $shipment;
### %test = () goes below here.


%test = (
    service        => '2DA',
    weight        => 20,
    from_zip    => '98682',
    from_state    => 'Washington',
    to_zip        => '96826',
);
$this_test_desc = "Hawaii 2DA: ";

$shipment = test( %test );
ok( $shipment->total_charges(),     "UPS Offline: " . $this_test_desc );
print "UPS Offline: " . $this_test_desc . $shipment->total_charges() . "\n";
