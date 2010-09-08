# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
use Config;
use POSIX qw/strftime/;

# Term::Menus Bootstrap Code.
BEGIN{my$p='Term::Menus';my$v=1.46;$p->VERSION||0>=$v
or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
(!defined($e)||$e!~m/--(?:default|skip|testonly)/and-t STDIN or
eval"use ExtUtils::MakeMaker;WriteMakefile(PREREQ_PM=>{'$p',$v}
);1"and exit)and print"==> $p $v required."and print
"*** Installing $p\n"and
do{if (eval '$>' and lc(`sudo -V`) =~ /version/){system('sudo',
$^X,"-MCPANPLUS","-e","CPANPLUS::install $p");eval"use $p $v;1"
||system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")}eval{
require CPANPLUS;CPANPLUS::install$p};eval"use $p $v;1"or eval{
require CPAN;CPAN::install$p};eval"use $p $v;1"||die"*** Please
manually install $p $v from cpan.org first...\n"}}}

BEGIN {
   unshift @ExtUtils::MakeMaker::Overridable, 'pm_to_blib';
};
use Term::Menus 1.46;

my $process_id='';
$process_id=pop @ARGV if $ARGV[$#ARGV-1]=~/^\d+$/;
my $install_cygwin_without_asking=0;
foreach my $arg (@ARGV) {
   if ($arg=~/INSTALL_*CYGWIN\s*=\*1/i) {
      $install_cygwin_without_asking=1;
      last;
   }
}

# Define metadata
name            'Net-FullAuto';
sign;
version         '0.41';
author          'Brian M. Kelly <Brian.Kelly@fullautosoftware.net>';
license         'gpl';
perl_version    '5.006';

if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {

   my %Menu_win_to_cyg=(

         Label  => 'Menu_win_to_cyg',
         Item_1 => {

            Text => "Install Cygwin Linux Emulation Layer for Windows",

         },
         Item_2 => {
 
            Text    => "DO *NOT* Install Cygwin (FullAuto Install will END)",
            Default => "*",
 
         },
         Banner => "   Would you like to install Cygwin?",

   );
   my $selection='';
   if ($install_cygwin_without_asking) {
      $selection='Install';
   } else {
      $selection=Menu(\%Menu_win_to_cyg);
   }
   exit if $selection eq ']quit[';
   if ($selection!~/NOT/) {
      if ($@) {
         do{my$p='LWP';my$v=5.386;$p->VERSION||0>=$v
         or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
         (!defined($e)||$e!~m/--(?:default|skip|testonly)/and-t STDIN or
         eval"use ExtUtils::MakeMaker;WriteMakefile(PREREQ_PM=>{'$p',$v}
         );1"and exit)and print"==> $p $v required."and print
         "*** Installing $p\n"and
         do{if (eval '$>' and lc(`sudo -V`) =~ /version/){system('sudo',
         $^X,"-MCPANPLUS","-e","CPANPLUS::install $p");eval"use $p $v;1"
         ||system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")}eval{
         require CPANPLUS;CPANPLUS::install$p};eval"use $p $v;1"or eval{
         require CPAN;CPAN::install$p};eval"use $p $v;1"||die"*** Please
         manually install $p $v from cpan.org first...\n"}}}
      }
      require LWP;
      my $ua=LWP::UserAgent->new;
      my $response = $ua->get('http://www.cygwin.com/setup.exe');
      open(CP,">setup.exe") || die $!;
      binmode(CP);
      if ($response->is_success) {
         print CP $response->content;
      } else {
         die $response->status_line;
      }
      close(CP) || die $!;
      chmod 0755, 'setup.exe';
      my $setup_cmd='cmd /c ".\\setup.exe -D -P gcc4-core,make,'
                   .'openssh,perl,db4.5 -A -q"';
	  my $pwd=`cmd /c chdir`;
	  chmod($pwd);
	  my $cygpath=$pwd;
	  $cygpath=~s/^(.):/\/cygdrive\/$1/;
	  $cygpath=~s/\\/\//g;
      system($setup_cmd);
#my $content = PAR::read_file('Makefile.PL');
#	  my $homedir=`cmd /c echo %HOMEDRIVE%%HOMEPATH%`;
#	  chomp($homedir);
#chdir $homedir;
#	  mkdir ".cpan", 0755 unless -e ".cpan";
#	  chdir ".cpan";
#	  mkdir "build", 0755 unless -e "build";
#	  mkdir "CPAN", 0755 unless -e "CPAN";
#	  my $pwd=`cmd /c chdir`;
#	  print "PWD=$pwd\n";
#	  require PAR;
#	  my $content = PAR::read_file('Makefile.PL');
#      open(FH,">Makefile.PL");
#      print FH $content;
#      close FH;
#      system('cmd /c C:\\cygwin\\bin\\bash -c "/usr/bin/perl ./Makefile.PL"');
#      system('C:\\cygwin\\bin\\bash -lc "/usr/bin/make install -C'.$cygpath.'"');
	  system('cmd /c C:\\cygwin\\bin\\bash -ic "/usr/bin/cpan -i Net::FullAuto"');
      exit;
   } elsif ($process_id) {
      exit;
   }
   my $die="\n       FATAL ERROR! : Cygwin Linux Emulation Layer".
           "\n                      is required to use FullAuto".
           "\n                      on Windows - goto www.cygwin.com.".
           "\n\n           Be sure to install the following programs in ".
           "\n           addition to the base package:".
           "\n\n           OpenSSH [as provided by Cygwin]".
           "\n           inetutils \(if telnet and/or ftp services are desired\)".
           "\n           perl [as provided by Cygwin] (*NOT* CPAN)".
           "\n           libwin32 [as provided by Cygwin] (*NOT* CPAN)".
           "\n           gcc [as provided by Cygwin]".
           "\n           Oracle Berkeley DB [as provided by Cygwin]".
           "\n\n           **IMPORTANT** - the FullAuto install, either manual".
           "\n           or via CPAN, must be run *inside* a Cygwin bash shell".
           "\n           when installing FullAuto on Microsoft Windows.".
           "\n\n";
   die $die;
}
if ($^O eq 'cygwin' && !can_cc()) {
   my $die="\n       FATAL ERROR! : The Gnu C Compiler 'gcc'".
           "\n                      version 4 as provided by Cygwin".
           "\n                      is required to install FullAuto".
           "\n                      on Windows.".
           "\n(Hint: Run Cygwin setup.exe and install 'gcc4-core' ".
           "under the Category 'Devel' ).".
           "\n\n";
   die $die;
} elsif (!can_cc()) {
   my $die="\n       FATAL ERROR! : A C Compiler (such as cc or gcc version 4)".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org for gcc version 4).".
           "\n\n";
   die $die;
}

if ($^O eq 'cygwin' && !(can_run('/bin/ssh') || can_run('/bin/telnet'))) {
   my $timeout=120;my $a='';
   eval {
      $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n". 
            "\n       WARNING! : The Secure Shell - 'ssh'".
            "\n                  and/or 'telnet' (via inetutils)".
            "\n                  as provided by Cygwin".
            "\n                  is required to install FullAuto".
            "\n                  on Windows.".
            "\n(Hint: Run Cygwin setup.exe and install OpenSSH ".
            "under the Category 'Net' ).".
            "\n\n";
      print "Press <ENTER> if you wish to continue, or 'N' to quit . . . [Y] ";$a=<STDIN>;
      alarm 0;
   };
   if ($@) {
      # timed out
      exit;
   } elsif ($a=~/^[Nn]$/s) {
      exit;
   }
}
if (!can_run('make') && !(($^O eq 'cygwin') && (-e "/usr/bin/make"))) {
   my $die="\n       FATAL ERROR! : Cannot locate 'make'. This program ".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org for gnumake).".
           "\n\n";
   die $die;
}

if (0) { ## This disables the following code testing for lynx

unless (can_run('lynx')) {
   my $timeout=120;my $a='';
   eval {
      $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n".
            "\n       WARNING! : Cannot locate 'lynx'. This program ".
            "\n                  is recommended for installing FullAuto".
            "\n                  from the CPAN (Hint: goto www.gnu.org).".
            "\n\n";
      print "Press <ENTER> if you wish to continue, or 'N' to quit . . . [Y] ";$a=<STDIN>;
      alarm 0;
   };
   if ($@) {
      # timed out
      exit;
   } elsif ($a=~/^[Nn]$/s) {
      exit;
   }
}

} ## End disable block

#Specific dependencies
requires        'Tie::Cache'             => 0;
requires        'Sort::Versions'         => 0;
requires        'Crypt::CBC'             => 0;
requires        'Crypt::DES'             => 0;
requires        'Getopt::Long'           => 0;
requires        'HTTP::Date'             => 0;
requires        'JSON'                   => 2.14;
requires        'IO::Pty'                => 0;
requires        'IO::Capture::Stderr'    => 0;
requires        'IO::CaptureOutput'      => 0;
requires        'Mail::Internet'         => 0;
requires        'Mail::Sender'           => 0;
requires        'DB_File'                => 0;
requires        'MLDBM'                  => 0;
requires        'MLDBM::Sync'            => 0;
requires        'MLDBM::Sync::SDBM_File' => 0;
requires        'Net::Telnet'            => 0;
requires        'Term::ReadKey'          => 0;
requires        'URI'                    => 0;
recommends      'Crypt::Rijndael'        => 0;

auto_install;

my %hash=();
eval {
   require DB_File;
   my $db = tie %hash, "DB_File", "fullauto_test_for_db_creation.db" 
      || die "Cannot tie fullauto_test_for_db_creation.db: $!" ;
   undef $db ;
   untie %hash ;
   unlink "fullauto_test_for_db_creation.db";
};
if ($@) {
   my $die="\n$@\n".
           "\n       FATAL ERROR! : Cannot create 'fullauto_test_for_db_creation.db'".
           "\n                      You may be missing the Berkeley DB 'c' library.".
           "\n                      This 'c' library is required to install FullAuto\n";
   if ($^O eq 'cygwin') {
      $die.="\n(Hint: Run Cygwin setup.exe and install Oracle Berkley DB ".
           "under the Category 'Database' ).";
   } else {
      $die.="\n(Hint: goto ->  http://www.oracle.com/technetwork/".
           "database/berkeleydb/downloads/index.html ).";
   }
   $die.="\n\n";
   die $die;
}

my $c_file='';
my $date=strftime('%D',localtime);

my $banner='';
unless (-w $Config{installsitelib}) {
   $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE 'NO' IN 2 MINUTES ***\n".
           "\n   WARNING!: You do not have permission to install FullAuto".
           "\n   to the default location -> $Config{installsitelib}.\n".
           "\n   Hint 1: You can use the PREFIX and LIB attributes to".
           "\n   set several attributes at once. The quickest way to".
           "\n   install FullAuto in a non-default location might be".
           "\n   setting PREFIX to '~'. You can do this by selecting".
           "\n   'Yes' below, or by re-running Makefile.PL with the".
           "\n   the following argument:\n".
           "\n   perl Makefile.PL PREFIX=~\n".
           "\n   This will install all FullAuto files under your home".
           "\n   directory, with man pages and libraries going into the".
           "\n   appropriate place (most likely ~/man and ~/lib)\n".
           "\n   You may also consider using the LIB attribute:\n".
           "\n   perl Makefile.PL LIB=~/lib\n".
           "\n   See the MakeMaker.pm module documetation for more".
           "\n   information:\n".
           "\n   http://search.cpan.org/~mschwern/ExtUtils-MakeMaker-6.56".
           "/lib/ExtUtils/MakeMaker.pm#PREFIX_and_LIB_attribute\n".
           "\n   Hint 2: Run perl MakeMaker.PL with an appropriate user".
           "\n   (such as root) or with a utility such as sudo if you".
           "\n   are authorized to use it (sudo perl Makefile.PL).".
           "\n   The same is true if you are attempting to install".
           "\n   FullAuto via the CPAN resposiory (i.e. 'sudo cpan')\n".
           "\n   Would like to install FullAuto to your home (~) directory?\n\n"
}

if ($banner) {

   my $timeout=120;my $selection='';
   eval {
      $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      my $menu1 = [
                  $banner,
                  [ "Yes", sub{ return 'Yes' } ],
                  [ "No   (FullAuto install will exit)", sub{ return 'No' } ],
                  #[ "Quit", sub {exit;} ],
                  ];
      $selection=&menu($menu1);
      alarm 0;
   };
   if ($@) {
      # timed out
      $selection = 'No';
   }
   if ($selection=~/No/) {
      exit;
   }
}

open(FH,">fullauto.c");

print FH '/* program: fullauto'."\n".
"   author:  Brian Kelly\n".
"   date:    $date\n".
"\n".
"   purpose: C program wrapper that calls $Config{installsitebin}/fullauto.pl script\n".
"   WARNING: This file is auto-generated by Makefile.PL, please change Makefile.PL.\n".
"            Any modifications made to this source file will be lost!\n".
'*/'."\n".
"\n".
'#define REAL_PL '.'"'.$Config{installsitebin}."/fullauto.pl\"\n".
"main(argc, argv)\n".
"char **argv;\n".
'{'."\n".
"\tsetuid(0);\n".
"\tseteuid(0);\n".
"\texecv(REAL_PL, argv);\n".
'}'."\n";

close FH;

my $timeout=120;my $selection='';my @selection=();
eval {
   $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
   alarm $timeout;
   my @list=('Install with Default Permissions',
             'Install with Setuid Permissions',
             'Install with Setgid Permissions');
   my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE 'Default' IN 2 MINUTES ***\n".
           "\n   Choose a Permission Setting :\n\n";
   @selection=&pick(\@list,$banner);
   alarm 0;
};
if ($@) {
   # timed out
   print "\n";
   $selection = 'Default';
}

my $permission = 'Default';
#print "SELECTION = $selection<==\n";sleep 3;
if (-1<index $selection,'Setuid') {
   $permission = 'Setuid';
} elsif (-1<index $selection,'Setgid') {
   $permission = 'Setgid';
} elsif (-1<index $selection,'quit') {
   exit;
} print "\n"; 

if ($^O eq 'cygwin') {
   `/usr/bin/touch "bin/fullauto.exe"`;
   install_script 'bin/fullauto.exe';
   unlink "bin/fullauto.exe";
} else {
   `/usr/bin/touch "bin/fullauto"`;
   install_script 'bin/fullauto';
   unlink "bin/fullauto";
}
install_script 'bin/fullauto.pl';

WriteAll;

sub menu {
    my $m = shift;
    my $choice;
    while (1) {
    print "$m->[0]\n";
    print map { "\t$_. $m->[$_][0]\n" } (1..$#$m);
    print "\n\n   PLEASE ENTER A CHOICE: ";
    chomp ($choice = <>);
    last if ( ($choice > 0) && ($choice <= $#$m ));
    print "You chose '$choice'.  That is not a valid option.\n\n";
    }
    &{$m->[$choice][1]};
}

package MY; # so that "SUPER" works right
sub MY::top_targets {

   my $inherited = shift->SUPER::top_targets(@_);

   $inherited =~ s/pure_all :: /pure_all :: fullauto\$(EXE_EXT) /;
   $inherited =~ s/ linkext//;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::makefile {

   use Config;

   my $inherited = shift->SUPER::makefile(@_);

   $inherited .= "fullauto\$(EXE_EXT): fullauto.c\n\t\$(CC) fullauto.c -o \$@".
                 "\n\t\$(CP) \$@ bin\n\n";

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_host.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_host.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*FullAuto.*fa_host.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_host.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_host.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_host.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_maps.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_maps.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_maps.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_maps.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_maps.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_maps.pm";
      unlink "blib/Net/FullAuto/Custom/fa_maps.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_conf.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_conf.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_conf.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_conf.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_conf.pm";
      unlink "blib/Net/FullAuto/Custom/fa_conf.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_menu.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_menu.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_menu.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_menu.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_menu.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_menu.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_code.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_code.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/fa_code.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_code.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_code.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_code.pm";
   }

   $inherited; 

}

package MY; # so that "SUPER" works right
sub MY::constants {

   use Config;

   my $inherited = shift->SUPER::constants(@_);

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") {
      my $fa_h="\tlib\/Net\/FullAuto\/Custom\/fa_host.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_host.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_host.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_host.pm \\/m; 
      $inherited =~
         s/(\s+blib.*Distro\/fa_host.pm \\)/$1\n$fa_h/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_host.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_maps.pm") {
      my $fa_m="\tlib\/Net\/FullAuto\/Custom\/fa_maps.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_maps.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_maps.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_maps.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_maps.pm \\)/$1\n$fa_m/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_maps.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      my $fa_g="\tlib\/Net\/FullAuto\/Custom\/fa_conf.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_conf.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_conf.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_conf.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_conf.pm \\)/$1\n$fa_g/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_conf.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") {
      my $fa_m="\tlib\/Net\/FullAuto\/Custom\/fa_menu.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_menu.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_menu.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_menu.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_menu.pm \\)/$1\n$fa_m/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_menu.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") {
      my $fa_c="\tlib\/Net\/FullAuto\/Custom\/fa_code.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_code.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_code.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_code.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/fa_code.pm \\)/$1\n$fa_c/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_code.pm.*)$//;
   }

   $inherited =~ 
      s/(PERM_RWX = \d+)/$1\nPERM_S_X = 4511\nPERM_G_X = 2551/m;
   $inherited =~
      s/(PERM_G_X = \d+)/$1\nPERM_R+X = 555\nPERM_R-X = 550\nPERM_R_X = 500/m;
   $inherited =~
      s/(PERM_R_X = \d+)/$1\nPERM_D-X = 750\nPERM_D_X = 700/m;

   $inherited;

}

package MY; # so that "SUPER works right
sub MY::installbin {

   my $inherited = shift->SUPER::installbin(@_);

   $inherited =~ s/RM_F\) \\/RM_F\) bin\/fullauto\$(EXE_EXT) fullauto.c fullauto\$(EXE_EXT)\\/;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::install {

   use Config;

   my $inherited = shift->SUPER::install(@_);

   if ($permission eq 'Setuid') {
      $inherited =~ s/(install ::.*)$/$1 setuid_permissions/m;
   } elsif ($permission eq 'Setgid') {
      $inherited =~ s/(install ::.*)$/$1 setgid_permissions/m;
   } else {
      $inherited =~ s/(install ::.*)$/$1 default_permissions/m;
   }

   my $link='';
   unless (-e $Config{installsitebin}."/fa") {
      my $lnpath='';
      if (-e "/bin/ln") {
         $lnpath="/bin/ln";
      } elsif (-e "/usr/bin/ln") {
         $lnpath="/usr/bin/ln";
      } elsif (-e "/usr/local/bin/ln") {
         $lnpath="/usr/local/bin/ln";
      }

      if ($lnpath) {
         $link="\t\$(NOECHO) $lnpath -s \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT) ".
               "\$(DESTINSTALLSITESCRIPT)\/fa\n"; 
      }

   } 

   $inherited .= "\nsetuid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_S_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link;
   $inherited .= "\nsetgid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setgid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_G_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link;
   $inherited .= "\ndefault_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Default Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_DIR) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link; 

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::dist_core {

   my $inherited = shift->SUPER::dist_core(@_);

   $inherited =~ s/tar$/tar\n\t\$(MV) \$(DISTVNAME).tar\$(SUFFIX) dist/m;

   $inherited;

}

package MY; # so that "SUPER" worls right
sub MY::clean {

   my $inherited = shift->SUPER::clean(@_);

   $inherited =~ s/blib\s*$/blib setup\$(EXE_EXT) /m;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::pm_to_blib {

   use Config;

   my $inherited = shift->SUPER::pm_to_blib(@_);

   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") &&
         ($inherited !~ /Custom\/fa_host.pm/)) {
      my $fa_h="\t  lib\/Net\/FullAuto\/Distro\/fa_host.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_host.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_host.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_host.pm).*/$1 \\\n$fa_h$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_host.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_maps.pm") &&
         ($inherited !~ /Custom\/fa_maps.pm/)) {
      my $fa_p="\t  lib\/Net\/FullAuto\/Distro\/fa_maps.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_maps.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_maps.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_maps.pm).*/$1 \\\n$fa_p$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_maps.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") &&
         ($inherited !~ /Custom\/fa_conf.pm/)) {
      my $fa_g="\t  lib\/Net\/FullAuto\/Distro\/fa_conf.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_conf.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_conf.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_conf.pm).*/$1 \\\n$fa_g$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_conf.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_menu.pm") &&
         ($inherited !~ /Custom\/fa_menu.pm/)) {
      my $fa_m="\t  lib\/Net\/FullAuto\/Distro\/fa_menu.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_menu.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_menu.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_menu.pm).*/$1 \\\n$fa_m$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_menu.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_code.pm") &&
         ($inherited !~ /Custom\/fa_code.pm/)) {
      my $fa_c="\t  lib\/Net\/FullAuto\/Distro\/fa_code.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_code.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_code.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_code.pm).*/$1 \\\n$fa_c$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_code.pm.*\n//m;
   }
   
   $inherited =~ s/\s+\\(\s*[$][(]NOE)/$1/s;

   $inherited;

}
