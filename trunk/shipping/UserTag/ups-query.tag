ifndef DEF_UPS_QUERY
Variable DEF_UPS_QUERY	 1 # Ensures that [ups-query] is only included once.
Message Loading [ups-query] usertag (compatiblity layer over [business-shipping])...

UserTag  ups-query  Order  mode origin zip weight country
UserTag  ups-query  addAttr
UserTag  ups-query  Routine <<EOR
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#
# $Id: ups-query.tag,v 1.5 2004/01/21 22:39:51 db-ship Exp $

=head1 NAME

[ups-query] usertag (compatiblity layer over [business-shipping]).

=head1 AUTHOR 

	Dan Browning <db@kavod.com>
	http://www.kavodtechnologies.com
	
=cut

sub 
{
	my( $mode, $origin, $zip, $weight, $country, $opt) = @_;
	my %opt = %$opt;
	return $Tag->business_shipping(
		mode 			=> 'UPS',
		service			=> $mode,
		weight			=> $weight,
		to_zip			=> $zip,
		to_country		=> $country,
		%opt,
	);
}
EOR
endif
