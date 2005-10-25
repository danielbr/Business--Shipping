# Business::Shipping - Rates and tracking for UPS and USPS
#
# $Id$
#
# Copyright (c) 2003-2005 Daniel Browning <db@kavod.com>. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See doc/License for more info.

package Business::Shipping;

=head1 NAME

Business::Shipping - Rates and tracking for UPS and USPS

=head1 VERSION

Version 2.02

=cut

$VERSION = '2.02';

=head1 SYNOPSIS

=head2 Rate request example

 use Business::Shipping;
 
 my $rate_request = Business::Shipping->rate_request(
     shipper   => 'UPS_Offline',
     service   => 'Ground Residential',
     from_zip  => '98683',
     to_zip    => '98270',
     weight    =>  5.00,
 );    
 
 $rate_request->execute() or die $rate_request->user_error();
 
 print $rate_request->rate();

=head1 FEATURES

Business::Shipping currently supports three shippers:

=head2 UPS_Offline: United Parcel Service

=over 4

=item * Shipment rate estimation using offline tables.  New tables are released whenever UPS updates them, and
a script is available for automatically updating the fuel surcharge every month.

=back

=head2 UPS_Online: United Parcel Service using UPS OnLine Tools (disabled)

=over 4

=item * Disabled as of version 1.90, see doc/UPS_Online_disabled.txt.

=item * Shipment rate estimation

=item * Shipment tracking.

=item * Rate Shopping.

Gets rates for all the services in one request:

 my $rr_shop = Business::Shipping->rate_request( 
     service      => 'shop',    
     shipper      => 'UPS_Online',
     from_zip     => '98682',
     to_zip       => '98270',
     weight       => 5.00,
     user_id      => '',
     password     => '',
     access_key   => '',
 );
 
 $rr_shop->execute() or die $rr_shop->user_error();
 
 foreach my $shipper ( @$results ) {
     print "Shipper: $shipper->{name}\n\n";
     foreach my $rate ( @{ $shipper->{ rates } } ) {
         print "  Service:  $rate->{name}\n";
         print "  Charges:  $rate->{charges_formatted}\n";
         print "  Delivery: $rate->{deliv_date_formatted}\n" 
             if $rate->{ deliv_date_formatted };
         print "\n";
     }
 }

=item * C.O.D. (Cash On Delivery)

Add these options to your rate request for C.O.D.:

cod: enable C.O.D.

cod_funds_code:  The code that indicates the type of funds that will be used for the COD payment.  
Required if CODCode is 1, 2, or 3.  Valid Values: 0 = All Funds Allowed.  8 = cashier's check or 
money order, no cash allowed.

cod_value: The COD value for the package.  Required if COD option is present.  Valid values: 0.01 - 50000.00

cod_code: The code associated with the type of COD.  Values: 1 = Regular COD, 2 = Express COD, 3 = Tagless COD
 
For example:

	cod            => 1,
	cod_value      => 400.00,
	cod_funds_code => 0,

=back

=head2 USPS_Online: United States Postal Service

=over 4

=item * Shipment rate estimation using USPS Online WebTools.

=item * Shipment tracking

=back

=head1 INSTALLATION

 perl -MCPAN -e 'install Bundle::Business::Shipping'

See doc/INSTALL.

=head1 REQUIRED MODULES

The following modules are required for offline UPS rate estimation.  See doc/INSTALL.

 Business::Shipping::DataFiles (any)
 Class::MethodMaker::Engine (any)
 Config::IniFiles (any)
 Log::Log4perl (any)

=head1 OPTIONAL MODULES

The following modules are used by online rate estimation and tracking.  See doc/INSTALL.

 Cache::FileCache (any)
 Clone (any)
 Crypt::SSLeay (any)
 LWP::UserAgent (any)
 XML::DOM (any)
 XML::Simple (2.05)
 
=head1 GETTING STARTED

Be careful to read, understand, and comply with the terms of use for the 
provider that you will use.

=head2 UPS_Offline: For United Parcel Service (UPS) offline rate requests

No signup required.  C<Business::Shipping::DataFiles> has all of rate tables, 
which are usually updated only once per year.

We recommend that you run the following script to update your fuel surcharge
every first monday of the month.

 bin/Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

=head2 UPS_Online: For United Parcel Service (UPS) Online XML: Free signup

=over 4

=item * Read the legal terms and conditions: 
L<http://www.ups.com/content/us/en/resources/service/terms/index.html>

=item * L<https://www.ups.com/servlet/registration>

=item * After receiving a User Id and Password from UPS, login, then select
        "Get Access Key", then "Get XML Access Key".

=item * Read more about UPS Online Tools at L<http://www.ec.ups.com>

=back

=head2 USPS_Online: For United States Postal Service (USPS): Free signup

=over 4

=item * L<http://www.uspswebtools.com/registration/>

=item * (More info at L<http://www.uspswebtools.com>)

=item * The online signup will result in a testing-only account (only a small
        sample of queries will work).  

=item * To activate the "production" use of your USPS account, you must follow 
        the USPS documentation.  As of Sept 16 2004, that means contacting the 
        USPS Internet Customer Care Center by e-mail 
        (C<icustomercare@usps.com>) or phone: 1-800-344-7779.

=back

=head1 ERROR/DEBUG HANDLING

Log4perl is used for logging error, debug, etc. messages.  For simple manipulation of the current log level, 
use the Business::Shipping->log_level( $log_level ) class method (below).  For more advanced logging/debugging
options, see config/log4perl.conf.

=head1 Preloading Modules

To preload all modules, call Business::Shipping with this syntax:

 use Business::Shipping { preload => 'All' };

To preload the modules for just one shipper:

 use Business::Shipping { preload => 'USPS_Online' };
 
Without preloading, some modules will be loaded at runtime.  Normally, runtime
loading is the best mode of operation.  However, there are some circumstances 
when preloading is advantagous.  For example:

=over 4

=item * For mod_perl, to load the modules only once at startup instead of at 
 startup and then additional modules later on.  (Thanks to Chris Ochs 
 <chris@paymentonline.com> for contributing to this information).

=item * For compatibilty with some security modules (e.g. Safe).

=item * To move the delay that would normally occur with the first request into 
 startup time.  That way, it takes longer to start up, but the first user
 will not experience any delay.

=back

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use Business::Shipping::Logging;
use Business::Shipping::Util 'unique';
#use Business::Shipping::ClassAttribs;
use Class::MethodMaker 2.0
    [ 
      new    => [ qw/ -hash new /                                     ],
      scalar => [ 'tx_type', 'shipper', '_user_error_msg'             ],
    ];

$Business::Shipping::RuntimeLoad = 1;

# test numbers:
# UPS  test tracking number: 1ZA723W80340522160
# USPS test tracking number: EJ958083578US


sub import 
{
    my ( $class_name, $record ) = @_;
    
    return unless defined $record and ref( $record ) eq 'HASH';
    
    while ( my ( $key, $val ) = each %$record ) {
        if ( lc $key eq 'preload' ) {
            
            # Required modules lists
            # ======================
            # Each of these modules does a compile-time require of all 
            # the modules that it needs.  If, in the future, any of these
            # modules switch to a run-time require, then update this list with
            # the modules that may be run-time required.
            
            my $module_list = {
                'USPS_Online' => [
                    'Business::Shipping::USPS_Online::Tracking',
                ],
                'UPS_Online' => [
                    'Business::Shipping::UPS_Online::Tracking',
                ],
                'UPS_Offline' => [
                ],
            };
                    
            my @to_load;
                
            if ( lc $val eq 'all' ) {
                for ( keys %$module_list ) {
                    my $aryref = $module_list->{ $_ };
                    push @to_load, @$aryref;
                }
            }
            else {
                while ( my ( $shipper, $mod_list ) = each %$module_list ) {
                    if ( lc $val eq lc $shipper ) {
                        push @to_load, ( 
                            @$mod_list, 
                            'Business::Shipping::' . $shipper . '::RateRequest',
                        );
                    }
                }
            }
            
            if ( @to_load ) 
                { $Business::Shipping::RuntimeLoad = 0 };
            
            foreach my $module ( Business::Shipping::Util::unique( @to_load ) ) {
                eval "use $module;";
                die $@ if $@;
            }
        }
    }
}

=head2 $obj->init()

Generic attribute setter.

=cut

sub init
{
    my ( $self, %args ) = @_;
    
    foreach my $arg ( keys %args ) {
        if ( $self->can( $arg ) ) {
            $self->$arg( $args{ $arg } );
        }
    }
    
    return;
}

=head2 $obj->user_error()

Log and store errors that should be visibile to the user.

=cut

sub user_error
{
    my ( $self, $msg ) = @_;
    
    if ( defined $msg ) {
        $self->_user_error_msg( $msg );
        
        # Make it look like I'm calling error() from the caller, instead of this
        # function.

        my ( $package, $filename, $line, $sub ) = caller( 1 );
        error( 
            { 
                caller_package  => '',
                caller_filename => $filename,
                caller_line     => $line,
                caller_sub      => $sub,
                caller_depth_modifier => 1,
            }, 
            $msg
        );
    }
    
    return $self->_user_error_msg;
}

=head2 $obj->validate()

Confirms that the object is valid.  Checks that required attributes are set.

=cut

sub validate
{
    trace '()';
    my ( $self ) = shift;
    
    my @required = $self->get_grouped_attrs( 'Required' );
    my @optional = $self->get_grouped_attrs( 'Optional' );
    
    debug(  "required = " . join (', ', @required ) ); 
    debug3( "optional = " . join (', ', @optional ) );    
    
    my @missing;
    foreach my $required_field ( @required ) {
        if ( ! $self->$required_field() ) {
            push @missing, $required_field;
        }
    }
    
    if ( @missing ) {
        $self->user_error( "Missing required argument(s): " . join ", ", @missing );
        $self->invalid( 1 );
        return 0;
    }
    else {
        return 1;
    }
}

=head2 $self->get_grouped_attrs( $attribute_name )

=cut

sub get_grouped_attrs
{
    my ( $self, $attr_name ) = @_;
    
    # attr_name = Attribute Name.
    
    my @results = $self->$attr_name();
    
    #print "get_grouped_attrs( $attr_name ): " . join( ', ', @results ) . "\n";
    
    return @results;
}

=head2 $obj->rate_request()

This method is used to request shipping rate information from online providers
or offline tables.  A hash is accepted as input.  The acceptable values are 
determined by the shipper class, but the following are common to all:

=over 4

=item * shipper

The name of the shipper to use. Must correspond to a module by the name of:
C<Business::Shipping::SHIPPER>.  For example, C<UPS_Online>.

=item * service

A valid service name for the provider. See the corresponding module 
documentation for a list of services compatible with the shipper.

=item * from_zip

The origin zipcode.

=item * from_state

The origin state in two-letter code format or full-name format.  Required for UPS_Offline.

=item * to_zip

The destination zipcode.

=item * to_country

The destination country.  Required for international shipments only.

=item * weight

Weight of the shipment, in pounds, as a decimal number.

=back 

There are some additional common values:

=over 4

=item * user_id

A user_id, if required by the provider. USPS_Online and UPS_Online require
this, while UPS_Offline does not.

=item * password

A password,  if required by the provider. USPS_Online and UPS_Online require
this, while UPS_Offline does not.

=back

=cut

sub rate_request
{
    my $class = shift;
    my ( %opt ) = @_;
    my $shipper = $opt{ shipper };
    
    Carp::croak 'shipper required' unless $opt{ shipper };

    # COMPAT: shipper compatibility
    # 1. Really old: "UPS" or "USPS" (assumes Online::)
    # 2. Semi-old:   "Online::UPS", "Offline::UPS", or "Online::USPS"
    # 3. Current:    "UPS_Online", "UPS_Offline", or "USPS_Online"
    
    my %old_to_new = (
        'Online::UPS'  => 'UPS_Online',
        'Offline::UPS' => 'UPS_Offline',
        'Online::USPS' => 'USPS_Online',
        'UPS'  => 'UPS_Online',
        'USPS' => 'USPS_Online'
    );
    
    $shipper = $old_to_new{ $shipper } if $old_to_new{ $shipper };
    
    # /COMPAT    
    
    
    my $rr = Business::Shipping->_new_subclass( $shipper . '::RateRequest' );
    logdie "New $shipper::RateRequest object was undefined." if not defined $rr;
    
    $rr->init( %opt );
   
    return $rr;
}

=head2 Business::Shipping->log_level()

Simple alternative to editing the config/log4perl.conf file.  Sets the log level
for all Business::Shipping objects.  

Takes a scalar that can be 'debug', 'info', 'warn', 'error', or 'fatal'.

=cut

*log_level = *Business::Shipping::Logging::log_level;

#=head2 Business::Shipping->_new_subclass()
#
#Private Method.
#
#Generates an object of a given subclass dynamically.  Will dynamically 'use' 
#the corresponding module, unless runtime module loading has been disabled via 
#the 'preload' option.
#
#=cut

sub _new_subclass
{
    my ( $class, $subclass, %opt ) = @_;
    
    Carp::croak( "Error before _new_subclass was called: $@" ) if $@;
    
    my $new_class = $class . '::' . $subclass;
    
    if ( $Business::Shipping::RuntimeLoad )
        { eval "use $new_class"; }
        
    Carp::croak( "Error when trying to use $new_class: \n\t$@" ) if $@;
    
    my $new_sub_object = eval "$new_class->new()";
    Carp::croak( "Failed to create new $new_class object.  Error: $@" ) if $@;
    
    return $new_sub_object;    
}

# COMPAT: event_handlers()

#=head2 $obj->event_handlers()
#
#For backwards compatibility with 1.06 and prior only.
#
#=cut

sub event_handlers
{
    my ( $self, $event_handlers_hash ) = @_;
    
    KEY: foreach my $key ( keys %$event_handlers_hash ) {
        $key = uc $key;
        foreach my $Log_Level ( @Business::Shipping::KLogging::Levels ) {
            if ( $key eq $Log_Level ) {
                # We ignore the value of the key (whether STDERR, STDOUT, etc.),
                # because it would be a lot of work to set it up correctly, and 
                # if a user is going to use the debug system, they would probably
                # be willing to upgrade to the most recent version.
                
                # The levels are in order from least to greatest, so as soon as 
                # we get a match, we need to stop, because the lowest level (DEBUG)
                # will automatically include all of the greater levels.
                
                Business::Shipping->log_level( $Log_Level );
                last KEY;
            }
        }
    }
    
    return;
}

sub Optional { return qw/ tx_type /; }
sub Required { return (); }
sub Unique   { return (); }

1;

__END__

=head1 SEE ALSO

Important modules that are related to Business::Shipping:

=over 4

=item * Business::Shipping::DataFiles - Required for offline cost estimation

=item * Business::Shipping::DataTools - Tools that generate DataFiles 
        (optional)

=back

Other Perl modules that are simliar to Business::Shipping:

=over 4

=item * Business::Shipping::UPS_XML - Online cost estimation module that has 
very few prerequisites.  Supports shipments that originate in USA and Canada.

=item * Business::UPS - Online cost estimation module that uses the UPS web form
instead of the UPS Online Tools.  For shipments that originate in the USA only.

=item * http://www.halofree.com/lib/public/code/Ship/UPS.pm

=item * http://www.halofree.com/lib/public/code/Ship/USPS.pm

=back
 
=head1 Use of this software

It is appreciated when users mention their use of Business::Shipping to the 
author and/or on their website or in their application.

=over 4

=item * Interchange e-commerce system ( L<http://www.icdevgroup.org> ).  See 
    C<UserTag/business-shipping.tag>.

=item * Many E-Commerce websites, such as Phatmotorsports.com.

=item * PaymentOnline.com software.

=item * The "Shopping Cart" Wobject for the WebGUI project, by Andy Grundman 
    L<http://www.plainblack.com/shopping_cart_wobject>

=item * Mentioned in YAPC 2004 Presentation: "Writing web applications with perl ..."

=back

=head1 WEBSITE

L<http://www.kavod.com/Business-Shipping/>

CPAN web site: L<http://search.cpan.org/~dbrowning/Business-Shipping/>

Backpan (old releases): L<http://backpan.cpan.org/authors/id/D/DB/DBROWNING/>

=head1 SUPPORT

This module is supported by the author.  Please report any bugs or feature 
requests to C<bug-business-shipping@rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org>.  The author will be notified, and then you'll 
automatically be notified of progress on your bug as the author makes changes.

=head1 KNOWN BUGS

See the C<doc/Todo> file for a comprehensive list of known bugs.

=head1 CREDITS

Many people have contributed to this module, please see the C<doc/Credits> file. 

=head1 AUTHOR

Daniel Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2005 Daniel Browning E<lt>F<db@kavod.com>E<gt>. All rights 
reserved.  This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See C<doc/License> for more info.

=cut
