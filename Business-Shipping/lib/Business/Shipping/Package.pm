# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

package Business::Shipping::Package;

=head1 NAME

Business::Shipping::Package - Abstract class

=head1 VERSION

2.2.0

=head1 DESCRIPTION

Represents package-level information (e.g. weight).  Subclasses provide real 
implementation.

=head1 METHODS

=cut

use Moose;
use version; our $VERSION = qv('2.2.0');

=head2 $package->weight()

Accessor for weight.

=head2 $package->id()

Package ID (for unique identification in a list of packages).

=cut

extends 'Business::Shipping';
has 'weight'             => (is => 'rw');
has 'id'                 => (is => 'rw');
has 'charges'            => (is => 'rw');
has 'dimensional_weight' => (is => 'rw');

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
