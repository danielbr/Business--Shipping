#!/usr/bin/perl

=head1 NAME

Simulator for Business::Shipping Interchange UserTag  

=head1 VERSION

This is simulator version ___, which is based on usertag version 1.13.

=head1 DESCRIPTION

Tests the module within a certain context: an Interchange UserTag (see 
C<UserTag/business-shipping.tag>).

This is a copy/paste of the usertag, with several changes:

=over4

=item * Interchange Variables and Values simulation

=item * Interchange "$Tag->___()" simulation

=item * Simulation of other Interchange facilities.

=back

Eventually, it should run a gamut of tests, for all modules, etc.

=cut

$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 

use strict;
use warnings;
use Business::Shipping;
use Test::More 'no_plan';

# Setup Interchange Environment Simulation
use Data::Dumper;
our $Values = {};
our $Variable = {};
our $Tag = {};
sub Log { print @_ };
sub uneval { return Dumper( @_ ); };

sub xps_query {
     my ( $mode, $opt ) = @_;
    
    #::logDebug( "[xps-query " . uneval( $opt ) );
     
    unless ( $mode and $opt->{weight} and $opt->{ 'service' }) {
        Log ( "mode, weight, and service required" );
        return ( undef );
    }
    
    # We pass the options mostly unmodifed to the underlying library, so here we
    # take out anything that might confuse it.
    delete $opt->{ 'reparse' };
    delete $opt->{ 'mode' };
    delete $opt->{ 'hide' };
    
    my $try_limit = delete $opt->{ 'try_limit' };
    $try_limit ||= 2;
    
    # Business::Shipping takes a hash anyway, we might as well deref it now.
    my %opt = %$opt;

    my $to_country_default = $Values->{ $Variable->{ XPS_TO_COUNTRY_FIELD } || 'country' };
    if ( $to_country_default ) {
        if ( $mode eq 'USPS' ) {
            $to_country_default = $Tag->data( 'country', 'name', $to_country_default );
        }
        elsif ( $mode eq 'UPS' ) {
            # Leave the country as a code
        }
    }

    my %defaults = (
        
        # For interchange, STDOUT will cause it to go to the IC debug.
        'event_handlers'    => ({ 
            #'debug' => undef, 
            'debug' => 'STDOUT',
            
            #'error' => 'STDERR', 
            'error' => 'STDOUT',
            
            #'trace' => undef,         
            'trace' => 'STDOUT', 
        }),
        #'tx_type'            => 'rate',
        
        'user_id'            => $Variable->{ "${mode}_USER_ID" },
        'password'            => $Variable->{ "${mode}_PASSWORD" },
        'to_country'        => $to_country_default,
        'to_zip'            => $Values->{ $Variable->{ XPS_TO_ZIP_FIELD } || 'zip' },
        'from_country'        => $Variable->{ XPS_FROM_COUNTRY },
        'from_zip'            => $Variable->{ XPS_FROM_ZIP },
    );
    
    # I'm not sure if the cache feature is safe enough to enable yet, but...
    #$opt{ 'cache_enabled' } = 1 unless defined( $opt{ 'cache_enabled' } );
    
    # USPS extras.
    
    if ( $mode eq 'USPS' ) {
        if ( $opt{ 'weight' } < 1.0 ) {
            $opt{ 'weight' } = 1;
        }
    }
    
    # UPS extras.
    $defaults{ 'access_key' } = $Variable->{ "${mode}_ACCESS_KEY" } if ( $Variable->{ "${mode}_ACCESS_KEY" } );
    
    for ( %defaults ) {
        if ( $_ ) {
            $opt{ $_ } ||= $defaults{ $_ } if defined $defaults{ $_ };
        }
    }
    
    print "getting a new object with mode $mode\n";
    my $rate_request = Business::Shipping->rate_request( 'shipper' => $mode );
    
    
    #print Dumper( $rate_request );
    $rate_request->init( %opt );
    $rate_request->submit() or die $rate_request->error();
        
    #my $rate_request = eval "Business::Shipping::${mode}->new()";
    #my $rate_request;
    #if ( $mode eq 'UPS' ) {
    #    #$rate_request = Business::Shipping::UPS->new();
    #}
    #elsif ( $mode eq 'USPS' ) {
    #    $rate_request = Business::Shipping::USPS->new();
    #}
    
    #if ( ! defined $rate_request ) {
    #    Log( "[xps-query] failure when calling Business::Shipping->new(): $@ " ) if $@;
    #    return undef;
    #}
    
    #::logDebug( "calling Business::Shipping::${mode}->submit( " . uneval( \%opt ) . " )" );
    
    
    
#    my $tries = 0;
#    my $success;
#    for ( my $tries = 1; $tries <= $try_limit; $tries++ ) {
#        if ( $rate_request->submit() ) {
#             Success, no more retries
#            $success = 1;
#            last;
#        }
#        else {
#            Log( "Try $tries: " . $rate_request->error() );
#            
#            for (    
#                    'HTTP Error. Status line: 500 read timeout',
#                    'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
#                    'HTTP Error. Status line: 500 Connect failed:',
#                    'HTTP Error. Status line: 500 Can\'t connect to production.shippingapis.com:80',
#                ) {
#                
#                if ( $rate_request->error() =~ /$_/ ) {
#                    Log( 'Error was on USPS server, trying again...' );
#                }
#            }
#        }
#    }
    #return undef unless $success;
    
    my $charges;
    #$charges = $rate_request->get_charges( $opt{ 'service' } );
    
    # get_charges() *should* be implemented for all use cases, in the future.
    # For now, we just fall back on total_charges()
    $charges ||= $rate_request->total_charges();
    
    if ( ! $charges ) {
        my $variables = uneval( \%opt ); 
        my $error = $rate_request->error();
        my $message = "[xps-query]: $mode error: $error.\nOptions were: $variables";
        Log $message;
        
        # This is a debugging / support tool.  Set the XPS_GEN_INCIDENTS and
        # SYSTEMS_SUPPORT_EMAIL variables to enable.
        if ( $Variable->{ 'XPS_GEN_INCIDENTS' } ) {
            
            # Not everyone has [incident], avoid errors.
            eval {
                $Tag->incident($message);
            };
            
            # Catch exception, but do nothing.
            my $eval_error = $@;
        }
    }
    
    $rate_request = ();
    
    #::logDebug( "[xps-query] returning" . uneval( $charges ) );
    
    return $charges;
}

my $charges;
my $opt;

sub skip_usps
{
    skip( 'Online::USPS: Username and password required for this test.', 1 ) 
        unless ( $ENV{ USPS_USER_ID } and $ENV{ USPS_PASSWORD } );
}

sub skip_ups
{
    skip( 'Online::UPS: Username, password, and UPS access key required for this test.', 1 ) 
        unless ( $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY } );
}

SKIP: { skip_usps();
    print "testing Online::USPS...\n";
    $opt = {
        'user_id'    => $ENV{ USPS_USER_ID },
        'password' => $ENV{ USPS_PASSWORD },
        'reparse' => "1",
        'service' => "Priority",
        'mode' => "USPS",
        'weight'    => 10,
        'from_zip'    => '20770',
        'to_zip'    => '20852',
    };
    $charges = xps_query( 'Online::USPS', $opt );
    print $charges if $charges;
    print "\n\n";
}

SKIP: { skip_usps();
    print "testing USPS again...\n";
    $charges = xps_query( 'USPS', $opt );
    print $charges if $charges;
    print "\n\n";
}

SKIP: { skip_ups();
    print "testing UPS...\n";
    $opt = {
        'reparse' => "1",
        'service' => "GNDRES",
        'mode' => "UPS",
        'weight' => "2.5",
        'to_zip'    => '98607',
        'from_zip'    => '98682',
        'access_key' => $ENV{ UPS_ACCESS_KEY },
        'user_id' => $ENV{ UPS_USER_ID },
        'password' => $ENV{ UPS_PASSWORD },
    };
    
    $charges = xps_query( 'UPS', $opt );
    print $charges if $charges;
    print "\n\n";

}

ok( 1, 'reached end of the test simulator' );
