# Business::Shipping::Util
# 
# $Id: Util.pm,v 1.1 2003/12/22 03:49:05 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Util;

use strict;
use warnings;

use vars qw( $VERSION @EXPORT );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
use base ( 'Exporter', 'Business::Shipping' );

use Data::Dumper;
use Business::Shipping::Debug;

use File::Find;
use File::Copy;
use Archive::Zip qw(:ERROR_CODES);
use Fcntl ':flock';


sub download_to_file
{
	my ( $url, $file ) = @_;
	trace "( $url, $file )";
	
	return unless $url and $file;
	
	eval {
		use LWP::UserAgent;
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(GET => $url);
		open( NEW_ZONE_FILE, "> $file" );
		print( NEW_ZONE_FILE $ua->request($req)->content() );		
		close( NEW_ZONE_FILE );
	};
	warn $@ if $@;
	
	return;
}

sub currency
{
	my ( $opt, $amount ) = @_;
	
	$amount = sprintf( "%9.2f", $amount );
	
	$amount = "\$$amount" unless $opt->{ no_format };
	
	return $amount;
}

#
# Extracts all files from the given zip
#
sub _unzip_file
{
	my ( $zipName, $destination_directory ) = @_;
	$destination_directory ||= './';
	
	my $zip = Archive::Zip->new();
	my $status = $zip->read( $zipName );
	if ( $status != AZ_OK )  {
		my $error = "Read of $zipName failed";
		#$self->error( $error );
		die $error;
	}
	if ( $@ ) { die $@; }
	
	$zip->extractTree( '', $destination_directory );
	
	return;
}

sub filename_only
{
	trace "( $_[0] )";
	my $filename_with_extension = $_[0];
	
	my $filename_only = $filename_with_extension; 
	$filename_only =~ s/\..+$//;
	
	return $filename_only;
}

#
# Return ( directory_path, file_name ) from any path.
#
sub split_dir_file
{
	my $path = shift;
	
	my @path_components = split( '/', $path );
	my $file = pop @path_components;
	my $dir = join( '/', @path_components );
	return ( $dir, $file ); 
}

sub remove_extension
{
	my $file = shift;
	trace "( $file )";
	
	my $filename_only = filename_only( $file );
	rename( $file, $filename_only );
	
	return $filename_only;
}

sub remove_elements_of_x_that_are_in_y
{
	my ( $x, $y ) = @_;
	
	my @new_x;
	foreach my $x_item ( @$x ) {
		my $match = 0;
		foreach my $y_item ( @$y ) {
			if ( $x_item eq $y_item ) {
				$match = 1;
			}
		}
		if ( ! $match ) {
			push @new_x, $x_item;
		}
		else {
			debug3( "removing $x_item" );
		}
	}
	
	return @new_x;
}

sub remove_windows_carriage_returns
{
	my $file = shift;
	trace "( $file )";
	
	open(		IN,			$file 		);
	flock(		IN,			LOCK_EX 	);
	binmode(	IN 						) if $Global::Windows;
	open(		OUT,		">$file.1" 	);
	flock(		OUT,		LOCK_EX 	);
	binmode(	OUT						) if $Global::Windows;

	#
	# read it all in at once.
	#
	undef $/;
	my $contents = <IN>;
	$contents =~ s/\r\n/\n/g;
	print OUT $contents;
	
	flock(		IN,			LOCK_UN 	);
	close(		IN						);
	flock(		OUT,		LOCK_UN 	);
	close(		OUT						);
	copy( 		"$file.1",	$file 		);
	unlink(		"$file.1"				);
	
	#
	# return no normal
	#
	$/ = "\n";
	return;
}

sub readfile
{
	my ( $file ) = @_;
	
	return undef unless open( READIN, "< $file" );
	undef $/;
	my $contents = <READIN>;
	close( READIN );
	
	return $contents;
}

