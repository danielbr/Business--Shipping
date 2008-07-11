ifndef USERTAG_INCIDENT
Variable USERTAG_INCIDENT 1
Message -i Loading [incident] usertag...
UserTag incident AddAttr
UserTag incident Routine     <<EOR
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
=head1 NAME

[incident] - Interchange usertag for incident alerts

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

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut

EOR
Message ...done.
endif
