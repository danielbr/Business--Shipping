package Business::Ship::USPS::Package;
use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = sprintf("%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Business::Ship::Package;
@ISA = qw( Business::Ship::Package );

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = $class->SUPER::new();
	
	my %options_defaults = qw/
		service		undef
		pounds		undef
		ounces		0
		container	None
		size		Regular
		machinable	False
	/;
	
	$self->build_subs( keys %options_defaults );
	$self->set( %options_defaults );
	
	bless( $self, $class );
	
	return $self;
}

1;
