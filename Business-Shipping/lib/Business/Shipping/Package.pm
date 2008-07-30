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

Daniel Browning, db@endpoint.com, L<http://www.endpoint.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2008 Daniel Browning <db@endpoint.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
