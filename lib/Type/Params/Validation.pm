package Type::Params::Validation;

use strict;
use warnings;

use Type::Params ();

use Exporter 'import';
our @EXPORT_OK = qw/&compile_named/;

use Try::Tiny;

sub compile_named {
    my @checks = @_;
    my $check = Type::Params::compile_named(@checks);
    
    return sub {
        my @params = @_;
        
        my $args = try {
            $check->(@params);
        };
        return $args if defined $args;
        
        my %params = @params; # original params
        my %checks = _split_compile(@checks);
        
        my %errors;
        foreach my $check_param ( keys %checks ) {
            
            my $check_value = $params{$check_param};
            my $check_check = $checks{$check_param};
            
            try {
                my $value = $check_check->(
                    exists( $params{$check_param} ) ?
                    ( $check_param => $check_value ) : ()
                );
                # seems to be all fine
            } catch {
                my $exception = $_;
                my $error;
                if ( $exception->message =~ /missing/i ) {
                    require Error::TypeTiny::MissingRequired;
                    $error = Error::TypeTiny::MissingRequired->new(
                        named_param => $check_param,
                    );
                } else {
                    $error = $exception;
                }
                $errors{$check_param} = $error;
            };
            
            delete $params{$check_param};
        }
        
        require Error::TypeTiny::Validation;
        Error::TypeTiny::Validation->throw(
            message => 'One or more exceptions have occurred',
            errors  => { %errors },
        );
    }
    
}

sub _split_compile {
    my @checks = @_;
    
    my %checks;
    while ( @checks ) {
        my $param = shift @checks;
        my $check = shift @checks;
        my $check_check = Type::Params::compile_named( $param => $check );
        $checks{$param} = $check_check;
    }
    
    return %checks
}
1;
