#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';

package Y;
use Class::MethodMaker [ scalar => [ 'ymeth' ], new => [ 'new' ] ];
1;

package Bob;
use Class::MethodMaker
    [new => 'new',
     scalar => [{ -type         => 'Y',
                  -default_ctor => 'new' },
                'df3',
               ]
    ];
1;

package main;

my $bob = Bob->new();
$bob->df3->ymeth( 'val2' );
print "bob->df3->ymeth = " . $bob->df3->ymeth . "\n";

ok( $bob->df3->ymeth eq 'val2', "default_ctor works" );

# Now test for default_ctor on array objects, see if it populates the array

package Tiny;
use Class::MethodMaker [ scalar => [ 'tmeth' ], new => [ 'new' ] ];
1;

package Collection;
use Class::MethodMaker
    [new => 'new',
     array => [{ -type         => 'Tiny',
                 -default_ctor => 'new' },
                'collection_of_tinies',
               ]
    ];
1;

package main;

my $collection = Collection->new();
$collection->collection_of_tinies_index( 0 )->tmeth( 'val3' );
ok( $collection->collection_of_tinies_index( 0 )->tmeth() eq 'val3', "default_ctor works on array objects" );


