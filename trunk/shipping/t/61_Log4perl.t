#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Carp;

BEGIN { 
    use_ok( 'Business::Shipping' );
    use_ok( 'Log::Log4perl' );
}

SKIP: {
    skip( 'Verbose Tests are disabled by default' ) 
        unless ( $ENV{ VERBOSE_TESTS } );

    use Log::Log4perl qw( :easy );
    
    Log::Log4perl->easy_init($INFO);
    
    drink();
    drink("Soda");
                        
    sub drink
    {
        my ( $what ) = @_;
        
        my $logger = get_logger();
        
        if ( defined $what ) 
            { $logger->info( 'Drinking ', $what  ); }
        else
            { $logger->error( 'No drink defined' ); }
    }
}

1;
