ifndef USERTAG_UPS_QUERY
Variable USERTAG_UPS_QUERY     1
Message Loading [ups-query] usertag (compatiblity layer over [business-shipping])...

UserTag  ups-query  Order  mode origin zip weight country
UserTag  ups-query  addAttr
UserTag  ups-query  Routine <<EOR
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#
# $Id$

=head1 NAME

[ups-query] - Interchange usertag for compatiblity (a layer over [business-shipping]).

=cut

sub 
{
    my( $mode, $origin, $zip, $weight, $country, $opt) = @_;
    my %opt = %$opt;
    return $Tag->business_shipping(
        mode       => 'UPS_Offline',
        service    => $mode,
        weight     => $weight,
        to_zip     => $zip,
        to_country => $country,
        %opt,
    );
}

__END__

=head1 AUTHOR

Daniel Browning, db@endpoint.com, L<http://www.endpoint.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2008 Daniel Browning <db@endpoint.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut

EOR
endif
