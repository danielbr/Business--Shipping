# Business::Shipping::Config - Configuration Functions.
# 
# $Id: Config.pm,v 1.1 2003/12/22 03:49:05 db-ship Exp $
# 
# Copyright (c) 2003 Kavod Technologies, Dan Browning. All rights reserved. 
# 
# Licensed under the GNU Public Licnese (GPL).  See COPYING for more info.
# 

package Business::Shipping::Config;

use strict;
use warnings;

use vars qw( $VERSION @EXPORT );
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
use base ( 'Exporter', 'Business::Shipping' );
@EXPORT = qw( cfg cfg_obj );
use Config::IniFiles;

my $support_files_dir;
my $main_config_file;

#
# Try the current directory first.
#
if ( -f "config/config.ini" ) {
	$support_files_dir = ".";
}

#
# Then try environment variables
#
$support_files_dir ||= $ENV{ BUSINESS_SHIPPING_SUPPORT_FILES };

#
# Then fall back on the default.
#
$support_files_dir ||= "/var/perl/Business-Shipping";

$main_config_file = "$support_files_dir/config/config.ini";
tie my %cfg, 'Config::IniFiles', ( 		-file => $main_config_file );
my $cfg_obj = Config::IniFiles->new(	-file => $main_config_file );

sub cfg 			{ return \%cfg; 				}
sub cfg_obj			{ return $cfg_obj;				}
sub support_files 	{ return $support_files_dir;	}

1;
__END__
