package Business::Shipping::UPS_Online::Shipment;

=head1 NAME

Business::Shipping::UPS_Online::Shipment

=head1 VERSION

2.2.0

=head1 METHODS

=cut

use Moose;
use Business::Shipping::Config;
use Business::Shipping::Logging;
use version; our $VERSION = qv('2.2.0');

extends 'Business::Shipping::Shipment::UPS';

# of 'Business::Shipping::UPS_Online::Package' objects
has 'packages' => (
    is         => 'rw',
    isa        => 'ArrayRef[Business::Shipping::UPS_Online::Package]',
    default    => sub { [Business::Shipping::UPS_Online::Package->new()] },
    auto_deref => 1
);
has 'max_weight' => (is => 'rw', default => 150);
has 'cod' => (is => 'rw');
has 'cod_funds_code' => (is => 'rw');
has 'cod_value'      => (is => 'rw');

__PACKAGE__->meta()->make_immutable();

1;

__END__

=head1 AUTHOR

Daniel Browning, db@endpoint.com, L<http://www.endpoint.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2008 Daniel Browning <db@endpoint.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
