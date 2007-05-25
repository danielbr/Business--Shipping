#!/usr/local/perl/bin/perl

=head1 NAME

Simulator for Business::Shipping Interchange UserTag  

=head1 VERSION

This is simulator version 221, which is based on usertag version 1.13.

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
use Test::More;

plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'USPS_Online' );
plan skip_all => '' unless Business::Shipping::Config::calc_req_mod( 'UPS_Offline' );
plan skip_all => 'No credentials' 
    unless $ENV{ UPS_USER_ID } and $ENV{ UPS_PASSWORD } and $ENV{ UPS_ACCESS_KEY };
plan 'no_plan';


# Setup Interchange Environment Simulation
use Data::Dumper;
our $Values = {};
our $Variable = {};
$Variable->{ BSHIPPING_MAX_WEIGHT } = 75;

package Nothing;
sub Nothing::data { return ''; };
our $Tag = bless( {}, "Nothing" ); # TODO: add the 'data' routine that will return a sample value.
package main;



sub Log { print $_[ 0 ] . "\n" };
sub uneval { return Dumper( @_ ); };



###############################################################################
##  Begin contents of business-shipping.tag 
###############################################################################

use Business::Shipping 2.03;

sub tag_business_shipping {
    my ( $shipper, $opt ) = @_;
    
    my $debug = delete $opt->{ debug } || $Variable->{ BSHIPPING_DEBUG } || 0;
    
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

    my $to_country_default = $Values->{ $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country' };
    
    # STDOUT goes to the IC debug files (usually '/tmp/debug')
    # STDERR goes to the global error log (usually 'interchange/error.log').
    #
    # Defaults: Cache enabled.  Log errors only.
    
    my $defaults = {
        'All' => {
            'to_country'        => $Values->{ 
                $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country' 
            },
            'to_zip'            => $Values->{ $Variable->{ BSHIPPING_TO_ZIP_FIELD } || 'zip' },
            'to_city'           => $Values->{ $Variable->{ BSHIPPING_TO_CITY_FIELD } || 'city' },
            'from_country'      => $Variable->{ BSHIPPING_FROM_COUNTRY },
            'from_zip'          => $Variable->{ BSHIPPING_FROM_ZIP },
            'cache'             => ( defined $opt{ cache } ? $opt{ cache } : 1 ), # Allow 0
        },
        'USPS_Online' => {
            'user_id'           => $Variable->{ "USPS_USER_ID" },
            'password'          => $Variable->{ "USPS_PASSWORD" },
            'to_country' => $Tag->data( 
                'country', 
                'name', 
                $Variable->{ BSHIPPING_TO_COUNTRY_FIELD } || 'country'
            ),
        },
        'UPS_Online' => {
            'access_key'        => $Variable->{ UPS_ACCESS_KEY },
            'user_id'           => $Variable->{ UPS_USER_ID },
            'password'          => $Variable->{ UPS_PASSWORD },
        },
        'UPS_Offline' => { 
            'from_state'        => $Variable->{ BSHIPPING_FROM_STATE },
            'cache'             => 0,
        },
    };
    
    if ( my $tier = $Variable->{ UPS_TIER } ) {
        if ( $tier >= 1 and $tier <= 7 ) {
            $defaults->{UPS_Offline}{tier} = $tier;
        }
    }
    
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
    
    # Short-circuit for the common case.
    return unless $opt{ to_zip } or $opt{ to_country }; 
    
    my $rate_request;
    eval { $rate_request = Business::Shipping->rate_request( 'shipper' => $shipper ); };
    if ( ! defined $rate_request or $@ ) {
        Log( "[business-shipping] Error during Business::Shipping->rate_request(): $@ " );
        return;
    }
    
    ::logDebug( "Initializing rate_request object with: " . Vend::Util::uneval_it( \%opt ) ) if $debug;
    
    eval { $rate_request->init( %opt ); };
    if ( $@ ) {
        Log( "[business-shipping] Error during rate_request->init(): $@ " );
        return;
    }
    
    # Setting maximum weight per package.
    
    $rate_request->shipment->max_weight( $Variable->{ BSHIPPING_MAX_WEIGHT } ) 
        if $Variable->{ BSHIPPING_MAX_WEIGHT }; 
    
    ::logDebug( "calling \$rate_request->go()" ) if $debug;

    my $success;
    my $submit_results;

    eval { $submit_results = $rate_request->go( %opt ); };
    if ( not $submit_results or $@ ) { 
        
        if ( 
             ( not $rate_request->invalid ) 
             or
             ( $rate_request->invalid and $Variable->{ BSHIPPING_LOG_INVALID_REQUESTS } )
           )
        {
            Log( "[business-shipping] Error: " . ( $rate_request->user_error() || 'no user_error returned, perl error: ' . $@ ) );
        }
        
        # Prevent 500 error on some systems?
        $@ = '';
        
        return;
    }
        
    my $charges;
    
    # get_charges() should be implemented for all shippers in the future.
    # For now, we just fall back on total_charges()

    $charges ||= $rate_request->total_charges();

    # This is a debugging / support tool.  It uses these variables: 
    #   BSHIPPING_GEN_INCIDENTS
    #   SYSTEMS_SUPPORT_EMAIL
    
    my $report_incident;
    if ( 
            ( ! $charges or $charges !~ /\d+/ )
        and
            $Variable->{ 'BSHIPPING_GEN_INCIDENTS' }
       ) 
    {
        # Don't report invalid rate requests:No zip code, GNDRES to Canada, etc.
       
        if ( $rate_request->invalid ) 
            { $report_incident = 0; }
        else 
            { $report_incident = 1; }
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
        
    }
    ::logDebug( "[business-shipping] returning " . ( $charges || 'undef' ) ) if $debug;
    
    return $charges;
}


###############################################################################
##  End contents of business-shipping.tag
##   - be sure to exclude the final line: \&business_shipping_tag;
###############################################################################

sub business_shipping_sim { return tag_business_shipping( @_ ); }

#Business::Shipping->log_level( 'debug' );

my $charges;
my $opt;

$opt = {
    'user_id'    => $ENV{ USPS_USER_ID },
    'password' => $ENV{ USPS_PASSWORD },
    'reparse' => "1",
    'service' => "Priority",
    'mode' => "USPS",
    'weight'    => 10,
    'from_zip'    => '20770',
    'to_zip'    => '20852',
    #cache => 1,
};

$charges = business_shipping_sim( 'Online::USPS', $opt );
ok( $charges, "USPS_Online OK: $charges" );

$charges = business_shipping_sim( 'USPS', $opt );
ok( $charges, "USPS again OK: $charges" );

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
    #cache => 0,
};

$charges = business_shipping_sim( 'UPS_Offline', $opt );
ok( $charges, "UPS_Offline: $charges" );

$charges = business_shipping_sim( 'UPS', $opt );
ok( $charges, "UPS OK: " . ( $charges || 'charges not found' ) );

$opt->{ weight } = 175;
$charges = business_shipping_sim( 'UPS_Offline', $opt );
ok( $charges, "UPS_Offline: $charges" );
