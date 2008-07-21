
=head1 NAME

Business::Shipping::Util - Miscellaneous functions

=head1 VERSION

2.2.0

=head1 DESCRIPTION

Misc functions.

=head1 METHODS

=cut

package Business::Shipping::Util;

use version; our $VERSION = qv('2.2.0');
@EXPORT_OK = qw( looks_like_number unique );

use strict;
use warnings;
use base ('Exporter');
use Data::Dumper;
use Business::Shipping::Logging;
use Carp;
use File::Find;
use File::Copy;
use Fcntl ':flock';
use English;

=head2 * currency( $opt, $amount )

Formats a number for display as currency in the current locale (currently, the
only locale supported is USD).

=cut

sub currency {
    my ($opt, $amount) = @_;

    return unless $amount;
    $amount = sprintf("%.2f", $amount);
    $amount = "\$$amount" unless $opt->{no_format};

    return $amount;
}

=head2 * unique( @ary )

Removes duplicates (but leaves at least one).

=cut

sub unique {
    my (@ary) = @_;

    my %seen;
    my @unique;
    foreach my $item (@ary) {
        push(@unique, $item) unless $seen{$item}++;
    }

    return @unique;
}

=head2 * looks_like_number( $scalar )

Shamelessly stolen from Scalar::Util 1.10 in order to reduce dependancies.
Not part of the normal copyright.

=cut

sub looks_like_number {
    local $_ = shift;

    # checks from perlfaq4
    return $] < 5.009002 unless defined;
    return 1 if (/^[+-]?\d+$/);    # is a +/- integer
    return 1
        if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);   # a C float
    return 1
        if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i)
        or ($] >= 5.006001 and /^Inf$/i);

    0;
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
