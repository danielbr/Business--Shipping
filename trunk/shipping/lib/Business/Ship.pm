# Copyright (c) 2003 Kavod Technologies, and Dan Browning.  
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.
# $Id: Ship.pm,v 1.15 2003/05/13 00:24:52 db-ship Exp $
package Business::Ship;
use strict;
use warnings;

=head1 NAME

Business::Ship - API for UPS and USPS

=head1 SYNOPSIS

use Business::Ship;
my $shipment = new Business::Ship( 'shipper' => 'USPS' );
 
$shipment->set(
	user_id		=> '',
	password	=> '',
	weight		=> '',
);

$shipment->submit() or print $shipment->error();


=head1 INSTALLATION:

 * Install all the necessary perl modules:
   - Bundle::LWP 
   - XML::Simple 
   - XML::DOM
   - Crypt::SSLeay
   - Digest::SHA1
   - Error
   - Cache::FileCache
   - You can install them with this command:
   - C<perl -MCPAN -e 'install Bundle::LWP XML::Simple etc. etc.'>

 * Sign up for USPS or UPS
 	- See instructions in Business::Ship module.
	- Add Access ID and code using Admin UI->Preferences

 * Copy the Ship/ directory into this directory:
   interchange/lib/Business/

=head1 MULTI-PACKAGE API

$shipment->set(
	user_id		=> '',
	password	=> '',
	from_zip	=> '',
);

$shipment->add_package(
	id			=> '0',
	weight		=> '',
	to_zip		=> '',
);

$shipment->add_package(
	id			=> '1',
	weight		=> '',
	to_zip		=> '',
);

print $shipment->get_package('0')->get_charges( 'Airmail Parcel Post' );
print $shipment->get_package('1')->get_charges( 'Airmail Parcel Post' );
print $shipment->get_total_price( 'Airmail Parcel Post' );
   
=cut


use vars qw($VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);

use Data::Dumper;
use Carp;
use Cache::FileCache;


# This new() does a little magic so that it can be called as:
# my $usps = new Business::Ship::USPS;
#  - or -
# my $usps = new Business::Ship( 'shipper' => 'USPS' );
# If called with a 'shipper' argument, then return a sub object (like Ship::USPS)
# If called without one, then return a Ship object 
#  - Like when a sub-class is calling as SUPER->new().
sub new 
{
	my( $class, %args ) = @_;

	# "Driver" (child-first) initiation, if used.
	if ( $args{ 'shipper' } ) {
		# Build a sub-object and return.
		# The sub-object will call this parent new() method again, as SUPER->new()
		# But 'shipper' wont be part of the arguments then, so the normal init will 
		# be done.
		my $shipper = delete $args{'shipper'};
	    my $subclass = "${class}::$shipper";
		if ( not defined &$subclass ) {
			eval "use $subclass";
			Carp::croak("unknown shipper $shipper ($@)") if $@;
		}
		return( eval "new $subclass( %args )" );
    }
	
	# Regular Initiation
	my %required = (
		user_id		=> undef,
		password	=> undef,
	);
	
	my %optional = (
		###########################
		# External
		###########################
		is_success	=> undef,
		tx_type		=> 'rate',
		test_mode	=> 0,
		test_url	=> undef,
		prod_url	=> undef,
		total_charges	=> undef,
		event_handlers	=> ({ 
				'debug' => undef,
				'trace' => undef,
				'error' => 'croak',
			}),		
		
		###########################
		# Internal
		###########################
		# Text response from server 
		response		=> undef,
		response_tree	=> undef,
		error_msg		=> undef,
		cache			=> new Cache::FileCache,
	);
	
	# For people who aren't using the multi-package API, this provides quick calling.
	my %alias_to_default_package = (
		id			=> undef,
		service 	=> undef,
		from_zip	=> undef,
		to_zip		=> undef,
		to_country	=> undef,
		get_charges	=> undef,
		weight		=> undef,
	);
	
	my $self = bless( {
			'required' => \%required,
		}, $class 
	);
	
	$self->trace('just blessed self, building subs and setting defaults now...');
	$self->build_subs( keys %required, keys %optional);
	$self->build_alias_subs( keys %alias_to_default_package );
	$self->set( %required, %optional, %args );
	$self->trace('...returning self');
	
	return $self;
}

sub required_vals
{
	my $self = shift;
	return keys %{$self->{ 'required' }};
}

sub build_alias_subs
{
	my $self = shift;
	foreach( @_ ) {
		unless ( $self->can( $_ ) ) {
			eval "sub $_ { return shift->default_package()->$_( \@_ ); }";
		}
    }
	return;
}

sub default_package { return shift->packages()->[0]; }
sub get_package { return shift->packages()->[ @_ ]; }

sub validate 
{
	my( $self, @fields ) = @_;
	
	foreach( $self->required_vals() ) {
		unless ( $self->can( $_ ) and $self->$_() ) {
			$self->error( "missing required field $_" );
			return undef;
		}
	}
	
	return 1;
}

sub get_unique_keys
{
	my $self = shift;
	
	# None at the Business::Ship level.
	my @unique_keys = ();
	
	return( @unique_keys );
}

sub build_subs 
{
	my $self = shift;
	foreach( @_ ) {
		unless ( $self->can( $_ ) ) {
			eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
		}
    }
	return;
}

# Checks to see if arg has a valid sub associated
# Then calls it, or errors out if it doesn't.
sub set {
    my( $self, %args ) = @_;
	
    foreach my $key ( keys %args ) {
		if( $self->can( $key ) ) {
			$self->$key( $args{ $key } );
		}
		else {
			$self->error( "$key not valid" );
		}
	}
}

sub _gen_url
{
	my ( $self ) = shift;
	
	return( $self->test_mode() ? $self->test_url() : $self->prod_url() );
}

# This was pulled into Business::Ship because it's likely that both
# shippers will benefit from a similar cache structure.
#
# Caches responses for speed.  Not all API users will be able to extract all
# of the pakage rates for each service at once, they will have to do it twice. 
# This helps a lot.
sub _get_response
{
	my $self = shift;
	my $request = shift;
	
	my @unique_values = $self->_gen_unique_values();
	my $key = join( "|", @unique_values );
	my $response = $self->cache()->get( $key );
	if ( not defined $response ) {
		#$self->trace( "unique_values = " . $self->uneval( @unique_values ) );
		$self->trace( "running request manually, then add to cache." );
		$response = $self->{'ua'}->request( $request );
		#TODO: Allow setting of cache properties (time limit, enable/disable, etc.)
		$self->cache()->set( $key, $response, "2 days" ); 
	}
	else {
		$self->trace( "using cached response." );
	}
	return $response;	
}

=item $shipment->submit( [%args] )

This method sets some values (optional), generates the request, then parses and
the results and assigns the total_charges amount.

=cut
sub submit
{
	my ( $self, %args ) = @_;
	$self->trace( "calling with ( " . $self->uneval( %args ) . " )" );
	$self->set( %args ) if %args;
	$self->_massage_values();
	$self->validate() or return ( undef );
	$self->response( $self->_get_response( $self->_gen_request() ) );
	$self->debug( "response content = " . $self->response()->content() );
	unless ( $self->response()->is_success() ) { 
		$self->error( "HTTP Error. Content: " . $self->response->content() );
		return( undef ); 
	}
	return $self->_handle_response();
}


###########################################################################
##  Helper methods
###########################################################################
sub uneval { my $self = shift; return Dumper ( @_ ); }

sub debug 
{
    my ( $self, $msg ) = @_;
    return $self->_log( 'debug', $msg );
}

sub trace
{
	my ( $self, $msg ) = @_;
	return $self->_log( 'trace', $msg );
}

sub error 
{
    my ( $self, $msg ) = @_;
	return $self->error_msg() unless $msg; 
	$msg .= "\n" unless ( $msg =~ /\n$/ );
	$self->is_success( undef );
	$self->error_msg( $msg );
    return $self->_log( 'error', $msg );
}

sub _log
{
    my $self = shift;
    my ( $type, $msg ) = @_;

	my( $package, $filename, $line, $sub ) = caller( 2 );
	$msg  = "$sub: $msg";
	$msg .= "\n" unless ( $msg =~ /\n$/ );
	
	foreach my $eh ( keys %{$self->{'event_handlers'}} ) {
		my $eh_value = $self->{'event_handlers'}->{$eh};
		if ( $type eq $eh and $eh_value ) {
			print STDERR $msg if $eh_value eq "STDERR";
			print STDOUT $msg if $eh_value eq "STDOUT";
			Carp::carp   $msg if $eh_value eq "carp";
			Carp::croak  $msg if $eh_value eq "croak";
		}
	}
	
	return ( $msg );
}

1;
