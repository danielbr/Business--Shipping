#!/usr/bin/perl

use strict;
use warnings;

use Carp;

###############################################################################
##  Parent
###############################################################################
package Parent;

sub new { bless {}, shift }
sub size { "big" }
sub new_subclass
{
    my ( $class, $subclass ) = @_;
    
    Carp::croak "Missing args" unless $class and $subclass;
    
    #$class = $class . '::' . $subclass;
    $class = $subclass;
    if ( not defined &$class ) {
        print "$class not defined, going to import it.\n";
        #eval "require $class";
        #eval "require $class";
        #Carp::croak( "unknown class $class ($@)" ) if $@;
    }
    else {
        print "$class already defined\n";
    }
    #eval "require $class";
    my $new_child = eval "$class->new()";
    
    #use Data::Dumper;    
    #print Dumper( $new_child );
    #$new_rate_request->init( %opt );
    
    return ( $new_child );
}



###############################################################################
##  Child
###############################################################################
package Child;

use vars ( '@ISA' );
@ISA = ( 'Parent' );
sub new { bless {}, shift }
sub size { return shift->SUPER::size . " small" }


###############################################################################
##  main
###############################################################################
package main;

#my $child = Child->new();
#print $child->size() . "\n";

my $child = Parent->new_subclass( 'Child' );
print $child->size();

