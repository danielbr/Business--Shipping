ifndef USERTAG_INCIDENT
Variable USERTAG_INCIDENT 1
Message -i Loading [incident] usertag...
UserTag incident AddAttr
UserTag incident Routine     <<EOR
=head1 NAME

[incident] - Incident Alert UserTag

=head1 SYNOPSIS

ITL:

[incident
    subject=""
    content=""
]

Or, use Perl:

$Tag->incident(
    {
        subject => "",
        content => "",
    }
);

=cut
sub
{
    my ( $opt ) = @_;
    return unless $Variable->{ SYSTEMS_SUPPORT_EMAIL };
    return unless $opt->{ subject } or $opt->{ content };
    
    my $timestamp = $Tag->time();
    my $dump = $Tag->dump();
    my $user = "User affected:\t" . $Values->{ fname } . " " . $Values->{ lname } . "\n" if $Session->{ logged_in };
    
    return $Tag->email(
        {
            'to' => $Variable->{ SYSTEMS_SUPPORT_EMAIL },
            'subject' => substr( $opt->{ subject }, 0, 67 ),
        },
            "Date & time:\t$timestamp\n"
        .    $user
        .    "\n"
        .    "\n"
        .    $opt->{ content } . "\n"
        .    "\n"
        .    $dump
    );
}
EOR
Message ...done.
endif
