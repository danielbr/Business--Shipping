  package Simple;

  use Class::MethodMaker
    get_set       => [qw(a b)],
    new_with_init => 'new';
    new_hash_init => 'hash_init';

  use constant INSTANCE_DEFAULTS => (a => 7, b => 'default') ;

  sub init  {
    my $self   = shift;
    my %values = (INSTANCE_DEFAULTS, @_);
    $self->hash_init(%values);
    return;
  }



  use Simple;
  my $test = Simple->new;             # now a==7, b==default
  my $test = Simple->new(a=>1);       # now a==1, b==default.
  my $test = Simple->new(a=>1, b=>2); # now a==1, b==2.


