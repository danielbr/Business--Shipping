# Business::Shipping - Interface for shippers (UPS, USPS)
#
# $Id: Shipping.pm,v 1.21 2004/03/31 19:11:05 danb Exp $
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#

package Business::Shipping;

=head1 NAME

Business::Shipping - Interface for shippers (UPS, USPS)

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
    
    $rate_request->submit() or die $rate_request->error();
    
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

 Archive::Zip (any)
 Bundle::DBD::CSV (any)
 Cache::FileCache (any)
 Class::MethodMaker (2.00)
 Clone (any)
 Config::IniFiles (any)
 Crypt::SSLeay (any)
 Data::Dumper (any)
 Devel::Required (0.03)
 Error (any)
 Getopt::Mixed (any)
 LWP::UserAgent (any)
 Math::BaseCnv (any)
 Scalar::Util (1.10)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 INSTALLATION

C<perl -MCPAN -e 'install Bundle::Business::Shipping'>

See the INSTALL file for more information.
 
=head1 MULTI-PACKAGE API

Please note that the Multi-package API may change in upcoming releases.

=head2 Online::UPS Example

 use Business::Shipping;
 use Business::Shipping::Shipment::UPS;
 
 my $shipment = Business::Shipping::Shipment::UPS->new();
 
 $shipment->init(
    from_zip  => '98682',
    to_zip    => '98270',
    service   => 'GNDRES',
    #
    # user_id, etc. needed here.
    #
 );

 $shipment->add_package(
    id        => '0',
    weight        => 5,
 );

 $shipment->add_package(
    id        => '1',
    weight        => 3,
 );
 
 my $rate_request = Business::Shipping::rate_request( shipper => 'Online::UPS' );
 #
 # Add the shipment to the rate request.
 #
 $rate_request->shipment( $shipment );
 $rate_request->submit() or ie $rate_request->error();

 print $rate_request->package('0')->get_charges( 'GNDRES' );
 print $rate_request->package('1')->get_charges( 'GNDRES' );
 print $rate_request->get_total_price( 'GNDRES' );

=head1 ERROR/DEBUG HANDLING

Log4perl is used for logging error, debug, etc. messages.  See 
config/log4perl.conf.
 
=head1 METHODS

=cut

$VERSION = do { my @r=(q$Revision: 1.21 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use Carp;
use Business::Shipping::Logging;
use Business::Shipping::ClassAttribs;
use Scalar::Util 'blessed';
use Class::MethodMaker 2.0
    [ 
      new    => [ qw/ -hash new  / ],
      scalar => [ 'tx_type', 'shipper', '_user_error_msg' ],
      scalar => [ { -static => 1, -default => 'tx_type' }, 'Optional' ]
    ];

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

sub user_error
{
    my ( $self, $msg ) = @_;
    
    if ( defined $msg ) {
        $self->_user_error_msg( $msg );
        error( $msg );
    }
    
    return $self->_user_error_msg;
}

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
        $self->error( "Missing required argument(s): " . join ", ", @missing );
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
C<Business::Shipping::RateRequest::SHIPPER>.  For example, C<Offline::UPS>.

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
    not $opt{ shipper } and Carp::croak( "shipper required" ) and return undef;

    #
    # Supports the specification of 'Offline::UPS' -- but if just 'UPS' is sent
    # then it assumes 'Online::UPS'.
    #
    my $full_shipper;
    if ( $opt{ shipper } =~ /::/ ) {
        $full_shipper = $opt{ shipper };
        my @shipper_components = split( '::', $opt{ shipper } );    
        $opt{ shipper } = pop @shipper_components;
    }
    else {
        $full_shipper = "Online::" . $opt{ shipper };
    }
        
    my $package;
    my $shipment;
    my $new_rate_request;
    eval { $package  = Business::Shipping->new_subclass( 'Package::'  . $opt{ 'shipper' } ); };
    die "Error when creating Package subclass: $@" if $@;
    die "package was undefined."  if not defined $package;
    eval { $shipment = Business::Shipping->new_subclass( 'Shipment::' . $opt{ 'shipper' } ); };
    die "Error when creating Shipment subclass: $@" if $@;
    die "shipment was undefined." if not defined $shipment;
    eval { $new_rate_request = Business::Shipping->new_subclass( 'RateRequest::' . $full_shipper ); };
    die "Error when creating RateRequest subclass: $@" if $@;
    die "RateRequest was undefined." if not defined $new_rate_request;
    
    $shipment->packages_push( $package );
    $new_rate_request->shipment( $shipment );
    
    # init(), in turn, automatically delegates certain options to Shipment and Package.
    #$new_rate_request->init( %opt );
    #
    # init() is not provided for us anymore, so we're using this...
    #
    for ( keys %opt ) {
        $new_rate_request->$_( $opt{ $_ } );
    }
    
    
    return ( $new_rate_request );
}

sub new_subclass
{
    my ( $class, $subclass, %opt ) = @_;
    
    my $new_class = $class . '::' . $subclass;
    if ( not defined &$new_class ) {  # TODO: this test is always false: get a better test.
        #
        # Clear previous errors
        #
        $@ = '';
        
        eval "require $new_class";
        Carp::croak( "Error when trying to require $new_class: \n\t$@" ) if $@;
        
        eval "import $new_class";
        Carp::croak( "Error when trying to import $new_class: $@" ) if $@;
    }
    else {
        # "$new_class already defined.";
    }
    
    my $new_sub_object = eval "$new_class->new()";
    if ( $@ ) {
        die "Failed to create new $new_class object.  Error: $@";
    }
    
    return $new_sub_object;    
}

sub get_class_name { return blessed $_[ 0 ]; }

sub determine_shipper_from_self
{
    my ( $self ) = @_;
    
    trace( 'called' );
    
    my $class = blessed $self;
    
    debug "class = $class";
    
    return 'UPS'  if $class =~ /UPS$/;
    return 'USPS' if $class =~ /USPS$/;
    
    return;
}

#
# Aliased for convenient access in each subclass.
#
sub config_to_hash          { return &Business::Shipping::Config::config_to_hash;          }
sub config_to_ary_of_hashes { return &Business::Shipping::Config::config_to_ary_of_hashes; }

sub event_handlers { warn 'Depreciated.  Event handlers are now configured via config/log4perl.conf.' }

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See LICENSE for more info.

=cut
