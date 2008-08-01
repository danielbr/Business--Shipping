package Business::Shipping::UPS_Offline::Package;

=head1 NAME

Business::Shipping::UPS_Offline::Package

=head1 VERSION

2.2.0

=head1 METHODS

=over 4

=cut

use Moose;
use version; our $VERSION = qv('2.2.0');

extends 'Business::Shipping::Package';

__PACKAGE__->meta()->make_immutable();

1;

__END__

=back

=head1 AUTHOR

Daniel Browning, db@endpoint.com, L<http://www.endpoint.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2008 Daniel Browning <db@endpoint.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
