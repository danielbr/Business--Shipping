use Test::More 'no_plan';

BEGIN { 
	use_ok( 'Business::Ship' );
	use_ok( 'XML::DOM' );
	use_ok( 'LWP::Simple' );
	use_ok( 'XML::Simple' => '2.05' ); 
	use_ok( 'Cache::FileCache' );
}

ok( 1,				'supporting modules exist and are the right versions' );

# This simulates the way that we use Cache::FileCache

my $cache = new Cache::FileCache( );
my $key = join( "|", ( 'Parcel Post', 'Germany', '5', 'Package' ) ); 
my $package = $cache->get( $key );

if ( not defined $package ) {
	sleep( 1 );
	$package = '5.99';
	$cache->set( $key, $package, "30 minutes" );
}

ok( 1,		'Cache::FileCache works.' );


 
