#!/bin/perl

package ABC;

use Class::MethodMaker
    [ new    => 'new',
      scalar => [ 'tx_type', 'error_msg' ],
      scalar => [ { -static => 1, -default => 'shipper from_zip to_zip' }, 'Optional' ],
    ];
    
    # So, for array structures, the default applies to each element of the array, not the array itself.


package main;

import ABC;

my $abc = ABC->new;
my $Optional = $abc->Optional;
print "Optional = \'$Optional\'\n";


