# $Id: UPS.pm,v 1.7 2004/03/03 04:07:51 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Package::UPS;

=head1 NAME

Business::Shipping::Package::UPS

=head1 VERSION

$Revision: 1.7 $      $Date: 2004/03/03 04:07:51 $

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::Package' );

=item * packaging

UPS-only attribute.

=cut
use Business::Shipping::CustomMethodMaker
    new_hash_init => 'new',
    grouped_fields_inherit => [ optional => [ 'packaging' ],
                                unique   => [ 'packaging' ],
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
