# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Net-FullAuto';
all_from        'lib/Net/FullAuto.pm';

if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
   print "\n       FATAL ERROR! : Cygwin Linux Emulation Layer".
         "\n                      is required to use FullAuto".
         "\n                      on Windows - goto www.cygwin.com.".
         "\n\n           Be sure to install the following programs in ".
         "\n           addition to the base package:".
         "\n\n           OpenSSH and the sshd service [as provided by Cygwin]".
         "\n           inetutils \(if telnet and/or ftp services are desired\)".
         "\n           perl [as provided by Cygwin] (NOT CPAN)".
         "\n           libwin32 [as provided by Cygwin] (NOT CPAN)".
         "\n           gcc [as provided by Cygwin]".
         "\n\n";
   exit;
}
if ($^O eq 'cygwin' && !can_cc()) {
   my $die="\n       FATAL ERROR! : The Gnu C Compiler 'gcc'".
           "\n                      as provided by Cygwin".
           "\n                      is required to install FullAuto".
           "\n                      on Windows - goto www.cygwin.com.".
           "\n\n";
   die $die;
} elsif (!can_cc()) {
   my $die="\n       FATAL ERROR! : A C Compiler (such as cc or gcc)".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org).".
           "\n\n";
   die $die;
}

if ($^O eq 'cygwin' && !(can_run('/bin/ssh') || can_run('/bin/telnet'))) {
   print "\n       WARNING! : The Secure Shell - 'ssh'".
         "\n                  and/or 'telnet' (via inetutils)".
         "\n                  as provided by Cygwin".
         "\n                  is required to install FullAuto".
         "\n                  on Windows - goto www.cygwin.com.".
         "\n\n";
   print "Press <ENTER> if you wish to continue . . .";<STDIN>;
}

unless (can_run('make')) {
   my $die="\n       FATAL ERROR! : Cannot locate 'make'. This program ".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org).".
           "\n\n";
   die $die;
}

unless (can_run('lynx')) {
   print "\n       WARNING! : Cannot locate 'lynx'. This program ".
         "\n                  is recommended for installing FullAuto".
         "\n                  from the CPAN (Hint: goto www.gnu.org).".
         "\n\n";
   print "Press <ENTER> if you wish to continue . . .";<STDIN>;
}

#Specific dependencies
requires        'Sort::Versions'         => 0;
requires        'Crypt::CBC'             => 0;
requires        'Crypt::DES'             => 0;
requires        'Getopt::Long'           => 0;
requires        'HTTP::Date'             => 0;
requires        'IO::Pty'                => 0;
requires        'LWP'                    => 0;
requires        'Mail::Internet'         => 0;
requires        'Mail::Sender'           => 0;
requires        'MemHandle'              => 0;
requires        'MLDBM'                  => 0;
requires        'MLDBM::Sync'            => 0;
requires        'MLDBM::Sync::SDBM_File' => 0;
requires        'Net::Telnet'            => 0;
requires        'Term::Menus'            => 0;
requires        'Tie::Cache'             => 0;
requires        'URI'                    => 0;
recommends      'Crypt::Rijndael'        => 0;

install_script 'bin/fullauto';

auto_install;
WriteAll;
