# Business::Shipping - Cost estimation and tracking for UPS and USPS
#
# $Id$
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

package Business::Shipping;

=head1 NAME

Business::Shipping - Cost estimation and tracking for UPS and USPS

=head1 SYNOPSIS

=head2 Rate request example

    use Business::Shipping;
    
    my $rate_request = Business::Shipping->rate_request(
        shipper   => 'Offline::UPS',
        service   => 'GNDRES',
        from_zip  => '98682',
        to_zip    => '98270',
        weight    =>  5.00,
    );    
    
    $rate_request->submit() or logdie $rate_request->user_error();
    
    print $rate_request->total_charges();

=head2 Shipping tasks implemented at this time

=over

=item * UPS shipment cost calculation using UPS Online WebTools.

=item * UPS shipment cost calculation using offline tables.

=item * USPS shipment cost calculation using USPS Online WebTools.

=item * UPS shipment tracking.

=item * USPS shipment tracking.

=back

=head2 Shipping tasks planned for future addition

=over

=item * USPS zip code lookup

=item * USPS address verification

=item * USPS shipment cost estimation via offline tables 

=item * FedEX shipment cost estimation

=back 

=head1 REQUIRED MODULES

 Bundle::DBD::CSV (any)
 Cache::FileCache (any)
 Class::MethodMaker::Engine (any)
 Clone (any)
 Config::IniFiles (any)
 Crypt::SSLeay (any)
 Getopt::Mixed (any)
 Log::Log4perl (any)
 LWP::UserAgent (any)
 Math::BaseCnv (any)
 Scalar::Util (1.10)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 INSTALLATION

C<perl -MCPAN -e 'install Bundle::Business::Shipping'>

See the INSTALL file for more information.
 
=head1 ERROR/DEBUG HANDLING

Log4perl is used for logging error, debug, etc. messages.  See 
config/log4perl.conf.  For simple manipulation of the current log level, use
the Business::Shipping->log_level( $log_level ) class method (below).
 
=head1 METHODS

=cut

$VERSION = '1.52';

use strict;
use warnings;
use Carp;
use Business::Shipping::Logging;
use Business::Shipping::ClassAttribs;
use Scalar::Util 'blessed';
use Class::MethodMaker 2.0
    [ 
      new    => [ qw/ -hash new /                                     ],
      scalar => [ 'tx_type', 'shipper', '_user_error_msg'             ],
      scalar => [ { -static => 1, -default => 'tx_type' }, 'Optional' ],
    ];

=head2 $self->init( %args )

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

=head2 $self->user_error( "Error message" )

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

=head2 $self->validate()

Confirms that the object is valid.  Checks that required attributes are set.

=cut

sub validate
{
    trace '()';
    my ( $self ) = shift;
    
    my @required = $self->get_grouped_attrs( 'Required' );
    my @optional = $self->get_grouped_attrs( 'Optional' );
    
    debug( "required = " . join (', ', @required ) ); 
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

=head2 rate_request()

This method is used to request shipping rate information from online providers
or offline tables.  A hash is accepted as input with the following key values:

=over 4

=item * shipper

The name of the shipper to use. Must correspond to a module by the name of:
C<Business::Shipping::SHIPPER>.  For example, C<UPS_Online>.

=item * user_id

A user_id, if required by the provider. Online::USPS and Online::UPS require
this, while Offline::UPS does not.

=item * password

A password,  if required by the provider. Online::USPS and Online::UPS require
this, while Offline::UPS does not.

=item * service

A valid service name for the provider. See the corresponding module 
documentation for a list of services compatible with the shipper.

=item * from_zip

The origin zipcode.

=item * from_state

The origin state in two-letter code format or full-name format.  Required for Offline::UPS.

=item * to_zip

The destination zipcode.

=item * to_country

The destination country.  Required for international shipments only.

=item * weight

Weight of the shipment, in pounds, as a decimal number.

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
    # 3. New:        "UPS_Online", "UPS_Offline", or "USPS_Online"
    
    my %old_to_new = (
        'Online::UPS'  => 'UPS_Online',
        'Offline::UPS' => 'UPS_Offline',
        'Online::USPS' => 'USPS_Online',
        'UPS'  => 'UPS_Online',
        'USPS' => 'USPS_Online'
    );
    
    while ( my ( $old, $new ) = each %old_to_new ) {
        if ( $shipper eq $old ) {
            $shipper = $new;
        }
    }
        
    my $rr = Business::Shipping->new_subclass( $shipper . '::RateRequest' );
    logdie "New $shipper::RateRequest object was undefined." if not defined $rr;
    
    $rr->init( %opt );
   
    return $rr;
}

=head2 Business::Shipping->new_subclass( "Subclass::Name", %opt )

Generates a subclass, such as a Shipment object.

=cut

sub new_subclass
{
    my ( $class, $subclass, %opt ) = @_;
    
    Carp::croak( "Error before new_subclass was called: $@" ) if $@;
    
    my $new_class = $class . '::' . $subclass;
    eval "use $new_class";
    Carp::croak( "Error when trying to use $new_class: \n\t$@" ) if $@;
    
    my $new_sub_object = eval "$new_class->new()";
    Carp::croak( "Failed to create new $new_class object.  Error: $@" ) if $@;
    
    return $new_sub_object;    
}

=head2 Business::Shipping->log_level( $log_level )

Sets the log level for all Business::Shipping objects.

$log_level can be 'debug', 'info', 'warn', 'error', or 'fatal'.

=cut

*log_level = *Business::Shipping::Logging::log_level;

# COMPAT: event_handlers() is for backwards compatibility only.
sub event_handlers
{
    my ( $self, $event_handlers_hash ) = @_;
    
    use Data::Dumper;
    print "called with event_handlers_hash = " . Dumper( $event_handlers_hash );
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


1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See LICENSE for more info.

=cut
