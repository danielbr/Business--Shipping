# Business::Shipping::Debug - Debugging functions
# 
# $Id: Debug.pm,v 1.6 2004/03/03 03:36:31 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#

package Business::Shipping::Debug;

=head1 NAME

Business::Shipping::Debug - Debugging functions

=head1 VERSION

$Revision: 1.6 $      $Date: 2004/03/03 03:36:31 $

=head1 SYNOPSIS

 use Business::Shipping::Debug;
 
 trace "called with parameters: $x, $y, and $z";
 debug "value of x = $x";
 log_error "encountered invalid data: $x";
 debug3 "here is a big list of all the potential data values: $big_list";

=head1 DESCRIPTION

Exports several functions useful for logging debug messages, trace information, 
or error messages. 

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT = qw( uneval debug debug3 trace log_error );

use strict;
use warnings;
use base ( 'Exporter' );

%Business::Shipping::Debug::event_handlers = ();
$Business::Shipping::Debug::event_handlers{ 'debug' } 	= undef;
$Business::Shipping::Debug::event_handlers{ 'debug3' }	= undef;
$Business::Shipping::Debug::event_handlers{ 'trace' } 	= undef;
$Business::Shipping::Debug::event_handlers{ 'error' } 	= 'STDERR';

=item * uneval( ... )

Takes any built-in object and returns a string of text representing the perl 
representation of it.  

It was copied from Interchange L<http://www.icdevgroup.org>, written by Mike 
Heins  E<lt>F<mike@perusion.com>E<gt>.

=cut
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

=item * log_error( $msg )

=item * debug( $msg )

=item * debug3( $msg )

=item * trace( $msg )

=cut
sub log_error	{
	my $msg = shift;
	# Remove three or more consecutive whitespaces.
	$msg =~ s/\s{3,}/ /g;
	return _log( 'error', $msg  ); 
}

sub debug		{ return _log( 'debug', shift ); }
sub debug3		{ return _log( 'debug3', shift ); }
sub trace		{ return _log( 'trace', shift ); }

=item * _log( $err_msg )

This is where all the work happens.  Determines the caller, cleans up the 
message, then prints it where it should go.

=cut
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

__END__

=back

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
