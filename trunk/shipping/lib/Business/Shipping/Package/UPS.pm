# Business::Shipping::Package::UPS
# 
# $Id: UPS.pm,v 1.5 2004/01/21 22:39:53 db-ship Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Package::UPS;

$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use strict;
use warnings;
use base ( 'Business::Shipping::Package' );
use Business::Shipping::CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields_inherit => [
		optional => [ 'packaging' ],
		unique => [ 'packaging' ],
	];

1;
