#####################################################################
##  CustomMethodMaker
#####################################################################
package Business::Shipping::CustomMethodMaker;
use base ( 'Class::MethodMaker' );

=head2 grouped_fields_inherit

Works like grouped_fields, except that it also calls the parent class.

=cut
sub grouped_fields_inherit {
  my ($class, %args) = @_;
  my %methods;
  foreach (keys %args) {
    my @slots = @{$args{$_}};
    $class->get_set(@slots);
	my $method_name = $_;
	my $caller = $class->find_target_class();
	$methods{$_} = sub {
		my $self = shift;
		#
		#print "installing $method_name() in $caller...\n";
		#
		# Without $caller and eval, the following line causes this error:
		# 
		# Can't locate auto/CustomMethodMaker/SUPER/[METHOD].al in @INC
		#
		my @parent_slots = eval "
			package $caller;
			if ( \$self->can( SUPER::$method_name ) ) {
				return \$self->SUPER::$method_name( \@_ );
			}
			else {
				return ( );
			}
			1;
		";
		die $@ if $@;
		return ( @parent_slots, @slots );
	};
  }
  $class->install_methods(%methods);
}

1;
