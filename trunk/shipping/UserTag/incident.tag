UserTag incident Order		error
UserTag incident Routine 	<<EOR
sub
{
	my ( $error ) = @_;
	
	return unless $Variable->{ SYSTEMS_SUPPORT_EMAIL }
	
	my $timestamp = $Tag->time();
	my $dump = $Tag->dump();		
	return $Tag->email(
		{
			'to' => $Variable->{ SYSTEMS_SUPPORT_EMAIL },
			'subject' => substr( $error, 0, 67 ),
		},
			"Date & time: $timestamp\n"
		.	"\n"
		.	"User affected: " . $Values->{ fname } . " " . $Values->{ lname } . "\n"
		.	"\n"
		.	$error . "\n"
		.	"\n"
		.	$dump
	);
}
EOR
