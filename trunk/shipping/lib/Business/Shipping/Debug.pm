# Business::Shipping::Debug - Compatibility wrapper for Logging.  Depreciated.
# 
# $Id$
# 
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved. 
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#

package Business::Shipping::Debug;

=head1 NAME

Business::Shipping::Debug - Compatibility wrapper for Logging.  Depreciated.

=head1 VERSION

$Rev$      $Date$

=head1 SYNOPSIS

 use Business::Shipping::Logging;
 
 trace "called with parameters: $x, $y, and $z";
 debug "value of x = $x";
 log_error "encountered invalid data: $x";
 debug3 "here is a big list of all the potential data values: $big_list";

=head1 DESCRIPTION

Note that this module has been depreciated.  Business::Shipping::Logging is the
correct module to use now.  What is left here is a compatibility wrapper, and it
may disappear in a future version.

Aside from the usual stuff, these functions have been speciall mapped:

    error_log => error 
    error     => moved to Shipping::user_error  
                 ('user_error' calls error, but also logs the message for 
                 display to the user).
    uneval    => moted to Util::uneval
                           

So, for compatibility, the 'error' sub here replaces the one that was normally
at Business::Shipping::error() (now called 'user_error()' ).

'uneval', on the other hand, should never have been here in the first place.
    
Exports several functions useful for logging debug messages, trace information, 
or error messages.

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };
@EXPORT = qw( debug debug3 trace log_error error );

use strict;
use warnings;
use base ( 'Exporter' );
use Business::Shipping::Logging;

{
    my @_compat = qw( debug debug1 debug2 debug3 trace info warn fatal );
    
    foreach my $_compat ( @_compat ) {
        eval "\*$_compat = \*Business::Shipping::Logging::$_compat";
    }
    
    *log_error = *Business::Shipping::Logging::error;
    *error     = *Business::Shipping::user_error;
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
