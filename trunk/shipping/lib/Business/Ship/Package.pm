package Business::Ship::Package;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Business::Ship;
use Data::Dumper;

my %options_defaults = (
	from_zip	=> undef,
	to_zip		=> undef,
	weight		=> undef,
	from_country	=> undef,
	response	=> undef,
);
	
sub new
{
	my( $class, %args ) = @_;
	
	my $self = bless( {}, $class );
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	$self->set( %args );
	
	return $self;
}

sub to_country
{
	my $self = shift;	
	if ( @_ ) {
		my $new_to_country = shift;
		$new_to_country = $self->_country_name_translator( $new_to_country );
		$self->{'to_country'} = $new_to_country;
	} 
	return $self->{'to_country'};
}

# Translate common usages (Great Britain) into the USPS proper name
# (Great Britain and Northern Ireland).
sub _country_name_translator
{
	my ( $self, $country ) = @_;
	my %country_translator = (
		'Great Britain' => 'Great Britain and Northern Ireland',
		'United Kingdom' => 'Great Britain and Northern Ireland',
	);
	if ( $country_translator{ $country } ) {
		return $country_translator{ $country };
	}
	else {
		return $country;
	}
}

sub set_price
{
	my ( $self, $service, $price ) = @_;
	$self->{'price'}->{$service} = $price;
	return $self->{'price'}->{$service};	
}

sub get_charges
{
	my ( $self, $service ) = @_;	
	return $self->{'price'}->{$service};	
}


sub is_empty
{
	my $self = shift;
	
	for ( keys %options_defaults ) {
		if ( $self->$_() and $self->$_() ne $options_defaults{ $_ } ) {
			return 0;
		}
	}		
	
	return 1;
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

=pod
# Translate codes ('US') into names ('United States')
# USPS uses the name instead of the code
sub _country_code_to_name
{
	my ( $self, $country_code ) = @_;
		
	return ( $country_code_table{ $country_code } or $country_code );
}
=cut


1;
