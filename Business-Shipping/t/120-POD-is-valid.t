#!/bin/env perl

# Check that all POD is valid with Test::POD.

use strict;
use warnings;
use Test::More;

eval { require Test::Pod };
plan skip_all => 'Test::Pod not installed.' if $@;
import Test::Pod;
all_pod_files_ok();
