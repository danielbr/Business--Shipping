package Business::Shipping::CustomMethodMaker;

use strict;
use warnings;

use base ( 'Class::MethodMaker' );

=head2 grouped_fields_inherit

Works like grouped_fields, except that it also calls the parent.  For
example:

grouped_fields => [
	optional => [ 'abc', 'def', 'ghi' ],
	required => [ 'a12', 'd12', 'g12' ]
];

$self->optional() results in ->SUPER::optional(), then $self->optional().

=cut

sub grouped_fields_inherit {
  my ($class, %args) = @_;
  my %methods;
  foreach (keys %args) {
    my @slots = @{$args{$_}};
    $class->get_set(@slots);
    
	my $method_name = $_;
	#print "\tmethod_name = $method_name\n";
	$methods{$_} = sub {
		my ( $self ) = @_;
        #print "self = $self\n" if $self;
		
		# @slots = ( 'abc', 'def', 'ghi' )
		# @slots
		#print "class is $class\n";
		#print "slots are " . join( ', ', @slots ) . "\n";
		#my @breakup = split( '::', $class );
		#pop @breakup;
		#my $real_class = join( '::', @breakup );
		#print "real class = $real_class\n";
		
		my @parent_slots = ();
		if ( $self->isa( 'Business::Shipping::RateRequest' ) ) {
			#print "going to execute \$self->SUPER::$method_name()\n";
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
		#print $@ if $@;
		
		return ( @parent_slots, @slots );
	};
	
  }
  $class->install_methods(%methods);
}

1;
