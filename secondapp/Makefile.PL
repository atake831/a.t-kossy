use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'secondapp',
    VERSION_FROM  => 'lib/secondapp.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.19',
    },
    MIN_PERL_VERSION => '5.008001'
);

