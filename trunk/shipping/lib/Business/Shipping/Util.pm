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
