# Business::Shipping::RateRequest::Offline::Template - Cost estimation template
# 
# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::RateRequest::Offline::Template;

=head1 NAME

Business::Shipping::RateRequest::Offline::Template - Cost estimation template

=head1 DESCRIPTION

Useful for creating new modules.

=head1 METHODS

=over 4 
    
=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use base ( 'Business::Shipping::RateRequest::Offline' );
use Business::Shipping::Logging;
use Business::Shipping::Config;
#use Business::Shipping::Shipment::Template;

use Class::MethodMaker 2.0
    [
      new => [ qw/ -hash new / ],
      scalar => [ { -static => 1, -default => 'arg1' },       'Required' ],
      scalar => [ { -static => 1, -default => 'arg2, arg3' }, 'Optional' ],
      scalar => [ { -default => 'foo' },                      'arg2'     ],
      #scalar => [ { -type    => 'Business::Shipping::Shipment::Template',
      #              -forward => [
      #                            'arg4',
      #                            'arg5'
      #                          ],
      #             },
      #                                                         'shipment'
      #          ],
      #scalar => [ { -static => 1, 
      #              -default => 'shipment=>Business::Shipping::Shipment::Template' 
      #            }, 
      #                                                         'Has_a' 
      #          ],
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
