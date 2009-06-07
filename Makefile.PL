use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# $Id$


my @programs_to_install = qw(dave);

WriteMakefile(
    'NAME'	=> 'HTTP::DAV',
    'VERSION_FROM' => 'DAV.pm', # finds $VERSION
    'dist'          => { COMPRESS => 'gzip -9f --best',
                         SUFFIX => '.gz',
#                         PREOP => 'bin/dist'
					   },
    'EXE_FILES'     => [ map {"bin/$_"} @programs_to_install ],
    'PREREQ_PM' => { 
        'LWP'          => 5.48,
        'Scalar::Util' => 0,
        'XML::DOM'     => 0,
    },
);
