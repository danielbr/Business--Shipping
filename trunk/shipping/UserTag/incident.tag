UserTag incident AddAttr
UserTag incident Routine 	<<EOR
sub
{
	my ( $opt ) = @_;
	return unless $Variable->{ SYSTEMS_SUPPORT_EMAIL };
	return unless $opt->{ subject } or $opt->{ content };
	
	my $timestamp = $Tag->time();
	my $dump = $Tag->dump();		
	return $Tag->email(
		{
			'to' => $Variable->{ SYSTEMS_SUPPORT_EMAIL },
			'subject' => substr( $opt->{ subject }, 0, 67 ),
		},
			"Date & time:\t$timestamp\n"
		.	"\n"
		.	"User affected:\t" . $Values->{ fname } . " " . $Values->{ lname } . "\n"
		.	"\n"
		.	"\n"
		.	$opt->{ content } . "\n"
		.	"\n"
		.	$dump
	);
}
EOR
