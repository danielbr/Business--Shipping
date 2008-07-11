#!/bin/perl

package ABC;

use Class::MethodMaker
    [ new => 'new',
      scalar => [ { -default => '123' }, 'bob' ],
    ];


package main;

import ABC;

my $a = ABC->new();
print $a->bob . "\n";




