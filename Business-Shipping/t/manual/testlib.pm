package testlib;

use Carp;
use Test::More 'no_plan';
use Business::Shipping;

#`rm -Rf /tmp/FileCache/`;

@EXPORT = qw/ test_ol_usps debug /;
use base ( 'Exporter' );

sub debug
{
    print STDERR $_[ 0 ] . "\n" if $::debug;
}

sub test_ol_usps
{
    my ( %args ) = @_;
    my $shipment = Business::Shipping->rate_request( 
        'shipper' => 'USPS',
        'user_id'        => $ENV{ UPS_USER_ID },
        'password'        => $ENV{ UPS_PASSWORD },
        'cache'    => 0,
        event_handlers => {
            #trace => 'STDERR', 
        }
    );
    $shipment->submit( %args ) or die $shipment->user_error();
    return $shipment;
}

1;

