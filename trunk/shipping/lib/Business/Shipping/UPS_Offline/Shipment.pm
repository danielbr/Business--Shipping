package Business::Shipping::UPS_Offline::Shipment;

=head1 NAME

Business::Shipping::UPS_Offline::Shipment

=head1 VERSION

$Rev: 158 $      $Date: 2004-09-09 15:58:17 -0700 (Thu, 09 Sep 2004) $

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev: 158 $; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment::UPS' );
use Business::Shipping::Config;

use Class::MethodMaker 2.0
    [ 
      new    => 'new',
      scalar => [ 'from_state' ],

      # We need this offline boolean to know if from_state is required.

      scalar => [ { -static => 1, -default => 'to_residential' }, 'Optional' ],
      scalar => [ { -static => 1, -default => 'to_residential' }, 'Unique' ],
      array  => [ { -type => 'Business::Shipping::UPS_Offline::Package',
                    -default_ctor => 'new' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'packages=>Business::Shipping::UPS_Offline::Package' }, 'Has_a' ],
    ];

=item * Required()

from_state only required for Offline international orders.

=cut

sub Required
{
    return 'service, from_state' if $_[ 0 ]->to_canada;
    return 'service, from_zip, from_state' if $_[ 0 ]->intl;
    return 'service, from_zip';
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