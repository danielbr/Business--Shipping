use strict;
use warnings;

use Business::Shipping::DataTools;
#Business::Shipping::Logging->log_level( 'debug' );
my $dt = Business::Shipping::DataTools->new( 
    download => 1,
    unzip => 1,    
    convert => 1,
);

$dt->do_update;

#svn stat | grep \? | xargs rm
