#!/usr/bin/perl
use strict;
use warnings;

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
use Class::MethodMaker
    new_hash_init => 'new',
    grouped_fields => [ 
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
