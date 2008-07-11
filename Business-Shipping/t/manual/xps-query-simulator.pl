#!/usr/bin/perl

use strict;
use warnings;

use Business::Shipping;

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
    $opt{ 'cache_enabled' } = 1 unless defined( $opt{ 'cache_enabled' } );
    
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
    my $shipment = Business::Shipping->new( 'shipper' => $mode );
    #my $shipment = eval "Business::Shipping::${mode}->new()";
    #my $shipment;
    #if ( $mode eq 'UPS' ) {
    #    #$shipment = Business::Shipping::UPS->new();
    #}
    #elsif ( $mode eq 'USPS' ) {
    #    $shipment = Business::Shipping::USPS->new();
    #}
    
    if ( ! defined $shipment ) {
        Log( "[xps-query] failure when calling Business::Shipping->new(): $@ " ) if $@;
        return undef;
    }
    
    #::logDebug( "calling Business::Shipping::${mode}->submit( " . uneval( \%opt ) . " )" );
    
    $shipment->set( %opt );
    
    my $tries = 0;
    my $success;
    for ( my $tries = 1; $tries <= $try_limit; $tries++ ) {
        if ( $shipment->submit() ) {
            # Success, no more retries
            $success = 1;
            last;
        }
        else {
            Log( "Try $tries: " . $shipment->user_error() );
            
            for (    
                    'HTTP Error. Status line: 500 read timeout',
                    'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
                    'HTTP Error. Status line: 500 Connect failed:',
                    'HTTP Error. Status line: 500 Can\'t connect to production.shippingapis.com:80',
                ) {
                
                if ( $shipment->user_error() =~ /$_/ ) {
                    Log( 'Error was on USPS server, trying again...' );
                }
            }
        }
    }
    return undef unless $success;
    
    my $charges = $shipment->get_charges( $opt{ 'service' } );
    
    # get_charges() *should* be implemented for all use cases, in the future.
    # For now, we just fall back on total_charges()
    $charges ||= $shipment->total_charges();
    
    if ( ! $charges ) {
        my $variables = uneval( \%opt ); 
        my $error = $shipment->user_error();
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
    
    $shipment = ();
    
    #::logDebug( "[xps-query] returning" . uneval( $charges ) );
    
    return $charges;
}

my $charges;
my $opt;



print "testing USPS...\n";
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
$charges = xps_query( 'USPS', $opt );
print $charges if $charges;
print "\n\n";


print "testing USPS again...\n";
$charges = xps_query( 'USPS', $opt );
print $charges if $charges;
print "\n\n";


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
