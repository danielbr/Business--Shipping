#!/usr/bin/perl

use strict;
use warnings;

use TestChild;

my $test_custom_method_maker = TestChild->new();

# Should print:
# "parent_required1, parent_required2, child_required1, child_required2 
print join( ', ', $test_custom_method_maker->required() ) . "\n";

# Should print:
# "parent_optional1, parent_optional2, child_optional1, child_optional2 
print join( ', ', $test_custom_method_maker->optional() ) . "\n";