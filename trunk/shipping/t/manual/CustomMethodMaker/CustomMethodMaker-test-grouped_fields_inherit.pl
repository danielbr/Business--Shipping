#!/usr/bin/perl
use strict;
use warnings;

=pod
Creating a simple test module that installs the SUPER-calling method into 
the example which doesn't use Class::MethodMaker would tell you if the 
issue is actually with using SUPER outside the base class, though, so 
that's maybe a good avenue to explore.
=cut

# See CustomMethodMaker.pm

###############################################################################
##  Bug
###############################################################################
package Bug;
use Class::MethodMaker
    new_hash_init => 'new',
    grouped_fields => [ 
        'required' => [ 'id', 'type', 'description' ],
        'optional' => [ 'severity' ],
    ];

###############################################################################
##  FixedBug
###############################################################################
package FixedBug;
use base ( 'Bug' );
use CustomMethodMaker
    new_hash_init => 'new',
    grouped_fields_inherit => [ 
        'required' => [ 'date_fixed', 'repairer'  ],
        'optional' => [ 'repair_notes', 'patch_file' ],
    ];

###############################################################################
##  Main
###############################################################################
package Main;

my $bug = Bug->new();
print join( ', ', $bug->required() ) . "\n";
#
# Prints 'id', 'type', 'description'
#

my $fixed_bug = FixedBug->new();
print join( ', ', $fixed_bug->required() )  . "\n";
#
# Prints 'date_fixed', 'repairer' -- but I want it to print:
# 'id', 'type', 'description', 'date_fixed', 'repairer' 
#
