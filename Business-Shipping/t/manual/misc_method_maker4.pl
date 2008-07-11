#!/usr/bin/perl

package Bob;

use Class::MethodMaker
    [
      new  => [ qw/ -hash new / ],
      scalar => [ 'jane', 'jack', 'fred' ]
    ];
    
package main;

import Bob;

my $bob = Bob->new( jane => '123', jack => '456' );

print "jane = " . $bob->jane . "\n";
print "jack = " . $bob->jack . "\n";
print "fred = " . $bob->fred . "\n";
