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

$VERSION = do { my @r=(q$Rev$=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 

use strict;
use warnings;
use Business::Shipping;
use Test::More;

plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'USPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Offline' );
plan 'no_plan';


# Setup Interchange Environment Simulation
use Data::Dumper;
our $Values = {};
our $Variable = {};
our $Tag = {};
sub Log { print @_ };
sub uneval { return Dumper( @_ ); };

sub business_shipping_sim {
    my ( $shipper, $opt ) = @_;
    
    my $debug = delete $opt->{ debug } || $Variable->{ BS_DEBUG } || 0;
    
    $shipper ||= delete $opt->{ shipper } || '';
    
    ::logDebug( "[business-shipping $shipper" . Vend::Util::uneval_it( $opt ) . " ]") if $debug;
    my $try_limit = delete $opt->{ 'try_limit' } || 2;
    
    delete $opt->{ shipper };
    
    unless ( $shipper and $opt->{weight} and $opt->{ 'service' }) {
        Log ( "mode, weight, and service required" );
        return;
    }
    
    # We pass the options mostly unmodifed to the underlying library, so here we
    # take out anything Interchange-specific that isn't necessary using a hash
    # slice.

    delete @{ $opt }{ 'reparse', 'mode', 'hide', 'shipper' };
    
    # Business::Shipping takes a hash.

    my %opt = %$opt;
    $opt = undef;

    my $to_country_default = $Values->{ $Variable->{ BS_TO_COUNTRY_FIELD } || 'country' };
    
    # STDOUT goes to the IC debug files (usually '/tmp/debug')
    # STDERR goes to the global error log (usually 'interchange/error.log').
    #
    # Defaults: Cache enabled.  Log errors only.
    
    my $defaults = {
        'All' => {
            'to_country'        => $Values->{ 
                $Variable->{ BS_TO_COUNTRY_FIELD } || 'country' 
            },
            'to_zip'            => $Values->{ $Variable->{ BS_TO_ZIP_FIELD } || 'zip' },
            'to_city'           => $Values->{ $Variable->{ BS_TO_CITY_FIELD } || 'city' },
            'from_country'      => $Variable->{ BS_FROM_COUNTRY },
            'from_zip'          => $Variable->{ BS_FROM_ZIP },
            'cache'             => ( defined $opt{ cache } ? $opt{ cache } : 1 ), # Allow 0
        },
        'USPS_Online' => {
            'user_id'           => $Variable->{ "USPS_USER_ID" },
            'password'          => $Variable->{ "USPS_PASSWORD" },
            'to_country' => $Tag->data( 
                'country', 
                'name', 
                $Variable->{ BS_TO_COUNTRY_FIELD } || 'country'
            )
        },
        'UPS_Online' => {
            'access_key'        => $Variable->{ UPS_ACCESS_KEY },
            'user_id'           => $Variable->{ UPS_USER_ID },
            'password'          => $Variable->{ UPS_PASSWORD },
        },
        'UPS_Offline' => { 
            'from_state'        => $Variable->{ BS_FROM_STATE },
            'cache'             => 0,
        },
    };
    
    # Apply all of the above defaults.  Sorting the hash keys causes 'all' to
    # be applied first, which allows each shipper to override the default.
    # For example, USPS_Online overrides the to_country method.

    foreach my $shipper_key ( sort keys %$defaults ) {
        if ( $shipper_key eq $shipper or $shipper_key eq 'All' ) {
            #::logDebug( "shipper_key $shipper_key matched shipper $shipper, or was \'all\'.  Looking into defualts..." ) if $debug;
            
            my $shipper_defaults = $defaults->{ $shipper_key };
            
            for ( keys %$shipper_defaults ) {
                #::logDebug( "shipper default: $_ => " . $shipper_defaults->{ $_ } ) if $debug;
                my $value = $shipper_defaults->{ $_ };
                $opt{ $_ } ||= $value if ( $_ and defined $value );
            }
        }
    }
    
    my $rate_request;
    eval { $rate_request = Business::Shipping->rate_request( 'shipper' => $shipper ); };
    if ( ! defined $rate_request or $@ ) {
        Log( "[business-shipping] Error: failure to get Business::Shipping object: $@ " );
        return;
    }
    
    ::logDebug( "Initializing rate_request object with: " . Vend::Util::uneval_it( \%opt ) ) if $debug;
    
    eval { $rate_request->init( %opt ); };
    if ( $@ ) {
        Log( "[business-shipping] Error: failure to initialize object with parameters: $@ " );
        return;
    }
    
    ::logDebug( "calling \$rate_request->go()" ) if $debug;

    my $success;
    my $submit_results;

    eval { $submit_results = $rate_request->go( %opt ); };
    if ( not $submit_results or $@ ) { 
        Log( "[business-shipping] Error: " . $rate_request->user_error() . "$@" );
        
        # Prevent 500 error on some systems?
        $@ = '';
        
        return;
    }
        
    my $charges;
    
    # get_charges() should be implemented for all shippers in the future.
    # For now, we just fall back on total_charges()

    $charges ||= $rate_request->total_charges();

    # This is a debugging / support tool.  It uses these variables: 
    #   BS_GEN_INCIDENTS
    #   SYSTEMS_SUPPORT_EMAIL
    
    my $report_incident;
    if ( 
            ( ! $charges or $charges !~ /\d+/ )
        and
            $Variable->{ 'BS_GEN_INCIDENTS' }
       ) 
    {
        # Don't report invalid rate requests:No zip code, GNDRES to Canada, etc.
       
        if ( $rate_request->invalid ) {
            $report_incident = 0;
        }
        else {
             $report_incident = 1;
        }
    }
    
    if ( $report_incident ) {
        my $vars_out = $rate_request->calc_debug_string;
        
        $vars_out .= "Important variables:\n";
        foreach ( 'shipper', 'service', 'to_country', 'weight', 'to_zip', 'to_city' ) {
            $vars_out .= "\t$_ => \t\'$opt{$_}\',\n";
        }
            
        $vars_out .= "\nAll variables\n";
        foreach ( sort keys %opt ) {
            $vars_out .= "\t$_ => \t\t\'$opt{$_}\',\n";
        }                
            
        $vars_out .= "\nActual values from the rate_request object\n";
        foreach ( sort keys %opt ) {
            $vars_out .= "\t$_ => \t\t\'" . $rate_request->$_() . "\',\n";
        }
        
        $vars_out .= "\nBusiness::Shipping Version:\t" . $Business::Shipping::VERSION . "\n";
        
        my $error = $rate_request->user_error();
        
        # Ignore errors if [incident] is missing or misbehaves.

        eval {
            $Tag->incident(
                {
                    subject => $shipper . ( $error ? ": $error" : '' ), 
                    content => ( $error ? "Error:\t$error\n" : '' ) . $vars_out
                }
            );
        };
        $@ = '';
    }
    ::logDebug( "[business-shipping] returning " . ( $charges || 'undef' ) ) if $debug;
    
    return $charges;
}

my $charges;
my $opt;

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
$charges = business_shipping_sim( 'Online::USPS', $opt );
print $charges if $charges;
print "\n\n";

print "testing USPS again...\n";
$charges = business_shipping_sim( 'USPS', $opt );
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

$charges = business_shipping_sim( 'UPS', $opt );
print $charges if $charges;
print "\n\n";


