# Copyright (c) 2003 Kavod Technologies, and Dan Browning.  
# All rights reserved. This program is free software; you can 
# redistribute it and/or modify it under the same terms as Perl 
# itself.
# $Id: Ship.pm,v 1.7 2003/04/23 01:39:59 db-ship Exp $
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
$VERSION = sprintf("%d.%03d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use Data::Dumper;
use Carp;

sub new {
	my( $class, $shipper, %args) = @_;
	
	Carp::croak( "unspecified shipper" ) unless $shipper;
	
	my $subclass = "${class}::$shipper";
	
	unless ( defined( &$subclass ) ) {
		eval "use $subclass";
		Carp::croak( "unknown shipper $shipper ($@)" ) if $@;
	}
	
	my @required_vals = qw/
		user_id
		password
	/;
	
	my @optional_vals = qw/
		success
		tx_type
		error_msg
		response
		
		test_url
		prod_url
		test_mode
		
		service 
		origination_zip
		destination_zip
		weight
		total_charges
		
		event_handlers
	/;

	my $self = bless {
		'shipper' => $shipper,
		'required_vals' => \@required_vals,
		'optional_vals' => \@optional_vals,
	}, $subclass;
	
	
	$self->build_subs( 'required_vals', 'optional_vals', @required_vals, @optional_vals );
	
	if($self->can("set_defaults")) {
		$self->set_defaults();
	}
	
	foreach(keys %args) {
		my $key = lc( $_ );
		my $value = $args{$_};
		$key =~ s/^\-//;
		$self->build_subs( $key );
		$self->$key( $value );
	}
	
	return $self;
}

sub validate {
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

sub set_defaults
{
	my $self = shift;
	$self->set(
		'event_handlers' => ({ 
			'debug' => undef,
			'error' => 'croak',
		})
	);
	return;
}

sub debug {
    my ( $self, $msg ) = @_;
    return $self->_log( 'debug', $msg );
}

sub error {
    my ( $self, $msg ) = @_;

	$msg .= "\n" unless ( $msg =~ /\n$/ );
	$self->success( undef );
	
    return $self->_log( 'error', $msg );
}

sub _log
{
    my $self = shift;
    my ( $type, $msg ) = @_;

	my( $package, $filename, $line, $sub ) = caller( 2 );
	$msg  = "$sub: $msg";
	
	$msg .= "\n" unless ( $msg =~ /\n$/ );
	
	# TODO: Allow to be settable via member var.
	#my %event_handlers = (
	#	'debug' => 'STDOUT',
	#	'error' => 'STDERR',
	#);
	#$self->{'event_handlers'} = \%event_handlers;
	
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


sub build_subs {
    my $self = shift;
    foreach( @_ ) {
        eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
    }
}



1;
