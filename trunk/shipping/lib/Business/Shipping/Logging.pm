# Business::Shipping::Logging - Logging interface
# 
# $Id: Logging.pm,v 1.1 2004/03/31 19:11:05 danb Exp $
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
# 

package Business::Shipping::Logging;

=head1 NAME

Business::Shipping::Logging - Logging interface

=head1 VERSION

$Revision: 1.1 $      $Date: 2004/03/31 19:11:05 $

=head1 DESCRIPTION

Wrapper for Log::Log4perl.  Default configuration file: "config/log4perl.conf". 

=head1 METHODS

=over 4

=cut

$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
@EXPORT = qw( debug debug1 debug2 debug3 trace info warn error fatal );

use strict;
use warnings;
use base ( 'Exporter' );
use Log::Log4perl;

_init_once();

=item * debug

=item * debug1

=item * debug2

=item * debug3

=item * trace

=item * info

=item * warn

=item * error

=item * fatal

=cut

# 
# Creates subs like the following:
# 
# sub debug3 { _log( { priority => 'debug', append => 'debug3' }, @_ ); }
#
BEGIN {
    #
    # Format:     
    #   sub_name priority:prepend_text
    #
    my %subs = qw( 
        debug    debug
        debug1   debug
        debug2   debug:debug2
        debug3   debug:debug3
        trace    debug
        info     info
        warn     warn
        error    error
        fatal    fatal
    );
    
    while ( my ( $sub_name, $parameters ) = each %subs ) {
        my ( $priority, $prepend ) = split( ':', $parameters );
        $prepend = $prepend ? $prepend . '::' : '';
        eval "sub $sub_name { _log( { priority => '$priority', prepend => '$prepend' }, \@_ ); }";
    }
    
}

=item * _init_once

Private function.

Loads configuration and does other setup tasks.

=cut

#
# TODO: Add config directory path.
#
sub _init_once
{
    my $file = 'config/log4perl.conf';
    
    if ( -f $file )
        { print STDERR Log::Log4perl::init_once( 'config/log4perl.conf' ) . "\n"; }
    else 
        { die "Could not get log4perl config file: $file"; }
        
    $Log::Log4perl::caller_depth = 2;
    
}

=item * _log

Private function.

Uses logger assigned to name. 

Automatically uses the package name (e.g. Business::Shipping::Shipment::UPS) as
the log4perl 'category'.

=cut
sub _log
{
    my ( $opt ) = shift;
    
    $opt->{ priority } ||= 'debug';
    $opt->{ prepend  } ||= '';
    $opt->{ append   } ||= '';
    $opt->{ package  }   = caller( 1 );
    
    my $category = $opt->{ prepend  } 
                 . $opt->{ package  }
                 . $opt->{ append   };
    my $priority = $opt->{ priority };
    my $logger   = Log::Log4perl->get_logger( $category );
    my $return   = $logger->$priority( @_ );
    
    return $return; 
}
    
1;

__END__

=back

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut
