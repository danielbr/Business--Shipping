#!/usr/bin/perl
use strict;
use warnings;

=pod
Creating a simple test module that installs the SUPER-calling method into 
the example which doesn't use Class::MethodMaker would tell you if the 
issue is actually with using SUPER outside the base class, though, so 
that's maybe a good avenue to explore.
=cut

# See CustomMethodMaker.pm

###############################################################################
##  Bug
###############################################################################
package Bug;
use CustomMethodMaker
    new_with_init => 'new',
    new_hash_init => 'hash_init',
    grouped_fields_inherit => [
        'required' => [ 'id', 'type' ],
        'unique' => [ 'id', 'type', 'description' ]
    ];
    #list => [ 'unique' ];
    
#use constant INSTANCE_DEFAULTS => (
#    unique => [ 'id', 'type', 'description' ]
#);
 
sub init
{
    my $self   = shift;
    #my %values = ( INSTANCE_DEFAULTS, @_ );
    my %values = ( @_ );
    $self->hash_init( %values );
    return;
}    

###############################################################################
##  FixedBug
###############################################################################
package FixedBug;
use base ( 'Bug' );
use CustomMethodMaker
    new_with_init => 'new',
    new_hash_init => 'hash_init',
    grouped_fields_inherit => [
        'unique' => [ 'date_fixed', 'repairer' ]
    ];
    #list_inherit => [ 'unique' ];
    
#use constant INSTANCE_DEFAULTS => (
    #unique => [ 'date_fixed', 'repairer' ]
#);
 
sub init
{
    my $self   = shift;
    #my %values = ( INSTANCE_DEFAULTS, @_ );
    my %values = ( @_ );
    $self->hash_init( %values );
    return;
}

###############################################################################
##  Main
###############################################################################
package Main;


my $bug = Bug->new();
my @unique = $bug->unique();
print "\n\n\nBug::unique() = ...";
print join( ', ', @unique )  . "\n\n\n\n";

my $fixed_bug = FixedBug->new();
@unique = $fixed_bug->unique();
print "\n\n\nFixedBug::unique() = ...";
print join( ', ', @unique )  . "\n";
