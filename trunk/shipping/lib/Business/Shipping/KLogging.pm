package Business::Shipping::KLogging;

=head1 NAME

Business::Shipping::KLogging - Logging interface

=head1 DESCRIPTION

Wrapper for Log::Log4perl.  Must be initialized before use.  Recommend usage is
via your own wrapper.  See Business::Shipping::Logging as an example wrapper.

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };

use strict;
use warnings;
use Carp;
use Log::Log4perl;

$Business::Shipping::KLogging::Current_Level = 'WARN';
@Business::Shipping::KLogging::Levels = ( 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL' );

=item * debug

=item * debug1

=item * debug2

=item * debug3

For long debug messages (entire XML output, etc.).  Prepends "debug3" to the 
category, allowing the user to filter out very verbose debug messages in 
config/log4perl.conf.

=item * trace

=item * info

=item * warn

=item * error

=item * fatal

=cut

# Creates subs like the following:
# 
# sub debug3 { _log( { priority => 'debug', prepend => 'debug3' }, @_ ); }
BEGIN
{
    # Format:     
    #   sub_name   priority:prepend_text
    
    my %subs = qw( 
        debug      debug
        debug1     debug
        debug2     debug:debug2
        debug3     debug:debug3
        trace      debug:trace1
        trace1     debug:trace1
        trace2     debug:trace2
        trace3     debug:trace3
        returning  debug:returning1
        returning1 debug:returning1
        returning2 debug:returning2
        returning3 debug:returning3
        info       info
        warn       warn
        error      error
        fatal      fatal
        logdie     logdie
        logwarn    logwarn
    );
    my @subs = sort keys %subs;
    
    sub subs
    {
        return ( @subs, 'uneval' );
    }
    
    while ( my ( $sub_name, $parameters ) = each %subs ) {
        my ( $priority,$prepend ) = split( ':', $parameters );
        $prepend = $prepend ? $prepend . '::' : '';
        eval "
            sub $sub_name 
            {
                my \$opts;
                my \@msg;

                \$opts->{ priority } = '$priority';
                \$opts->{ prepend  } = '$prepend'; 
                
                # If first element is a hash, add the options to our hash. 
                
                my \$ref_element_1 = ref \$_[ 0 ];
                if ( \$ref_element_1 and \$ref_element_1 eq 'HASH' ) {
                    my \$in_opts = shift;
                    foreach my \$opt ( keys \%\$in_opts ) {
                        \$opts->{ \$opt } = \$in_opts->{ \$opt };
                    }
                }

                \@msg = \@_;
                
                _log( 
                    \$opts,
                    \@_ 
                );
            }
        ";
    }
}

=item * init( %opt )

Arguments:

 file         => 'path/to/file',   # Required
 caller_depth => $interger,        # Optional
 once         => true/false        # Optional

caller_depth:

If you are using one wrapper on top of this module, the caller_depth should be
set to 2.  For example:

 Log::Log4perl
  |
  |
 Business::Shipping::KLogging
  |
  |
 MyNameSpace::Logging
 
once:
 
 If true, calls init_once (which ignores any settings if init has already been
 called once).
 
=cut

sub init
{
    my ( %opt ) = @_;
    
    my $file         = $opt{ file         };
    my $caller_depth = $opt{ caller_depth };
    my $once         = $opt{ once         };
    
    if ( not $file ) {
        carp "file arg required.";
        return;
    }
    
    if ( -f $file ) { 
        if ( $once )
          { Log::Log4perl::init_once( $file ); }
        else 
          { Log::Log4perl::init( $file ); }
    }
    else
        { croak "Could not get log4perl config file: $file"; }
        
    ${Log::Log4perl::caller_depth} = $caller_depth if $caller_depth;
    
    return;    
}

=item * _log

Private function.

Automatically uses the package name and subroutine as the log4perl 'category'.

=cut

sub _log
{
    my ( $opt ) = shift;
    
    $opt->{ priority        } ||= 'debug';
    $opt->{ prepend         } ||= '';
    $opt->{ append          } ||= '';
    $opt->{ call_lev        } ||= 1;
    
    if ( $opt->{ caller_depth_modifier } ) {
        ${Log::Log4perl::caller_depth} += $opt->{ caller_depth_modifier };
    }
 
    my ( $package, $filename, $line, $sub ) = caller( $opt->{ call_lev } );

    $opt->{ caller_package  } = $package  if not defined $opt->{ caller_package  };
    $opt->{ caller_filename } = $filename if not defined $opt->{ caller_filename };
    $opt->{ caller_line     } = $line     if not defined $opt->{ caller_line     };
    $opt->{ caller_sub      } = $sub      if not defined $opt->{ caller_sub      };
    
    my $category = $opt->{ prepend        } 
                 . $opt->{ caller_package }
                 . $opt->{ caller_sub     }
                 . $opt->{ append         };
    my $priority = $opt->{ priority       };
    
    my $logger   = Log::Log4perl->get_logger( $category );
    
    # TODO: Allow overrides.
    # $logger->disable_all() if $Quiet.   
    
    my $return   = $logger->$priority( @_ );
    
    if ( $opt->{ caller_depth_modifier } ) {
        ${Log::Log4perl::caller_depth} -= $opt->{ caller_depth_modifier };
    }
    
    return $return; 
}

=item * uneval( ... )

Takes any built-in object and returns the perl representation of it as a string
of text.  It was copied from Interchange L<http://www.icdevgroup.org>, written 
by Mike Heins E<lt>F<mike@perusion.com>E<gt>.  

=cut

sub uneval { 
    my ( $self, $o ) = @_;        # recursive
    my ( $r, $s, $i, $key, $value );

    local($^W) = 0;
    no warnings; #supress 'use of unitialized values'
    
    $r = ref $o;
    if (!$r) {
        $o =~ s/([\\"\$@])/\\$1/g;
        $s = '"' . $o . '"';
    } 
    elsif ($r eq 'ARRAY') {
        $s = "[";
        foreach $i (0 .. $#$o) {
            $s .= uneval($o->[$i]) . ",";
        }
        $s .= "]";
    }
    elsif ($r eq 'HASH') {
        $s = "{";
        while (($key, $value) = each %$o) {
            $s .= "'$key' => " . uneval($value) . ",";
        }
        $s .= "}";
    } 
    else {
        $s = "'something else'";
    }

    $s;
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

Sub uneval copyright (c) 2002-2003 Interchange Development Group.

=cut
