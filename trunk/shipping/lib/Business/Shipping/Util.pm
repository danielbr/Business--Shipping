=head1 NAME

Business::Shipping::Util - Miscellaneous functions

=head1 VERSION

$Rev$

=head1 DESCRIPTION

Misc functions, some others.

=head1 METHODS

=over 4

=cut

package Business::Shipping::Util;

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };
@EXPORT  = ( 'element_in_array' );

use strict;
use warnings;
use base ( 'Exporter' );
use Data::Dumper;
use Business::Shipping::Logging;
use Carp;
use File::Find;
use File::Copy;
use Fcntl ':flock';
use English;

=item * currency( $opt, $amount )

Formats a number for display as currency in the current locale (currently, the
only locale supported is USD).

=cut

sub currency
{
    my ( $opt, $amount ) = @_;
    
    return unless $amount;
    $amount = sprintf( "%.2f", $amount );
    $amount = "\$$amount" unless $opt->{ no_format };
    
    return $amount;
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

=item * readfile( $file )

=cut

sub readfile
{
    my ( $file ) = @_;
    
    return undef unless open( READIN, "< $file" );
    
    # TODO: Use English;
    
    undef $/;
    
    my $contents = <READIN>;
    close( READIN );
    
    return $contents;
}

=item * element_in_array( $element, @array )

TODO: Replace with List::Util?

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
    open $file_handle, "$filename" 
        || carp "could not open file: $filename.  Error: $!";
    
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
