# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
use Config;
use POSIX qw/strftime/;
BEGIN {
   unshift @ExtUtils::MakeMaker::Overridable, 'pm_to_blib';
};

# Define metadata
name            'Net-FullAuto';
all_from        'lib/Net/FullAuto.pm';

if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
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

unless (can_run('make')) {
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
requires        'IO::Pty'                => 0;
requires	'IO::Capture::Stderr'    => 0;
requires        'IO::CaptureOutput'      => 0;
requires        'Mail::Internet'         => 0;
requires        'Mail::Sender'           => 0;
requires        'DB_File'                => 0;
requires        'MLDBM'                  => 0;
requires        'MLDBM::Sync'            => 0;
requires        'MLDBM::Sync::SDBM_File' => 0;
requires        'Net::Telnet'            => 0;
requires        'Term::Menus'            => 1.40;
requires        'Term::ReadKey'          => 0;
requires        'URI'                    => 0;
recommends      'Crypt::Rijndael'        => 0;

auto_install;

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

use Term::Menus;

my $timeout=120;my $selection='';
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
   install_script 'bin/fullauto.exe';
} else {
   install_script 'bin/fullauto';
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

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_hosts.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/fa_hosts.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/fa_hosts.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*FullAuto.*fa_hosts.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/fa_hosts.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/fa_hosts.pm";
      unlink "blib/lib/Net/FullAuto/Custom/fa_hosts.pm";
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
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/menu_cfg.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/menu_cfg.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/menu_cfg.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/menu_cfg.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/menu_cfg.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/menu_cfg.pm";
      unlink "blib/lib/Net/FullAuto/Custom/menu_cfg.pm";
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/usr_code.pm") {
      $inherited .= "lib/Net/FullAuto/Custom/usr_code.pm:".
                    "\n\t\$(CP) lib/Net/FullAuto/Distro/usr_code.pm \$@\n\n";
   } else {
      $inherited =~ s/^(.*Custom\/usr_code.pm.*)$//m;
      $inherited .= "lib/Net/FullAuto/Custom/usr_code.pm:".
                    "\n\t\$(NOECHO)\n\n";
      unlink "lib/Net/FullAuto/Custom/usr_code.pm";
      unlink "blib/lib/Net/FullAuto/Custom/usr_code.pm";
   }

   $inherited; 

}

package MY; # so that "SUPER" works right
sub MY::constants {

   use Config;

   my $inherited = shift->SUPER::constants(@_);

   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_hosts.pm") {
      my $fa_h="\tlib\/Net\/FullAuto\/Custom\/fa_hosts.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/fa_hosts.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/fa_hosts.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/fa_hosts.pm \\/m; 
      $inherited =~
         s/(\s+blib.*Distro\/fa_hosts.pm \\)/$1\n$fa_h/m;
   } else {
      $inherited =~ s/^(.*Custom\/fa_hosts.pm.*)$//;
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
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/menu_cfg.pm") {
      my $fa_c="\tlib\/Net\/FullAuto\/Custom\/menu_cfg.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/menu_cfg.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/menu_cfg.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/menu_cfg.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/menu_cfg.pm \\)/$1\n$fa_c/m;
   } else {
      $inherited =~ s/^(.*Custom\/menu_cfg.pm.*)$//;
   }
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/usr_code.pm") {
      my $fa_u="\tlib\/Net\/FullAuto\/Custom\/usr_code.pm ".
               "\\\n\tblib\/Net\/FullAuto\/Custom\/usr_code.pm \\";
      $inherited =~
         s/(\s+lib.*Distro\/usr_code.pm \\)/$1\n\tlib\/Net\/FullAuto\/Custom\/usr_code.pm \\/m;
      $inherited =~
         s/(\s+blib.*Distro\/usr_code.pm \\)/$1\n$fa_u/m;
   } else {
      $inherited =~ s/^(.*Custom\/usr_code.pm.*)$//;
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

   $inherited .= "\nsetuid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_S_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n\n";
   $inherited .= "\nsetgid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setgid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_G_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n\n";
   $inherited .= "\ndefault_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Default Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_DIR) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n\n"; 

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::pm_to_blib {

   use Config;

   my $inherited = shift->SUPER::pm_to_blib(@_);

   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_hosts.pm") &&
         ($inherited =~ /Custom\/fa_hosts.pm/)) {
      my $fa_h="\t  lib\/Net\/FullAuto\/Distro\/fa_hosts.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_hosts.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_hosts.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_hosts.pm).*/$1 \\\n$fa_h$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_hosts.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_maps.pm") &&
         ($inherited =~ /Custom\/fa_maps.pm/)) {
      my $fa_m="\t  lib\/Net\/FullAuto\/Distro\/fa_maps.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/fa_maps.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/fa_maps.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/fa_maps.pm).*/$1 \\\n$fa_m$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/fa_maps.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/menu_cfg.pm") &&
         ($inherited =~ /Custom\/menu_cfg.pm/)) {
      my $fa_c="\t  lib\/Net\/FullAuto\/Distro\/menu_cfg.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/menu_cfg.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/menu_cfg.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/menu_cfg.pm).*/$1 \\\n$fa_c$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/menu_cfg.pm.*\n//m;
   }
   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/usr_code.pm") &&
         ($inherited =~ /Custom\/usr_code.pm/)) {
      my $fa_u="\t  lib\/Net\/FullAuto\/Distro\/usr_code.pm ".
               "blib\/lib\/Net\/FullAuto\/Custom\/usr_code.pm";
      my $wrap='';
      $inherited =~ /\s+blib.*Distro\/usr_code.pm( \\)/m;
      $wrap=$1;
      $inherited =~
         s/(\s+blib.*Distro\/usr_code.pm).*/$1 \\\n$fa_u$wrap/m;
   } else {
      $inherited =~ s/.*Custom\/usr_code.pm.*\n//m;
   }
   
   $inherited =~ s/\s+\\(\s*[$][(]NOE)/$1/s;

   $inherited;

}
