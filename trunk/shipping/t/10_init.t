#!perl
use Test::More 'no_plan';
use strict;
use warnings;

BEGIN {

    use_ok( 'Business::Shipping' );
    
    foreach my $shipper ( Business::Shipping::Config::calc_req_mod() ) {
        ok( 1, "All required modules for $shipper installed" );
        foreach my $mod_name ( Business::Shipping::Config::get_req_mod( shipper => $shipper ) ) {
            use_ok( $mod_name );
        }
    }
    
    # Make sure that enough modules are install for at least ONE shipper
    my @installed_shippers = Business::Shipping::Config::calc_req_mod();
    if ( not @installed_shippers ) {
        ok( 0, "Required modules are not installed.  See INSTALL file." );
    }
    else {
        my $shippers2 = join( ', ', @installed_shippers );  
        ok( 1, "Required modules installed for: $shippers2" );
    }
    
    # This simulates the way that we use Cache::FileCache
    
    use_ok( 'Cache::FileCache' );
    if ( ! $@ ) {
        my $cache = Cache::FileCache->new;
        my $key = join( "|", ( 'Parcel Post', 'Germany', '5', 'Package' ) ); 
        my $rate = $cache->get( $key );
        
        if ( not defined $rate ) {
            sleep( 1 );
            $rate = '5.99';
            $cache->set( $key, $rate, "30 minutes" );
        }
        
        ok( 1,        'Cache::FileCache works as expected.' );
    }
}

ok( 1, 'Supporting modules exist and are the right versions' );
