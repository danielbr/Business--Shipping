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


package MyMethodInstaller;

sub find_target_class {
  # Find the class to add the methods to. I'm assuming that it would be
  # the first class in the caller() stack that's not a subsclass of
  # MethodMaker. If for some reason a sub-class of MethodMaker also
  # wanted to use MethodMaker it could redefine ima_method_maker to
  # return a false value and then $class would be set to it.
  my $class;
  my $i = 0;
  while (1) {
    $class = (caller($i))[0];
    ( $class->isa('Class::MethodMaker')
      and
      &{$class->can ('ima_method_maker')} )
      or last;
    $i++;
  }
  return $class;
}


sub install_methods {
  my ($class, %methods) = @_;

  no strict 'refs';
#  print STDERR "CLASS: $class\n";
  my $TargetClass = $class->find_target_class;
  my $package = $TargetClass . "::";

  my ($name, $code);
  while (($name, $code) = each %methods) {
    # add the method unless it's already defined (which should only
    # happen in the case of static methods, I think.)
    my $reftype = ref $code;
    if ( $reftype eq 'CODE' ) {
      *{"$package$name"} = $code unless defined *{"$package$name"}{CODE};
    } elsif ( ! $reftype ) {
      my $coderef = eval $code;
      croak "Code:\n$code\n\ndid not compile: $@\n"
	if $@;
      croak "String:\n$code\n\ndid not eval to a code ref: $coderef\n"
	unless ref $coderef eq 'CODE';
      *{"$package$name"} = $coderef unless defined *{"$package$name"}{CODE};
    } else {
      croak "What do you expect me to do with this?: $code\n";
    }
  }
}


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
