use strict;
use warnings;

use Business::Shipping;
use Benchmark;

use constant INCREMENT => 5;
use constant NUM_TESTS => 20;
# Benchmarking indicates that it is 5% faster to re-use the existing object.
use constant CREATE_OBJ_EVERY_TIME => 0; 

#Business::Shipping->log_level( 'debug' );

if ( ! CREATE_OBJ_EVERY_TIME ) {
    $main::rr = Business::Shipping->rate_request( 
        shipper => 'UPS_Offline', 
        cache => 0,
        service => '1DA',
        from_zip => '98682',
        to_zip   => '98270',
    );
}

Benchmark::timethese( NUM_TESTS, {
    "Sequential Scan Algorithm with " . 150 / INCREMENT . " tests each." => \&test,
});


sub test
{
    for ( my $weight = INCREMENT; $weight < 150; $weight += INCREMENT ) {
        
        if ( CREATE_OBJ_EVERY_TIME ) {
            $main::rr = Business::Shipping->rate_request( 
                shipper => 'UPS_Offline', 
                cache => 0,
                service => '1DA',
                from_zip => '98682',
                to_zip   => '98270',
            );
        }

        $main::rr->submit( weight => $weight ) or die $main::rr->user_error();
        #print "$weight: " . $main::rr->total_charges . "\n";
        #print ".";
    }
    
    return;
}

#use Data::Dumper;
#print Dumper( $main::rr );
