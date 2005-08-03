package Business::Shipping::UPS_Online::Package;

=head1 NAME

Business::Shipping::UPS_Online::Package

=head1 VERSION

$Rev: 157 $
$Date: 2004-07-09 14:25:49 -0700 (Fri, 09 Jul 2004) $

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev: 157 $; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping::Package' );

=item * packaging

UPS_Online-only attribute.

=item * signature_type

  UPS_Online-only attrbute.

  If not set, then DeliveryConfirmation/DCISType will not be sent to UPS.

  Possible values:

  1 - No signature required.
  2 - Signature required.
  3 - Adult signature required.

  Only valid for US domestic shipments.

=item * insured_currency_type

  UPS_Online-only attribute
  
  Used in conjunction with insured_value.

=item * insured_value
  
  UPS_Online-only attribute
 
=cut
 
use Class::MethodMaker 2.0
    [ 
      new    => [ qw/ new / ],
      new    => [ qw/ default_new / ],
      scalar => [ 'packaging', 'signature_type', 'insured_currency_type', 'insured_value' ],
    ];

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
