package Business::Ship::UPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Business::Ship::Package;
use Data::Dumper;
@ISA = qw( Business::Ship::Package );

# Compared to USPS, UPS doesn't carry much data at the Package level.	
my %options_defaults = (
	id			=> undef,
	service		=> undef,
	packaging	=> undef,
);

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = $class->SUPER::new();
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	$self->set( @_ );
	#$self->compatibility_map( %compatibility_map );
	bless( $self, $class );
	
	return $self;
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
