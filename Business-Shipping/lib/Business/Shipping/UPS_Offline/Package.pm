package Business::Shipping::UPS_Offline::Package;

=head1 NAME

Business::Shipping::UPS_Offline::Package

=head1 VERSION

2.2.0

=head1 METHODS

=over 4

=cut

use version; our $VERSION = qv('2.2.0');

use strict;
use warnings;
use base ('Business::Shipping::Package');

use Class::MethodMaker 2.0 [new => 'new'];

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
