# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

package Business::Shipping::Logging;

=head1 NAME

Business::Shipping::Logging - Logging interface

=head1 VERSION

$Id$

=head1 DESCRIPTION

Wrapper for KLogger.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use base ( 'Exporter' );
use vars ( '@EXPORT', '$VERSION'  );
use Business::Shipping::KLogging;
use Business::Shipping::Config;

@EXPORT = Business::Shipping::KLogging::subs;
$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

BEGIN
{
    foreach my $_sub ( Business::Shipping::KLogging::subs ) {
        eval "\*$_sub = \*Business::Shipping::KLogging::$_sub";
    }
    
    *trace    = *Business::Shipping::KLogging::debug;

    my $file         = Business::Shipping::Config::support_files()
                     . '/config/log4perl.conf';
    my $caller_depth = 2;
    
    Business::Shipping::KLogging::init(
        file         => $file,
        caller_depth => $caller_depth,
        once         => 1,
    );
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
