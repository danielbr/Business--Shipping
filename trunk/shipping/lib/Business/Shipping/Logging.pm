=head1 NAME

Business::Shipping::Logging - Interface between KLogging and Business::Shipping

=head1 VERSION

$Rev $

=head1 DESCRIPTION

Wrapper for KLogger.

=head1 METHODS

=cut

package Business::Shipping::Logging;

use strict;
use warnings;
use base ( 'Exporter' );
use vars ( '@EXPORT', '$VERSION'  );
use Business::Shipping::KLogging;
use Business::Shipping::Config;

@EXPORT = Business::Shipping::KLogging::subs;
$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

foreach my $_sub ( Business::Shipping::KLogging::subs ) {
    eval "\*$_sub = \*Business::Shipping::KLogging::$_sub";
}

*trace    = *Business::Shipping::KLogging::debug;

my $file         = Business::Shipping::Config::support_files()
                 . '/config/log4perl.conf';
my $caller_depth = 2;

bs_init();

=head2 bs_init()

Initializes KLogging with values from Business::Shipping::Config.

=cut

sub bs_init
{
    Business::Shipping::KLogging::init(
        file         => $file,
        caller_depth => $caller_depth,
        once         => 0,              #disabled for event_handlers() support
    );
    
    return;
}

=head2 log_level()

Does the heavy lifting for Business::Shipping->log_level().

=cut

sub log_level
{
    my ( $class, $log_level ) = @_;
    
    return unless $log_level;
    
    $log_level = uc $log_level;
    
    if ( grep( $log_level, @Business::Shipping::KLogging::Levels ) ) 
        { $Business::Shipping::KLogging::Current_Level = $log_level; }
    
    Business::Shipping::Logging::bs_init();
    
    return $log_level;
}

1;

__END__

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
