# Business::Shipping::Package::UPS
# 
# $Id: UPS.pm,v 1.1 2003/07/07 21:37:59 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Package::UPS;

use strict;
use warnings;

use vars qw( @ISA $VERSION );
@ISA = ( 'Business::Shipping::Package' );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Business::Shipping::Debug;
use Class::MethodMaker
	new_hash_init => 'new',
	grouped_fields => [
		optional => [ 'packaging' ],
	];

#sub packaging
#{
#	return 'packaging needs to be defined';
#}
	
1;
