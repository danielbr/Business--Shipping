package Business::Ship::Package;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use Business::Ship;

sub new
{
	my( $class, %arg ) = @_;
	
	my %options_defaults = (
		from_zip	=> undef,
		to_zip		=> undef,
		weight		=> undef,
	);
	
	my $self = bless( {}, $class );
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	
	return $self;
}

sub build_subs
{
	my $self = shift;
    foreach( @_ ) {
		unless ( $self->can( $_ ) ) {
			eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }";
		}
    }
	return;
}

sub set
{
    my( $self, %args ) = @_;
	
    foreach my $key ( keys %args ) {
		if( $self->can( $key ) ) {
			$self->$key( $args{ $key } );
		}
		else {
			Carp::carp( "$key not valid" );
		}
	}
}

1;
