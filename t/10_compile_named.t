use Test::Most;

BEGIN { use Type::Params::Validation qw/compile_named/ };

use Types::Standard qw/Str ArrayRef Num/;

subtest 'positives empty' => sub {
    my $check = compile_named();
    
    is( ref($check) , 'CODE',
        "Returns a 'CodeRef'"
    );
    
    my $args;
    lives_ok{
        $args = $check->()
    } "... and does run without problems";
    
    is( ref($args) , 'HASH',
        "... which returns a HASH ref"
    );
    
};

subtest 'positives simple' => sub {
    my $check = compile_named( sort_code => Str );
    
    is( ref($check) , 'CODE',
        "Returns a 'CodeRef'"
    );
    
    my $args;
    lives_ok{
        $args = $check->( sort_code => '12-34-56' )
    } "... and does run without problems";
    
    is( ref($args) , 'HASH',
        "... which returns a HASH ref"
    );
    
    is( $args->{sort_code}, '12-34-56',
        "... and returns the expected value"
    );
    
    $args = $check->( sort_code => '98-76-54' );
    is( $args->{sort_code}, '98-76-54',
        "... and returns another expected value"
    );
    
};

subtest 'negative simple' => sub {
    my $check = compile_named( monies => ArrayRef[Num] );
    
    is( ref($check) , 'CODE',
        "Returns a 'CodeRef'"
    );
    
    my $args;
    lives_ok{
        $args = $check->( monies => [12.34, 56,78] )
    } "... and does run without problems";
    
    cmp_deeply( $args =>
        {
            monies => [ 12.34, 56,78 ]
        },
        "... and has some numbers"
    );
    
    dies_ok{
        $args = $check->( monies => ["abc"] )
    } "... dies when passing bad values";
    
    isa_ok( $@, 'Error::TypeTiny' );
    
};

subtest 'error_typetiny_validation' => sub {
    my $check = compile_named( account_number => Num );
    
    my $args;
    dies_ok{
        $args = $check->( account_number => '123.456.789' )
    } "... dies when passing bad values";
    
    my $exception = $@;
    
    isa_ok( $exception, 'Error::TypeTiny::Validation' );
    
    like( $exception->message, qr/One or more exceptions have occurred/,
        "... And has a message about 'One or more exceptions'"
    );
    
    ok( $exception->errors,
        "... and has errors"
    );
    
};

done_testing();
