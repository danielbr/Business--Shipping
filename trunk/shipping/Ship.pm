# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: Ship.pm,v 1.1 2003/05/31 22:39:47 db-ship Exp $

package Business::Ship;
use strict;
use warnings;

=head1 NAME

Business::Ship - API for UPS and USPS

=head1 SYNOPSIS

use Business::Ship;

my $shipment = new Business::Ship( 
	'shipper' 		=> 'USPS'
	'user_id'		=> '',
	'password'		=> '',
	'from_zip'		=> '',
	'to_zip'		=> '',
	'weight' 		=> '',
	'service'		=> '',
);

$shipment->submit() or print $shipment->error();

print $shipment->total_charges();

=head1 DESCRIPTION

In normal use, the application creates a C<Business::Ship::*> object, and then
configures it with values for user id, password, access key, etc.  The query is
run via the submit() method, and the total_charges can be accessed via the
total_charges() method.

Note that you can set variables in the submit() method, via the set() method,
or via the new() constructor.

=head1 MULTI-PACKAGE API

$shipment->set(
	user_id		=> '',
	password	=> '',
	from_zip	=> '',
	to_zip		=> '',
);

$shipment->add_package(
	id			=> '0',
	weight		=> '',
);

$shipment->add_package(
	id			=> '1',
	weight		=> '',
);

$shipment->submit() or print $shipment->error();

print $shipment->get_package('0')->get_charges( 'Airmail Parcel Post' );
print $shipment->get_package('1')->get_charges( 'Airmail Parcel Post' );
print $shipment->get_total_price( 'Airmail Parcel Post' );

=head1 ERROR/DEBUG HANDLING

The 'event_handlers' argument takes a hashref telling interchange what to do
for error, debug, trace, and the like.  The value can be one of four options:

 * 'STDERR'
 * 'STDOUT'
 * 'carp'
 * 'croak'

For example:

$shipment->set( 
	'event_handlers'	=> ({ 
		'debug' => undef,
		'trace' => undef,
		'error' => 'croak',
	})
);
 
The default is 'STDERR' for error handling, and nothing for debug/trace handling.
Note that you can still access error messages even with no handler, by accessing
the return values of methods.  For example:

	$shipment->set( %values ) or print $shipment->error();
	
However, if you don't save the error value before the next call, it could be
overwritten by a new error.

=cut

use vars qw($VERSION);
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Data::Dumper;
use Carp;
use Cache::FileCache;
use HTTP::Request;

# Pull them in now to avoid runtime requires (in hopes of compatibility with
# Safe.pm sometime in the future. 
use Business::Ship::UPS;
use Business::Ship::USPS;

# This new() does a little magic so that it can be called as:
# my $shipment = new Business::Ship::USPS;
#  - or -
# my $shipment = new Business::Ship( 'shipper' => 'USPS' );
# If called with a 'shipper' argument, then return a sub object (like Ship::USPS)
# If called without one, then return a Ship object 
#  - Like when a sub-class is calling as SUPER->new().
sub new 
{
	my( $class, %args ) = @_;
	
	my $subclass;
	foreach my $potential_subclass_name ( 'subclass', 'shipper', 'package' ) {
		my $test = $args{ $potential_subclass_name };
		if ( $test ) {
			$subclass = delete $args{ $potential_subclass_name };
		}
	}	
	if ( $subclass ) {
		my $qualified_subclass = "${class}::$subclass";
		if ( not defined &$qualified_subclass ) {
			eval "use $qualified_subclass";
			Carp::croak("unknown subclass $subclass ($@)") if $@;
		}
		return( eval "new $qualified_subclass( %args )" );
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
		cache_enabled	=> 1, 
		
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
		get_charges	=> undef,
		weight		=> undef,
	);
	
	my $self = bless( {
			'required' => \%required,
		}, $class 
	);
	
	$self->build_subs( keys %required, keys %optional);
	$self->build_alias_subs( keys %alias_to_default_package );
	$self->set( %required, %optional, %args );
	
	return $self;
}

sub initialize
{
	my ( $self, %args ) = @_;
	$self->build_subs( $self->_metadata( 'internal' ) );
	$self->build_subs( $self->_metadata( 'required' ) );
	$self->build_subs( $self->_metadata( 'optional' ) );
	$self->build_alias_subs( $self->_metadata( 'alias_to_default_package' ) );
	foreach ( 'required', 'internal', 'optional', 'parent_defaults' ) {
		$self->set(
			%{ $self->_metadata( $_ ) }
		);
	}
	$self->set( %args );
	# Hmmm... currently nothing needed for compatibility's sake...
	#$self->compatibility_map( %{ $self->_metadata( 'compatibility_map' ) } ); 
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
	my ( $self ) = shift;
	
	my @missing_args;
	
	foreach my $required ( $self->_metadata( 'required' ) ) {
		unless ( $self->$required() ) {
			push @missing_args, $required;	
		}
	}
	if ( @missing_args ) {
		$self->error( "Missing required argument " . join ", ", @missing_args );
		return undef;
	}
	else {
		return 1;
	}
}
	
=pod Old one
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
=cut

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

sub _gen_unique_values
{
	my ( $self ) = @_;
		
	# Now I need to get unique values for all packages.
	
	my @unique_values;
	foreach my $package ( @{$self->packages()} ) {
		push @unique_values, $package->get_unique_values();
	}
	
	# We prefer 0 in the key to represent 'undef'
	# clean it all up...
	my @new_unique_values;
	foreach my $value ( @unique_values ) {
		if ( not defined $value ) {
			$value = 0;
		}
		push @new_unique_values, $value;
	}

	return( @new_unique_values );
}

sub _gen_request
{
	my ( $self ) = shift;
	$self->trace( "called" );
	
	my $request_xml = $self->_gen_request_xml();
	my $request = new HTTP::Request 'POST', $self->_gen_url();
	
	$request->header( 'content-type' => 'application/x-www-form-urlencoded' );
	$request->header( 'content-length' => length( $request_xml ) );
	$request->content( $request_xml );
	
	return ( $request );
}

# This was pulled into Business::Ship because it's likely that both
# shippers will benefit from a similar cache structure.
#
# Caches responses for speed.  Not all API users will be able to extract all
# of the pakage rates for each service at once, they will have to do it twice. 
# This helps a lot.
#
# TODO:  A more efficient caching method would be to cache the end-result
# (the amounts, or whatever), then look it up at submit() time based on the
# same _unique_values. 
sub _get_response
{
	my $self = shift;
	my $request = shift;
	
	if ( $self->cache_enabled() ) {
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
	else {
		$self->trace( 'cache disabled.' );
		$self->debug( "sending this request: " . Dumper( $request ) );
		return $self->{'ua'}->request( $request );
	}	
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
		$self->error( "HTTP Error. Status line: " . $self->response->status_line .
		"Content: " . $self->response->content() );
		return( undef ); 
	}
	return $self->_handle_response();
}


sub add_package
{
	my $self = shift;
	$self->trace('called with' . $self->uneval( @_ ) );
	
	my $new = new Business::Ship( 'package' => $self->package_subclass_name() );
	$new->set( @_ );
	
	# If the passed package has an ID, then use that.
	if ( $new->id() or ( $new->id() and $new->id() == 0 ) ) {
		$self->trace( "Using id in passed package" );
		$self->packages()->[$new->id()] = $new;
		return 1;
	}
		
	# If the "default" package ($self->packages()->[0]) is 
	# still in "default" state (has not yet been updated),
	# then replace it with the passed package.
	$self->trace( 'checking to see if default package is empty...' );
	if ( $self->default_package()->is_empty() ) {
		$self->trace( 'yes, is empty.' );
		$self->packages()->[0] = $new;
		$self->trace( 'done setting up default package.' );
		return 1;	
	}
	$self->trace( 'no, not empty.' );
	
	# Otherwise, add the package in the second slot.
	push( @{$self->packages()}, $new );
	
	return 1;
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

=pod
 * TODO: Allow the use of Net::SSLeay as well as Crypt::SSLeay?
 * Here's how interchange does it...

BEGIN {

	my $selected;
	eval {
		package Vend::Payment;
		require Net::SSLeay;
		import Net::SSLeay qw(post_https make_form make_headers);
		$selected = "Net::SSLeay";
	};

	$Vend::Payment::Have_Net_SSLeay = 1 unless $@;

	unless ($Vend::Payment::Have_Net_SSLeay) {

		eval {
			package Vend::Payment;
			require LWP::UserAgent;
			require HTTP::Request::Common;
			require Crypt::SSLeay;
			import HTTP::Request::Common qw(POST);
			$selected = "LWP and Crypt::SSLeay";
		};

		$Vend::Payment::Have_LWP = 1 unless $@;

	}

	unless ($Vend::Payment::Have_Net_SSLeay or $Vend::Payment::Have_LWP) {
		die __PACKAGE__ . " requires Net::SSLeay or Crypt::SSLeay";
	}

	::logGlobal("%s payment module initialized, using %s", __PACKAGE__, $selected)
		unless $Vend::Quiet;
}

=cut
