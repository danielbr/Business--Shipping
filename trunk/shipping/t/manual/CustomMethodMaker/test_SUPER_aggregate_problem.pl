#!/usr/bin/perl
use strict;
use warnings;

#####################################################################
##  Bug
#####################################################################
package Bug;
sub new { bless {}, shift }
sub required
{ 
    my @required = ( 'id', 'type', 'description' ); 
    return @required;
}

#####################################################################
##  FixedBug
#####################################################################
package FixedBug;
use base ( 'Bug' );
sub new { bless {}, shift }
sub required
{
    my @required = ( 
                    'date_fixed', 'repairer', 
                    shift->SUPER::required() 
                   );
    return @required;
}

#####################################################################
##  Main
#####################################################################
package Main;
my $fixed_bug = FixedBug->new();
print join( ', ', $fixed_bug->required() ) . "\n";
