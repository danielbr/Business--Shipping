package Business::Shipping::DataFiles;

use warnings;
use strict;

=head1 NAME

Business::Shipping::DataFiles - Tables for offline cost estimation via Business::Shipping 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

To use any of the Business::Shipping offline cost estimation methods, this 
module is required.  It installs all of the rate tables that Business::Shipping
relies on.  It is stored in a separate module because it is updated less 
frequently than Business::Shipping.

=head1 AUTHOR

Dan Browning, C<< <db@kavod.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-shipping-datafiles@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 Dan Browning, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Business::Shipping::DataFiles
