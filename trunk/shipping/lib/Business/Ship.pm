# Copyright (c) 2003 Kavod Technologies, and Dan Browning.  
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.
# $Id: Ship.pm,v 1.10 2003/04/30 08:25:47 db-ship Exp $
package Business::Ship;
use strict;
use warnings;

=pod

use Business::Ship;

my $shipment = new Business::Ship( 'UPS');
$shipment->set(
	user_id		=> '',
	password	=> '',
	weight		=> '',
);
$shipment->submit_rate_query();

if( $shipment->rate_success() ) {
	print $shipment->total_charges();
}
else {
	print $shipment->error();
}

=cut


use vars qw($VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

use Data::Dumper;
use Carp;


# If called with a 'shipper' argument, then return a sub object (like Ship::USPS)
# If called without one, then return a Ship object (it's likely a sub-class is calling)
sub new 
{
	my( $class, %args ) = @_;
	print "Business::Ship::new()\n";
	
	# Defaults
	my %required = (qw/
		user_id		undef
		password	undef
	/);
	
	my %optional = (qw/
		success		undef
		tx_type		undef
		error_msg	undef
		response	undef
		
		test_url	undef
		prod_url	undef
		test_mode	undef
		
		service 	undef
		from_zip	undef
		to_zip		undef
		weight		undef
		total_charges	undef
		
		event_handlers	undef
	/);
	
	my %internal = (qw/
	
	/);
	my $self = bless( {}, $class );
	
	$self->build_subs( keys %required, keys %optional, keys %internal );
	$self->set( %required, %optional, %internal );
	$self->set(
		'event_handlers' => ({ 
			'debug' => undef,
			'error' => 'croak',
		})
	);
	$self->set( %args );
	
	return $self;
}

sub validate 
{
	my( $self, @fields ) = @_;
	
	foreach( $self->required_vals() ) {
		unless( $self->can( $_ ) ) {
			$self->error( "missing required field $_" );
			return ( undef );
		}
	}
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

sub debug 
{
    my ( $self, $msg ) = @_;
    return $self->_log( 'debug', $msg );
}

sub error 
{
    my ( $self, $msg ) = @_;
	$msg .= "\n" unless ( $msg =~ /\n$/ );
	$self->success( undef );
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



1;
