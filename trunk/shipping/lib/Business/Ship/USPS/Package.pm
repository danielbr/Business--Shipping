package Business::Ship::USPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

use Business::Ship::Package;
use Data::Dumper;
@ISA = qw( Business::Ship::Package );

	
my %options_defaults = (
	id			=> undef,
	service		=> undef,
	pounds		=> undef,
	ounces		=> 0,
	container	=> 'None',
	size		=> 'Regular',
	machinable	=> 'False',
	mail_type	=> 'Package',
);

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my %args = @_;
	my $self = $class->SUPER::new();
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	$self->set( %args );
	
	bless( $self, $class );
	
	return $self;
}

# Alias weight to pounds?
# For now, just round weight up to the next pound. :-(
# TODO: calculate correct ounces.
sub weight
{
	my $self = shift;
	$self->{'pounds'} = $self->_round_up( shift ) if @_;
	return $self->{'pounds'};
}

sub _round_up
{
	my $self = shift;
	my $f = shift;
	if ( $f ) {
		return ( sprintf( "%1.0f", $f ) );
	}
	else {
		return ( undef );
	}
}

sub get_unique_values
{
	my $self = shift;
	my @unique_keys = $self->get_unique_keys();
	my @unique_values;
	foreach my $key ( @unique_keys ) {
		push( @unique_values, $self->$key() );
	}
	
	return @unique_values;
}

sub get_unique_keys
{
	my $self = shift;
	my @unique_keys;
	push @unique_keys, ( 
		'service', 'pounds', 'ounces', 'container', 
		'size', 'machinable', 'mail_type', 'to_country',
	);
	return( @unique_keys );
}
1;
