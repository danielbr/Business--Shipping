# Business::Shipping::RateRequest::Offline - Placeholder.
#
# $Id: Offline.pm,v 1.2 2003/12/22 03:49:06 db-ship Exp $
#
# Copyright (c) 2003 Kavod Technologies, Dan Browning. 
#
# All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
#

package Business::Shipping::RateRequest::Offline;

use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
use base ( 'Business::Shipping::RateRequest' );

use Business::Shipping::RateRequest;
use Business::Shipping::Shipment;
use Business::Shipping::Package;
use Business::Shipping::Debug;

use Business::Shipping::CustomMethodMaker
	new_with_init => 'new',
	new_hash_init => 'hash_init',
	grouped_fields_inherit => [
		#
		# Nothing?
		#
	];
	
# We don't have online things to request.
sub perform_action {}

1;
