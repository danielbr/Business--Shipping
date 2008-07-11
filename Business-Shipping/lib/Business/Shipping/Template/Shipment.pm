=head1 NAME

Business::Shipping::Template::Shipment

=head1 VERSION

$Rev$      $Date$

=head1 METHODS

=over 4

=cut

package Business::Shipping::Template::Shipment;

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base( 'Business::Shipping::Shipment' );
use Business::Shipping::Config;

use Class::MethodMaker 2.0
    [ 
      new    => [ { -hash => 1 },  'new' ],
      array  => [ { -type => 'Business::Shipping::Template::Package' }, 'packages' ],      
      scalar => [ { -static => 1, -default => 'packages=>Business::Shipping::Template::Package' }, 'Has_a' ],
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