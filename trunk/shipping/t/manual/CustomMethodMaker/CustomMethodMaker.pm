############################################################################
## CustomMethodMaker.pm
############################################################################

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
	$methods{$_} = sub {
		my $self = shift;
		my @parent_slots = ();
		
		if	( 
			#	$self
			#and $method_name 
			#and $self->can( "SUPER::$method_name" )
			1
			) 
		{
			my $to_exec = "SUPER::$method_name";
			#print "going to execute \$self->$to_exec()\n";
			@parent_slots = $self->$to_exec();
		}
		return ( @parent_slots, @slots );
	};
	
  }
  $class->install_methods(%methods);
}

1;

