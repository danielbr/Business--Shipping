use strict;
use warnings;

use Test::More 'no_plan';
use Carp;

package bob;
use Business::Shipping::CustomMethodMaker
    grouped_fields_inherit => [
        required => [ 'bob', 'jane' ],
        optional => [ 'color', 'speed' ]
    ];


sub mybob
{
    #return shift->required();
    return;
}

package main;

ok(  1, 'CustomMethodMaker loaded' );


