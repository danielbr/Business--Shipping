#!/usr/bin/perl

package CustomMethodMaker;

use strict;
use warnings;

use base ( 'Class::MethodMaker' );

=head2 grouped_fields_inherit

Works like grouped_fields, except that it also calls the parent.  For
example:

grouped_fields => [
	required => [ 'r1', 'r2' ],
	optional => [ 'o1', 'o2' ]
];

$self->optional() results in $self->SUPER::optional(), then $self->optional().

=cut

# Slightly modified 'grouped_fields' function 
sub grouped_fields_inherit {
  my ($class, %args) = @_;
  my %methods;
  foreach (keys %args) {
    my @slots = @{$args{$_}};
    $class->get_set(@slots);
    
	my $method_name = $_;
	print "\tmethod_name = $method_name\n";
	$methods{$_} = sub {
		my ( $self ) = @_;
        print "self = $self\n" if $self;
		
		# @slots = ( 'abc', 'def', 'ghi' )
		# @slots
		#print "class is $class\n";
		#print "slots are " . join( ', ', @slots ) . "\n";
		#my @breakup = split( '::', $class );
		#pop @breakup;
		#my $real_class = join( '::', @breakup );
		#print "real class = $real_class\n";
		
		my @parent_slots = ();
		if ( $self->can( "SUPER::$method_name" ) ) {
			print "going to execute \$self->SUPER::$method_name()\n";
			#eval "$self->SUPER::$method_name()";
			#my $to_execute = "SUPER::$method_name";
			#@parent_slots = $self->$to_execute();
			
			#eval "$self->SUPER::$method_name()";
			die $@ if $@;
			#@parent_slots = Business::Shipping::$method_name();
		}
		
		#if ( $self->can( "SUPER::$_" ) ) {
		#	@parent_slots = $self->SUPER::$_;
		#}
		print $@ if $@;
		
		return ( @parent_slots, @slots );
	};
	
  }
  $class->install_methods(%methods);
}

package TestParent;

use CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields_inherit => [
		required => [ 'parent_required_1', 'parent_required_2' ],
		optional => [ 'parent_optional_1', 'parent_optional_2' ]
	];

package TestChild;

use CustomMethodMaker
	new_hash_init => 'new',
	grouped_fields_inherit => [
		required => [ 'child_required_1', 'child_required_2' ],
		optional => [ 'child_optional_1', 'child_optional_2' ]
	];

package main;

use TestChild;

my $test_custom_method_maker = TestChild->new();

# Should print:
# "parent_required1, parent_required2, child_required1, child_required2 
print join( ', ', $test_custom_method_maker->required() ) . "\n";

# Should print:
# "parent_optional1, parent_optional2, child_optional1, child_optional2 
print join( ', ', $test_custom_method_maker->optional() ) . "\n";
