# Business::Shipping::Debug - Debugging Functions
# 
# $Id: Debug.pm,v 1.5 2004/01/21 22:39:52 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Debug;

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT = qw( uneval debug debug3 trace log_error );

use strict;
use warnings;
use base ( 'Exporter', 'Business::Shipping' );

%Business::Shipping::Debug::event_handlers = ();
$Business::Shipping::Debug::event_handlers{ 'debug' } 	= undef;
$Business::Shipping::Debug::event_handlers{ 'debug3' }	= undef;
$Business::Shipping::Debug::event_handlers{ 'trace' } 	= undef;
$Business::Shipping::Debug::event_handlers{ 'error' } 	= 'STDERR';

# uneval() was shamelessly copied from Interchange.
# Written by Mike Heins <mike@perusion.com>
sub uneval { 
    my ( $self, $o ) = @_;		# recursive
    my ( $r, $s, $i, $key, $value );

	local($^W) = 0;
	no warnings; #supress 'use of unitialized values'
	
    $r = ref $o;
    if (!$r) {
		$o =~ s/([\\"\$@])/\\$1/g;
		$s = '"' . $o . '"';
    } 
	elsif ($r eq 'ARRAY') {
		$s = "[";
		foreach $i (0 .. $#$o) {
			$s .= uneval($o->[$i]) . ",";
		}
		$s .= "]";
    }
	elsif ($r eq 'HASH') {
		$s = "{";
		while (($key, $value) = each %$o) {
			$s .= "'$key' => " . uneval($value) . ",";
		}
		$s .= "}";
    } 
	else {
		$s = "'something else'";
    }

    $s;
}

sub log_error	{
	my $msg = shift;
	# Remove three or more consecutive whitespaces.
	$msg =~ s/\s{3,}/ /g;
	return _log( 'error', $msg  ); 
}

sub debug		{ return _log( 'debug', shift ); }
sub debug3		{ return _log( 'debug3', shift ); }
sub trace		{ return _log( 'trace', shift ); }

sub _log
{
    my ( $type, $msg ) = @_;
	
	my ( $package, $filename, $line, $sub ) = caller( 2 );
	
	# Go one level deeper if called by Shipping::error()
	# It's a shortcut so we don't have to call Shipping::error() and log_error()
	if ( $sub eq 'Business::Shipping::error' ) {
		( $package, $filename, $line, $sub ) = caller( 3 );
	}
	
	$msg  = "$sub: $msg" if $sub and $msg;
	$msg .= "\n" unless ( $msg =~ /\n$/ );
	
	#
	# Take off the "Business::Shipping::" to save space
	#
	$msg =~ s/Business::Shipping:://;
	
	my @event_handlers = ( 'debug', 'debug3', 'trace', 'error' );
	
	foreach my $eh ( @event_handlers ) {
		my $eh_value = $Business::Shipping::Debug::event_handlers{ $eh };
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
