# Business::Shipping::Util - Miscellaneous functions
# 
# $Id: Util.pm,v 1.8 2004/05/06 20:15:26 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Util;

=head1 NAME

Business::Shipping::Util - Miscellaneous functions

=head1 VERSION

$Revision: 1.8 $      $Date: 2004/05/06 20:15:26 $

=head1 DESCRIPTION

Many file-related functions, some others.

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT  = ( 'element_in_array', 'uneval' );

use strict;
use warnings;
use base ( 'Exporter' );
use Data::Dumper;
use Business::Shipping::Logging;
use Carp;
use File::Find;
use File::Copy;
use Archive::Zip qw(:ERROR_CODES);
use Fcntl ':flock';

=item * download_to_file( $url, $file )

=cut
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

=item * currency( $opt, $amount )

Formats a number for display as currency in the current locale (currently, the
only locale supported is USD).

Analagous to $Tag->currency() in Interchange.

=cut
sub currency
{
    my ( $opt, $amount ) = @_;
    
    return unless $amount;
    $amount = sprintf( "%.2f", $amount );
    $amount = "\$$amount" unless $opt->{ no_format };
    
    return $amount;
}

=item * _unzip_file( $zipName, $destination_directory )

=cut
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
        #$self->user_error( $error );
        die $error;
    }
    if ( $@ ) { die "_unzip_file error: $@"; }
    
    $zip->extractTree( '', $destination_directory );
    
    return;
}

=item * filename_only( $path )

=cut
sub filename_only
{
    trace "( $_[0] )";
    my $filename_with_extension = $_[0];
    
    my $filename_only = $filename_with_extension; 
    $filename_only =~ s/\..+$//;
    
    return $filename_only;
}

=item * split_dir_file( $path )

=cut
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

=item * remove_extension( $file )

=cut
sub remove_extension
{
    my $file = shift;
    trace "( $file )";
    
    my $filename_only = filename_only( $file );
    rename( $file, $filename_only );
    
    return $filename_only;
}

=item * remove_elements_of_x_that_are_in_y( $x, $y )

=cut
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

=item * remove_windows_carriage_returns( $path )

=cut
sub remove_windows_carriage_returns
{
    my $file = shift;
    trace "( $file )";
    
    open(    IN,        $file      );
    flock(   IN,        LOCK_EX    );
    binmode( IN                    ) if $Global::Windows;
    open(    OUT,       ">$file.1" );
    flock(   OUT,       LOCK_EX    );
    binmode( OUT                   ) if $Global::Windows;

    #
    # read it all in at once.
    #
    undef $/;
    my $contents = <IN>;
    $contents =~ s/\r\n/\n/g;
    print OUT $contents;
    
    flock(  IN,        LOCK_UN     );
    close(  IN                     );
    flock(  OUT,       LOCK_UN     );
    close(  OUT                    );
    copy(   "$file.1", $file       );
    unlink( "$file.1"              );
    
    #
    # return to normal line endings.
    #
    $/ = "\n";
    return;
}

=item * readfile( $file )

=cut
sub readfile
{
    my ( $file ) = @_;
    
    return undef unless open( READIN, "< $file" );
    undef $/;
    my $contents = <READIN>;
    close( READIN );
    
    return $contents;
}

=item * element_in_array( $element, @array )

=cut
sub element_in_array
{
    my ( $e, @a ) = @_;
    return unless $e and @a;
    
    for ( @a ) {
        return 1 if $_ eq $e;
    }
    
    return 0;
}

=item * get_fh( $filename )

=cut
sub get_fh
{
    my ( $filename ) = @_;

    my $file_handle;
    open $file_handle, "$filename" || carp "could not open file: $filename.  Error: $@";
    
    return $file_handle;
}

=item * close_fh( $file_handle )

=cut
sub close_fh
{
    my ( $file_handle ) = @_;
    
    close $file_handle;
    
    return;
}

=item * unique( @ary )

Removes duplicates (but leaves at least one).

=cut
sub unique
{
    my ( @ary ) = @_;
    
    my %seen;
    my @unique;
    foreach my $item ( @ary ) {
        push( @unique, $item ) unless $seen{ $item }++;
    }
    
    return @unique;
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
