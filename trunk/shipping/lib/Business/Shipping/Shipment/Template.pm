# $Id: Template.pm,v 1.1 2004/03/31 19:11:07 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Shipment::Template;

=head1 NAME

Business::Shipping::Shipment::Template

=head1 VERSION

$Revision: 1.1 $      $Date: 2004/03/31 19:11:07 $

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment' );
use Business::Shipping::Config;

use Class::MethodMaker 2.0
    [ 
      new    => [ { -hash => 1, -init => 'this_init' },  'new' ],
      array  => [ { -type => 'Business::Shipping::Package::Template' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'default_package=>Business::Shipping::Package::Template' }, 'Has_a' ],
    ];

sub this_init
{
    $_[ 0 ]->shipper(      'Template' );
    return;
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