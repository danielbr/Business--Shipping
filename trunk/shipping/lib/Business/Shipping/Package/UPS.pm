package Business::Shipping::Package::UPS;

=head1 NAME

Business::Shipping::Package::UPS

=head1 VERSION

$Revision$


$Date$

=head1 METHODS

=over 4

=cut


$VERSION = do { my @r=(q$Rev$=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::Package' );


=item * packaging

UPS-only attribute.

=cut
 
use Class::MethodMaker 2.0
    [ 
      new    => [ qw/ -hash new / ],
      scalar => [ 'packaging' ],
      scalar => [ { -static => 1, -default => 'weight'    }, 'Required' ],
      scalar => [ { -static => 1, -default => 'packaging' }, 'Optional' ],
      scalar => [ { -static => 1, -default => 'packaging' }, 'Unique' ]      
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
