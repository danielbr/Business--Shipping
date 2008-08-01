package Business::Shipping::Logging;

=head1 NAME

Business::Shipping::Logging - Log4perl wrapper for easy, non-OO usage.

=head1 VERSION

2.2.0

=head1 METHODS

=cut

use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT @Levels $Current_Level);
use Carp;
use Log::Log4perl;
use Business::Shipping::Config;
use version; our $VERSION = qv('2.2.0');

$Current_Level = 'WARN';
@EXPORT = qw(
    fatal    is_fatal    logdie 
    error    is_error
    warn     is_warn     logwarn
    info     is_info 
    debug    is_debug
    trace    is_trace
);

init();

1;

=head2 init

Build wrapper on top of Log4perl, increasing caller_depth to one:

 Business::Shipping::UPS_Offline::RateRequest::debug()
  |
  |
 Business::Shipping::Logging::debug()
  |
  |
 Log::Log4perl->logger->DEBUG()

=cut

# TODO: Should assume some basic configuration when the file isn't available.

sub init {
    my $config_dir = Business::Shipping::Config::config_dir();
    return carp "Could not find config directory." unless defined $config_dir;

    my $file =  "$config_dir/log4perl.conf";
    return croak "Could not get log4perl config file: $file" unless -f $file;
    
    Log::Log4perl::init($file);
    ${Log::Log4perl::caller_depth} = 2;

    return;
}

sub logdie   { _log('logdie',  @_); }
sub logwarn  { _log('logwarn', @_); }

sub fatal    { _log('fatal', @_); }
sub error    { _log('error', @_); }
sub warn     { _log('warn',  @_); }
sub info     { _log('info',  @_); }
sub debug    { _log('debug', @_); }
sub trace    { _log('trace', @_); }

sub is_fatal { _log('is_fatal' ); }
sub is_error { _log('is_error' ); }
sub is_warn  { _log('is_warn'  ); }
sub is_info  { _log('is_info'  ); }
sub is_debug { _log('is_debug' ); }
sub is_trace { _log('is_trace' ); }

=head2 _log

Automatically uses the package name and subroutine as the log4perl 'category'.

=cut

sub _log {
    my $priority = shift;
    
    # Not using $line currently.
    my ($package, $filename, undef, $sub) = caller(1);
    my $category = $package . $sub;
    my $logger = Log::Log4perl->get_logger($category);
    
    return $logger->$priority(@_);
}

=head2 log_level()

Does the heavy lifting for Business::Shipping->log_level().

=cut

sub log_level {
    my ($class, $log_level) = @_;
    return unless $log_level;

    $log_level = lc $log_level;
    if (grep($log_level, @Levels)) {
        $Current_Level = $log_level;
    }
    Business::Shipping::Logging::init();

    return $log_level;
}

__END__

=head1 AUTHOR

Daniel Browning, db@endpoint.com, L<http://www.endpoint.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2008 Daniel Browning <db@endpoint.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
