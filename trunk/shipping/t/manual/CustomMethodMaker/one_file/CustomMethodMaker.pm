###############################################################################
##  CustomMethodMaker
##  (must be in it's own file, due to the fact that it has to be 'used'.
###############################################################################
package CustomMethodMaker;
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



=head2 list_inherit

Works like list, except that it also calls the parent class.

=cut
sub list_inherit {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;
	my $caller = $class->find_target_class();

    $methods{$field} =
      sub {
        my $self = shift;
		my ( @list ) = @_;
		
        defined $self->{$field} or $self->{$field} = [];

        # Maintain any existing reference (avoid replacing)
        @{$self->{$field}} = map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @list
          if @list;
		
		print "\ninstalling $field() in $caller...\n";
		use vars ( '@ISA' );
		print "Before, ISA = @ISA\n";
		if ( wantarray ) {
			print "wants array, running eval...\n";
			my @parent_slots = eval "
				package $caller;
				use vars ( '\@ISA' );
				my \$myclass = qq{\@ISA};
				print qq{ Bug::unique() = } . \@{ Bug::unique() } . qq{\n};
				if ( \$self->can( SUPER::$field ) ) {
					print qq{yes, I can execute SUPER\n};
					return \$self->SUPER::$field( \@_ );
				}
				else {
					print qq{no, I cannot execute SUPER, returning empty list\n};
					return ( );
				}
				1;
			";
			die $@ if $@;
			print "Parent stuff = " . join( ', ', @parent_slots ) . "\n";
			return wantarray ? ( @parent_slots, @{ $self->{ $field } } ) : $self->{$field};
		}
		else {
			print "Doens't want array\n";
		}
		print "returning...\n";
        return wantarray ? @{$self->{$field}} : $self->{$field};
      };

    $class->_add_list_methods(\%methods, $field);

    #
    # Deprecated. v0.95 1.vi.00
    #
    $methods{"${field}_ref"} =
      sub {
        my ($self) = @_;
        $self->{$field};
      };

  }
  $class->install_methods(%methods);
}


1;
