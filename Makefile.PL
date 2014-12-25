### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright (C) 2000-2014  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

################################################################
#
#  Makefile.PL for Net::FullAuto
#
################################################################

BEGIN {

   $main::VERSION='0.999999999954';

   # ASCII BANNER Courtesy of:  http://www.network-science.de/ascii/
   # When FullAuto is installed, run:  fa --figlet  to view multiple fonts.

   my $fa_banner=<<'END';



    __       __)
   (, )  |  /      /)
      | /| /   _  // _  ______    _    _/_ ___
      |/ |/  _(/_(/_(__(_) // (__(/_   (__(_)
      /  |



           _   _      _         _____      _ _    _         _
          | \ | | ___| |_      |  ___|   _| | |  / \  _   _| |_ ___
          |  \| |/ _ \ __| o o | |_ | | | | | | / _ \| | | | __/ _ \
          | |\  |  __/ |_  o o |  _|| |_| | | |/ ___ \ |_| | || (_) |
          |_| \_|\___|\__|     |_|   \__,_|_|_/_/   \_\__,_|\__\___/



   Copyright (C) 2000-2014  Brian M. Kelly  Brian.Kelly@fullautosoftware.net


END

   %main::amazon=();
   %main::system_type='';
   if ($^O eq 'linux' || $^O eq 'freebsd') {
      if ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,'amazon:linux')) {

         # Manual Setup Amazon AMI host before CPAN:
         #
         # sudo yum -y install cpan

         $main::amazon{'ami'}='';
         $main::system_type='ami';
      } elsif ((-e "/etc/os-release") &&
            (-1<index `cat /etc/os-release`,'ubuntu')) {
         if (-e "/usr/bin/ec2metadata") {
            $main::amazon{'ubuntu'}='';
         }
         $main::system_type='ubuntu';
      } elsif ($^O eq 'freebsd') {

         # Manual Setup FreeBSD host before CPAN:
         #
         # su
         # pkg_add -r perl

         if ((-e "/usr/local/bin/aws") &&
               (-1<index `cat /usr/local/bin/aws`,'aws.amazon')) {
            $main::amazon{'freebsd'}='';
         }
         $main::system_type='freebsd';
      } elsif (-e "/etc/SuSE-release") {
         if (-e "/etc/profile.d/amazonEC2.sh") {
            $main::amazon{'suse'}='';
         }
         $main::system_type='suse';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'fedoraproject')) {
         if (-e "/etc/yum/pluginconf.d/amazon-id.conf") {
            $main::amazon{'fedora'}='';
         }
         $main::system_type='fedora';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'redhat:enterprise_linux')) {

         # Manual Setup Redhat host before CPAN:
         #
         # sudo yum -y install cpan

         if (-e "/etc/yum/pluginconf.d/amazon-id.conf") {
            $main::amazon{'rhel'}='';
         }
         $main::system_type='rhel';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'centos:linux')) {

         # Manual Setup CentOS host before CPAN:
         #
         # sudo yum -y groupinstall "Development tools"
         # sudo yum -y install cpan 

         if ((-e "/sys/hypervisor/compilation/compiled_by") &&
               (-1<index `cat /sys/hypervisor/compilation/compiled_by`,
               'amazon')) {
            $main::amazon{'centos'}='';
         }
         $main::system_type='centos';
      } elsif (-e "/etc/gentoo-release") {

         # Manual Setup CentOS host before CPAN:
         #

         if ((-e "/sys/hypervisor/compilation/compiled_by") &&
               (-1<index `cat /sys/hypervisor/compilation/compiled_by`,
               'amazon')) {
            $main::amazon{'gentoo'}='';
         }
         $main::system_type='gentoo';
      }
   } else { $main::system_type=$^O }

   sub get_cygwin_location {
      my $cygwin_query=
            `REG QUERY HKEY_LOCAL_MACHINE\\SOFTWARE\\Cygwin\\setup 2>&1`;
      my $showcq=$cygwin_query;
      my $sep='\\';
      if (-1<index $showcq,'Invalid key name') {
         $cygwin_query=
            `REG QUERY HKEY_LOCAL_MACHINE\\\\SOFTWARE\\\\Cygwin\\\\setup 2>&1`;
         $showcq=$cygwin_query;
         $sep='\\\\';
      }
      $showcq=~s/^/   /mg;chomp $showcq;
      my $cygwin_query_success=0;
      if (-1<index $cygwin_query,'REG_SZ') {
         $cygwin_query_success=1;
      } else {
         my $rcmd="REG QUERY HKEY_LOCAL_MACHINE${sep}SOFTWARE$sep".
                  "Wow6432Node${sep}Cygwin${sep}setup 2>&1";
         $cygwin_query=`$rcmd`;
         $showcq=$cygwin_query;
         $showcq=~s/^/   /mg;chomp $showcq;
         if (-1<index $cygwin_query,'REG_SZ') {
            $cygwin_query_success=1;
         }
      }
      if ($cygwin_query_success) {
         #print "\n   REG QUERY RESULT:\n\n   $showcq";
         $cygwin_query=~s/^.*REG_SZ\s+(.*)\s*$/$1/s;
         $cygwin_query=~s/^\s*//s;
         $cygwin_query=~s/\s*$//s;
         unless (-W $cygwin_query) {
            unless (-d $cygwin_query) {
               # The cygwin directory indicated in the Registry does not
               # exist - let's delete the Registry entry
               if (-1<$cygwin_query,'Wow6432') {
                  my $rcmd="REG DELETE HKEY_LOCAL_MACHINE${sep}SOFTWARE${sep}".
                           "Wow6432Node${sep}Cygwin /f 2>&1";
                  my $regout=`$rcmd`;
                  return 0;
               } else {
                  my $rcmd='REG DELETE HKEY_LOCAL_MACHINE'.
                           "${sep}SOFTWARE${sep}Cygwin /f 2>&1";
                  my $regout=`$rcmd`;
                  return 0;
               }
            }
            if (-1<index $0,'Setup-FullAuto') {
               my $name=substr($0,(rindex $0,'\\'));
               print "\n\n".
                  "   Fatal Error! - Write Access to $cygwin_query\n".
                  "   is needed in order to install FullAuto or OpenSSH.\n\n".
                  "   If you have Administrator Rights, be sure to Right\n".
                  "   Click on the $name\n   icon and select ".
                  "\"Run as administrator\"\n\n".
                  "   Or, contact your Windows System Administrator\n".
                  "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
            } else {
               print "\n\n".
                  "   Fatal Error! - Write Access to $cygwin_query\n".
                  "   is needed in order to install FullAuto or OpenSSH.\n\n".
                  "   Please contact your Windows System Administrator\n".
                  "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
            }
            <STDIN>;
            exit 1;
         }
         my $getver='';
         if ($^O eq 'cygwin') {
            $getver='cygcheck -c cygwin 2>&1';
         } else {
            $getver='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
                '"cygcheck -c cygwin" 2>&1';
         }
         my $cygver=`$getver`;
         if ($cygver=~/(1.7.11-1)/) {
            print "\n\n   Fatal Error! - The current Cygwin version: $1\n".
                  "   (Base Cygwin cygwin1.dll) is incompatible with\n".
                  "   FullAuto. Please update to either a newer or older\n".
                  "   version of Base Cygwin before again attempting to\n".
                  "   to install FullAuto.\n\n".
                  "   You may need to contact your Windows System\n".
                  "   Administrator to resolve.\n\n".
                  "   PRESS ANY KEY to Exit Setup\n\n";
            <STDIN>;
            exit 1;
         }
         if (-e "$cygwin_query/bin/bash.exe") {
            my $getid='';
            if ($^O eq 'cygwin') {
               $getid='id 2>&1';
            } else {
               $getid='SET CYGWIN=nodosfilewarning & '.
                   "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
                   '"id"';
            }
            my $groups=`$getid`;
            if ((-1==index $groups,"(Administrators)") && 
                  ($ENV{'USERNAME'} ne 'Administrator')) {
               print "\n\n",
                     "   Fatal Error! - The User $ENV{'USERNAME'} needs to\n",
                     "   be a member of the Administrator's group in order\n",
                     "   to install FullAuto or OpenSSH.\n\n",
                     "   Please contact your Windows System Administrator\n",
                     "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
               <STDIN>;
               exit;
            }
         }
         if ($_[0]) {
            my $getpath='';
            $cygwin_query=~s/\\/\\\\/g;
            if ($^O eq 'cygwin') {
               $getpath="/usr/bin/cygpath -u $cygwin_query 2>&1";
            } else {
               $getpath='SET CYGWIN=nodosfilewarning & '.
                   "cmd /c $cygwin_query${sep}bin${sep}bash -lc ".
                   "\"/usr/bin/cygpath -u $cygwin_query\" 2>&1";
            }
            $cygwin_query=`$getpath`;
            chomp $cygwin_query;
            return '' if $cygwin_query eq '/';
         }
         return $cygwin_query;
      } return 0
   }
   $SIG{ INT } = sub{ eval { require Term::ReadKey };
                      unless ($@) { Term::ReadKey::ReadMode(0) };
                      print "\n";
                      exit };
   use Cwd qw/cwd/;
   use lib '.';
   use lib './inc';
   use inc::Module::Install;
   use Config;
   use File::stat;
   eval {
      CPAN::HandleConfig->load;
   };
   if ($@) {
      if ((-x "/usr/local/bin/perl") && ($^X ne "/usr/local/bin/perl")) {
         my $timeout=300;my $a='';
         my $toperror=$@;
         eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            my $message=<<END;

   ERROR!:  $toperror

            It appears that the perl installation used to run
            Makefile.PL is an old system installation, and not
            the intended one.

            Another perl installation using /usr/local/bin/perl
            as the primary executable has been discovered.

            Would you like Makefile.PL to be run against that
            installation?

END

            my $fae="No   (FullAuto Setup will exit)";
            my $menu1 = [
                        $message,
                        [ "Yes", sub{ return 'Yes' } ],
                        [ $fae, sub{ return 'No' } ],
                        ];
            my $selection=&menu($menu1);
            exit 0 if $selection eq ']quit[';
            exit 0 if -1<index $selection, 'No   (';
            my $argvs=join " ", @ARGV;
            exec "/usr/local/bin/perl Makefile.PL $argvs";
            alarm 0;
         };
         die "$@: $!\n" if $@;
      } else {
         die "$@: $!\n" if $@;
      }
   }
   use POSIX qw/strftime/;
   my $mycpantest=0; 
   $main::curdir=&cwd;
   $main::PARdir=$main::curdir;
   $main::domain_gr_flag=0;
   my $exec_cnt=0;
   foreach my $dir (@INC) {
      my $incdir=$dir;
      $mycpantest=1 if -e $incdir."/CPAN/MyConfig.pm";
      if ((substr($incdir,-3) eq 'inc') &&
            (1<index $incdir,'par-')) {
         $main::PARdir=substr($incdir,0,-4);
      }
   }
   chdir $main::PARdir;
   $INC{'Module/Install.pm'}=$main::PARdir.'/Module/Install.pm';
   unless (exists $ENV{FA_EDITOR} || grep { /Encrypted|SKIP/i } @ARGV) {
      print $fa_banner;
      sleep 2;
   } elsif (grep { /SKIP/i } @ARGV) {
      $exec_cnt=$ARGV[$#ARGV];
      $exec_cnt++;
      my $module_fail=$ARGV[$#ARGV-1];
      my $mod_info='';
      eval {
         require CPAN;
         {
            local *STDOUT;
            open(STDOUT, ">", \$mod_info);
            CPAN::Shell->m($module_fail);
         }
      };
      my $instfile='';
      ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
      my $instver='';
      ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
      my $cpanver='';
      ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
      if ($exec_cnt==1 && $cpanver ne $instver) {
            # && $instfile=~/vendor_perl/) { # &&
            #((exists $main::amazon{'ami'}) ||
            #(exists $main::amazon{'rhel'}))
            #&& $module_fail eq 'Pod::Man') {
         # Amazon's AMI has Pod::Man installed in the vendor_perl
         # directory which has precedence over the system directory
         # this module actually belongs in. The only solution is to
         # delete it from the vendor_perl area before we attempt to
         # install Pod::Man. We are doing this ONLY on Amazaon AMI
         # systems currently.
         system("sudo echo y | /bin/rm -rf \"$instfile\"");
      } elsif (2<$exec_cnt) {
         my $timeout=300;my $a='';
         eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            $mod_info=~s/^.*?(CPAN.*)$/$1/s;
            $mod_info=~s/^\s*/      /mg;
            print "\n\n   Fatal Error!: The following Perl CPAN ",
                  "module could\n                 ",
                  "not be installed on your system:",
                  "\n\n      $module_fail\n\n$mod_info\n",
                  "   The FullAuto installation will not",
                  "\n   succeed without this module installed",
                  "\n   and loaded.",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.";<STDIN>;
                  return;
         };
         alarm 0;
         exit 1;
      }
   }

   my $demo_banner=<<'END';

                              ___     _ _   _       _
                             | __|  _| | | /_\ _  _| |_ ___
   (   /_ /_   _  _          | _| || | | |/ _ \ || |  _/ _ \
   |/|/(-(( ()//)(-  To The  |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    ___                        _            _   _
   |   \ ___ _ __  ___ _ _  __| |_ _ _ __ _| |_(_)___ _ _
   | |) / -_) '  \/ _ \ ' \(_-<  _| '_/ _` |  _| / _ \ ' \
   |___/\___|_|_|_\___/_||_/__/\__|_| \__,_|\__|_\___/_||_|
   --------------------------------------------------------

   If you are new to FullAuto, and would like a better idea of what it
   is and what it does, please explore the brief introduction before
   running the demonstration. You can access the introduction by just
   pressing [ENTER]

   Otherwise, use the DOWN ARROW [v] key to move the arrow to item 2
   and press [ENTER] - or just type 2 and press [ENTER] to start the
   demonstration.

END

   my $demo_banner_1=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    ___     _               _         _   _
   |_ _|_ _| |_ _ _ ___  __| |_  _ __| |_(_)___ _ _
    | || ' \  _| '_/ _ \/ _` | || / _|  _| / _ \ ' \
   |___|_||_\__|_| \___/\__,_|\_,_\__|\__|_\___/_||_|
   --------------------------------------------------

   FullAuto is a breakthrough innovation in Network Process Automation.
   Any time a process involves more than one device, it is a "networked"
   process. Anyone who uses the Internet, engages in "network processing"
   - otherwise known as SURFING!

   The KEY <~[] to process **AUTOMATION**, is secure, persistent access
   to the command-line environments of connected devices. The Internet
   is in fact BILLIONS of connected devices.

   Browsers however, do NOT have direct access to the command-line
   functionality of remote devices, nor are they supposed to.
END

   my $demo_banner_2=<<'END';

   This is precisely why you are *not* reading this in a browser.
   -------------------------------------------------------------

   FullAuto is an Automation and High Productivity Framework - it is *NOT*
   a browser - nor is it "supposed" to be. But that doesn't mean it has to 
   be ...
               .-'''-.                                        ___
              '   _    \                                   .'/   \
   /|       /   /` '.   \         .--.   _..._            / /     \
   ||      .   |     \  '         |__| .'     '.   .--./) | |     |
   ||      |   '      |  '.-,.--. .--..   .-.   . /.''\\  | |     |
   ||  __  \    \     / / |  .-. ||  ||  '   '  || |  | | |/`.   .'
   ||/'__ '.`.   ` ..' /  | |  | ||  ||  |   |  | \`-' /   `.|   |
   |:/`  '. '  '-...-'`   | |  | ||  ||  |   |  | /("'`     ||___|
   ||     | |             | |  '- |  ||  |   |  | \ '---.   |/___/
   ||\    / '             | |     |__||  |   |  |  /'""'.\  .'.--.
   |/\'..' /              | |         |  |   |  | ||     ||| |    |
   '  `'-'`               |_|         |  |   |  | \'. __// \_\    /
                                      '--'   '--'  `'---'   `''--'
END

   my $demo_banner_3=<<'END';

                        (                   (        )   ____
                        )\ )   (     (      )\ )  ( /(  |   /
                       (()/(   )\    )\    (()/(  )\()) |  /
                        /(_))(((_)((((_)(   /(_))((_)\  | /
                       (_))  )\___ )\ _ )\ (_)) __ ((_) |/
           ___ _ _     / __|((/ __|(_)_\(_)| _ \\ \ / /(
          / _ \ '_|    \__ \ | (__  / _ \  |   / \ V / )\
          \___/_|      |___/  \___|/_/ \_\ |_|_\  |_| ((_)


 BECAUSE you don't have to . . .

  ____ ____ ____ ____ ____ ____ ____ ____     ___     _ _   _       _
 ||R |||E |||M |||E |||M |||B |||E |||R ||   | __|  _| | | /_\ _  _| |_ ___ 
 ||__|||__|||__|||__|||__|||__|||__|||__||   | _| || | | |/ _ \ || |  _/ _ \
 |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
  ____ ____ ____ ____ ____ ____ ____ ____
 ||C |||O |||M |||M |||A |||N |||D |||S ||    _  _  __ __  ______   _
 ||__|||__|||__|||__|||__|||__|||__|||__||   | \/ \|_ (_    |  |   |_||  |  
 |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|   |_/\_/|____)  _|_ |   | ||__|__
END

   my $demo_banner_4=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)

      _  _   _ _____ ___  __  __   _ _____ ___ ___
     /_\| | | |_   _/ _ \|  \/  | /_\_   _| __/ __|
    / _ \ |_| | | || (_) | |\/| |/ _ \| | | _|\__ \
   /_/ \_\___/  |_| \___/|_|  |_/_/ \_\_| |___|___/  THE

    #####   ###     #####   ##  ## #####     FASTER,
   #######  ###    ### ### ### ###  #####    EASIER,
   ### # #  ###    ### ### ### ###  ## ###   with more,
   ##      ###     ##   ## ##  ###  ##  ##   VISIBILITY,
   ##      ###     ##   ## ###  ## ###  ##   more PRECISION,
   ### # # ### ### ### ### ### ### ### ###   more CUSTOMIZABLE,
   ####### ####### ####### ####### ######    LESS COST, and MORE RESULTS than
    #####   #####   #####   #####  #####     any other technology AVAILABLE!!

END

   my $demo_banner_5=<<'END';


     __    _____ _____ / __    '########::'########::::'###::::'##:::::::
     ||    ||==   ||    ((      ##.... ##: ##.....::::'## ##::: ##:::::::
     ||__| ||___  ||   \_))     ##:::: ##: ##::::::::'##:. ##:: ##:::::::
                                ########:: ######:::'##:::. ##: ##:::::::
      ____  _____ _____         ##.. ##::: ##...:::: #########: ##:::::::
     (( ___ ||==   ||           ##::. ##:: ##::::::: ##.... ##: ##:::::::
      \\_|| ||___  ||           ##:::. ##: ########: ##:::: ##: ########:
                               ..:::::..::........::..:::::..::........:: 

   The *CLOUD* is nothing more than REMOTE DEVICES. FULL Automation of
   the *CLOUD* means FULL remote control of these devices. To achieve
   that, a tool requires FULL, PERSISTENT and SECURE access to a remote
   device's command-line environment. Computer Professionals typically
   use tools like SSH (Secure Shell) and SFTP (Secure FTP) to gain full
   access to remote command-line environments. These utilities are already
   installed on billions of devices globally, or can be easily installed
   for FREE on nearly EVERY network connected device in existence -
   including smart phones and tablets!
END

   my $demo_banner_6=<<'END';

        ___     _ _   _       _
       | __|  _| | | /_\ _  _| |_ ___
       | _| || | | |/ _ \ || |  _/ _ \
   THE |_| \_,_|_|_/_/ \_\_,_|\__\___/(c) 
    ______                    _           _                            _
   (____  \                  | |      _  | |                          | |
    ____)  ) ____ _____ _____| |  _ _| |_| |__   ____ ___  _   _  ____| |__
   |  __  ( / ___) ___ (____ | |_/ |_   _)  _ \ / ___) _ \| | | |/ _  |  _ \
   | |__)  ) |   | ____/ ___ |  _ (  | |_| | | | |  | |_| | |_| ( (_| | | | |
   |______/|_|   |_____)_____|_| \_)  \__)_| |_|_|   \___/|____/ \___ |_| |_|
                                                                (_____|

   Current automation technologies do not typically use generic and readily
   available utilities designed for human interaction - like the command
   shell you are now using for this demonstration. Rather they rely on an
   architecture known as client-server. The problem with client-server is
   that special (and often VERY costly) software needs to be installed on
   *EVERY* device BEFORE it can be accessed and automated. This very
   requirement is one of the biggest productivity obstables to rapid
   automation implementation. Additionally, client-server setups are much
   more complex, fragile, and challenging to code and maintain than FullAuto!
END

   my $demo_banner_7=<<'END';

        ___     _ _   _       _
       | __|  _| | | /_\ _  _| |_ ___
       | _| || | | |/ _ \ || |  _/ _ \
   THE |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
       ____  _ ________
      / __ \(_) __/ __/__  ________  ____  ________
     / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ ___/ _ \
    / /_/ / / __/ __/  __/ /  /  __/ / / / /__/  __/
   /_____/_/_/ /_/  \___/_/   \___/_/ /_/\___/\___/

   FullAuto uses already available SSH and SFTP services to FULLY automate
   command operations on remote devices. The DIFFERENCE lies in *HOW* FullAuto
   connects to and uses these services. Unlike any other technology, FullAuto
   creates and maintains a PERSISENT connection via these protocols, and
   even older ones like TELNET and FTP. Current SSH 2.0 implementations can
   be configured to allow similar behavior, but it varies from device to
   device, and is not widely available. FullAuto has NO such dependency. If
   a SSH client (or TELNET or SFTP or FTP) of ANY kind can connect to the
   device, FUllAuto can connect to it as well - PERSISTENTLY.

END

   my $demo_banner_8=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
    __    __ _              _____ _                  _   _
   / / /\ \ \ |__  _   _    \_   \ |_    /\/\   __ _| |_| |_ ___ _ __ ___
   \ \/  \/ / '_ \| | | |    / /\/ __|  /    \ / _` | __| __/ _ \ '__/ __|
    \  /\  /| | | | |_| | /\/ /_ | |_  / /\/\ \ (_| | |_| ||  __/ |  \__ \
     \/  \/ |_| |_|\__, | \____/  \__| \/    \/\__,_|\__|\__\___|_|  |___/
                   |___/
 
   For the very first time, there is now an automation tool that works just
   like computer professionals do. The very same commands and work-flows
   that professionals use every day can now be introduced almost verbatim
   into a FullAuto custom code file, and work precisely the same as if
   performed manually. FullAuto leverages the skillsets and legacy tools
   and scripts already in place in countless organizations all over the
   world - and simply connects them ALL together like never before. The
   result is faster automation implementation, eaiser maintainability, and
   significantly lower costs. Staff will spend less time on repetitive
   tasks, and more time on innovation.
END

   my $demo_banner_9=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___
   | _| || | | |/ _ \ || |  _/ _ \
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)
      _             _   __    __ _                 __               ___
     /_\  _ __   __| | / / /\ \ \ |__  _   _    /\ \ \_____      __/ _ \
    //_\\| '_ \ / _` | \ \/  \/ / '_ \| | | |  /  \/ / _ \ \ /\ / /\// /
   /  _  \ | | | (_| |  \  /\  /| | | | |_| | / /\  / (_) \ V  V /   \/
   \_/ \_/_| |_|\__,_|   \/  \/ |_| |_|\__, | \_\ \/ \___/ \_/\_/    ()
                                       |___/

   False assumptions. The "experts" thought a tool like FullAuto was not
   possible. The assumption was because output from a generic connection
   could have INFINITE variation (TRUE), that there was "no way" to create
   a solution that could successfully separate transmission noise from
   valid command-line output and error output (which makes unpredictable
   appearances in the output). Running one command programmatically has
   never been an issue - but the goal of running MULTIPLE commands
   INTERACTIVELY over a PERSISENT "generic" (i.e., not client-server)
   connection - was assumed to be **impossible**. (FALSE!!)

END

   my $demo_banner_10=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_ ___      ___    __   __     _  __ _ ___ __ 
   | _| || | | |/ _ \ || |  _/ _ \      | |_||_   |_  \/ |_)|_ |_) | (_
   |_| \_,_|_|_/_/ \_\_,_|\__\___/(c)   | | ||__  |__ /\ |  |__| \ | __)

   __      _____ ___ ___     _      _____  ____  _  _______  __ 
   \ \    / / __| _ \ __|   | | /| / / _ \/ __ \/ |/ / ___/ / /
    \ \/\/ /| _||   / _|    | |/ |/ / , _/ /_/ /    / (_-- /_/
     \_/\_/ |___|_|_\___|   |__/|__/_/|_|\____/_/|_/\____/(_)


   Not the first time in history this has happened. There is no technical
   reason that a tool like FullAuto could not have been created 30 years
   ago, but for the false belief that it wasn't possible. Experts will
   generally not spend their time trying to solve "impossible" problems.
   Not until Brian Kelly has anyone apparently thought any differently.
   Brian conceived of FullAuto as early as 1998, and began active
   development in 2000. However, it would take 15 LONG years to make it
   a reality. The experts were wrong - but they weren't crazy. The
   problem was not trivial, and the solution is not either!

END

   my $demo_banner_11=<<'END';

   People typically use utilities like SSH and SFTP to access the
   command-line environments of remote devices. These utilities are
   already installed on millions of devices globally, or can be easily
   installed for FREE on mearly EVERY networked device - including phones
   and tablets.

   Programs however, typically rely on client-server architecture,
   which requires that special software be installed on *EVERY*
   device BEFORE it can be accessed and automated.

   "Technically", ssh and sftp are also "client-server". The critical
   difference is that these programs are *NOT* "special".



   As long as a device can be remotely connected to via ssh, sftp,
   telnet, ftp, http or really, ANY remote computing protocol,
   FullAuto can completely automate any and all activities on that
   device, and other devices all simultaneously and persistently.

   Essentially, whatever a person can do on and with a device
   "manually" - FullAuto can do PROGRAMMATICALLY ... securely.

END

   my %fullauto_demo_10=(

      Name => 'fullauto_demo_10',
      Banner => $demo_banner_10,
      Result => sub { return '{fullauto_demo}<' },

   );

   my %fullauto_demo_9=(

      Name => 'fullauto_demo_9',
      Banner => $demo_banner_9,
      Result => \%fullauto_demo_10,

   );

   my %fullauto_demo_8=(

      Name => 'fullauto_demo_8',
      Banner => $demo_banner_8,
      Result => \%fullauto_demo_9,

   );

   my %fullauto_demo_7=(

      Name => 'fullauto_demo_7',
      Banner => $demo_banner_7,
      Result => \%fullauto_demo_8,

   );

   my %fullauto_demo_6=(

      Name => 'fullauto_demo_6',
      Banner => $demo_banner_6,
      Result => \%fullauto_demo_7,

   );

   my %fullauto_demo_5=(

      Name => 'fullauto_demo_5',
      Banner => $demo_banner_5,
      Result => \%fullauto_demo_6,

   );

   my %fullauto_demo_4=(

      Name => 'fullauto_demo_4',
      Banner => $demo_banner_4,
      Result => \%fullauto_demo_5,

   );

   my %fullauto_demo_3=(

      Name => 'fullauto_demo_3',
      Banner => $demo_banner_3,
      Result => \%fullauto_demo_4,

   );

   my %fullauto_demo_2=(

      Name => 'fullauto_demo_2',
      Banner => $demo_banner_2,
      Result => \%fullauto_demo_3,

   );

   my %fullauto_demo_1=(

      Name => 'fullauto_demo_1',
      Banner => $demo_banner_1,
      Result => \%fullauto_demo_2,

   );

   my %fullauto_demo=(

      Name => 'fullauto_demo',
      Item_1 => {
     
         Text => "FullAuto Introduction",
         Result => \%fullauto_demo_1,

      },
      Item_2 => {

         Text => "FullAuto Demonstration",

      },
      Scroll => 1,
      Banner => $demo_banner,

   );

   if (-1<index lc($0), 'demo') {

      my $demo_out=Menu(\%fullauto_demo);
      print "DONE WITH DEMO\n";<STDIN>;
      exit;
   }

   my $cryptography_banner=<<'END';
   __      __             _           _
   \ \    / /_ _ _ _ _ _ (_)_ _  __ _| |
    \ \/\/ / _` | '_| ' \| | ' \/ _` |_|
     \_/\_/\__,_|_| |_||_|_|_||_\__, (_)
                                |___/

   Exporting, importing and/or using cryptography software, or even
   communicating technical details about cryptography software, is illegal
   in some parts of the world. You are strongly advised to investigate and
   adhere to any export/import and use laws which apply to you when you
   import a release of Net::FullAuto including cryptography modules like
   Crypt::CBC, Crypt::DES and Crypt::Rijndael to your country or
   re-distribute source code from them in any way.

   This website may be a helpful resource:   http://www.cryptolaw.org

   It surveys cryptography laws from around the world. However, consult
   local legal experts before engaging in any potentially risky activity. 
END

   my $cryptography=sub {

      my %cryptography=(

         Name => 'cryptography',
         Result => sub { return '{license_agree}<' },
         Banner => $cryptography_banner,

      );
      return \%cryptography

   };

   my $license_banner=<<END;

   *THANK YOU* For Trying FullAuto!   Net::FullAuto INSTALLATION PROGRAM

   Copyright (C) 2000-2014   Brian M. Kelly   Brian.Kelly\@fullautosoftware.net

   This program comes with ABSOLUTELY NO WARRANTY; for details select  2.
   This is free software, and you are welcome to redistribute it under certain
   conditions; select  3  for details. FullAuto uses  Crypt::DES  which is
   software developed by Systemics Ltd (http://www.systemics.com/). FullAuto
   uses the  Net::SSLeay  module which is software developed by the OpenSSL
   Project for use in the OpenSSL Toolkit. (http://www.openssl.org/) and
   includes cryptographic software written by Eric Young (eay\@cryptsoft.com)
   and Tim Hudson (tjh\@cryptsoft.com)

END

   use CPAN;
   if (-e "dependencies/CPAN/authors" &&
         !(grep {
         /(?:use[-_]?)?internet|online|connect_to_internet_ok/i } @ARGV)) {
      opendir(DH,"dependencies/CPAN/authors/id/F/FR/FREW") ||
         die "Cannot open dir dependencies/CPAN/authors/id/F/FR/FREW: $1\n";
      my $filenames_not_trunced=0;my $got_sub=0;
      while (my $line=readdir(DH)) {
         chomp($line=~tr/\0-\11\13-\37\177-\377//d);
         if ($line=~/Sub-Exporter-Progressive-.*gz$/) {
            $filenames_not_trunced=1;
            last;
         }
         if (-1<index $line,'Sub-') {
            $got_sub=1;
         }
      }
      close DH;
      unless ($filenames_not_trunced) {
         if ($got_sub) {
            if ($^O eq 'solaris' && (-e '/usr/sfw/bin/gtar')) {
               my $message=<<END;

   FullAuto Setup ERROR!:  It appears that the solaris system tar
                           command was used to expand
                           Net-FullAuto-Complete-$main::VERSION.tar.gz,
                           which is a problem. The solaris tar utility
                           has a limit on the length of directory depth
                           and filename that is exceeded by some of the
                           dependencies bundled with FullAuto Setup.

                           Use the tar utility /usr/sfw/bin/gtar to
                           expand Net-FullAuto-Complete-$main::VERSION.tar.gz.

END
               print $message;exit 1;
            } else {
               my $message=<<END;

   FullAuto Setup ERROR!:  It appears that the tar command used to expand
                           Net-FullAuto-Complete-$main::VERSION.tar.gz,
                           has a problem. Some tar utilities have a limit
                           on the length of directory depth and filename
                           that is exceeded by some of the dependencies
                           bundled with FullAuto Setup.

                           Hint: Install and use GNU tar to untar (expand)
                                 Net-FullAuto-Complete-$main::VERSION.tar.gz.

END
               print $message;exit 1;
            }
         } else {
              my $message=<<END;

   FullAuto Setup ERROR!:  It appears that there are missing dependencies
                           in the dependencies/CPAN/authors folder of this
                           Net-FullAuto-Complete distribution.

END
               print $message;exit 1;
         }
      }
      my $loc="$main::curdir/dependencies/CPAN";
      $CPAN::Config->{keep_source_where}=$loc;
      $CPAN::Config->{connect_to_internet_ok}=0;
   }
   use File::Path;

   $main::root_dir=$main::curdir;

   my $incflag=0;my @drive_options=();
   $main::uname_a='';
   my $perl_version=$^V;
   $perl_version=~s/^v//;
   $main::uname_a=`/bin/uname -a` if $^O eq 'linux' || $^O eq 'freebsd';
   if ($^O eq 'cygwin') {
      my $cygcheck=`/bin/cygcheck -c` || die $!;
      my $uname=`/bin/uname` || die $!;
      my $uname_all=`/bin/uname -a` || die $!;
      $uname_all.=$uname;
      my %need_packages=();
      if ($uname=~/x86_64/) {
         foreach my $package ('gcc-core','gcc-g++','make','openssh','openssl',
                              'openssl-devel','perl','db','libdb-devel',
                              'ncurses','cron','inetutils','procps','vim',
                              'unzip','libmpfr4','libcrypt-devel') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
         if (exists $need_packages{'libdb-devel'}) {
            if (-1<index $cygcheck, 'libdb4.8-devel' ||
                  -1<index $cygcheck, 'libdb4.5-devel') {
               delete $need_packages{'libdb-devel'};
            }
         }
         if (exists $need_packages{'db'}) {
            if (-1<index $cygcheck, 'db4.8' ||
                  -1<index $cygcheck, 'db4.5') {
               delete $need_packages{'db'}
            }
         }
      } else {
         foreach my $package ('gcc-core','gcc-g++','make','openssh','openssl',
                              'openssl-devel','perl','perl-libwin32','db4.8',
                              'libdb4.8-devel','ncurses','cron','inetutils',
                              'procps','vim','unzip','libmpfr4') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
      }
      if (keys %need_packages) {
         my $packs='';
         foreach my $pack (sort keys %need_packages) {
            $packs.="      $pack\n";
         }
         if ($packs) {
            print "\n\n   Fatal Error!: The following Cygwin",
                  "\n                 packages are missing from",
                  "\n                 your installation:",
                  "\n\n$packs",
                  "\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
                  exit 1;
         }
      }
      my $services=`ps -e` || die $!;
      my @required_cygwin_services=();
      foreach my $cygwin_service ('sshd','cygserver') {
         push @required_cygwin_services, $cygwin_service
            if -1==index $services,$cygwin_service;
      } 
      if (-1<$#required_cygwin_services) {
         my $services='';
         foreach my $service (sort @required_cygwin_services) {
            $services.="      $service\n";
         }
         if ($services) {
            print "\n\n   Fatal Error!: The following Cygwin ".
                  "services are not running on your system:".
                  "\n\n$services".
                  "\n\n   The FullAuto installation will not".
                  "\n   succeed without these services installed".
                  "\n   and running.".
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
                  exit 1;
         }
      }
      if (!can_cc()) {
         if ($Config{cc} && $Config{cc}=~/gcc-4/) {
            `cd /usr/bin;ln -s gcc.exe gcc-4`;
            `cd /usr/bin;ln -s g++.exe g++-4;cd $main::cwd`;
         } else {
            my $stup='setup-x86.exe';
            $stup='setup-x86_64.exe' if $uname=~/WOW64/;
            my $die=<<END;

       FATAL ERROR! : The Gnu C Compiler 'gcc': gcc-core
                      & gcc-g++ as provided by Cygwin
                      is required to install FullAuto
                      on Windows.

       ( Hint: Run Cygwin $stup and install 'gcc-core'
               and 'gcc-g++' under the Category 'Devel' ).

END
            die $die;
         }
      }
   } elsif ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
      if (-1==index $0,'Setup-FullAuto-v') {
         my $die=<<'END';

       FATAL ERROR! : Cygwin Linux Emulation Layer
                      is required to use FullAuto
                      on Windows - goto www.cygwin.com.

           Be sure to install the following programs in
           addition to the base package:

           inetutils and openssh [as provided by Cygwin]
           perl [as provided by Cygwin] (*NOT* CPAN)
           perl-libwin32 [as provided by Cygwin] (*NOT* CPAN)
           ncurses, cron, and procps [as provided by Cygwin]
           gcc-core and gcc-g++ [as provided by Cygwin]
           Oracle Berkeley DB [as provided by Cygwin or Oracle]

           **IMPORTANT** - the FullAuto install, either manual
           or via CPAN, must be run *inside* a Cygwin bash shell
           when installing FullAuto on Microsoft Windows.

END
         unless ($ENV{'AUTOMATED_TESTING'}) {
            die $die;
         } else {
            print $die;
            exit 1;
         }
      }
      $incflag=1 if -e './inc';
      use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Win32::DriveInfo";
      use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Term::Menus";

      my %read_license=(

         Label => 'read_license',
         Item_1 => {
            Text => "I accept the license provisions",
         },
         Item_2 => {
            Text => "I do *NOT* accept the license provisions ".
                    "(Install will Exit)",
         },
         Item_3 => {

            Text => "]C[",
            Convey => sub {

               my $endcount=30;
               my @content=();my $tl=0;
               my $linenumber="]P[";
               $linenumber||=1;
               $linenumber=~s/["]//g;
               my $choice=$linenumber;
               if (-1==index $linenumber,'Review') {
                  if ($linenumber=~/Next|Previous/) {
                     $linenumber=~s/^(?:Next|Previous) Page\s*//;
                  }
                  ($linenumber,$endcount)=split '-', $linenumber;
                  open (FH,"<$main::PARdir/inc/LICENSE")
                     or die "Cannot open $main::PARdir/inc/LICENSE: $!\n";
                  @content=<FH>;
                  close FH;
                  $tl=$#content+1;
                  my $lt=$linenumber+13;
                  $endcount=($lt<$tl)?$lt:$tl;
               } elsif (-1<index $linenumber,'WARRANTY') {
                  $linenumber=588;
                  $endcount=597;
               } else { $linenumber=1 }
               my $ec=$endcount-1;
               if (-1==index $choice,'WARRANTY') {
                  if ($ec == $#content) {
                     my $lm=$linenumber-13;
                     return ("Previous Page $lm-$linenumber");
                  } elsif ($linenumber==1) {
                     my $lo=$linenumber+13;
                     my $ln=$lo+13;
                     return ("Next Page $lo-$ln");
                  } else {
                     my $lo=$linenumber+13;
                     my $ln=$lo+29;
                     my $el=$linenumber-1;
                     my $pl=$linenumber-13;
                     return ("Next Page $lo-$ln","Previous Page $pl-$el");
                  }
               }
            },
            Result => { 'read_license'=>'recurse' },

         },
         Item_4 => {
            Text => "Return to previous screen",
            Result => sub { return '{license_agree}<' },
         },
         Banner => sub {
               my $linenumber="]P[";
               $linenumber||=1;
               $linenumber=~s/["]//g;
               open (FH,"<$main::PARdir/inc/LICENSE")
                  or die "Cannot open $main::PARdir/inc/LICENSE: $!\n";
               my @content=<FH>;
               close FH;
               my $co=$#content+1;
               my $endcount=(13<$co)?13:$co;
               if (-1==index $linenumber,'Review') {
                  if ($linenumber=~/Next|Previous/) {
                     $linenumber=~s/^(?:Next|Previous) Page\s*//;
                  }
                  ($linenumber,$endcount)=split '-', $linenumber;
                  my $tl=$#content+1;
                  my $lt=$linenumber+13;
                  $endcount=($lt<$tl)?$lt:$tl;
               } elsif (-1<index $linenumber,'WARRANTY') {
                  $linenumber=588;
                  $endcount=597;
               } else { $linenumber=1 }
               $linenumber=0 if $linenumber==1;
               --$endcount;
               my $banner=join "", @content[$linenumber..$endcount];
               $banner=~s/^/   /mg;
               return $banner;
            }

      );

      my %license_agree=(

         Name => 'license_agree',
         Item_1 => {

            Text => "I agree to the license provisions\n\n",

         },
         Item_2 => {

            Text => "Review GNU Affero Public License WARRANTY DISCLAIMER\n",
            Result => \%read_license,

         },
         Item_3 => {

            Text => "*IMPORTANT* STRONG CRYPTOGRAPHY WARNING!",
            Result => $cryptography,

         },
         Item_4 => {

            Text => "I DO NOT AGREE to the license provisions\n".
                    "                   ( FullAuto Install will EXIT )",
         },
         Scroll => 1,
         Banner => $license_banner,

      );

      my $lic_sel=Menu(\%license_agree);
      chomp($lic_sel);
      exit if $lic_sel eq ']quit[';
      if (-1<index $lic_sel, 'NOT') {
         print "\n\n   You have elected *NOT* to install FullAuto.",
               "\n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@fullautosoftware.net.",
               "\n\n   Press ANY key to exit.\n\n";<STDIN>;
         exit;
      }
      my $cygwin_loc=get_cygwin_location();
      if ($cygwin_loc) {
         my $drv=substr($cygwin_loc,0,1);
         my $dt=Win32::DriveInfo::DriveType($drv);
         my $FileSystemName=(Win32::DriveInfo::VolumeInfo($drv))[3];
         my $file_size = (Win32::DriveInfo::DriveSpace("$drv:"))[6];
         my $banner=<<'END';print "MKLINE=".__LINE__."\n";

    ___                     _            _     _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  | |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _| |_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__| (_)
             |_|
END
   my $size_file=&size_fmt($file_size);print "MKLINE=".__LINE__."\n";
         $banner.=<<END;print "MKLINE=".__LINE__."\n";

   FullAuto Setup has detected a Cygwin installation at $cygwin_loc.
   Setup has also determined that there is $size_file Free Space on
   the Drive $drv Volume. It is IMPORTANT TO NOTE that FullAuto Setup
   will attempt to use this installation. If this is undesirable, then
   select choice '2' and FullAuto Setup will EXIT. It is recommended
   that you use the cpan utility to install or update FullAuto, if
   there is more than one Cygwin installation on your system.

   If you're sure you wish to proceed with your $cygwin_loc setup,
   then select choice '1' and FullAuto Setup will continue . . .

END
         my %cygchoice=(

               Label => 'cygchoice',
               Item_1 => {
                  Text => 'Continue with FullAuto Setup',
               },
               Item_2 => {
                  Text => 'CANCEL FullAuto Setup and EXIT',
               },
               Scroll => 1,
               Banner => $banner,
         );
         my $selection=Menu(\%cygchoice);
         chomp($selection);
         if (-1<index $selection,'Continue') {
            my $cwd=cwd();
            my $p='/usr/bin/perl -MCPAN -e';
            my $b="$cygwin_loc/bin/bash -lc";
            exec "$b \"$p 'install Net::FullAuto'\";'fa --new-user'";
         }
         exit if $selection eq ']quit[';
         exit if $selection eq 'CANCEL FullAuto Setup and EXIT';
         $main::root_dir=$cygwin_loc;
      } else {
         my $drv='';
         foreach my $d (Win32::DriveInfo::DrivesInUse()) {
            my $dt=Win32::DriveInfo::DriveType($d);
            next if $dt == 5 || $dt == 4 || !$dt;
            my $FileSystemName=(Win32::DriveInfo::VolumeInfo($d))[3];
            next if $FileSystemName ne 'NTFS';
            my $file_size = (Win32::DriveInfo::DriveSpace("$d:"))[6];
            my $one_gb=1024*1024*1024;
            if ($one_gb<$file_size) {
               $drv=$d;
               if ($dt == 3) {
                  push @drive_options, "Drive $d NTFS Fixed Disk ".
                                        &size_fmt($file_size)." Free Space";
               } elsif ($dt == 2) {
                  push @drive_options, "Drive $d NTFS Removeable Disk ".
                                        &size_fmt($file_size)." Free Space";
               } else {
                  push @drive_options, "Drive $d NTFS Volume ".
                                        &size_fmt($file_size)." Free Space";
               }
            }
         }
         if (-1<$#drive_options) {
            if (0==$#drive_options) {
               $main::root_dir="$drv:\\cygwin";
            } else{
               my $banner="\n\n   Please select the Drive/Volume where you ".
                          "would like\n   Cygwin and FullAuto Installed.\n".
                          "\n   ( If you don't see the Drive/Volume you ".
                          "desire,\n     it is probably because the Drive/".
                          "Volume lacks\n     sufficient disk space. At ".
                          "least One Gigabyte\n     of free space is needed ".
                          "for a Windows based\n     Cygwin/FullAuto ".
                          "Installation. )\n\n";
               my %menu_drives=(

                  Label => 'menu_drives',
                  Item_1 => {

                     Text => "]C[",
                     Convey => \@drive_options,

                  },
                  Banner => $banner,

               );
               my $selection=Menu(\%menu_drives);
               chomp($selection);
               exit if $selection eq ']quit[';
               $selection=~s/^\s*Drive\s+([A-Z])\s+NTFS.*$/$1/s;
               $main::root_dir="$selection:\\cygwin";
            }
         } else {
            print "\n\n   Fatal Error! - Insufficient Disk Space.\n".
                  "                 At least One Gigabyte (1.0 GB) of\n".
                  "                 Free Disk Space is needed to install\n".
                  "                 Cygwin and FullAuto on this Windows\n".
                  "                 host.".
                  "n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
         }
      }
   } elsif (!can_cc() && ((exists $main::amazon{'ami'}) ||
         (exists $main::amazon{'rhel'}) ||
         (exists $main::amazon{'centos'}))) {

      my $grpi=`sudo yum grouplist`;
      if (-1<index $grpi,'no installed groups file') {
         my $out=`sudo yum groups mark convert`;
         $grpi=`sudo yum grouplist`;
      }
      my %groups=();my $group_type='';
      foreach my $ln (split "\n",$grpi) {
         if ($ln=~/^(.*) [Gg]roups:$/) {
            $group_type=$1;
            $groups{$group_type}={};
         } else {
            $ln=~/^\s*(.*)$/;
            $groups{$group_type}->{$1}='';
         }
      }
      my $yins=`sudo yum list installed`;
      unless (exists $groups{'Installed'}->{'Development tools'}) {
         open(AG,"sudo yum -y update|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
         open(AG,"sudo yum -y clean all|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
         open(AG,"sudo yum -y groupinstall 'Development tools'|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
      }
      unless (-1<index $yins,'openssl-devel') {
         open(LD,"sudo yum -y install 'openssl-devel'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      if ((exists $main::amazon{'rhel'}) ||
            (exists $main::amazon{'centos'})) {
         unless (-1<index $yins,'wget') {
            open(LD,"sudo yum -y install 'wget'|");
            while (my $line=<LD>) {
               print $line;
            }
            close LD;
         }
         my $wget_url='http://pkgs.repoforge.org/rpmforge-release/'.
                      'rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm';
         #my=$wget_url='http://dl.fedoraproject.org/pub/epel/beta/7'.
         #             '/x86_64/epel-release-7-0.2.noarch.rpm';
         open(LD,"sudo wget $wget_url|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
         #my $rpm='epel-release-7-0.2.noarch.rpm';
         my $rpm='rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm';
         open(LD,"sudo rpm -ivh $rpm|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
         open(LD,"sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      unless (-1<index $yins,'figlet') {
         open(LD,"sudo yum -y install 'figlet'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      unless (-1<index $yins,'nano') {
         open(LD,"sudo yum -y install 'nano'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      my $argvs=join " ", @ARGV;
      #if (grep { /-*add[-_]?dependencies/i } @ARGV) {
      #   exec 'sudo',$^X,'Makefile.PL','add_dependencies';
      #} else {
      exec "sudo $^X Makefile.PL $argvs";
      #}
   } elsif (exists $main::amazon{'centos'}) {

      my $yins=`yum list installed`;
      unless (-1<index $yins,'openssl-devel') {
         open(LD,"sudo yum -y install 'openssl-devel'|");
         while (my $line=<LD>) {
            if (-1<index $line,"allocate") {
print "YEP MEMORY=$line\n";<STDIN>;
            }
            print $line;
         }
         close LD;
      }
      my $new_wget=0;
      unless (-1<index $yins,'wget') {
         $new_wget=1;
         open(LD,"sudo yum -y install 'wget'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      if ($new_wget) {
         my $wget_url='http://pkgs.repoforge.org/rpmforge-release/'.
                      'rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm';
         #my=$wget_url='http://dl.fedoraproject.org/pub/epel/beta/7'.
         #             '/x86_64/epel-release-7-0.2.noarch.rpm';
         open(LD,"sudo wget $wget_url|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
         #my $rpm='epel-release-7-0.2.noarch.rpm';
         my $rpm='rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm';
         open(LD,"sudo rpm -ivh $rpm|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
         open(LD,"sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      unless (-1<index $yins,'figlet') {
         open(LD,"sudo yum -y install 'figlet'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      unless (-1<index $yins,'nano') {
         open(LD,"sudo yum -y install 'nano'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      my $argvs=join " ", @ARGV;
      #if (grep { /-*add[-_]?dependencies/i } @ARGV) {
      #   exec 'sudo',$^X,'Makefile.PL','add_dependencies';
      #} else {
      exec "sudo $^X Makefile.PL $argvs";
      #}

   } elsif (!can_cc() && (exists $main::amazon{'suse'})) {

      # Manual Setup openSuSE host before CPAN:
      #
      # zypper ar -f -n openSUSE:13.1 http://download.opensuse.org/distribution/13.1/repo/oss/ openSUSE:13.1
      # zypper -n --gpg-auto-import-keys install --force-resolution wget
      # zypper -n --gpg-auto-import-keys install --force-resolution figlet
      # zypper -n --gpg-auto-import-keys install --force-resolution nano
      # zypper -n install --type pattern Basis-Devel
      # zypper -n install openssl-devel
      # wget http://www.cpan.org/src/5.0/perl-5.20.0.tar.gz
      # tar zxvf perl-5.20.0.tar.gz
      # cd perl-5.20.0
      # ./Configure -d -Dnoextensions=ODBM_File
      # make install
      # cpan
      #

      my $zypper=`/bin/zypper packages -i`;
      if (0 && -1==index $zypper,'gcc') {
         open(ZP,"zypper -n install --type pattern Basis-Devel|");
         while (my $line=<AG>) {
            print $line;
         }
         close ZP;
         open(ZP,"zypper -n install openssl-devel|");
         while (my $line=<AG>) {
            print $line;
         }
         close ZP;
         my $repos='zypper ar -f -n openSUSE:13.1 '.
                   'openSUSE:13.1 http://download.'.
                   'opensuse.org/distribution/13.1'.
                   '/repo/oss/  openSUSE:13.1';
         open(ZP,"$repos|");
         while (my $line=<AG>) {
            print $line;
         }
         close ZP;
         my $figlet="zypper -n --gpg-auto-import-keys install".
                    " --force-resolution figlet";
         open(ZP,"$figlet|");
         while (my $line=<AG>) {
            print $line;
         }
         close ZP;
         my $nano="zypper -n --gpg-auto-import-keys install".
                    " --force-resolution nano";
         open(ZP,"$nano|");
         while (my $line=<AG>) {
            print $line;
         }
         close ZP;
      }
         
   } elsif (!can_cc() && (exists $main::amazon{'ubuntu'})) {

      my $dpkg=`/bin/dpckg -l`;
      my $update_flag=0;
      if (-1==index $dpkg,'build-essential') {
         open(AG,"sudo apt-get -y update|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
         $update_flag==1;
         open(AG,"sudo apt-get -y install 'build-essential'|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
      }
      if (-1==index $dpkg,'libssl-dev') {
         unless ($update_flag) {
            open(AG,"sudo apt-get -y update|");
            while (my $line=<AG>) {
               print $line;
            }
         }
         open(LD,"sudo apt-get -y install 'libssl-dev'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      if (-1==index $dpkg,'figlet') {
         open(LD,"sudo apt-get -y install 'figlet'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      if (-1==index $dpkg,'nano') {
         open(LD,"sudo apt-get -y install 'nano'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }
      if (-1==index $dpkg,'perl-doc') {
         open(LD,"sudo apt-get -y install 'perl-doc'|");
         while (my $line=<LD>) {
            print $line;
         }
         close LD;
      }

   } elsif (!can_cc()) {

      my $moreinfo='';my $s='          ';
      if ($Config{cc} and $Config{cc}!~/^\s*$/) {
         $moreinfo="\n\n$s            You are running $^X version $].\n".
              "\n$s            The Config.pm file for this perl installation".
              "\n$s            contains \"$Config{cc}\" as the compiler used".
              "\n$s            to build this perl, but this compiler does not".
              "\n$s            exist in the PATH and may not be installed on".
              "\n$s            this host.\n".
              "\n$s            Retrofitting an existing perl installation to".
              "\n$s            work properly with a new compiler for building".
              "\n$s            CPAN modules, is tricky and NOT recommended.".
              "\n$s            Often the available perl (especially on Unix".
              "\n$s            systems) is highly integrated with the host".
              "\n$s            OS and many of its features and utilities.".
              "\n$s            Upgrading the system perl, but not the overall".
              "\n$s            OS is risky and may result in more than a".
              "\n$s            few system problems and instabilities.\n".
              "\n$s            The recommended approach is build a NEW perl".
              "\n$s            from source with your choice of newly installed".
              "\n$s            compiler (such as gcc) in a different location".
              "\n$s            (such as /usr/local/lib) or your home directory".
              "\n$s            if you lack root/admin privileges."
      }
      my $die="\n       FATAL ERROR! : A C Compiler (such as cc or gcc)".
              "\n                      is required to install FullAuto".
              $moreinfo.
              "\n                      (Hint: goto www.gnu.org for gcc).".
              "\n\n";
      die $die;

   } elsif (exists $main::amazon{'freebsd'}) {
      unless (-e '/usr/local/bin/figlet') {
         open(AG,"pkg_add -r figlet|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
      }
      unless (-e '/usr/local/bin/nano') {
         open(AG,"pkg_add -r nano|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
      }
   } elsif (exists $main::amazon{'gentoo'}) {
      unless (-e '/usr/local/bin/figlet') {
         my $fs='ftp://ftp.figlet.org/pub/figlet/program'.
                '/unix/figlet-2.2.5.tar.gz';
         open(AG,"(wget $fs;tar zxvf fig*gz;cd figlet-2.2.5;make install)|");
         while (my $line=<AG>) {
            print $line;
         }
         close AG;
      }
   }
   if ($incflag && ($main::PARdir ne $main::curdir)) {
      open(PD,">$main::PARdir/inc_exists.txt")
         or die "Cannot open $main::PARdir/inc_exists.txt: $!\n";
      print PD cwd()."/inc\n";
      close(PD);
   }
   my $cpantest=0;
   $cpantest=1 unless $mycpantest;
   use if ($mycpantest), "CPAN::MyConfig";
   use if ($cpantest), "CPAN::Config";
   
   sub fa_err_exit {
      die "$_[0]\n\n*** Please manually install $_[1]".
          " from cpan.org first...\n"
   }

   sub fa_find_latest {
      my $temp=0;
      my $look=shift||'';
      unless ($look) {
         die "ERROR - No argument provided to &fa_find_latest().\n";
      }
      $look=~s/::/-/g;
      if ($look eq 'LWP') {
         $look='libwww-perl';
      } elsif ($look eq 'Compress-Zlib') {
         $look='IO-Compress';
      } elsif ($look eq 'MIME-Entity') {
         $look='MIME-tools';
      } elsif ($look eq 'Term-ReadKey') {
         $look='TermReadKey';
      } elsif ($look eq 'IO-Pty') {
         $look='IO-Tty';
      } elsif ($look eq 'Mail-Internet') {
         $look='MailTools' ;
      } elsif ($look eq 'Mail-Header') {
         $look='MailTools' ;
      } elsif ($look eq 'Mail-Field') {
         $look='MailTools' ;
      } elsif ($look eq 'Date-Format') {
         $look='TimeDate';
      } elsif ($look eq 'Pod-Man') {
         $look='podlators';
      }
      print "***** Looking for Most Recent \"$look Dir\" \n";
      CPAN::HandleConfig->load;
      my $d = $CPAN::Config->{build_dir};
      if (!(defined $d) || !(-d $d)) {
         $d=(getpwuid $>)[7].'/.cpan/build';
         unless (-d $d) {
            unless (-d "/root/.cpan/build") {
               die "ERROR - Can't locate .cpan/build directory";
            } else {
               $d='/root/.cpan/build';
            }
         }
      }
      my $new='';my $file='';
      opendir(DH,$d) or
         die "ERROR - Can't read Directory $d: $!\n";
      while ($_ = readdir(DH)) {
         next if ($_ eq ".") || ($_ eq "..") || (/\.yml$/);
         if ($_!~/^$look[-]\d/) {
            if (-d $d.'/'.$_) {
               my $dr=$d.'/'.$_;
               $new=&look_inside_dir($dr,$look);
               #last if $new;
            } next
         }
         $file=sprintf("%s/%s",$CPAN::Config->{build_dir},$_);
         my $attrs = stat $file;
         my $diff = time()-$attrs->[9];
         if ($temp == 0 && $_=~/^$look[-]\d/) {
           $temp=$diff;
           $new=$file;
         }
         if ($diff<$temp) {
            $temp=$diff;
            $new=$_;
         }
      }
      close(DH);
      $new=$file if !$new && $file;
      print "***** Module Directory ",$new,"\n";
      return $new; 
   }

   sub look_inside_dir {

      my $d=$_[0];
      my $look=$_[1];
      my $found='';
      opendir(LI,$d) or
         die "ERROR - Can't read Directory $d: $!\n";
      my $tar='';
      while ($_ = readdir(LI)) {
         next if ($_ eq ".") || ($_ eq "..");
         if ($_=~/[.]tar$/ && $_=~/^$look[-]\d/) {
            $tar=$_;
            next;
         }
         if ($_=~/^$look[-]\d/ && -d $_) {
            $tar='';
            last;
         }
      }
      close(LI);
      if ($tar) {
         unless ($CPAN::Config->{tar}) {
            if (-e '/usr/sfw/bin/gtar') {
               $CPAN::Config->{tar}='/usr/sfw/bin/gtar';
            } elsif (-e '/usr/bin/tar') {
               $CPAN::Config->{tar}='/usr/bin/tar';
            } elsif (-e '/usr/local/bin/tar') {
               $CPAN::Config->{tar}='/usr/local/bin/tar';
            } else {
               print "\n\n   Fatal Error!: The 'tar' utility is".
                  " missing.\n".
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
                  exit 1;
            }
         }
         chdir $d;
         if (($main::system_type eq 'ami') ||
               ($main::system_type eq 'ubuntu') ||
               ($main::system_type eq 'rhel') ||
               ($main::system_type eq 'centos')) {
            print "***** Untar: sudo ",$CPAN::Config->{tar}," xvf $tar\n";
            open(FH, "sudo ".$CPAN::Config->{tar}." xvf $tar|");
         } else {
            print "***** Untar: ",$CPAN::Config->{tar}," xvf $tar\n";
            open(FH, $CPAN::Config->{tar}." xvf $tar|");
         }
         while (my $line=<FH>) {
            print $line;
         }
         close FH;
         chdir $CPAN::Config->{build_dir};
         $tar=~s/[.]tar$//;
         return "$d/$tar";
      }
      return '';

   }
   
   sub fa_install_mod {
   
      my $p=$_[0];
      my $task=$_[1];
      my $butil=$_[2]||'';
      my $force=$_[3]||'';
      my $version=$_[4]||'';
      my $echo=$_[5]||'';
      my $dir='';
      my $cpan_error='';
      eval {
         require CPAN::Mini;
         import CPAN::Mini;
      };
      if (!$@ && grep { /-*add[-_]?dependencies/i } @ARGV) {
         my $distribution = CPAN::Shell->expand(
               "Module",$p 
            )->distribution()->pretty_id();
         my $let=unpack('a1',$distribution);
         my $lett=unpack('a2',$distribution);
         my $minicpan=CPAN::Mini->new(

            #remote => "http://www.cpan.org",
            remote => "http://www.perl.com/CPAN",
            local  => cwd()."/dependencies/CPAN",
            log_level => 'debug',
            exact_mirror => 1,
            
         );
         $minicpan->mirror_file(
            "authors/id/$let/$lett/$distribution");
      }
      my $mod_info='';my $instfile='';
      if (!$version && !(-e "dependencies/CPAN/authors") || (grep {
            /(?:use[-_]?)?internet|online|connect_to_internet_ok/i
            } @ARGV)) {
         CPAN::Shell->m($p);
         eval {
            require CPAN;
            {
               local *STDOUT;
               open(STDOUT, ">", \$mod_info);
               CPAN::Shell->m($p);
            }
         };
         my $instver='';my $cpanver='';
         if ($mod_info) {
            ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
            ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
            ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
         }
         if (!$version && ($instver<$cpanver)) {
            unlink $instfile if $exec_cnt;
            $version=$cpanver;
         }
      }
      eval "require $p;1";
      my $ver='';
      my $testp=$p;
      $testp=~s/::/\//g;
      unless ($@) {
         if ($version) {
            my $ttmp='$ver=$'.$p.'::VERSION';
            eval $ttmp;
            $ver=eval $ver;
            $force=($ver<$version)?1:0;
         } else { $force=0 } 
      } elsif ((-1<index $@,"Can't locate") &&
            (-1==index $@,$testp)) {
         print "\n\n";
         print "   Fatal Error: $@\n\n";
         exit 1;
      }
      if ($@ || $instfile eq '(not' || $force) {
         if ($ENV{'AUTOMATED_TESTING'}) {
            print "Automated Testing Detected: FullAuto needs $p\n",
                  "   to continue, but $p was not detected on this\n",
                  "   host.\n\n";
                  "FullAuto Install will EXIT.";
            exit 1;
         }
         if ($version && $p eq 'Term::Menus') {
            $p="REEDFISH/Term-Menus-$version.tar.gz";
         } elsif ($version && $p eq 'Term::RawInput') {
            $p="REEDFISH/Term-RawInput-$version.tar.gz";
         }
         print "==> $p required."
         and print "*** Installing $p via CPAN\n"
         and
         eval {
            require CPAN;
            CPAN::Shell->notest('get',$p);
         };
         if ($@) {
            $cpan_error="$@ $!";
            die "CPAN Error: $cpan_error\n";
         }
         if ($version && (-1<index $p,'Term-Menus')) {
            $p='Term::Menus';
         } elsif ($version && (-1<index $p,'Term-RawInput')) {
            $p='Term::RawInput';
         }
         if (lc($task) eq 'install') {
            my $sudo='';
            if (($main::system_type eq 'ami') ||
                  ($main::system_type eq 'ubuntu') ||
                  ($main::system_type eq 'rhel') ||
                  ($main::system_type eq 'centos')) {
               $sudo='sudo ';
            }
            $dir||=&fa_find_latest($p);
            print "*** Running $sudo$^X $butil.PL\n";
            print "*** cd to $dir\n";
            if ($echo) {
               system("cd \"$dir\";echo $echo | $sudo$^X $butil.PL");
            } else {
               system("cd \"$dir\";$sudo$^X $butil.PL");
            }
            if ($butil eq 'Makefile') {
               print "*** Running ${sudo}make install\n";
               system("cd \"$dir\";${sudo}make install");
            } else {
               print "*** Running ${sudo}Build install\n";
               system("cd \"$dir\";./Build build;${sudo}./Build install");
            }
         }
         chdir $main::curdir;
         my $_p=$p;
         $_p=~s/::/\//g;
         $_p.='.pm';
         unless (exists $INC{$_p}) {
            eval {
               require $_p;
            };
            if ($@ && -1==index $@,'Attempt to reload') {
               warn $@;
            } else {
               print "*** $p Loaded Successfully\n";
               $exec_cnt=0;
            }
         } elsif (lc($task) eq 'install') {
            my $sudo=0;
            if (($main::system_type eq 'ami') ||
                  ($main::system_type eq 'ubuntu') ||
                  ($main::system_type eq 'rhel') ||
                  ($main::system_type eq 'centos')) {
               $sudo=1;
            }
            my $argvs=join " ", @ARGV;
            if ($sudo) {
               #if (grep { /-*add[-_]?dependencies/i } @ARGV) {
               exec "sudo $^X Makefile.PL $argvs SKIP $p $exec_cnt";
               #} else {
               #   exec 'sudo',$^X,'Makefile.PL','SKIP',$p,$exec_cnt;
               #}
            #} elsif (grep { /-*add[-_]?dependencies/i } @ARGV) {
            #   exec "$^X Makefile.PL SKIP $argvs $p $exec_cnt";
            } else {
               exec "$^X Makefile.PL SKIP $argvs $p $exec_cnt";
            }
         }
      } else {
         print "*** $p Loaded Successfully\n";
         $exec_cnt=0;
      }
      return '';
   }
   
   sub fa_install_module {
       my $stdout='';my $stderr='';
       eval { require IO::CaptureOutput };
       if ($@) {
          eval { &fa_install_mod(@_) };
          if ($@) {
             &fa_err_exit($@,$_[0]);
          }
       } else {
          eval {
             require IO::CaptureOutput;
             IO::CaptureOutput::capture {
                &fa_install_mod(@_)
             } \$stdout, \$stderr;
          };
          print $stdout if $stdout;
          &fa_err_exit($stderr,$_[0]) if $stderr;
       }
   }
   
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

   sub size_fmt {
      my $size = shift(@_);

      if ($size < 1024) {
         return $size . " bytes";
      }
      if ($size < (1024*1024)) {
         return sprintf("%.2f KB",$size / 1024);
      }
      if ($size < (1024*1024*1024)) {
         return sprintf("%.2f MB",$size / (1024*1024));
      }
      if ($size < (1024*1024*1024*1024)) {
         return sprintf("%.2f GB",$size / (1024*1024*1024));
      }
      return sprintf("%.2f TB",$size / (1024*1024*1024*1024));
   }

   my $stdout='';my $stderr='';
   #&fa_install_mod('ExtUtils::MakeMaker','install','Makefile','','6.98');
   &fa_install_mod('ExtUtils::MakeMaker','install','Makefile');
   &fa_install_mod('File::Which','install','Makefile');
   &fa_install_module('Term::ReadKey','install','Makefile');
   &fa_install_mod('Perl::OSType','install','Makefile');
   &fa_install_mod('Locale::Maketext::Simple','install','Makefile');
   eval { require Test::Tester };
   if ($@) {
      &fa_install_mod('Test::Simple','install','Makefile');
   } else {
      &fa_install_mod('Test::Simple','install','Makefile');
      &fa_install_mod('Test::Tester','install','Makefile');
   }
   &fa_install_mod('Params::Check','install','Makefile');
   &fa_install_mod('Module::CoreList','install','Makefile');
   &fa_install_mod('Module::Load','install','Makefile');
   &fa_install_mod('parent','install','Makefile');
   &fa_install_mod('version','install','Makefile');
   &fa_install_mod('Module::Metadata','install','Makefile');
   &fa_install_mod('Module::Load::Conditional','install','Makefile');
   &fa_install_mod('IPC::Cmd','install','Makefile');
   &fa_install_mod('ExtUtils::CBuilder','install','Makefile');
   &fa_install_mod('YAML','install','Makefile');
   &fa_install_mod('Algorithm::Diff','install','Makefile');
   &fa_install_mod('Text::Diff','install','Makefile');
   &fa_install_mod('PAR::Dist','install','Makefile');
   &fa_install_mod('Compress::Raw::Zlib','install','Makefile');
   &fa_install_mod('Compress::Zlib','install','Makefile');
   &fa_install_mod('CPAN::Meta::YAML','install','Makefile');
   &fa_install_mod('Parse::CPAN::Meta','install','Makefile');
   &fa_install_mod('CPAN::Meta::Requirements','install','Makefile');
   &fa_install_mod('JSON::PP','install','Makefile');
   my $mod_info='';my $mod_build_version=0.3601;
   unless (-e "dependencies/CPAN/authors" &&
         !(grep {
         /(?:use[-_]?)?internet|online|connect_to_internet_ok/i } @ARGV)) {
      eval {
         require CPAN;
         {
            local *STDOUT;
            open(STDOUT, ">", \$mod_info);
            CPAN::Shell->m('Module::Build');
         }
      };
      unless ($@) {
         my $instfile='';my $instver='';my $cpanver='';
         if ($mod_info) {
            ($instfile=$mod_info)=~s/^.*INST_FILE\s+([^\s]+).*$/$1/s;
            ($instver=$mod_info)=~s/^.*INST_VERSION\s+([^\s]+).*$/$1/s;
            ($cpanver=$mod_info)=~s/^.*CPAN_VERSION\s+([^\s]+).*$/$1/s;
         }
         if ($instver<$cpanver) {
            $mod_build_version=$cpanver;
         }
      }
   }
   eval { require Module::Build };
   if ((!($@) && $Module::Build::VERSION<=$mod_build_version) || $@
         || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_mod('CPAN::Meta','install','Makefile');
      &fa_install_mod('ExtUtils::ParseXS','install','Makefile','force');
      &fa_install_mod('Compress::Raw::Bzip2','install','Makefile');
      &fa_install_mod('Compress::Raw::Zlib','install','Makefile');
      &fa_install_mod('IO::Zlib','install','Makefile');
      &fa_install_mod('Archive::Tar','install','Makefile');
      &fa_install_mod('Regexp::Common','install','Makefile');
      &fa_install_mod('Pod::Checker','install','Makefile');
      &fa_install_mod('Pod::Parser','install','Makefile');
      &fa_install_mod('Pod::Readme','install','Makefile');
      &fa_install_mod('Module::Build','install','Makefile','force');
   }
   &fa_install_mod('IO::CaptureOutput','install','Makefile');
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64' ||
         grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('IO::Pty','install','Makefile');
      unless (grep { /-*add[-_]?dependencies/i } @ARGV) {
         my $argv0=$ARGV[0]||'';
         exit if $argv0 eq 'install_IO_Pty_from_CPAN';
      }
   }
   &fa_install_module('HTML::Tagset','install','Makefile');
   &fa_install_module('HTML::Parser','install','Makefile');
   &fa_install_module('URI','install','Makefile');
   &fa_install_module('HTTP::Date','install','Makefile');
   &fa_install_module('Digest::MD5','install','Makefile');
   &fa_install_module('LWP::MediaTypes','install','Makefile');
   &fa_install_module('Encode::Locale','install','Makefile');
   &fa_install_module('IO::HTML','install','Makefile');
   &fa_install_module('HTTP::Message','install','Makefile');
   &fa_install_module('File::Listing','install','Makefile');
   &fa_install_module('HTTP::Cookies','install','Makefile');
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64' && $^O ne 'cygwin'
         || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('HTTP::Daemon','install','Makefile');
      &fa_install_module('Encode::Locale','install','Makefile');
      &fa_install_module('WWW::RobotRules','install','Makefile');
      &fa_install_module('Date::Format','install','Makefile');
      &fa_install_module('Date::Parse','install','Makefile');
      &fa_install_module('Mail::Internet','install','Makefile');
      &fa_install_module('Mail::Header','install','Makefile');
      &fa_install_module('Mail::Field','install','Makefile');
      &fa_install_module('Test::NoWarnings','install','Makefile');
      &fa_install_module('Test::Deep','install','Makefile');
      &fa_install_module('MIME::Base64','install','Makefile');
      &fa_install_module('MIME::Entity','install','Makefile');
   }
   &fa_install_module('LWP::MediaTypes','install','Makefile');
   &fa_install_module('HTTP::Negotiate','install','Makefile');
   &fa_install_module('Net::HTTP','install','Makefile');
   &fa_install_module('Data::Dump','install','Makefile');
   &fa_install_module('File::HomeDir','install','Makefile');
   &fa_install_module('LWP','install','Makefile');
   &fa_install_module('CPAN::Mini','install','Makefile');
   eval { require Net::SSLeay };
   if ($@) {
      my $ssleay_error_banner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND FULLAUTO SETUP WILL EXIT
                    IN 5 MINUTES IF NO CHOICE IS MADE ***

      FullAuto Setup ERROR: Missing dependency 'openssl-devel'

   The CPAN module Net::SSLeay requires the 'openssl-devel' system package to
   be installed. Would you like FullAuto Setup to attempt installing this
   package?
END

      &fa_install_module('Net::SSLeay','get');
      my $dir=&fa_find_latest('Net-SSLeay');
      #system("cd \"$dir\";echo n | $^X Makefile.PL;")
      #   || warn $!;
      open(FH, "(cd \"$dir\";echo n | $^X Makefile.PL) 2>&1|");
      while (my $line=<FH>) {
         print $line;
      }
      close FH;
      SSL: while (1) {
         open(FH, "(cd \"$dir\";make install) 2>&1|");
         while (my $line=<FH>) {
            if (-1<index $line,
                  'error: openssl/err.h: No such file or directory') {
               my $timeout=300;my $selection='';
               eval {
                  local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                  alarm $timeout;
                  my $fae="No   (FullAuto Setup will exit)";
                  my $menu1 = [
                              $ssleay_error_banner,
                              [ "Yes", sub{ return 'Yes' } ],
                              [ $fae, sub{ return 'No' } ],
                              ];
                  $selection=&menu($menu1);
                  exit if $selection eq ']quit[';
                  alarm 0;
               };
               if ($@) {
                  # timed out
                  $selection = 'No';
               }
               if ($selection=~/No/) {
                  exit;
               } alarm 0;
               if (($main::system_type eq 'rhel') ||
                     ($main::system_type eq 'centos') ||
                     ($main::system_type eq 'fedora')) {
                  open(LD,"sudo yum -y install 'openssl-devel'|");
                  while (my $line=<LD>) {
                     print $line;
                  }
                  close LD;
                  next SSL;
               } elsif ($main::system_type eq 'suse') {
                  open(ZP,"zypper -n install openssl-devel|");
                  while (my $line=<AG>) {
                     print $line;
                  }
                  close ZP;
                  next SSL;
               } elsif ($main::system_type eq 'ubuntu') {
                  open(LD,"sudo apt-get -y install 'libssl-dev'|");
                  while (my $line=<LD>) {
                     print $line;
                  }
                  close LD;
                  next SSL;
               }
            }
            print $line;
         } last;
      }
      close FH;
   } elsif (grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Net::SSLeay','get');
   }
   &fa_install_module('IO::Socket::SSL','install','Makefile','','','n');
   &fa_install_module('Mozilla::CA','install','Makefile');
   &fa_install_module('LWP::Protocol::https','install','Makefile');
   &fa_install_module('Task::Weaken','install','Makefile');
   &fa_install_module('ExtUtils::Depends','install','Makefile');
   &fa_install_module('B::Utils','install','Makefile');
   &fa_install_module('ExtUtils::Config','install','Makefile');
   &fa_install_module('ExtUtils::InstallPaths','install','Makefile');
   &fa_install_module('ExtUtils::Helpers','install','Makefile');
   &fa_install_module('Test::Harness','install','Makefile','','3.33');
   &fa_install_module('CPAN::Meta','install','Makefile');
   &fa_install_module('Module::Build::Tiny','install','Build');
   &fa_install_module('Class::Method::Modifiers','install','Makefile');
   &fa_install_module('common::sense','install','Makefile');
   &fa_install_module('Types::Serialiser','install','Makefile');
   &fa_install_module('Term::RawInput','install','Makefile');
   if ($^O eq 'cygwin' || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Win32::API','install','Makefile');
      &fa_install_module('Win32::DriveInfo','install','Makefile');
   }
   my $cpanvalue=$ENV{PERL5_CPAN_IS_RUNNING}||'';
   my $cpanmvalue=$ENV{PERL5_CPANM_IS_RUNNING}||'';
   undef $ENV{PERL5_CPAN_IS_RUNNING};
   undef $ENV{PERL5_CPANM_IS_RUNNING};
   &fa_install_module('JSON::XS','install','Makefile');
   &fa_install_module('JSON','install','Makefile');
   $ENV{PERL5_CPAN_IS_RUNNING}=$cpanvalue if $cpanvalue;
   $ENV{PERL5_CPANM_IS_RUNNING}=$cpanmvalue if $cpanmvalue;
   &fa_install_module('Devel::Symdump','install','Makefile');
   &fa_install_module('PadWalker','install','Makefile');
   eval { require Data::Dump::Streamer };
   if ($@ || grep { /-*add[-_]?dependencies/i } @ARGV) {
      &fa_install_module('Data::Dump::Streamer','get');
      unless (grep { /-*add[-_]?dependencies/i } @ARGV) {
         my $dir=&fa_find_latest('Data-Dump-Streamer');
         system("cd \"$dir\";$^X Build.PL NODDS;");
         system("cd \"$dir\";./Build install;");
      }
   }
   &fa_install_module('Term::Menus','install','Makefile');
   &fa_install_module('IO::String','install','Makefile');
   &fa_install_module('Crypt::CBC','install','Makefile');
   &fa_install_module('Crypt::DES','install','Makefile');
   &fa_install_module('Test::Manifest','install','Makefile');
   &fa_install_module('Crypt::Rijndael','install','Makefile');
   &fa_install_module('Clone','install','Makefile');
   &fa_install_module('File::Remove','install','Makefile');
   &fa_install_module('Exporter::Tiny','install','Makefile');
   &fa_install_module('List::MoreUtils','install','Makefile');
   &fa_install_module('Params::Util','install','Makefile');
   &fa_install_module('Test::Object','install','Makefile');
   &fa_install_module('Hook::LexWrap','install','Makefile');
   &fa_install_module('Test::SubCalls','install','Makefile');
   &fa_install_module('Class::Inspector','install','Makefile');
   &fa_install_module('PPI','install','Makefile');
   &fa_install_module('Tie::Cache','install','Makefile');
   &fa_install_module('String::Random','install','Build');
   &fa_install_module('Net::Telnet','install','Makefile');
   &fa_install_module('Sort::Versions','install','Makefile');
   &fa_install_module('Capture::Tiny','install','Makefile');
   &fa_install_module('IO::Capture','install','Makefile');
   &fa_install_module('Pod::Man','install','Makefile');
   &fa_install_module('Sub::Exporter::Progressive','install','Makefile');
   &fa_install_module('MRO::Compat','install','Makefile');
   &fa_install_module('Sub::Install','install','Makefile');
   &fa_install_module('Data::OptList','install','Makefile');
   &fa_install_module('B::Hooks::OP::Check','install','Makefile');
   &fa_install_module('Lexical::SealRequireHints','install','Makefile');
   &fa_install_module('multidimensional','install','Makefile');
   &fa_install_module('bareword::filehandles','install','Makefile');
   &fa_install_module('indirect','install','Makefile');
   &fa_install_module('strictures','install','Makefile');
   &fa_install_module('Role::Tiny','install','Makefile');
   &fa_install_module('Devel::GlobalDestruction','install','Makefile');
   &fa_install_module('Module::Runtime','install','Makefile');
   &fa_install_module('Import::Into','install','Makefile');
   &fa_install_module('Try::Tiny','install','Makefile');
   &fa_install_module('Sub::Exporter','install','Makefile');
   &fa_install_module('Sub::Exporter::Util','install','Makefile');
   &fa_install_module('Moo','install','Makefile');
   &fa_install_module('Test::Fatal','install','Makefile');
   &fa_install_module('MooX::Types::MooseLike','install','Makefile');
   &fa_install_module('MooX::Types::MooseLike::Base','install','Makefile');
   &fa_install_module('Devel::StackTrace','install','Makefile');
   &fa_install_module('Throwable','install','Makefile');
   &fa_install_module('Email::Date::Format','install','Makefile');
   &fa_install_module('Email::Simple','install','Makefile');
   &fa_install_module('Email::Address','install','Makefile');
   &fa_install_module('Module::Pluggable','install','Build');
   &fa_install_module('Email::Abstract','install','Makefile');
   &fa_install_module('Email::Sender','install','Makefile');
   &fa_install_module('Data::Password::Check','install','Makefile');

};

sub ws_info {
   my $selection='';
   if ($_[0]) {
      print "\nRunning command: net user /domain ->".
            " This may take a couple of minutes\n\n";
   }
   # Do we have Cygwin?
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   $clo=~s/\\/\\\\/g;
   my %userlist=();my %passlins=();
   my @newpassw=();my $modflag=0;
   if (-e $cygwin_loc."/bin") {
      my $pasen='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                '"cat /etc/passwd"';
      my $passe=`$pasen`;my $cnt=0;my %passlins=();
      foreach my $en (split "\n",$passe) {
         chomp($en);
         push @{$passlins{$en}},$cnt++;
         push @newpassw,$en;
      }
      foreach my $lin (keys %passlins) {
         my $linn=$lin;
         my @pl=@{$passlins{$linn}};
         if (0<$#pl) {
            my %asklin=(
               Label => asklin,
               Item_1 => {
                  Text => "]C[",
                  Convey => sub {

                     my @ret=();
                     foreach my $p (@pl) {
                        push @ret, "\n                $linn\n".
                                   "\n                Line: $p\n\n";
                     }
                     return @ret;

                  },
               },
               Item_2 => {
                  Text => "Skip this operation",
               },
               Banner => "   Duplicate Lines in /etc/passwd found!\n\n".
                         "   The following lines are all duplicates, ".
                         "the only one being utilized is\n   the first ".
                         "one found. It is recommended that the ".
                         "others be removed.\n\n".
                         "   Select the one you wish to keep, or choose ".
                         "'Skip this operation' and\n   FullAuto Setup ".
                         "will continue.\n\n",
            );
            my $select=Menu(\%asklin);
            chomp($select);
            exit if $select eq ']quit[';
            my $s=0;
            ($s=$select)=~s/^.*\n\s+Line: (\d+).*$/$1/s;
            my $adjust=0;
            foreach my $i (@pl) {
               my $ii=$i;
               my $n=0;
               ($n=$ii)=~s/^.*\n\s+Line: (\d+).*$/$1/s;
               next if $s eq $n;
               $n-=$adjust;
               splice(@newpassw,$n,1);
               $modflag=1;
               $adjust++;
            }
         }
      }
      if ($modflag) {
         my $npass=join "\n",@newpassw;
         open(NP,">$cygwin_loc/etc/passwd");
         foreach my $l (@newpassw) {
            print NP "$l\n";
         }
         close NP;
      } $modflag=0;
      my $users='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                '"cat /etc/passwd |grep '.
                '\\"/bin/bash\\" |grep '.
                '\\"[5-9][0-9][0-9]\\""';
      my $userlist=`$users`;
      my %ulist=();my $cyguser='';
      foreach my $us (split "\n",$userlist) {
         chomp($us);
         $cyguser=substr($us,0,(index $us,':'));
         next if $cyguser ne 'cyg_server';
         push @{$ulist{$cyguser}}, $us;
      }
      my @u=@{$ulist{cyg_server}};
      my @list=();my @retrn=();
      my $domain_id_flag=0;
      my $local_id_flag=0;
      my %cYgsrvs=();
      if (-1<$#u) {
         foreach my $e (@u) {
            my @it=split ':',$e;
            my $info=(split ',',$it[4])[1];
            my $d='';my $i='';
            if (-1<index $info,'\\') {
               ($d,$i)=split /\\/,$info;
               $d=~s/^.*-(.*)$/$1/;
               $d="DOMAIN: $d";
               $domain_id_flag=1;
            } else {
               $d="LOCAL: $hostname";
               $local_id_flag=1;
            }
            push @retrn,"cyg_server -> $d";
            $cygsrvs{"cyg_server -> $d"}=$e;
         }
      }
      if (0<$#retrn) {
         my %askcyg=(

            Label => 'askcyg',
            Item_1 => {

               Text => "]C[",
               Convey => \@retrn,

            },
            Banner => "   More than one instance of the user 'cyg_server'\n" .
                      "   have been located in the /etc/passwd file. However".
                      ",\n   only one can be used. Please choose one:\n",
         );
         my $select=Menu(\%askcyg);
         chomp($select);
         exit if $select eq ']quit[';
         delete $cygsrvs{$select};
         my $pasen='SET CYGWIN=nodosfilewarning & '.
                   "cmd /c $cygwin_loc\\bin\\bash -lc ".
                   '"cat /etc/passwd"';
         my $passe=`$pasen`;my $cnt=0;my %passlins=();
         foreach my $en (split "\n",$passe) {
            chomp($en);
            push @{$passlins{$en}},$cnt++;
            push @newpassw,$en;
         }
         my $ct=0;my $n=0;my $modflag=0;
         foreach my $lin (keys %passlins) {
            my $linn=$lin;
            $lin=~s/\s*$//;
            foreach my $i (values %cygsrvs) {
               my $ii=$i;
               $ii=~s/\s*$//;
               if ($lin eq $ii) {
                  splice(@newpassw,$n,1);
                  $ct++;
                  $modflag=1;
                  next;
               }
               $ct++;$n++;
            }
         }
         if ($modflag) {
            open(NP,">$cygwin_loc/etc/passwd");
            foreach my $l (@newpassw) {
               print NP "$l\n";
            }
            close NP;
         }
         test_windows_user_rights('cyg_server');
      }
   }
   my $found_dotted=0;
   my $domain='';
   $domain=' /domain' if $_[0];
   my $server='';
   foreach my $line (split "\n", `net user$domain 2>&1`) {
      unless ($found_dotted) {
         if (-1<index $line,'-------') {
            $found_dotted=1;
         } elsif (-1<index $line,' for domain ') {
            ($domain=$line)=~s/^.* for domain (.*)[.]\s*$/$1/s;
         } elsif (-1<index $line,' accounts for ') {
            ($server=$line)=~s/^.* accounts for\s+(.*)\s*$/$1/s;
         }
         next;
      }
      push @output, $line;
   }
   my $limit=9;
   $limit=$#output if $#output<9;
   my @test=@output[0..$limit];
   my %testone=();
   my %testtwo=();
   while (my $line=shift @test) {
      chomp($line=~tr/\0-\11\13-\37\177-\377//d);
      $line=~s/\s*$//s;
      my $ln2=rindex $line, ' ';
      $testtwo{$ln2}++;
      substr($line,$ln2)='';
      $line=~s/\s*$//s;
      my $ln1=rindex $line, ' ';
      $testone{$ln1}++;
   }
   my $two=0;
   foreach my $key (keys %testtwo) {
      $two=$key if $two<$key;
   }
   my $one=0;
   foreach my $key (keys %testone) {
      $one=$key if $one<$key;
   }
   $one++;
   my $mid=$two-$one+1;
   my @users=();my $cyg_id='';
   my $success_flag=0;
   foreach my $line (@output) {
      my ($on,$tw,$th)=unpack("a$one a$mid a$two",$line);
      $on=~s/\s*$//;$tw=~s/\s*$//;$th=~s/\s*$//;
      if (-1<index $on,'The command compl') {
         $success_flag=1;
         last;
      }
      push @users, $on if $on;
      $cyg_id='cyg_server' if $on eq 'cyg_server';
      push @users, $tw if $tw;
      $cyg_id='cyg_server' if $tw eq 'cyg_server';
      push @users, $th if $th;
      $cyg_id='cyg_server' if $th eq 'cyg_server';

   }

   my $dom=(defined $_[0] && $_[0])?$_[0]:'Local';
   my $hostname=`hostname`;
   chomp($hostname);

   if ($dom ne 'Local') {
      unless ($success_flag) {
         my %_cygservnf=(
            Label => '_cygservnf',
            Item_1 =>  {
                  Text   => "]C[",
                  Convey => [ "Use Domain ID \'cyg_server\'\n           ".
                              "     ( You need to know the password! )\n\n",
                              "Enter a different User ID\n\n",
                              'Use a Local account' ],
            },
            Banner=> "   WARNING! - The Windows command   net user /domain\n".
                     "      did *NOT* complete successfully. The following\n".
                     "      is the output from that command:\n\n".
                     "      ".(join "\n",@output)."\n\n".
                     "   The FullAuto Installer cannot validate User ID's\n".
                     "      without this information. You may proceed if\n".
                     "      the ID you intend to use exists.\n\n".
                     "   (If you wish to use a Domain User ID, please\n".
                     "      *make sure it exists* in the current Domain:".
                     "\n      -> $dom - before running FullAuto Setup.\n".
                     "      If you wish to use a Local account, FullAuto\n".
                     "      can use an existing one, or create a new one.)",
         );
         $selection=Menu(\%_cygservnf);
         chomp $selection;
         exit if $selection eq ']quit[';
         $selection='UsE_separate_login_id_for_sshd'
            if -1<index $selection,'Use a Local';
         if (-1<index $selection,'Enter a different') {
            while (1) {
               print "\n\n\n   Please enter the $domain User ID you",
                     "   intend to use for the sshd service: ".
                     "\n\n\n",
                     "   Please TYPE the User ID: ";
               $cyg_id=<STDIN>;
               chomp $selection;
               print "\n\n\n   You entered ==> $cyg_id\n\n".
                     "   is this correct? (Y|N): ";
               my $yn=<STDIN>;
               last if lc($yn) eq 'y' || 'yes';
            }
         }
      } elsif ($cyg_id eq 'cyg_server') {
         my $o=`net user cyg_server 2>&1`;
         if (-1==index $o,'user name could not be found') {
            my %_cygserv=(
   
               Label => '_cygserv',
               Item_1 =>  {
                     Text   => "]C[",
                     Convey => [ "Use Domain ID \'cyg_server\'\n".
                                 '                '.
                                 '( You need to know the password! )',
                                 'Select ID from All Domain ID\'s',
                                 'Use a Local account' ],
               },
               Banner=> "   The Domain User 'cyg_server' has been located,\n".
                        "   do you wish to use it, or would you rather\n".
                        "   select from all Domain Users, or use a Local\n".
                        "   account for the sshd service?\n\n".
                        "   (If you wish to use a Domain User ID, please\n".
                        "   *make sure it exists* in the current Domain: $dom".
                        "\n   before".
                        " running FullAuto Setup. If you wish to use\n".
                        "   a Local account, FullAuto can use an existing\n".
                        "   one, or create a new one.)",
            );
            $selection=Menu(\%_cygserv);
            chomp $selection;
            exit if $selection eq ']quit[';
            $selection='UsE_separate_login_id_for_sshd'
               if -1<index $selection,'Use a Local';
         } else {
            test_windows_user_rights('cyg_server') if $^O eq 'cygwin';
            $selection='cyg_server'; 
         }         
      } else {
         my %_cygserv=(

            Label => '_cygserv',
            Item_1 =>  {
                  Text   => "]C[",
                  Convey => [ 'Select ID from All Domain ID\'s',
                              'Use a Local account' ],
            },
            Banner=> "   'cyg_server' has *NOT* been located in the $dom ".
                     "Domain.\n".
                     "   If you wish to use the 'cyg_server' id as a Domain".
                     " ID\n".
                     "   for the OpenSSH sshd service on this host: ".
                     $hostname."\n".
                     "   type 'quit', exit FullAuto Setup, create the\n".
                     "   'cyg_server' User in the $dom Domain, and *then*\n".
                     "   run FullAuto Setup again.\n\n",
                     "   Or, would you rather select from all Domain Users,".
                     "   or use a Local account for the sshd service?\n\n".
                     "   (If you wish to use a Local account, FullAuto\n".
                     "    can use an existing one, or create a new one.)",
         );
         $selection=Menu(\%_cygserv);
         chomp($selection);
         exit if $selection eq ']quit[';
         $selection='UsE_separate_login_id_for_sshd'
            if -1<index $selection,'Use a Local';
      }
      if (-1<index $selection, 'All Domain' || !$cyg_id) {
         my %_users=(

            Label => '_users',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => \@users,
                       },
            Banner=> "   Select the $dom User to Run the sshd Service\n\n".
                     "   Hit <ENTER> or user ARROW keys to scroll\n\n".
                     "   List can be searched by typing  /[string]\n".
                     "   (forward slash key followed by text to search for).", 
         );
         $selection=Menu(\%_users);
         chomp($selection);
         exit if $selection eq ']quit[';
         test_windows_user_rights($selection) if $^O eq 'cygwin';
      } elsif (-1<index $selection, 'Use Domain') {
         test_windows_user_rights('cyg_server') if $^O eq 'cygwin';
         $selection='cyg_server'; 
      }
   }
   return $selection;

}

sub clean_mswin {
   my $rmdir_out=rmdir $main::curdir.'/inc/.author';
   print "ERROR $main::curdir/inc/.author: $!\n" unless $rmdir_out;
   my $un_out=unlink $main::curdir.'/inc/Module/Install/Base.pm';
   print "ERROR $main::curdir/inc/Module/Install/Base.pm: $!\n"
      unless $un_out;
   $un_out=unlink $main::curdir.'/inc/Module/Install/Metadata.pm';
   print "ERROR $main::curdir/inc/Module/Install.pm: $!\n" unless $un_out;
   $un_out=unlink $main::curdir.'/inc/Module/Install.pm';
   print "ERROR $main::curdir/inc/Module/Install.pm: $!\n" unless $un_out;
   $rmdir_out=rmdir $main::curdir.'/inc/Module/Install';
   print "ERROR /inc/Module/Install: $!\n" unless $rmdir_out;
   $rmdir_out=rmdir $main::curdir.'/inc/Module';
   print "ERROR $main::curdir/inc/Module: $!\n" unless $rmdir_out;
   unless (-e $main::PARdir.'/inc_exists.txt') {
      $rmdir_out=rmdir $main::curdir.'/inc';
      print "ERROR $main::curdir/inc: $!\n" unless $rmdir_out;
   } else {
      $un_out=unlink $main::PARdir.'/inc_exists.txt';
      print "ERROR $main::PARdir/inc_exists.txt: $!\n" unless $un_out;
   }

}

# Load the Module::Install bundled in ./inc/
# use inc::Module::Install;

# Define metadata
version         $main::VERSION;
name            'Net-FullAuto';
sign;
author          'Brian M. Kelly <Brian.Kelly@fullautosoftware.net>';
license         'gpl-3.0';
perl_version    '5.006';

#unshift @INC, $main::PARdir if $main::unshift_incdir;

#use Config;
#use File::stat;
#CPAN::HandleConfig->load;
#use POSIX qw/strftime/;

require Mozilla::CA;
require Term::Menus;
require Term::ReadKey;
require Term::RawInput;
my $last_known_good_location=
      "http://download.oracle.com/berkeley-db/db-5.2.28.tar.gz";

if ($^O eq 'cygwin' || $^O eq 'MSWin32' || $^O eq 'MSWin64') {
   $ENV{'CYGWIN'}='nodosfilewarning' if $^O eq 'cygwin';
}

BEGIN {
   unshift @ExtUtils::MakeMaker::Overridable, 'pm_to_blib';
};

my $process_id='';my $PREFIX='';
$process_id=pop @ARGV if $ARGV[$#ARGV-1]=~/^\d+$/;
my $install_cygwin_without_asking=0;
$main::cygwin_berkeley_db_mode=777;
if (exists $ENV{FA_BERKELEY} &&
      (-1<index $ENV{FA_BERKELEY},'Owner Group')) {
   $main::cygwin_berkeley_db_mode=770;
}
$main::mozrepl_file='mozrepl-1.1-fx.xpi';
$main::install_firefox_without_asking=0;
$main::install_firefox=0;
$main::install_firefox=$ENV{FA_MOZREPL} if exists $ENV{FA_MOZREPL};

if (exists $Config{prefix} &&
      $Config{prefix}) {
   $PREFIX=$Config{prefix};
}

foreach my $arg (@ARGV) {
   if ($arg=~/INSTALL_*CYGWIN\s*=\*1/i) {
      $install_cygwin_without_asking=1;
   } elsif ($arg=~/INSTALL_*FIREFOX\s*=\*1/i) {
      $main::install_firefox_without_asking=1;
   } elsif ($arg=~/-*-PREFIX=/i) {
      $PREFIX=$arg;
      $PREFIX=~s/^-*-[Pp][Rr][Ee][Ff][Ii][Xx]=//;
      $PREFIX=~s/^["']//;
      $PREFIX=~s/["']$//;
   }
}

$PREFIX='' if $PREFIX='/usr';

my $editor='';my $selection='';my $berkeleydb='';
if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {

   my $cygwin_loc=get_cygwin_location();

   if ($cygwin_loc) {

      my %Menu_update_cyg=(

         Label  => 'Menu_update_cyg',
         Item_1 => {

            Text => "Update Cygwin Linux ".
                    "Emulation Layer for Windows at $cygwin_loc\n".
                    "                and ".
                    "INSTALL FullAuto:\n\n                ( FullAuto ".
                    "Install will download and utilize a number of ".
                    "\n                  development utilities including the".
                    " gcc compiler ).\n\n\n",
                    #"                -------------------------------".
                    #"---------------------------\n",

         },
         Item_2 => {

            Text => "Update Cygwin Linux ".
                    "Emulation Layer for Windows at $cygwin_loc\n            ".
                    "    and Install OpenSSH *ONLY*:\n\n              ".
                    "  ( This will update and configure Base Cygwin and ".
                    "OpenSSH only\n                  so that remote FullAuto ".
                    "processes can connect and interact\n                  ".
                    "with this host; but FullAuto itself will NOT be ".
                    "installed ).\n\n\n",

         },
         Item_3 => {

            Text    => "DO *NOT* Update Cygwin ( FullAuto Install will END )".
                       ".\n\n",
            #Default => "*",

         },
         Banner => "   There are two types of installations available:\n\n",

      );
      if ($install_cygwin_without_asking) {
         $selection='Install';
      } else {
         $selection=Term::Menus::Menu(\%Menu_update_cyg);
         chomp($selection);
         exit if $selection eq ']quit[';
      }
   } else {

      my %Menu_win_to_cyg=(

         Label  => 'Menu_win_to_cyg',
         Item_1 => {

            Text => "INSTALL or Update Cygwin Linux ".
                    "Emulation Layer for Windows\n                and ".
                    "INSTALL FullAuto:\n\n                ( FullAuto ".
                    "Install will download and utilize a number of ".
                    "\n                  development utilities including the".
                    " gcc compiler ).\n\n\n",
                    #"                -------------------------------".
                    #"---------------------------\n",

         },
         Item_2 => {

            Text => "Install a *MINIMAL* Cygwin Linux ".
                    "Emulation Layer\n                for Windows and ".
                    "  DO *NOT*   Install FullAuto:\n\n                ( This ".
                    "will install and configure Base Cygwin and OpenSSH only".
                    "\n                  so that remote FullAuto ".
                    "processes can connect and interact\n                  ".
                    "with this host; but FullAuto itself will NOT be ".
                    "installed ).\n\n\n",

         },
         Item_3 => {

            Text    => "DO *NOT* Install Cygwin ( FullAuto Install will END ).",
            #Default => "*",

         },
         Banner => "   There are two types of installations available:",

      );
      if ($install_cygwin_without_asking) {
         $selection='Install';
      } else {
         $selection=Term::Menus::Menu(\%Menu_win_to_cyg);
         chomp($selection);
         exit if $selection eq ']quit[';
      }
   }
   if ($selection!~/will END/s) {
      if ($selection!~/MINIMAL/s) {
         my @editors=('nano    ( Easiest - Recommended for Beginners )',
                      'vim     ( ViIMproved - enhanced vi editor )',
                      "emacs   ( The extensible, customizable,\n           ".
                      "               self-documenting real-time\n         ".
                      "                display editor )",
                      "joe     ( Fast and simple editor that\n             ".
                      '             emulates 5 other editors )', 
                     );
         my $tp='';
         unless ($tp=&fa_find_editor('TextPad.exe')) {
            if (-e ${ENV}{SystemDrive}.
                  "\\Program Files\\TextPad 5\\TextPad.exe") {
               $tp='default';
            }
         }
         if ($tp) {
            push @editors, 'TextPad (The Text Editor for Windows)';
         }

         my $banner="   In order to use the integrated edit features\n".
                    "   you will need to choose an editor.";
         my %Menu_select_editor=();
         if (-e ${ENV}{SystemDrive}.
                  "\\Program Files\\Windows NT\\Accessories\\wordpad.exe") {
            $banner="   In order is use the integrated edit features\n".
                    "   you will need to choose an editor. MS Wordpad\n".
                    "   is set as the default - and is recommended if\n".
                    "   you are not familiar with the other listed\n".
                    "   editors.";
            %Menu_select_editor=(

                  Label  => 'Menu_select_editor',
                  Item_1 => {
   
                     Text => "Wordpad (Microsoft Wordpad -\n               ".
                             "          Available on all Windows Systems)",
                     Default => "*",

                  },
                  Item_2 => {

                     Text    => "]C[",
                     Convey  => \@editors,

                  },
                  Scroll => 1,
                  Banner => $banner,

            );
         } else {
            %Menu_select_editor=(

                  Label  => 'Menu_select_editor',
                  Item_1 => {

                     Text    => "]C[",
                     Convey  => \@editors,

                  },
                  Scroll => 1,
                  Banner => $banner,

            );
         }
      
         if ($install_cygwin_without_asking) {
            my $look_for_wordpad=${ENV}{SystemDrive}.
                  "\\Program Files\\Windows NT\\Accessories\\wordpad.exe";
            if (-e $look_for_wordpad) {
               $selection='wordpad';
               my $sysdr=`cmd /c echo %SystemDrive%`;
               $sysdr=~s/^\s*(.*)\s*$/$1/s;
               my $let=substr($sysdr,0,1);
               my $lt=lc($let);
               $editor='/cygdrive/'.$lt.'/Program Files/Windows NT/'.
                       'Accessories/wordpad.exe';
            }
         } elsif (0<$#editors) {
            $selection=Term::Menus::Menu(\%Menu_select_editor);
            chomp($selection);
            exit if $selection eq ']quit[';
         } elsif (0==$#editors) {
            $selection=$editors[0];
         }
         if ($selection=~/([Ww]ordpad)/) {
            $selection=$1;
            my $sysdr=`cmd /c echo %SystemDrive%`;
            $sysdr=~s/^\s*(.*)\s*$/$1/s;
            my $let=substr($sysdr,0,1);
            my $lt=lc($let);
            $editor='/cygdrive/'.$lt.
               '/Program Files/Windows NT/Accessories/wordpad.exe';
         } elsif ($selection=~/(TextPad)/) {
            $selection=$1;
            if ($tp eq 'default') {
               my $sysdr=`cmd /c echo %SystemDrive%`;
               $sysdr=~s/^\s*(.*)\s*$/$1/s;
               my $let=substr($sysdr,0,1);
               my $lt=lc($let);
               $editor='/cygdrive/'.$lt.
                  '/Program Files/TextPad 5/TextPad.exe';
            } else {
               $tp=~s/\\/\//g;
               $tp=~s/^([A-Za-z]):(.*)/$1$2/;
               $editor='/cygdrive/'.$tp;
            }
         } elsif ($selection=~/(vim)/) {
            $selection=$1;
            $editor='/bin/vim.exe';
         } elsif ($selection=~/(emacs)/) {
            $selection=$1;
            $editor='/bin/emacs.exe';
         } elsif ($selection=~/(joe)/) {
            $selection=$1;
            $editor='/bin/joe.exe';
         } elsif ($selection=~/(nano)/) {
            $selection=$1;
            $editor='/bin/nano.exe';
         }

         my $p_one='Install with Full Access Permissions (Default)';
         my $p_two='Install with Owner Group Permissions';
         my $p_banner="\n\n   FullAuto Security:\n".
                      "\n   Owner Group is more secure - but choose".
                      "\n   this only if security is important, and".
                      "\n   you know how to work with OS permissions\n\n".
                      "\n   Choose a Permission Setting :\n\n";
         my %Menu_select_permissions=(

            Label  => 'Menu_select_permissions',
            Item_1 => {
                         Text => $p_one,
                      },
            Item_2 => { Text => $p_two },
            Scroll => 1,
            Banner => $p_banner,

         );
         $selection=Term::Menus::Menu(\%Menu_select_permissions);
         chomp($selection);
         exit if $selection eq ']quit[';
         $main::cygwin_berkeley_db_mode=$selection;

         &find_windows_app() if 
            (-1==index $main::install_firefox,'Install') &&
            (-1==index $main::install_firefox,'NOT');

      }

      my $url='http://www.cygwin.com/setup-x86.exe';
      $url='http://www.cygwin.com/setup-x86_64.exe'
         if $^O eq 'MSWin64';
      if ($CPAN::META->has_usable('LWP')) {
         FA::LWP::UserAgent->config;
         print "Fetching with LWP:\n  $url\n";
         my $Ua;
         eval { $Ua = FA::LWP::UserAgent->new(
                timeout=>300,show_progress=>1) };
         if ($@) {
            $CPAN::Frontend->mywarn(
               "ERROR: FA::LWP::UserAgent->new dies with $@\n");
         } else {
            my($var);
            $Ua->proxy('http', $var)
               if $var = $CPAN::Config->{http_proxy} ||
               $ENV{http_proxy};
            $Ua->no_proxy($var)
               if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
         }
         my $req = HTTP::Request->new(GET => $url);
         $req->header('Accept' => 'text/html');
         my $res = $Ua->request($req);
         if ($res->is_success) {
            print " + request successful.\n"
               if $CPAN::DEBUG;
            mkpath($main::root_dir,1) unless -d $main::root_dir;
            unless (-w $main::root_dir) {
               print "\n\n   Fatal Error! - The current Cygwin directory: ".
                        "\n\n      ".$main::root_dir."\n\n".
                        "   is not writable. Please change the permissions\n".
                        "   to writable before installing FullAuto.\n";
               print "\n   PRESS ANY KEY TO EXIT SETUP\n\n";
               <STDIN>;
               exit 1;
            }
            if ($^O eq 'MSWin64') {
               open(CP,">$main::root_dir\\setup-x86_64.exe") || die $!;
            } else {
               open(CP,">$main::root_dir\\setup-x86.exe") || die $!;
            }
            binmode(CP);
            print CP $res->content;
            my $cyghome=$Ua->get('http://www.cygwin.com');
            if ($^O ne 'cygwin' && $cyghome->is_success) {
               my $content=$cyghome->content;
               my $cygver='';
               ($cygver=$content)=~
                  s/^.*of the Cygwin DLL is ([\d|.|-]). In.*$/$1/s;
               if ($cygver=~/(1.7.11-1)/) {
                  print "\n\n   Fatal Error! - The current Cygwin version: $1".
                        "\n   (Base Cygwin cygwin1.dll) at cygwin.com is\n".
                        "   incompatible with FullAuto. Please manually\n".
                        "   download the setup utility from www.cygwin.com,\n".
                        "   and install an\n   older version of Base Cygwin.\n".
                        "   Only then can\n   successfully install FullAuto.\n".
                        "   Optionally, you\n   can also manually install\n".
                        "   Perl when setting up\n   a compatible version of\n".
                        "   Cygwin, and afterwards\n   use the bundled cpan\n".
                        "   utility to install FullAuto\n   You may need to\n".
                        "   contact your Windows System\n   Administrator to\n".
                        "   resolve.\n\n".
                        "   PRESS ANY KEY to Exit Setup\n\n";
                  <STDIN>;
                  exit 1;
               }
            } 
         } elsif ($res->status_line=~/403/) {
            if ($^O eq 'MSWin64') { 
               $url='http://www.fullautosoftware.net/download/setup-x86_64.exe';
            } else {
               $url='http://www.fullautosoftware.net/download/setup-x86.exe';
            }
            $req = HTTP::Request->new(GET => $url);
            $req->header('Accept' => 'text/html');
            $res = $Ua->request($req);
            if ($res->is_success) {
               print " + request successful.\n"
                  if $CPAN::DEBUG;
               mkpath($main::root_dir,1) unless -d $main::root_dir;
               if ($^O eq 'MSWin64') {
                  open(CP,">$main::root_dir\\setup-x86_64.exe") || die $!;
               } else {
                  open(CP,">$main::root_dir\\setup-x86.exe") || die $!;
               }
               binmode(CP);
               print CP $res->content;
            } elsif ($res->status_line=~/403/) {
               $url='http://www.fullautosoftware.net/download/setup.tar.gz';
               $req = HTTP::Request->new(GET => $url);
               $req->header('Accept' => 'text/html');
               $res = $Ua->request($req);
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  open(CP,">$main::PARdir\\setup.tar.gz") || die $!;
                  binmode(CP);
                  print CP $res->content;
               } else {
                  print $res->status_line;
                  sleep 10;
                  die $res->status_line;
               }
            } else {
               print $res->status_line;
               sleep 10;
               die $res->status_line;
            }
         } else {
            print $res->status_line;
            sleep 10;
            die $res->status_line;
         }
         close(CP) || die $!;
         if ($^O eq 'MSWin64') {
            chmod 0755, "$main::root_dir\\setup-x86.exe";
         } else {
            chmod 0755, "$main::root_dir\\setup-x86_64.exe";
         }
        
         my $mirror_url='http://www.cygwin.com/mirrors.html';
         $req = HTTP::Request->new(GET => $mirror_url);
         $req->header('Accept' => 'text/html');
         $res = $Ua->request($req);
         my $href='';my @urls=();
         $mirror_url='http://cygwin.mirrors.pair.com';
         if ($res->is_success) {
            print " + request successful.\n"
               if $CPAN::DEBUG;
            my $mirrors=$res->content;
            foreach my $href ($mirrors=~/href="(.*?)"/mg) {
               next if -1==index $href,'://';
               next if -1<index $href,'html';
               next if -1==index $href,'http';
               push @urls, $href;
            }
            $mirror_url=$urls[int(rand($#urls))];
         }
         my $setup_cmd='';
         my $drlet=substr($main::root_dir,0,2);
         if ($selection!~/[Ww]ordpad|MINIMAL/s) {
            if ($selection eq 'vim') {
               $selection='';
            } else {
               $selection=",$selection";
            }
            if ($^O eq 'MSWin64') {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86_64.exe -P gcc-core,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'procps,vim,unzip,libmpfr4,figlet,'
                      .'perl-libwin32,db,libdb-devel,ncurses,cron,inetutils,'
                      .$selection.' -X -A -q '."-R $main::root_dir "
                      .'-s '.$mirror_url;
            } else {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86.exe -P gcc-core,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'perl-libwin32,db4.8,libdb4.8-devel,ncurses,cron,'
                      .'inetutils,procps,vim,unzip,libmpfr4,figlet'.
                      $selection.' -X -A -q '."-R $main::root_dir "
                      .'-s '.$mirror_url;
            }
         } elsif ($selection!~/MINIMAL/s) {
            if ($^O eq 'MSWin64') {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86_64.exe -P gcc-core,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'perl-libwin32,db,libdb-devel,ncurses,cron,inetutils,'
                      .'procps,vim,unzip,libmpfr4,figlet'
                      .' -X -A -q '."-R $main::root_dir "
                      .'-s '.$mirror_url;
            } else {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86.exe -P gcc-core,'
                      .'gcc-g++,make,openssh,openssl,openssl-devel,perl,'
                      .'perl-libwin32,db4.8,libdb4.8-devel,ncurses,cron,'
                      .'inetutils,procps,vim,unzip,libmpfr4,figlet'
                      .' -X -A -q '."-R $main::root_dir "
                      .'-s '.$mirror_url;
            }
         } else {
            if ($^O eq 'MSWin64') {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86_64.exe -P openssh,ncurses,inetutils,procps,'
                      .'vim,libmpfr4,figlet -X -A -q '."-R $main::root_dir ".'-s '
                      .$mirror_url;
            } else {
               $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup-x86.exe -P openssh,ncurses,inetutils,procps,vim,'
                      .'libmpfr4,figlet -X -A -q '."-R $main::root_dir ".'-s '
                      .$mirror_url;
            }
         }
         
         my $wver=&windows_ver;
         my $account_type='separate';
         my @sshd_password=();
         my $sshd_account='cyg_server';
         my $privl='';
         my $domain_user='';my $domain='';
         if ($wver!~/95|98|ME/) {
            my $domain=`net config workstation`;
            $domain=~/^.*Workstation domain\s+(.+)\s*$/m;
            $domain=$1||'';
            chomp($domain=~tr/\0-\37\177-\377//d);
            if ($wver=~/XP|2000|NT/) {
               my $banner="   For $wver, you have a choice of using\n"
                         ."   either the LocalSystem account for the\n"
                         ."   REQUIRED sshd (Secure Shell Daemon/Service\n"
                         ."   supplied by OpenSSH) or a separate user\n"
                         ."   account. The LocalSystem account is less\n"
                         ."   maintenance and you won't need to manage or\n"
                         ."   remember a separate account and password -\n"
                         ."   BUT IT IS LESS SECURE. Using a separate user\n"
                         ."   account is *HIGHLY* recommended!:";
               my %Menu_select_account_type=(
         
                   Label  => 'Menu_select_account_type',
                   Item_1 => {
        
                      Text => "Use LocalSystem account for sshd service", 
                      Default => "*",
         
                   },
                   Item_2 => {

                      Text => "Use separate user account for sshd service", 
         
                   },
                   Banner => $banner,
         
               );
               $account_type=Term::Menus::Menu(\%Menu_select_account_type);
               chomp($account_type);
               exit if $account_type eq ']quit[';
               $privl=' --privileged' if -1<index $account_type,'separate';
            }
            $domain_user=&ws_info($domain) unless $wver=~/XP|2000|NT/;
            my $setup_cyg_server=0;
            if ($domain_user eq 'UsE_separate_login_id_for_sshd') {
               $account_type='separate';
               $domain_user='';
               $setup_cyg_server=1 if (-1==index `net user`,'cyg_server');
            }
            if ($domain_user) {
               print "\n\n\n   Please enter the Password for the $domain ",
                     "account $domain_user,\n   and take steps to insure ".
                     "it's security and recoverability\n   ",
                     "(i.e. - store a copy in a SAFE ",
                     "place where you can find\n   it if necessary.)\n\n\n",
                     "   Please TYPE the Password\n   for ",
                     "$domain domain account \'$domain_user\': ";
               Term::ReadKey::ReadMode(2);
               my $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[0]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[0]);
               print "\n\n   Please verify the $domain_user Password: ";
               Term::ReadKey::ReadMode(2);
               $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[1]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[1]);
               if ($sshd_password[0] ne $sshd_password[1]) {
                  @sshd_password=();
                  my $cc=2;
                  while ($cc--) {
                     print "\n\n";
                     print "   Your Password entries do NOT match!\n\n",
                           "   Please carefully type the\n",
                           "   $domain_user Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[0]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[0]);
                     print "\n\n   Please verify the $domain_user Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[1]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[1]);
                     last if $sshd_password[0] eq $sshd_password[1];
                  }
               }
               if ($sshd_password[0] ne $sshd_password[1]) {
                  print "\n\n";
                  print "Fatal Error: Unable to verify Password entries!\n\n";
                  print "Press any key to exit FullAuto Setup.\n";
                  <STDIN>;exit 1;
               }
               print "\n";
            } elsif (((-1<index $account_type,'separate') &&
                     (&test_windows_user($sshd_account))) ||
                      $setup_cyg_server) {
               my $banner="   OpenSsh's sshd service running via Cygwin is ".
                  "*REQUIRED* for\n   FullAuto to run on MS Windows. Two ".
                  "separate user accounts\n   are needed - one for the ".
                  "service itself, and one for \"privilege\n   separation\"".
                  " The id 'sshd' will be created for the privilege\n".
                  "   separation purpose. For more info,\n".
                  "   read /usr/share/doc/openssh/README.privsep.\n\n".
                  "   Unless you indicate otherwise, the account 'cyg_server'".
                  " will be\n   utilized by the sshd service and will be ".
                  "automatically created\n   if needed.\n\n   Please make ".
                  "a selection:";
               my $sa=$sshd_account;
               my %Menu_select_account=(

                  Label  => 'Menu_select_account',
                  Item_1 => {

                    Text => "Use the account \'$sa\' for the sshd service",
                    Default => "*",

                  },
                  Item_2 => {

                    Text => "Use a different account ( You will be prompted. )",

                  },
                  Banner => $banner,

               );
               $selection=Term::Menus::Menu(\%Menu_select_account);
               chomp($selection);
               exit if $selection eq ']quit[';
               if (-1<index $selection,'different') {
                  print "\n       Please type the name of the $wver\n",
                        "        user account that will be used by the sshd\n",
                        "        service: ";
                  $sshd_account=<STDIN>;
                  print "\n";
               }
               print "\n\n\n   Now is the time to CAREFULLY select a ",
                     "password for the\n   $sshd_account account, and",
                     " take steps to insure it's security\n   and ",
                     "recoverability (i.e. - store a copy in a SAFE ",
                     "place where\n   you can find it if necessary.)\n\n\n",
                     "   Please TYPE your new Password\n   for ",
                     "account \'$sshd_account\': ";
               Term::ReadKey::ReadMode(2);
               my $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[0]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[0]);
               print "\n\n   Please verify your new Password: ";
               Term::ReadKey::ReadMode(2);
               $pas=<STDIN>;
               $pas=~/^(.*)$/;
               $sshd_password[1]=$1;
               Term::ReadKey::ReadMode(0);
               chomp($sshd_password[1]);
               if ($sshd_password[0] ne $sshd_password[1]) {
                  @sshd_password=();
                  my $cc=2;
                  while ($cc--) {
                     print "\n\n";
                     print "   Your Password entries do NOT match!\n\n",
                           "   Please carefully type your\n",
                           "   new Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[0]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[0]);
                     print "\n\n   Please verify your new Password: ";
                     Term::ReadKey::ReadMode(2);
                     $pas=<STDIN>;
                     $pas=~/^(.*)$/;
                     $sshd_password[1]=$1;
                     Term::ReadKey::ReadMode(0);
                     chomp($sshd_password[1]);
                     last if $sshd_password[0] eq $sshd_password[1];
                  }
               }
               if ($sshd_password[0] ne $sshd_password[1]) {
                  print "\n\n";
                  print "Fatal Error: Unable to verify Password entries!\n\n";
                  print "Press any key to exit FullAuto Setup.\n";
                  <STDIN>;exit 1;
               }
            } else {
               my $netuser=`net user`;
               $netuser=~s/^.*----(.*)The command comp.*$/$1/s;
               $netuser=~s/^\s*//s;
               $netuser=~s/\s*$//s;
               $netuser=~s/\n/         /g;
               my @netuser=split /    \s*/, $netuser;
               @netuser=grep { $_ ne 'sshd' } @netuser;
               my %sshd_account=();
               if (grep { 'cyg_server' eq $_ } @netuser) {
                  my $cs_info=`net user cyg_server`;
                  my $pwls='';my $ll='';
                  ($pwls=$cs_info)
                     =~s/^.*(Password last set\s*.*?(?:PM|AM)).*/$1/s;
                  ($ll=$cs_info)
                     =~s/^.*(Last logon\s*.*?(?:PM|AM)).*/$1/s;
                  %sshd_account=(

                     Label => 'sshd_account',
                     Item_1 => {

                        Text => 'Remove and recreate local \'cyg_server\''.
                                ' account.'.
                                "\n                 ( Recommended )\n\n",
                        Default => "*",
                     },
                     Item_2 => {

                        Text => 'Use the pre-existing local \'cyg_server\''.
                                " account.\n\n",

                     },
                     Item_3 => {

                        Text => 'Use or create a different local account.',

                     },
                     Banner => "\n   Cygwin's sshd service requires a".
                               "\n   dedicated Windows user account.".
                               "\n   A pre-existing local \'cyg_server\' ID ".
                               "\n   was found with the following properies:".
                               "\n\n      $pwls\n      $ll".
                               "\n\n   Please select an action:",


                  );
               }
               my $selection=Menu(\%sshd_account);
               if (-1<index $selection, 'Remove') {
                  my $ndout=`net user sshd /DELETE 2>&1`;
                  my $cgout=`net user cyg_server /DELETE 2>&1`;
               } elsif (-1==index $selection, 'pre-existing') {
                  @netuser=grep { $_ ne 'cyg_server' } @netuser;
                  %sshd_account=(

                     Label => 'sshd_account',
                     Item_1 => {

                        Text => 'Create a new dedicated Windows user account'.
                                "\n                   (You will be prompted)".
                                "\n\n",

                     },
                     Item_2 => {

                        Text => 'Use the pre-existing \']C[\' local account.',
                        Convey => \@netuser,

                     },
                     Banner => "\n   Cygwin's sshd service requires a".
                               "\n   dedicated Windows user account.".
                               "\n   You can select a pre-existing one,".
                               "\n   or elect to use a different one.".
                               "\n\n   Please select an action:",


                  );
                  $selection=Menu(\%sshd_account);
                  chomp($selection);
                  exit if $selection eq ']quit[';
                  if (-1<index $selection,'pre-exist') {
                     $selection=~s/^.*?['](.*?)['].*$/$1/;
                     $sshd_account=$selection;
                  } else {


                  }
               }
# Check if cyg_server exists but is bad
# Then either remove and ask or just ask if cyg_server or other id
            }
            # Let's see if Cygwin remnants remain that could mess
            # up the installation
            my $check_for_orphaned_sshd_service=`sc qc sshd 2>&1`;              
            unless (-1<index $check_for_orphaned_sshd_service,'does not') {
               my $cygpath=~s/^.*H_NAME\s+:\s+(.*exe).*$/$1/s;
               $cygpath=~s/\\/\//g;
               unless (-e $cygpath) {
                  # cygrunsrv does not exist - let's see if its running?
                  my $chkrun=`sc query sshd 2>&1`;
                  if (-1<index $chkrun,'RUNNING') {
                     # Its running - let's stop it
                     my $stopout=`net stop sshd 2>&1`;
                     unless (-1<index $stopout,'stopped suc') {
                        print "FATAL ERROR - cannot stop sshd: $stopout\n";
                        exit 1;
                     } 
                  }
                  # Now let's delete sshd 
                  my $sc_out=`sc delete sshd 2>&1`;
                  unless (-1<$sc_out,'SUCCESS') {
                     print "FATAL ERROR - cannot delete sshd: $sc_out\n";
                     exit 1;
                  }
               }
            }
            my $check_for_orphaned_cygserver_service=`sc qc cygserver 2>&1`;
            unless (-1<index $check_for_orphaned_cygserver_service,'does not') {
               my $cygpath=~s/^.*H_NAME\s+:\s+(.*exe).*$/$1/s;
               $cygpath=~s/\\/\//g;
               unless (-e $cygpath) {
                  # cygrunsrv does not exist - let's see if its running?
                  my $chkrun=`sc query cygserver 2>&1`;
                  if (-1<index $chkrun,'RUNNING') {
                     # Its running - let's stop it
                     my $stopout=`net stop cygserver 2>&1`;
                     unless (-1<index $stopout,'stopped suc') {
                        print "FATAL ERROR - cannot stop cygserver: $stopout\n";
                        exit 1;
                     }
                  }
                  # Now let's delete cygserver
                  my $sc_out=`sc delete cygserver 2>&1`;
                  unless (-1<$sc_out,'SUCCESS') {
                     print "FATAL ERROR - cannot delete cygserver: $sc_out\n";
                     exit 1;
                  }
               }
            }
         }
         
         my $pwd=`cmd /c chdir`;
         chmod($pwd);
         my $cygpath=$pwd;
         $cygpath=~s/^(.):/\/cygdrive\/$1/;
         $cygpath=~s/\\/\//g;
         system($setup_cmd);

         if ($^O eq 'cygwin') {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $srvcmd='export CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv -L"';
            my $cygsrvs=`$srvcmd 2>&1`;
            if (-1==index $cygsrvs,'sshd') {
               if ($domain_user) {
                  system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                  system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                         '-g  \"Domain Users\" '.
                         '>> /etc/group"');
                  $main::domain_gr_flag=1;
                  $sshd_account=$domain_user;
               }
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/ssh-host-config -y '.
                      '-u \"'.$sshd_account.'\" -w \"'.
                      $sshd_password[0].'\" '.
                      '-c \"ntsec\"'.$privl.'"');
               print "\n   FullAuto Install continues . . . \n\n";
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/ssh-user-config -n"');
               print "\n   FullAuto Install continues . . . \n\n";
            }
            if (-1==index $cygsrvs,'cygserver') {
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygserver-config -y"');
            }
            #system('export CYGWIN=nodosfilewarning & '.
            #       "cmd /c $clo\\\\bin\\\\bash -lc ".
            #       '"/usr/bin/cron-config"');
            if (-1==index $cygsrvs,'sshd') {
               my $netstart="cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netout=`$netstart`;
            }
            if (-1==index $cygsrvs,'cygserver') {
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"net start cygserver 2>&1"');
            }
            #system('export CYGWIN=nodosfilewarning & '.
            #       "cmd /c $clo\\\\bin\\\\bash -lc ".
            #       '"net start cron 2>&1"');
         } else {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv -L 2>&1"';
            my $cygsrvs=`$srvcmd 2>&1`;
            if (-1<index $cygsrvs,'system cannot find') {
               $url='http://www.cygwin.com/mirrors.html';
               $req = HTTP::Request->new(GET => $url);
               $req->header('Accept' => 'text/html');
               $res = $Ua->request($req);
               my $href='';my @urls=();my $mirror_url2='';
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  my $mirrors=$res->content;
                  foreach my $href ($mirrors=~/href="(.*?)"/mg) {
                     next if -1==index $href,'://';
                     next if -1<index $href,'html';
                     next if -1==index $href,'http';
                     next if -1<index $href,$mirror_url;
                     push @urls, $href;
                  }
                  $mirror_url2=$urls[int(rand($#urls))];
                  $setup_cmd=~s/-s .*$/-s $mirror_url2/; 
                  system($setup_cmd);
                  my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                             "cmd /c $clo\\\\bin\\\\bash -lc ".
                             '"/usr/bin/cygrunsrv -L 2>&1"';
                  my $cygsrvs=`$srvcmd 2>&1`;
                  if (-1<index $cygsrvs,'system cannot find') {
                     print "\n\n".
                        "   Fatal Error! - Cannot install Cygwin\n".
                        "   There were two attempts from two different\n\n".
                        "   Cygwin mirror sites:\n\n".
                        "   $mirror_url\n".
                        "   $mirror_url2\n\n";
                        "   PRESS ANY KEY to Exit Setup\n\n";
                     <STDIN>;
                     exit 1;
                  }
               } else {
                  print "\n\n".
                     "   Fatal Error! - Cannot install Cygwin\n".
                     "   There were two attempts from two different\n\n".
                     "   Cygwin mirror sites:\n\n".
                     "   $mirror_url\n".
                     "   $mirror_url2\n\n";
                     "   PRESS ANY KEY to Exit Setup\n\n";
                  <STDIN>;
                  exit 1;
               }
            } elsif (-1==index $cygsrvs,'sshd') {
               if ($domain_user) {
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\bin\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                  unless ($main::domain_gr_flag) {
                     system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\bin\\bash -lc ".
                         '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                         '-g  \"Domain Users\" '.
                         '>> /etc/group"');
                     $main::domain_gr_flag=1;
                  }
                  $sshd_account=$domain_user;
               }
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/ssh-host-config -y '.
                      '-u \"'.$sshd_account.'\" -w \"'
                      .$sshd_password[0].'\" '.
                      '-c \"ntsec\"'.$privl.'"');
               print "\n   FullAuto Install continues . . . \n\n";
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/ssh-user-config -n"');
               print "\n   FullAuto Install continues . . . \n\n";
            }
            if (-1==index $cygsrvs,'cygserver') {
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/cygserver-config -y"');
            }
            #system('SET CYGWIN=nodosfilewarning & '.
            #       "cmd /c $cygwin_loc\\bin\\bash -lc ".
            #       '"/usr/bin/cron-config"');
            if (0<length $cygsrvs) {
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net stop sshd 2>&1"');
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net stop cygserver 2>&1"');
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
                    '"/bin/rebaseall -v"');
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
                    '"/bin/perlrebase"');
               my $netstart='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\bin\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netout=`$netstart`;
               if (-1<index $netout,'System error') {
                  my $netdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\bin\\bash -lc ".
                    '"net user sshd /DELETE 2>&1"';
                  my $ndout=`$netdel`;
                  my $cygdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\bin\\bash -lc ".
                    '"net user cyg_server /DELETE 2>&1"';
                  my $cgout=`$cygdel`;
                  my $netrm='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\bin\\bash -lc ".
                    '"/usr/bin/cygrunsrv -R sshd 2>&1"';
                  my $rmout=`$netrm`;
                  if ($domain_user) {
                     system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\bin\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                     unless ($main::domain_gr_flag) {
                        system('SET CYGWIN=nodosfilewarning & '.
                            "cmd /c $clo\\bin\\bash -lc ".
                            '"/usr/bin/mkgroup -d \"'.$domain.'\" '.
                            '-g  \"Domain Users\" '.
                            '>> /etc/group"');
                        $main::domain_gr_flag=1;
                     }
                  }
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-host-config -y '.
                         '-u \"'.$sshd_account.'\" -w \"'.
                         $sshd_password[0].'\" '.
                         '-c \"ntsec\"'.$privl.'"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-user-config -n"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  my $net_start='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"net start sshd 2>&1"';
                  my $netot=`$net_start`;
               }
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net start cygserver 2>&1"');
            } else {
#print "REBASE TWO\n";
#               system('SET CYGWIN=nodosfilewarning & '.
#                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
#                    '"/bin/rebaseall -v"');
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
                    '"/bin/perlrebase"');
            }
            if (-1==index $cygsrvs,'sshd') {
               my $nettstart='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netut=`$nettstart`;
               if (-1<index $netut,'System error') {
                  my $netdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net user sshd /DELETE 2>&1"';
                  my $ndout=`$netdel`;
                  my $netrm='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv -R sshd 2>&1"';
                  my $rmout=`$netrm`;
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-host-config -y '.
                         '-u \"'.$sshd_account.'\" -w \"'.
                         $sshd_password[0].'\" '.
                         '-c \"ntsec\"'.$privl.'"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/ssh-user-config -n"');
                  print "\n   FullAuto Install continues . . . \n\n";
                  my $net_start='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"net start sshd 2>&1"';
                  my $netot=`$net_start`;
               }
            }
            if (-1==index $cygsrvs,'cygserver') {
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\bash -lc ".
                    '"net start cygserver 2>&1"');
            }
            #system('SET CYGWIN=nodosfilewarning & '.
            #       "cmd /c $cygwin_loc\\bin\\bash -lc ".
            #       '"net start cron 2>&1"');
         }
         if ($selection!~/MINIMAL/) {
            my $cygwin_loc=get_cygwin_location();
            my $clo=$cygwin_loc;
            $clo=~s/\\/\\\\/g;
            my $incpath=$INC[0];
            $incpath=~s/\\/\//g;
            if ($^O eq 'cygwin') {
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e \"eval { require IO::Pty;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Pty\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Tagset;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Tagset\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Parser;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Parser\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require URI;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'URI\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval {require ExtUtils::Depends;1}'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'ExtUtils::Depends\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Task::Weaken;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Task::Weaken\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Digest::MD5;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Digest::MD5\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require B::Utils;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'B::Utils\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Algorithm::Diff;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Algorithm::Diff\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Data::Dump::Streamer;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Data::Dump::Streamer\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::API;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::API\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::DriveInfo;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::DriveInfo\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON::XS;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON::XS\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Term::ReadKey;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::ReadKey\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::RawInput;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::RawInput\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::Menus;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::Menus\')}\""');
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Mozilla::CA;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Mozilla::CA\')}\""');
               my $par_dir='export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$main::PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export FA_BERKELEY=\\"'.
                         $main::cygwin_berkeley_db_mode.'\\";'.
                      'export FA_MOZREPL=\\"'.$main::install_firefox.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      '/usr/bin/echo y|/usr/bin/cpan -i '.
                      "REEDFISH/Net-FullAuto-$main::VERSION.tar.gz\"");
            } else {
               my $build_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"echo y | /usr/bin/perl -e '.
                      '\"require CPAN and CPAN::HandleConfig-^^^>load;'.
                      'print \$CPAN::Config-^^^>{build_dir}\" 2>&1"';
               my $bd=`$build_dir`;
               if ($bd=~/^\s*$|Can\'t locate/s) {
                  my $rmdir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e '.
                      '\"foreach my \$f (@INC) { my \$e=\$f;'.
                      'if (-e \$e.\'/CPAN/Config.pm\') {'.
                      'rm -f \$e.\'/CPAN/Config.pm\';'.
                      'rm -f \$e.\'/CPAN/Config.pm~\';'.
                      'last}print \'done\'}\" 2>&1"';
                  my $rmd=`$rmdir`;
                  system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/echo y | /usr/bin/cpan"');
               }
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require IO::Pty;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\',\'IO::Pty\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Tagset;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Tagset\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require HTML::Parser;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'HTML::Parser\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require URI;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'URI\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval {require ExtUtils::Depends;1}'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'ExtUtils::Depends\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Task::Weaken;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Task::Weaken\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Digest::MD5;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Digest::MD5\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require B::Utils;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'B::Utils\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Algorithm::Diff;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Algorithm::Diff\')}\""');
               my $ddstest='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Data::Dump::Streamer;print \'DDS\' }'.
                      ' or do { print \'NODDS\' }\""';
               my $ddst=`$ddstest`;
               chomp($ddst);
               if ($ddst eq 'NODDS') {
                  system('SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $cygwin_loc\\bin\\bash -lc ".
                         '"/usr/bin/perl -e \"eval { '.
                         'require Data::Dump::Streamer;1 }'.
                         ' or do {require CPAN and '.
                         'CPAN::Shell-^^^>notest(\'get\','.
                         '\'Data::Dump::Streamer\')}\""');
                  my $streamdir='SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/perl -e '.
                         '\"require CPAN and CPAN::HandleConfig-^^^>load;'.
                         'print \$CPAN::Config-^^^>{build_dir}\""';
                  my $stmout=`$streamdir`;
                  $stmout=~s/\s*$//s;
                  $stmout=~s/^\s*//s;
                  $streamdir='SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/cygpath -lm \"'.$stmout.'\""';
                  $stmout=`$streamdir`;
                  $stmout=~s/\s*$//s;
                  $stmout=~s/^\s*//s;
                  $streamdir='SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/perl -e '.
                         '\"opendir(DIR,\''.$stmout.'\') or die \$!;'.
                         'my\$t=0;my\$n=\'\';my\$f=\'\';my \$e;'.
                         'while(\$e=readdir(DIR)){'.
                         'next if \$e eq \'.\';'.
                         'next if \$e eq \'..\';'.
                         'next if \$e!~/^Data-Dump-Streamer/;'.
                         'next if substr(\$e,-3) eq \'yml\';'.
                         '\$f=\''.$stmout.'\'.\'/\'.\$e;'.
                         'my \$a=(stat(\$f))[9];'.
                         'my \$d=time() - \$a;'.
                         'if(\$t==0 and \$e=~/^Data-Dump-Streamer/){'.
                         '\$t=\$d;\$n=\$f;}if(\$d^^^<\$t){'.
                         '\$t=\$d;\$n=\$f;}}\$n=\$f if !\$n and \$f;'.
                         'print \$f\""';
                  my $sdir=`$streamdir`;
                  $sdir=~s/\s*$//s;
                  $sdir=~s/^\s*//s;
                  system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"cd \"'.$sdir.'\";/usr/bin/perl Build.PL NODDS;"');
                  system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"cd \"'.$sdir.'\";./Build install;"');
               }
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::API;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::API\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Win32::DriveInfo;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Win32::DriveInfo\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON::XS;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON::XS\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require JSON;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'JSON\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { require Term::ReadKey;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::ReadKey\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::RawInput;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::RawInput\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Term::Menus;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Term::Menus\')}\""');
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"/usr/bin/perl -e \"eval { '.
                      'require Mozilla::CA;1 }'.
                      ' or do {require CPAN and '.
                      'CPAN::Shell-^^^>notest(\'install\','.
                      '\'Mozilla::CA\')}\""');
               my $par_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$main::PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export FA_BERKELEY=\\"'.
                         $main::cygwin_berkeley_db_mode.'\\";'.
                      'export FA_MOZREPL=\\"'.$main::install_firefox.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      '/usr/bin/echo y|/usr/bin/cpan -i '.
                      "REEDFISH/Net-FullAuto-$main::VERSION.tar.gz\"");
            }
         }
         my $rmdir_out=rmdir $main::curdir.'/inc/.author'; 
         my $un_out=unlink $main::curdir.'/inc/Module/Install/Base.pm';
         $un_out=unlink $main::curdir.'/inc/Module/Install/Metadata.pm';
         $un_out=unlink $main::curdir.'/inc/Module/Install.pm';
         $rmdir_out=rmdir $main::curdir.'/inc/Module/Install';
         $rmdir_out=rmdir $main::curdir.'/inc/Module';
         unless ((exists $ENV{PARdir} && (-f $ENV{PARdir}.'/inc_exists.txt'))) {
            $rmdir_out=rmdir $main::curdir.'/inc';
         } else {
            $un_out=unlink $ENV{PARdir}.'/inc_exists.txt';
         }
         opendir(CD,$main::curdir)
            or die "Cannot open ".$main::curdir.": $!\n";
         while (my $file = readdir(CD) ) {
            chomp($file);
            if (-1<index $file,'http%3a%2f%2f') {
               $un_out=unlink $main::curdir."/$file/setup.ini";
               print "ERROR: $!\n" unless $un_out;
               if (-e $main::curdir."/$file/release/_update-info-dir") {
                  opendir(OD,"$main::curdir/$file/release/_update-info-dir")
                        or die $!;
                  while (my $fil = readdir(OD) ) {
                     chomp($fil);
                     $un_out=unlink $main::curdir.
                                "/$file/release/_update-info-dir/$fil";
                     my $cnt=0;
                     while (-e $main::curdir.
                           "/$file/release/_update-info-dir/$fil") {
                         sleep 1;
                         last if ++$cnt==100; 
                     }
                     print "ERROR: $!\n" unless $un_out;
                  }
                  close(OD);
                  $rmdir_out=rmdir $main::curdir.
                        "/$file/release/_update-info-dir";
                  print "ERROR $main::curdir/$file/release/_update-info-dir:",
                        " $!\n" unless $rmdir_out;
                  $rmdir_out=rmdir $main::curdir."/$file/release";
                  print "ERROR $main::curdir/$file/release:",
                        " $!\n" unless $rmdir_out;
               }
               $rmdir_out=rmdir $main::curdir."/$file";
               print "ERROR: $!\n" unless $rmdir_out;
               last;
            }
         }
         close(CD);
         &install_firefox() if -1<index $main::install_firefox,'Install';
         print "\n\n   FullAuto Installation has completed",
               "\n\n   Thank you!",
               "\n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@fullautosoftware.net.",
               "\n\n   Press ANY key to exit.\n\n";<STDIN>;
         exit 0;
      }
   } elsif ($process_id) {
      exit;
   }
   my $die=<<'END';

       FATAL ERROR! : Cygwin Linux Emulation Layer
                      is required to use FullAuto
                      on Windows - goto www.cygwin.com.

           Be sure to install the following programs in
           addition to the base package:

           inetutils and openssh [as provided by Cygwin]
           perl [as provided by Cygwin] (*NOT* CPAN)
           perl-libwin32 [as provided by Cygwin] (*NOT* CPAN)
           ncurses, cron, and procps [as provided by Cygwin]
           gcc-core and gcc-g++ [as provided by Cygwin]
           Oracle Berkeley DB [as provided by Cygwin or Oracle]

           **IMPORTANT** - the FullAuto install, either manual
           or via CPAN, must be run *inside* a Cygwin bash shell
           when installing FullAuto on Microsoft Windows.

END
   die $die;
}

unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
   my @editors=();
   my $banner="   In order is use the integrated edit features\n".
              "   you will need to choose an editor.";
   unless ($editor) {
      if ($^O eq 'cygwin') {
         if (exists $ENV{FA_EDITOR} and $ENV{FA_EDITOR}) {
            $editor=$ENV{FA_EDITOR};
         } else {
            my $tp='';
            my $mount=`/bin/mount -p`;
            $mount=~s/^.*(\/\S+).*$/$1/s;
            unless ($tp=&fa_find_editor('TextPad.exe')) {
               my $sysdr=`cmd /c echo %SystemDrive%`;
               $sysdr=~s/^\s*(.*)\s*$/$1/s;
               my $let=substr($sysdr,0,1);
               my $lt=lc($let);
               if (-e $mount."/$lt/Program Files/TextPad 5/TextPad.exe") {
                  $tp='default';
               }
            }
            if ($tp) {
               push @editors, 'TextPad (The Text Editor for Windows)';
            }
            my $wordpad=0;
            my $sysdr=`cmd /c echo %SystemDrive%`;
            $sysdr=~s/^\s*(.*)\s*$/$1/s;
            my $let=substr($sysdr,0,1);
            my $lt=lc($let);
            if (-e $mount.
                   "/$lt/Program Files/Windows NT/Accessories/wordpad.exe") {
               $banner="   In order is use the integrated edit features\n".
                       "   you will need to choose an editor. MS Wordpad\n".
                       "   is set as the default - and is recommended if\n".
                       "   you are not familiar with the other listed\n".
                       "   editors.";
               $wordpad=1;
            }
            if (-e '/bin/vim.exe') {
               push @editors,'vim';
            } elsif (-e '/bin/vim-nox.exe') {
               push @editors,'vim';
            }
            if (-e '/bin/emacs.exe') {
               push @editors, 'emacs';
            } elsif (-e '/bin/emacs-nox.exe') {
               push @editors, 'emacs';
            }
            if (-e '/bin/joe.exe') {
               push @editors, 'joe';
            }
            if (-e '/bin/nano.exe') {
               push @editors, 'nano';
            }
            my %Menu_select_editor=();
            if ($wordpad) {
               %Menu_select_editor=(

                     Label  => 'Menu_select_editor',
                     Item_1 => {

                        Text => "Wordpad (Microsoft Wordpad -\n               ".
                                "          Available on all Windows Systems)",
                        Default => "*",

                     },
                     Item_2 => {

                        Text    => "]C[",
                        Convey  => \@editors,

                     },
                     Scroll => 1,
                     Banner => $banner,

               );
               $selection=Term::Menus::Menu(\%Menu_select_editor);
               chomp($selection);
               exit if $selection eq ']quit[';
            } else {
               %Menu_select_editor=(

                     Label  => 'Menu_select_editor',
                     Item_1 => {

                        Text    => "]C[",
                        Convey  => \@editors,

                     },
                     Scroll => 1,
                     Banner => $banner,

               );
               $selection=Term::Menus::Menu(\%Menu_select_editor);
               chomp($selection);
               exit if $selection eq ']quit[';
            }
            if ($selection=~/TextPad/) {
               if ($tp eq 'default') {
                  my $sysdr=`cmd /c echo %SystemDrive%`;
                  $sysdr=~s/^\s*(.*)\s*$/$1/s;
                  my $let=substr($sysdr,0,1);
                  my $lt=lc($let);
                  $editor=$mount.
                     "/$lt/Program Files/TextPad 5/TextPad.exe";
               } else {
                  $tp=~s/\\/\//g;
                  $tp=~s/^([A-Za-z]):(.*)/$1$2/;
                  $editor="$mount/$tp";
               }
            } elsif ($selection=~s/(vim)/$1/) {
               if (-e '/bin/vim-nox.exe') {
                  $editor='/bin/vim-nox.exe';
               } else {
                  $editor='/bin/vim.exe';
               }
            } elsif ($selection=~s/(emacs)/$1/) {
               if (-e '/bin/emacs-nox.exe') {
                  $editor='/bin/emacs-nox.exe';
               } else {
                  $editor='/bin/emacs.exe';
               }
            } elsif ($selection=~s/(joe)/$1/) {
               $editor='/bin/joe.exe';
            } elsif ($selection=~s/(nano)/$1/) {
               $editor='/bin/nano.exe';
            }
            exit if $selection eq ']quit[';
         }
      } else {
         if (-e '/usr/bin/vi') {
            push @editors, 'vi';   
         }
         if (-e '/usr/bin/emacs') {
            push @editors, 'emacs';
         }
         if (1<$#editors) {
            my %Menu_select_editor=(

               Label  => 'Menu_select_editor',
               Item_1 => {

                  Text    => "]C[",
                  Convey  => \@editors,

               },
               Scroll => 1,
               Banner => $banner,

            );
            $selection=Term::Menus::Menu(\%Menu_select_editor);
            chomp($selection);
            exit if $selection eq ']quit[';
            if ($selection=~s/(vi)/$1/) {
               $editor='/usr/bin/vi';
            } elsif ($selection=~s/(emacs)/$1/) {
               $editor='/usr/bin/emacs';
            }
         } elsif (1==$#editors) {
            $editor=$editors[0];
         } else {
            $editor='';
         }
      }

   }
} else {
   chmod 0755, $Config{installsitelib}."/Net/FullAuto/Distro"; 
}

&find_windows_app() if $^O eq 'cygwin' &&
   ((-1==index $main::install_firefox,'Install') &&
   (-1==index $main::install_firefox,'NOT'));

if ($^O eq 'cygwin' && !can_cc()) {
   my $uname=`/bin/uname`;
   my $stup='setup-x86.exe';
   $stup='setup-x86_64.exe' if $uname=~/WOW64/;
   my $die="\n       FATAL ERROR! : The Gnu C Compiler 'gcc': gcc-core".
           "\n                      & gcc-g++ as provided by Cygwin".
           "\n                      is required to install FullAuto".
           "\n                      on Windows.".
           "\n(Hint: Run Cygwin $stup and install 'gcc-core' ".
           "and 'gcc-g++' under the Category 'Devel' ).".
           "\n\n";
   die $die;
} 

if ($^O eq 'cygwin' && !(can_run('/bin/ssh') || can_run('/bin/telnet'))) {
   my $timeout=120;my $a='';
   eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      my $uname=`/bin/uname`;
      my $stup='setup-x86.exe';
      $stup='setup-x86_64.exe' if $uname=~/i686/;
      print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n". 
            "\n       WARNING! : The Secure Shell - 'ssh'".
            "\n                  and/or 'telnet' (via inetutils)".
            "\n                  as provided by Cygwin".
            "\n                  is required to install FullAuto".
            "\n                  on Windows.".
            "\n(Hint: Run Cygwin $stup and install OpenSSH ".
            "under the Category 'Net' ).".
            "\n\n";
      print "Press <ENTER> if you wish to continue, or 'N' to quit . . . [Y] ";
      $a=<STDIN>;
      alarm 0;
   };
   if ($@) {
      # timed out
      exit 1;
   } elsif ($a=~/^[Nn]$/s) {
      exit;
   } alarm 0;
}
if (!can_run('make') && !(($^O eq 'cygwin') && (-e "/usr/bin/make"))) {
   my $die="\n       FATAL ERROR! : Cannot locate 'make'. This program ".
           "\n                      is required to install FullAuto".
           "\n                      (Hint: goto www.gnu.org for gnumake).".
           "\n\n";
   die $die;
}
my $greppath='';
if (-e "/bin/grep") {
   $greppath="/bin/";
} elsif (-e "/usr/bin/grep") {
   $greppath="/usr/bin/";
} elsif (-e "/usr/local/bin/grep") {
   $greppath="/usr/local/bin/";
}
my $get_BerkeleyDB=0;
eval { require BerkeleyDB };
$get_BerkeleyDB=1 if $@;
my $cpan_error='';
eval {
   require CPAN::Mini;
   import CPAN::Mini;
};
if (!$@ && grep { /-*add[-_]?dependencies/i } @ARGV) {
   my $distribution = CPAN::Shell->expand(
         "Module",'BerkeleyDB'
      )->distribution()->pretty_id();
   my $let=unpack('a1',$distribution);
   my $lett=unpack('a2',$distribution);
   my $minicpan=CPAN::Mini->new(

      #remote => "http://www.cpan.org",
      remote => "http://www.perl.com/CPAN",
      local  => cwd()."/dependencies/CPAN",
      log_level => 'debug',
      exact_mirror => 1,

   );
   $minicpan->mirror_file(
      "authors/id/$let/$lett/$distribution");
}
if ($get_BerkeleyDB && $^O ne 'cygwin') {
   # Let's find if Berkeley DB is already on the system
   my $findpath='';
   if (-e "/bin/find") {
      $findpath="/bin/";
   } elsif (-e "/usr/bin/find") {
      $findpath="/usr/bin/";
   } elsif (-e "/usr/local/bin/find") {
      $findpath="/usr/local/bin/";
   }
   my $xargspath='';
   if (-e "/bin/xargs") {
      $xargspath="/bin/";
   } elsif (-e "/usr/bin/xargs") {
      $xargspath="/usr/bin/";
   } elsif (-e "/usr/local/bin/xargs") {
      $xargspath="/usr/local/bin/";
   }
   if ($findpath && $xargspath && $greppath) {
      my @output=();
      my $testgrep =`${greppath}grep -H 2>&1`;
      my $testgrep2=`${greppath}grep 2>&1`;
      my $grepopt='';
      if ((-1==index $testgrep,'illegal option')
            && (-1==index $testgrep2,'-insvxbhwyu')) {
         $grepopt='-H ';
      }
      my $find_cmd1="${findpath}find ";
      my $find_cmd2=" -d 4 -name \"*.h\" ".
                   "| ${xargspath}xargs ${greppath}grep ".
                   "${grepopt}DB_VERSION_STRING";
      print "\nSearching for latest verison of Berkeley DB.\n".
            "This may take up to five minutes ...\n\n";
      foreach my $dir ('/usr/','/opt/',(getpwuid $>)[7].'/') {
         next if unpack('a1',$dir) eq '.';
         next unless -d $dir;
         opendir(DIR, $dir) or die $!;
         while (my $file = readdir(DIR) ) {
            next if ($file eq "." or $file eq ".." or $file eq "doc" or
                     $file eq "X11R6" or $file eq "docs" or
                     $file eq "man" or $file eq "ssl" or
                     $file eq "license" or $file eq "logfile" or
                     $file eq "bin" or ($^O eq 'cygwin' &&
                     ($file eq "Application Data" or
                      $file eq "Favorites" or $file eq
                      "Local Settings" or $file eq "Recent" or
                      $file eq "Start Menu" or $file eq "SendTo" or
                      $file eq "NetHood" or $file eq "PrintHood")));
            if (-d $dir.$file) {
               print "Searching $dir$file ...\n";
               my @subout=`$find_cmd1\"$dir$file\"$find_cmd2`;      
               push @output, @subout;
            }
         }
      }
      my @vers=();my %verhash=(); 
      if (-1<$#output) {
         foreach my $version (@output) {
            next if (-1<index $version, $CPAN::Config->{cpan_home}) || 
                    (-1<index $version, 'Net-FullAuto-') ||
                    $version!~/db.h:.*DB_VERSION_STRING/;
            my @fileparts=split 'db.h:', $version;
            $fileparts[1]=~s/^.*DB (\d+[^:]+):.*$/$1/;
            $verhash{$fileparts[1]}=$fileparts[0]; 
         }
      }
      my $header_to_use='';my $ver='';
      foreach my $vr (reverse sort keys %verhash) {
         $header_to_use=$verhash{$vr};
         $vr=~s/^(^\d+[.]\d+).*$/$1/;
         chomp($vr);
         $ver=$vr;
         my $find_cmd="${findpath}find /usr -name \"libdb-".$ver.".a\"";
         my @lib=`$find_cmd`;
         chomp($lib[0]);$berkeleydb=$lib[0];last;
      }
      my $major_minor_ver=substr($ver,0,(rindex $ver,'.'));
      $major_minor_ver=$ver if -1==index $major_minor_ver,'.';
      if ($^O eq 'cygwin' && !(grep { /build_berkeleydb/i } @ARGV)) {
         if ($berkeleydb && $major_minor_ver>=4.5) {
            $berkeleydb=~s/^(.*)\/.*$/$1/;
            $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
            $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
            $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
            $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
            $ENV{'DB_FILE_LIB'}=$berkeleydb;
            $ENV{'DB_FILE_NAME'}="-ldb-$ver";
            $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
            $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};
         } else {
            my $uname=`/bin/uname`;
            my $uname_all=`/bin/uname -a`;
            $uname_all.=$uname;
            my $dbdev="libdb${major_minor_ver}-devel";
            $dbdev='libdb-devel' if $uname=~/WOW64|x86_64/;
            print "\n\n   Fatal Error!: The \'$dbdev\' package is".
                  " missing from your Cygwin installation.\n".
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
                  exit 1;
         }
      } elsif ($ENV{AUTOMATED_TESTING} ||
            ($berkeleydb && $major_minor_ver>=5.1)) {
         $berkeleydb=~s/^(.*)\/.*$/$1/;
         $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
         $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
         $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
         $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
         $ENV{'DB_FILE_LIB'}=$berkeleydb;
         $ENV{'DB_FILE_NAME'}="-ldb-$ver";
         $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
         $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};
      } else {
         if (-e "dependencies/BerkeleyDB" && !(grep {
               /(?:use[-_]?)?internet|online|connect_to_internet_ok/i
               } @ARGV)) {
            cpan_gunzip_and_untar();
            my $dir=&cwd.'/dependencies/BerkeleyDB';
            opendir(DIR,$dir);
            @files = readdir(DIR);
            closedir(DIR);
            my $file='';my $filename='';
            foreach my $f (@files) {
               next if $f eq '.';
               next if $f eq '..';
               if (-1==index $f,'.md5') {
                  $file=$f;
                  last;
               }
            }
            my $filenm=$file;
            $file=~s/.tar.gz$//;
            $filename="${file}_${$}.tar.gz";
            File::Copy::copy("$dir/$filenm",&cwd."/$filename");
            my $so=system($CPAN::Config->{gzip}." -d $filename");
            if ($so==-1) {
               die "Cannot gunzip $filename: $!\n";
            }
            $filename=~s/\.gz$//;
            print "***** Untar4: ",
               $CPAN::Config->{tar}," xvf $filename\n";
            open(FH, $CPAN::Config->{tar}." xvf $filename|");
            while (my $line=<FH>) {
               print $line;
            }
            close FH;
            $filename=~/^(.*)_(\d+).tar$/;
            $filename=$1;
            my $uniq=$2;
            File::Copy::move("$filename.NC","$filename.NC_$uniq");
            my $ver=$filenm;
            $ver=~s/_.*$//;
            $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
            my $pre="/usr/local/BerkeleyDB.$ver";
            $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
            build_berkeleydb($filename,$uniq,$pre,$PREFIX,'');
         } else {
            download_berkeleydb();
         }
         unless (exists $ENV{'BERKELEYDB_INCLUDE'} &&
               $ENV{'BERKELEYDB_INCLUDE'}) {
            my $BerkDownload='http://www.oracle.com/technetwork/products/'.
                             'berkeleydb/downloads/index.html';
            my $PackManagers='http://en.wikipedia.org/wiki/'.
                             'List_of_software_package_management_systems';
            my $w='      ';
            my $die="\n$w ".
               "FATAL ERROR! : Cannot locate 'Berkeley DB'. This C Library".
               " \n$w                is required to install FullAuto".
               "\n$w                (Hint: goto\n".
               "\n$w $BerkDownload\n".
               "\n$w                 for Berkeley DB Source Code. Binary".
               " versions".
               "\n$w                 of the Library are widely available via".
               "\n$w                 package managers such as yum and apt-get".
               "\n$w                 See:\n".
               "\n$w $PackManagers).".
               "\n\n";
            die $die;
         }
      }
   }
} elsif ($^O eq 'cygwin') {
   my $uname=`/bin/uname` || die $!;
   my $uname_all=`/bin/uname -a` || die $!;
   $uname_all.=$uname;
   $ENV{'BERKELEYDB_INCLUDE'}='/usr/include';
   $ENV{'BERKELEYDB_LIB'}='/usr/lib';
   if ($uname_all=~/WOW64|x86_64/) {
      $ENV{'BERKELEYDB_NAME'}='-ldb';
      $ENV{'DB_FILE_NAME'}='-ldb';
   } else {
      $ENV{'BERKELEYDB_NAME'}='-ldb-4.8';
      $ENV{'DB_FILE_NAME'}='-ldb-4.8';
   }
   $ENV{'DB_FILE_INCLUDE'}='/usr/include';
   $ENV{'DB_FILE_LIB'}='/usr/lib';
}

if (grep { /-*add[-_]?dependencies/i } @ARGV) {
   my @download=download_berkeleydb();
   `mkdir -p 'dependencies/BerkeleyDB'` unless
      -e 'dependencies/BerkeleyDB';
   `rm -rf dependencies/BerkeleyDB/*`;
   File::Copy::move($download[0],
      "dependencies/BerkeleyDB/$download[2].tar.gz");
   File::Copy::move($download[1],
      "dependencies/BerkeleyDB/$download[2].tar.gz.md5");
   require File::Copy;
   open(MO,"<MANIFEST");
   open(MN,">MANIFEST_NEW");
   while (my $file=<MO>) {
      next if $file=~/dependencies\/CPAN/s;
      next if $file=~/dependencies\/BerkeleyDB/s;
      print MN $file;
   }
   close MO;close MN;
   File::Copy::move('MANIFEST_NEW','MANIFEST');
   open(MF,">>MANIFEST") || die "Cannot open MANIFEST: $!\n";
   if (grep { /-*add[-_]?dependencies/i } @ARGV) {
      my $found=`find dependencies/CPAN -type f`;
      $found.=`find dependencies/BerkeleyDB -type f`;
      my @found=split "\n",$found;
      open(MF,">>MANIFEST") || die "Cannot open MANIFEST: $!\n";
      foreach my $fnd (@found) {
         print MF "$fnd\n";
      }
      close NF;
   }
} else {
   require File::Copy;
   open(MO,"<MANIFEST");
   open(MN,">MANIFEST_NEW");
   while (my $file=<MO>) {
      next if $file=~/dependencies\/CPAN/s;
      next if $file=~/dependencies\/BerkeleyDB/s;
      print MN $file;
   }
   close MO;close MN;
   File::Copy::move('MANIFEST_NEW','MANIFEST');
}

chdir $main::curdir;

if ($get_BerkeleyDB) {

   do {
      my $p='BerkeleyDB';
      eval "use $p;1" or
      do {
         print"==> $p required."
         and print "*** Installing $p\n"
         and
         do {
            eval{
               require CPAN;
               CPAN::Shell->force('install',$p);
            };
            eval "use $p;1" ||
               die "$@ *** Please manually install $p from cpan.org first...\n"
         }
      }
   }
}

chdir $main::curdir;

my $B_flag=1;
while (1) {
   eval {
      my %hash=();
      require BerkeleyDB;
      my $db = tie %hash, "BerkeleyDB::Btree",
          -Filename => "fullauto_test_for_db_creation.db",
          -Flags =>  BerkeleyDB::DB_CREATE()
      or die "Cannot tie fullauto_test_for_db_creation.db: $!";
      undef $db;
      untie %hash;
      unlink "fullauto_test_for_db_creation.db";
   };
   if ($@) {
      if (-1<index $@,'libgcc_s.so.1' && $B_flag) {
         if (-e '/usr/local/lib/libgcc_s.so.1') {
            `ln -s /usr/local/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1`;
            # Flush inheritance caches
            @{BerkeleyDB::ISA} = ();
            my $symtab = 'BerkeleyDB::';
            # Delete all symbols except other namespaces
            for my $symbol (keys %$symtab) {
               next if $symbol =~ /\A[^:]+::\z/;
               delete $symtab->{$symbol};
            }
            delete $INC{'BerkeleyDB.pm'};
            $B_flag=0;
            next;
         }
      }
      my $die=<<END;
$@
   FATAL ERROR! : Cannot create 'fullauto_test_for_db_creation.db'
                  You may be missing the Berkeley DB 'c' library.
                  This 'c' library is required to install FullAuto.
END
      if ($^O eq 'cygwin') {
         my $uname=`/bin/uname`;
         my $stup='setup-x86.exe';
         $stup='setup-x86_64.exe' if $uname=~/i686/;
         $die.="\n(Hint: Run Cygwin $stup and install Oracle Berkley ".
               "DB under the Category 'Database' ).";
      } else {
         $die.="\n(Hint: goto ->  http://www.oracle.com/technetwork/".
               "products/berkeleydb/downloads/index.html ).";
      }
      $die.="\n\n";
      die $die;
   }
   last
}

sub download_berkeleydb {

   my $url=
      'http://www.oracle.com/technetwork/'.
      'products/berkeleydb/downloads/index.html';
   if ($CPAN::META->has_usable('LWP')) {
      FA::LWP::UserAgent->config;
      print "Fetching with LWP:\n  $url\n";
      my $Ua;
      eval { $Ua = FA::LWP::UserAgent->new(
             timeout=>300,show_progress=>1) };
      if ($@) {
         $CPAN::Frontend->mywarn(
            "ERROR: FA::LWP::UserAgent->new dies with $@\n");
      } else {
         my($var);
         $Ua->proxy('http', $var)
            if $var = $CPAN::Config->{http_proxy} ||
            $ENV{http_proxy};
         $Ua->no_proxy($var)
            if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
      }
      my $req = HTTP::Request->new(GET => $url);
      $req->header('Accept' => 'text/html');
      my $res = $Ua->request($req);
      my $BDB_selection='NON-ENCRYPTED';
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         my $source=$res->content;
         my $site='download.oracle.com';
         $source=~
           s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
         my $file=$2;
         my $file=substr($file,(index $file,'/')+1,-7);
         $ver=$file;
         $ver=~s/_.*$//;
         $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
         my $timeout=120;my $a='';my $w="      ";
         my $pre="/usr/local/BerkeleyDB.$ver";
         $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
         my $berkeley_banner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND PROCEED WITH Berkeley DB
                      INSTALLATION in 5 MINUTES ***

   Berkeley DB is a file-based (lightweight) database that FullAuto uses for
   storing and retrieving credentials and persistence data. Berkeley DB is
   maintained by Oracle Corporation and hosted at Oracle.com. It has the same
   open source license as FullAuto: GNU Affero General Public License V3.0.
   The default version of Berkeley DB that FullAuto will install and use is
   the latest **NON-ENCRYPTED** version. There is an option to choose
   Encrypted on the next screen.

         There is **NO WARRANTY** for Berkeley DB. USE AT YOUR RISK!

   FullAuto setup will download source code from Oracle.com and build it. It
   will be installed into:   $pre
END

               my $berkeleybanner=<<END;

         *** THIS SCREEN WILL TIMEOUT AND PROCEED WITH Berkeley DB
                      INSTALLATION in 5 MINUTES ***







END

               my $encrypted_banner=<<END;

   From http://http://docs.oracle.com/cd/E17076_03/html/index.html:

   "Berkeley DB releases optionally include strong cryptographic support;
   this release DOES contain cryptographic support. Export/import and/or
   use of cryptography software, or even communicating technical details
   about cryptography software, is illegal in some parts of the world. You
   are strongly advised to pay close attention to any export/import and/or
   use laws which apply to you when you import a release of Berkeley DB
   including cryptography to your country or re-distribute source code
   from it in any way."

   FullAuto does *NOT* utilize the encrypted features of Berkeley DB, and
   only offers to install the encrypted version as a courtesy. You are
   advised to install the NON-ENCRYPTED version unless you have specific
   reasons for needing the encrypted one.
END

         my %encryted_berkeley=(

            Name => 'encrypted_berkeley',
            Item_1 => {

               Text => "Install NON-ENCRYPTED Berkeley DB".
                       " ( Recommended! )",

            },

            Item_2 => {

               Text => "Install Encrypted Berkeley DB",

            },
            Banner => $encrypted_banner,

         );

         my %berkeleymenu=(

             Name => 'berkeleymenu',
             Item_1 => {

                Text => "Install NON-ENCRYPTED Berkeley DB",

             },
             Item_2 => {

                Text => "Install Encrypted Berkeley DB",
                Result => \%encryted_berkeley,

             },
             Item_3 => {

                Text => "Exit FullAuto Setup",

             },
             Scroll => 1,
             Banner => $berkeleybanner,

         );
         my %berkeley_menu=(

            Name   => 'berkeley_menu',
            Result => \%berkeleymenu,
            Banner => $berkeley_banner,

         );
         my $already_downloaded=0;
         my $filename='';
         unless (grep { /Encrypted/i } @ARGV) {
            unless (keys %main::amazon) { 
               eval {
                  local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                  alarm $timeout;
                  $BDB_selection=Menu(\%berkeley_menu);
                  alarm 0;
               };
               if ($@) {
                  # timed out
                  $BDB_selection='NON-ENCRYPTED';
                  $source=~s/tar.gz/NC.tar.gz/;
               } elsif ($BDB_selection=~/\]quit\[|Exit/s) {
                  print "\n";
                  exit;
               } elsif (-1<index $BDB_selection,'Encrypted') {
                  $BDB_selection='Encrypted';
               } else {
                  $source=~s/tar.gz/NC.tar.gz/;
               } alarm 0;
            } else {
               $BDB_selection='NON-ENCRYPTED';
               $source=~s/tar.gz/NC.tar.gz/;
            }
         } elsif (grep  { /Encrypted/ } @ARGV) {
            $BDB_selection='Encrypted';
            $already_downloaded=1;
            $filename=$ARGV[$#ARGV];
         } else {
            $source=~s/tar.gz/NC.tar.gz/;
            $already_downloaded=1;
            $filename=$ARGV[$#ARGV];
         }
         my $fh='';
         my $suffix=($BDB_selection eq 'Encrypted')?
               '.tar.gz':'.NC.tar.gz';
         unless ($already_downloaded) {
            ($fh,$filename)=get_temp_file($file,$suffix);
            my $end_flag=0;my $md5filename='';
            my %errors = ('500'=>'Bad hostname supplied',
                          '404'=>'URL not found',
                          '403'=>'URL forbidden',
                          '401'=>'Authorization failed',
                          '400'=>'Bad request found',
                          '302'=>'Redirected URL'
            );
            while (1) {
               $req = HTTP::Request->new(GET => $source);
               $req->header('Accept-Encoding' => 'gzip, compress');
               $res = $Ua->request($req);
               my $success=1;
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  print $fh $res->content;
                  close $fh;
               } else {
                  my $status_line=$res->status_line;
                  ($status_line) = ($status_line =~ /(\d+)/);
                  if (defined($errors{$status_line})) {
                     print(
                        "LWP failed with code $status_line, ",
                        "message $errors{$status_line}\n".
                        "Please check your connection to the Internet!\n",
                        $status_line,
                        $res->message,
                     );
                     if (!$end_flag && ($status_line eq '404')) {
                        $source=$last_known_good_location;
                        $end_flag=1;my $rt=qr/b.*?\d.tar.gz/;
                        my $h=qr/http:\/\/$site\//;
                        $source=~s/^.*?($h)(?:otn\/)*($rt).*$/$1$2/s;
                        $file=$2;
                        $file=substr($file,(index $file,'/')+1,-7);
                        $ver=$file;
                        $ver=~s/_.*$//;
                        $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
                        next;
                     }
                  } else {
                     print(
                        "LWP failed with an Unknown Error\n".
                        "Please check your connection to the Internet!\n",
                     );
                  }
                  $success = 0;
                  close $fh;
                  last;
               }
               print(qq{ + saved content to $filename \n})
                  if $CPAN::DEBUG;
               my $md5fh='';
               ($md5fh,$md5filename)=get_temp_file($file,$suffix.'.md5');
               $req = HTTP::Request->new(GET => $source.'.md5');
               $req->header('Accept-Encoding' => 'gzip, compress');
               $res = $Ua->request($req);
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  print $md5fh $res->content;
                  close $md5fh;
               } else {
                  my $status_line=$res->status_line;
                  ($status_line) = ($status_line =~ /(\d+)/);
                  if (defined($errors{$status_line})) {
                     print(
                        "LWP failed with code $status_line, ",
                        "message $errors{$status_line}\n".
                        "Please check your connection to the Internet!\n",
                        $status_line,
                        $res->message,
                     );
                     if (!$end_flag && ($status_line eq '404')) {
                        $source=$last_known_good_location;
                        $end_flag=1;my $rt=qr/b.*?\d.tar.gz/;
                        my $h=qr/http:\/\/$site\//;
                        $source=~s/^.*?($h)(?:otn\/)*($rt).*$/$1$2/s;
                        $file=$2;
                        $file=substr($file,(index $file,'/')+1,-7);
                        $ver=$file;
                        $ver=~s/_.*$//;
                        $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
                        next;
                     }
                  } else {
                     print(
                        "LWP failed with an Unknown Error\n".
                        "Please check your connection to the Internet!\n",
                     );
                  }
                  $success = 0;
                  close $fh;
                  last;
               }
               print(qq{ + saved md5 content to $md5filename \n})
                  if $CPAN::DEBUG;
               open(MH,"<$md5filename") || die $!;
               my $mhf=<MH>;
               close(MH);
               my $checksum=$mhf;
               $checksum=~s/^\s*(\S+)\s+.*$/$1/s;
               open(FILE, $filename) or die "Can't open '$file': $!";
               binmode(FILE);
               require Digest::MD5;
               import Digest::MD5;
               my $digestmd5=Digest::MD5->new->addfile(*FILE)->hexdigest;
               if ($checksum eq $digestmd5) {
                  print(qq{ + CHECKSUM Test for $filename *PASSED* \n})
                     if $CPAN::DEBUG;
               } else {
                  print "CHECKSUM test for $filename *FAILED*\n";
                  print "CALCULATED=$digestmd5 and ",
                        "DOWNLOADED=$checksum\n";
                  print "\nPress ANY key to terminate FullAuto ",
                        "installation ...\n";
                  <STDIN>;
                  die "FATAL ERROR! : ".
                      "CHECKSUM Test for $filename *FAILED*\n";
               }
               close(FILE);
               last;
            }
            if (grep { /-*add[-_]?dependencies/i } @ARGV) {
               Term::ReadKey::ReadMode(0);
               return $filename,$md5filename,$file;
            } else {
               cpan_gunzip_and_untar();
               unless (keys %main::amazon) {
                  my $so=system($CPAN::Config->{gzip}." -d $filename");
                  if ($so==-1) {
                     die "Cannot gunzip $filename: $!\n";
                  }
               }
               $filename=~s/\.gz$//;
            }
         }
         if (keys %main::amazon) {
            unless (exists $main::amazon{'freebsd'}) {
               unless ($already_downloaded) {
                  if (grep { /-*add[-_]?dependencies/i } @ARGV) {
                     exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                          $BDB_selection,$filename;
                  } else {
                     exec 'sudo',$^X,'Makefile.PL',$BDB_selection,
                          $filename;
                  }
               }
               my $so=system($CPAN::Config->{gzip}." -d $filename");
               if ($so==-1) {
                  die "Cannot gunzip $filename: $!\n";
               }
               print "***** Untar1: sudo ",
                  $CPAN::Config->{tar}," xvf $filename\n";
               open(FH, "sudo ".$CPAN::Config->{tar}." xvf $filename|");
            } else {
               unless ($already_downloaded) {
                  if (grep { /-*add[-_]?dependencies/i } @ARGV) {
                     exec 'sudo',$^X,'Makefile.PL','add_dependencies',
                          $BDB_selection,$filename;
                  } else {
                     exec 'sudo',$^X,'Makefile.PL',$BDB_selection,
                          $filename;
                  }
               }
               my $so=system($CPAN::Config->{gzip}." -d $filename");
               if ($so==-1) {
                  die "Cannot gunzip $filename: $!\n";
               }
               print "***** Untar2: ",
                  $CPAN::Config->{tar}," xvf $filename\n";
               open(FH, $CPAN::Config->{tar}." xvf $filename|");
            }
         } else {
            print "***** Untar3: ",
               $CPAN::Config->{tar}," xvf $filename\n";
            open(FH, $CPAN::Config->{tar}." xvf $filename|");
         }
         while (my $line=<FH>) {
            print $line;
         }
         close FH;
         my $uniq='';
         if ($BDB_selection eq 'Encrypted') {
            $filename=~/^.*(......).tar$/;
            $uniq=$1;
            $filename=~s/........tar$//;
            `mv -f $filename ${filename}_$uniq`;
         } else {
            $filename=~/^.*(......).NC.tar$/;
            $uniq=$1;
            $filename=~s/........NC.tar$//;
            `mv -f $filename.NC $filename.NC_$uniq`;
         }
         build_berkeleydb($filename,$uniq,$pre,$PREFIX,$BDB_selection);
      } else {
         if ($res->is_error(500)) {
            print(sprintf(
               "LWP failed with code[%s], message[%s]\n".
               "Please check your connection to the Internet!\n",
               $res->code,
               $res->message,
            ));
         } else {
            print(sprintf(
               "LWP failed with code[%s], message[%s]\n",
               $res->code,
               $res->message,
            ));
         }
      }
   } else {
      $CPAN::Frontend->mywarn("  LWP not available\n");
   }

}

sub build_berkeleydb {

   my $filename=$_[0];
   my $uniq=$_[1];
   my $pre=$_[2]||'';
   my $PREFIX=$_[3]||'';
   my $BDB_selection=$_[4]||'';
   my $args='';
   if ($PREFIX) {
      $args=' --prefix="'.$PREFIX.'"';
   }
   if ($BDB_selection eq 'Encrypted') {
      open(FH,
         "cd ${filename}_$uniq/build_unix;".
         "../dist/configure$args|")
      || warn $!;
   } else {
      open(FH,
         "cd ${filename}.NC_$uniq/build_unix;".
         "../dist/configure$args|")
      || warn $!;
   }
   while (my $line=<FH>) {
      print $line;
   }
   close FH;
   unless ($CPAN::Config->{make}) {
      if (-e '/usr/bin/make') {
         $CPAN::Config->{make}='/usr/bin/make';
      } elsif (-e '/usr/local/bin/make') {
         $CPAN::Config->{make}='/usr/local/bin/make';
      }
   }
   if ($BDB_selection eq 'Encrypted') {
      print "*** Starting Encrypted BerkeleyDB build\n";
      system("(cd ${filename}_$uniq/build_unix;".
            $CPAN::Config->{make}." install) 2>&1")
         || warn $!;
      print "*** Completed Encrypted BerkeleyDB build\n";
   } else {
      print "*** Starting Non-Encrypted BerkeleyDB build\n";
      system("(cd ${filename}.NC_$uniq/build_unix;".
         $CPAN::Config->{make}." install) 2>&1")
         || warn $!;
      print "*** Completed Non-Encrypted BerkeleyDB build\n";
   }
   my $ver=$filename;
   $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
   $berkeleydb=$pre.'/lib';
   $header_to_use=$pre.'/include';
   $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
   $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
   $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
   $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
   $ENV{'DB_FILE_LIB'}=$berkeleydb;
   $ENV{'DB_FILE_NAME'}="-ldb-$ver";
   $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
   $ENV{'LD_RUN_PATH'}=$ENV{'LD_LIBRARY_PATH'};

}

sub get_temp_file {

   my $file=$_[0];
   my $suffix=$_[1];
   my $fh='';
   if ($CPAN::META->has_usable("File::Temp")) {
      $fh = File::Temp->new(
            dir      => cwd(),
            template => "${file}_XXXXXX",
            suffix => $suffix,
            unlink => 0,
           );
      $filename = $fh->filename;
   } else {
      $fh = FileHandle->new;
      $filename = "${file}_${$}$suffix";
   }
   chomp($filename);
   return $fh,$filename;

}

sub cpan_gunzip_and_untar {

   unless ($CPAN::Config->{gzip}) {
      if (-e '/usr/bin/gzip') {
         $CPAN::Config->{gzip}='/usr/bin/gzip';
      } elsif (-e '/usr/local/bin/gzip') {
         $CPAN::Config->{gzip}='/usr/local/bin/gzip';
      } else {
         print "\n\n   Fatal Error!: The 'gzip' utility is".
            " missing.\n".
            "\n\n   Please report any bugs and send any",
            "\n   questions, thoughts or feedback to:",
            "\n\n      Brian.Kelly\@fullautosoftware.net.",
            "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
      }
   }
   unless ($CPAN::Config->{tar}) {
      if (-e '/usr/sfw/bin/gtar') {
         $CPAN::Config->{tar}='/usr/sfw/bin/gtar';
      } elsif (-e '/usr/bin/tar') {
         $CPAN::Config->{tar}='/usr/bin/tar';
      } elsif (-e '/usr/local/bin/tar') {
         $CPAN::Config->{tar}='/usr/local/bin/tar';
      } else {
         print "\n\n   Fatal Error!: The 'tar' utility is".
            " missing.\n".
            "\n\n   Please report any bugs and send any",
            "\n   questions, thoughts or feedback to:",
            "\n\n      Brian.Kelly\@fullautosoftware.net.",
            "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
      }
   }

}

sub find_windows_app {

   # Let's look for Firefox
   my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
               'Mozilla\\Mozilla Firefox" 2>&1';
   $firefox=`$firefox`;
   chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
   $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
   $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
            "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
   open (FF,"$firefox|");
   while (my $line=<FF>) {
      $firefox.=$line;
   }
   close FF;
   chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
   $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
   $firefox=~s/\s*$//s;
   my $fftest=substr($firefox,0,2) if 1<length $firefox;
   $fftest||='';
   my $selection='';
   if ($fftest=~/\w:|\/\w/) {
      $fftest=substr($firefox,0,(rindex $firefox,'\\'));
   } else {
      $fftest='';
   }
   if (-1<index $firefox,'unable to find') {
      unless ($main::install_firefox_without_asking) {
         # Ask if we should install
         my $one="YES - Install Mozilla Firefox & MozRepl\n\n";
         my %_askfirefox=(

            Label => '_askfirefox',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => [ $one,
                                       'NO  - DO *NOT* INSTALL Firefox' ],
                       },
            Banner=> "   Mozilla Firefox has an available add-on called ".
                     "MozRepl.\n\n   With Firefox equipped with MozRepl, ".
                     "FullAuto can do\n   extremely powerful WEB ".
                     "Automation!\n\n   Would you like the FullAuto ".
                     "installer to install Firefox\n   and MozRepl?\n",
         );
         $selection=Term::Menus::Menu(\%_askfirefox);
         chomp($selection);
         $selection='Install_Mozilla_Firefox'
            if -1<index $selection,'Install Mozilla Firefox';
         $selection='DO_NOT_INSTALL'
            if -1<index $selection,'*NOT* INSTALL';
         exit if $selection eq ']quit[';
      } else { $selection='Install_Mozilla_Firefox' }
      $main::install_firefox=$selection;
   } else { # Look for MozRepl
      my $up=$ENV{'USERPROFILE'};
      if (-1<index $up,'Documents') {
         $up.="\\Application Data\\Mozilla\\Firefox\\Profiles\\";
      } else {
         $up.="\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles\\";
      }
      my @dirs=();
      if (-e $up) {
         opendir(DIR,$up);
         @dirs = readdir(DIR);
         closedir(DIR);
      }
      if (-1<$#dirs) {
         foreach my $profile (@dirs) {
            opendir(DIR,$up."\\$profile\\extensions");
            my @files = readdir(DIR);
            closedir(DIR);
            foreach my $file (@files) {
               if (-1<index $file,'mozrepl') {
                  return 0;
               }
            }
         }
      }
      unless ($main::install_firefox_without_asking) {
         # Ask if we should install
         my $one="YES - Install MozRepl Plugin for Firefox\n\n";
         my %_askfirefox=(

            Label => '_askfirefox',
            Item_1 =>  {
                           Text   => "]C[",
                           Convey => [ $one,'NO  - DO *NOT* INSTALL MozRepl' ],
                        },
            Banner=> "   Mozilla Firefox has an available add-on ".
                     "called MozRepl.\n\n   With Firefox equipped ".
                     "with MozRepl, FullAuto can do\n   extremely ".
                     "powerful WEB Automation!\n\n   Would you ".
                     "like the FullAuto installer to install ".
                     "the\n   MozRepl plugin?\n",
         );
         $selection=Term::Menus::Menu(\%_askfirefox);
         chomp($selection);
         $selection='Install_MozRepl'
            if -1<index $selection,'Install MozRepl Plugin';
         $selection='DO_NOT_INSTALL'
            if -1<index $selection,'*NOT* INSTALL';
         exit if $selection eq ']quit[';
      } else { $selection='Install_MozRepl' }
      $main::install_firefox=$selection;
   }
}

sub install_firefox {

   my $Ua;
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
   if ($CPAN::META->has_usable('LWP')) {
      FA::LWP::UserAgent->config;
      eval { $Ua = FA::LWP::UserAgent->new(
             timeout=>300,show_progress=>1) };
      if ($@) {
         $CPAN::Frontend->mywarn(
         "ERROR: FA::LWP::UserAgent->new dies with $@\n");
      } else {
         my($var);
         $Ua->proxy('http', $var)
            if $var = $CPAN::Config->{http_proxy} ||
            $ENV{http_proxy};
         $Ua->no_proxy($var)
            if $var = $CPAN::Config->{no_proxy} || $ENV{no_proxy};
      }
      $Ua->ssl_opts( SSL_verify_mode => 'SSL_VERIFY_NONE' );
   } else {
      die "Unable to install Firefox due to no LWP availability";
   }
   my $fftest='';
   unless ($main::install_firefox eq 'Install_MozRepl') {
      my $url='http://www.mozilla.org/en-US/firefox/all/';
      print "Fetching with LWP:\n  $url\n";
      my $req = HTTP::Request->new(GET => $url);
      $req->header('Accept' => 'text/html');
      my $res = $Ua->request($req);
      my $href='';
      if ($res->is_success) {
         print " + request successful.\n"
            if $CPAN::DEBUG;
         my $count=0;
         my $content = $res->decoded_content();
         if (utf8::is_utf8($content)) {
            binmode STDOUT,':utf8';
         } else {
            binmode STDOUT,':raw';
         }
         foreach my $line (split "\n", $content) {
            if ((-1<index $line, 'english (us) english (us)') ||
                  ((0<$count) && ($count<5))) {
               if ($count==3) {
                  $href=$line;
                  last;
               }
               $count++;
            }
         }
      }
      $href=~s/^.*href=["](.*?)["].*$/$1/;
      $href=~s/https/http/;
      $href=~s/&amp;/&/g;
      my $exe_name=substr($href,(rindex $href,'/'));
      $exe_name=~s/^.*?product=(.*?)[&].*$/$1/;
      $exe_name=~s/firefox-/Firefox Setup /;
      $req = HTTP::Request->new(GET => $href);
      $req->header('Accept' => 'text/html');
      $res = $Ua->request($req);
      if ($res->is_success) {
         print " + request successful.\n"
         if $CPAN::DEBUG;
         mkpath($main::root_dir,1) unless -d $main::root_dir;
         unless (-w $main::root_dir) {
            print "\n\n   Fatal Error! - The current Cygwin directory: ".
                  "\n\n      ".$main::root_dir."\n\n".
                  "   is not writable. Please change the permissions\n".
                  "   to writable before installing FullAuto.\n";
            print "\n   PRESS ANY KEY TO EXIT SETUP\n\n";
            <STDIN>;
            exit 1;
         }
         open(CP,">$main::root_dir/${exe_name}.exe") || die $!;
         binmode(CP);
         print CP $res->content;
         close CP;
         if ($^O eq 'cygwin') {
            `/usr/bin/chmod 777 \"$main::root_dir/${exe_name}.exe\"`;
         } else {
            my $cygwin_loc=get_cygwin_location();
            system('SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_loc\\bin\\bash -lc ".
                "/usr/bin/chmod 777 \"$main::root_dir/${exe_name}.exe\"");
         }
         `"$main::root_dir/${exe_name}.exe" -ms`;
         # Let's look for Firefox
         my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                     'Mozilla\\Mozilla Firefox" 2>&1';
         $firefox=`$firefox`;
         chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
         $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
         $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                  "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
         open (FF,"$firefox|");
         while (my $line=<FF>) {
            $firefox.=$line;
         }
         close FF;
         chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
         $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
         $firefox=~s/\s*$//s;
         $fftest=substr($firefox,0,2) if 1<length $firefox;
         $fftest||='';
         my $selection='';
         if ($fftest=~/\w:|\/\w/) {
            $fftest=substr($firefox,0,(rindex $firefox,'\\'));
         } else {
            $fftest='';
         }
      }
   } else {
      # Let's look for Firefox
      my $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
                  'Mozilla\\Mozilla Firefox" 2>&1';
      $firefox=`$firefox`;
      chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
      $firefox=~s/^.*CurrentVersion\s*REG_SZ\s*(.*?)\n.*$/$1/s;
      $firefox='REG QUERY "HKEY_LOCAL_MACHINE\\SOFTWARE\\'.
               "Mozilla\\Mozilla Firefox\\$firefox\\Main\" 2>&1";
      open (FF,"$firefox|");
      while (my $line=<FF>) {
         $firefox.=$line;
      }
      close FF;
      chomp($firefox=~tr/\0-\11\13-\37\177-\377//d);
      $firefox=~s/^.*Path(?:To)*Exe\s*REG_SZ\s*(.*\.exe).*$/$1/s;
      $firefox=~s/\s*$//s;
      $fftest=substr($firefox,0,2) if 1<length $firefox;
      $fftest||='';
      my $selection='';
      if ($fftest=~/\w:|\/\w/) {
         $fftest=substr($firefox,0,(rindex $firefox,'\\'));
      } else {
         $fftest='';
      }
   }
   my $url='https://addons.mozilla.org/firefox/downloads/file/'.
        "138898/$main::mozrepl_file?src=dp-btn-primary";
   my $req = HTTP::Request->new(GET => $url);
   $req->header('Accept' => 'text/html');
   my $res = $Ua->request($req);
   my $href='';
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   my $mz="$clo\\$main::mozrepl_file";
   if ($res->is_success) {
      print " + request successful.\n"
         if $CPAN::DEBUG;
      open(CP,">$mz") || die $!;
      binmode(CP);
      print CP $res->content;
      close CP;
      my $ff=$fftest.'\\firefox';
      my $mP=$main::PARdir;
      if ($^O eq 'cygwin') {
         $mz=~s/\\/\\\\/g;
         my $chmod_out=
               `chmod -v 777 \"$mP/bin/install_mozrepl_plugin\" 2>&1`;
         print "CYGCHMOD=$chmod_out\n" if $chmod_out;
         print "MOZREPL COMMAND=\"$mP/bin/install_mozrepl_plugin\" ".
               "\"$ff\" \"$mz\" 2>&1\n";
         my $output=
               `\"$mP/bin/install_mozrepl_plugin\" \"$ff\" \"$mz\" 2>&1`;
         print "CYGOUTPUT=$output\n" if $output;
      } else {
         my $output=
               `\"$mP\\bin\\install_mozrepl_plugin\" \"$ff\" \"$mz\" 2>&1`;
         print "WINOUTPUT=$output\n" if $output;
      }
   }
}

sub remove_sshd {
   my $sshd_account=$_[0];
   my $cygwin_loc=get_cygwin_location();
   my $clo=$cygwin_loc;
   $clo=~s/\\/\\\\/g;
   if (-e $cygwin_loc) {
      if ($^O eq 'cygwin') {
         my $srvcmd='export CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv --verbose --query sshd"';
         my $cygout=`$srvcmd 2>&1`;
         if ($cygout=~/^Account\s+: .\\$sshd_account$/m) {
            my $srvcmd='export CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv --remove sshd"';
            my $cygout=`$srvcmd 2>&1`;
         } elsif (-1==index $cygout,'service does not exist') {
            return 0;
         }
      } else {
         my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv --verbose --query sshd"';
         my $cygout=`$srvcmd 2>&1`;
         if ($cygout=~/^Account\s+: .\\$sshd_account$/m) {
            my $srvcmd='SET CYGWIN=nodosfilewarning & '.
                       "cmd /c $clo\\\\bin\\\\bash -lc ".
                       '"/usr/bin/cygrunsrv --remove sshd"';
            my $cygout=`$srvcmd 2>&1`;
         } elsif (-1==index $cygout,'service does not exist') {
            return 0;
         }
      }
      my $remove_out=`net user /delete sshd 2>&1`;
      if (-e "$cygwin_loc\\etc\\passwd") {
         do {
            local $^I='.bak'; # see perlvar(1)
            local @ARGV=("$cygwin_loc\\etc\\passwd");
            while(<>){
               s/^$sshd_account:.*\s*$//;
               s/^sshd:.*\s*$//;
               print;
            }
         };
      }
   }
   return 1;
}

sub test_windows_user_rights {

   my $user=$_[0];

   # Is Cygwin installed?
   my $cygwin_location=get_cygwin_location();

   # Adjust memory quotas for a process             (SeIncreaseQuotaPrivilege)
   # Create a token object                          (SeCreateTokenPrivilege)
   # Log on as a service                            (SeServiceLogonRight)
   # Replace a process level token
   #                                           (SeAssignPrimaryTokenPrivilege)

   # Act as part of the operating system            (SeTcbPrivilege)

   # >  And for security.....

   # Deny log on locally                         (SeDenyInteractiveLogonRight)
   # Deny access to this computer from the network   (SeDenyNetworkLogonRight)
   # Deny log on through Terminal Services
   #                                       (SeDenyRemoteInteractiveLogonRight)

   my $rights=`$cygwin_location\\bin\\editrights -u $user -l`;
   my $output='';
   if ((-1==index $rights,'SeServiceLogonRight') ||
         (-1==index $rights,'SeTcbPrivilege') ||
         (-1==index $rights,'SeCreateTokenPrivilege') ||
         (-1==index $rights,'SeAssignPrimaryTokenPrivilege') || 1) {
      my $die='DYING';
      my @missing_rights=();
      if (-1==index $rights,'SeTcbPrivilege') {
         unless ($output=
               `/bin/editrights -a SeTcbPrivilege -u $user`) {
            push @missing_rights, 'SeTcbPrivilege';
         }
      }
      if (-1==index $rights,'SeCreateTokenPrivilege') {
         my $prv='SeCreateTokenPrivilege';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeCreateTokenPrivilege';
         }
      }
      if (-1==index $rights,'SeAssignPrimaryTokenPrivilege') {
         my $prv='SeAssignPrimaryTokenPrivilege';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeAssignPrimaryTokenPrivilege';
         }
      }
      if (-1==index $rights,'SeServiceLogonRight') {
         my $prv='SeServiceLogonRight';
         unless (`/bin/editrights -a $prv -u $user`) {
            push @missing_rights, 'SeServiceLogonRight';
         }
      }
      if (-1<$#missing_rights) {
         my $mis=join "\n",map { "               $_" } @missing_rights;
         my $die="   Fatal Error! - The following priviliges are\n   ".
                 "               missing from the ID '".$user."':\n\n".
                 $mis."\n\n   An attempt was made to add these rights,\n".
                 "   but was not successul. Please contact your\n".
                 "   your Domain and Server Administrators for\n".
                 "   assistance.\n\n   PRESS ANY KEY to EXIT FullAuto".
                 " Setup.\n\n";
         print $die;<STDIN>;
         exit 1;
      }
      my $gpout=`gpupdate 2>&1`;
      if (-1<index $gpout,'completed successfully') {
         @missing_rights=();
         if (-1==index $rights,'SeTcbPrivilege') {
            push @missing_rights, 'SeTcbPrivilege';
         }
         if (-1==index $rights,'SeCreateTokenPrivilege') {
            push @missing_rights, 'SeCreateTokenPrivilege';
         }
         if (-1==index $rights,'SeAssignPrimaryTokenPrivilege') {
            push @missing_rights, 'SeAssignPrimaryTokenPrivilege';
         }
         if (-1==index $rights,'SeServiceLogonRight') {
            push @missing_rights, 'SeServiceLogonRight';
         }
         if (-1<$#missing_rights) {
            my $mis=join "\n",map { "               $_" } @missing_rights;
            my $die="   Fatal Error! - The following priviliges were\n".
                    "                  added to the ID '".$user."':\n\n".
                    $mis."\n\n   However, these priviliges were\n".
                    "   subsequently removed by a Domain Global\n".
                    "   Policy Update. Please contact your Windows\n".
                    "   Domain and Server Administrators to have the\n".
                    "   Global Domain Policy changed for this ID.\n\n".
                    "   PRESS ANY KEY to EXIT FullAuto".
                    " Setup.\n\n";
            print $die;<STDIN>;
            exit 1;
         }
      }
   }
}

sub test_windows_user {
   my $sshd_account=$_[0];
   my $test_user=`net user $sshd_account 2>&1`;
   if (-1<index $test_user,'not be found') {
      my $return=&remove_sshd($sshd_account); 
      return 1;
   }
   # Is Cygwin installed?
   my $cygwin_location=get_cygwin_location();

   # Adjust memory quotas for a process             (SeIncreaseQuotaPrivilege)
   # Create a token object                          (SeCreateTokenPrivilege)
   # Log on as a service                            (SeServiceLogonRight)
   # Replace a process level token
   #                                           (SeAssignPrimaryTokenPrivilege)

   # Act as part of the operating system            (SeTcbPrivilege)

   # > 	And for security.....

   # Deny log on locally                         (SeDenyInteractiveLogonRight)
   # Deny access to this computer from the network   (SeDenyNetworkLogonRight)
   # Deny log on through Terminal Services 
   #                                       (SeDenyRemoteInteractiveLogonRight)

   if ($cygwin_location) {
      my $rights=`$cygwin_location\\bin\\editrights -u $sshd_account -l`;
      print "RIGHTS for $sshd_account ======>\n$rights\n<=======\n";
      if ((-1==index $rights,'SeServiceLogonRight') || 
            ((-1==index $rights,'SeDenyRemoteInteractiveLogonRight') &&
            (-1==index $rights,'SeDenyInteractiveLogonRight'))) {
         print "\n\n   FullAuto Install has determined that the current",
               "\n   \"$sshd_account\" user ID, lacks sufficient privileges",
               "\n   to act as the sshd service ID.",
               "\n\n      The needed privileges are:",
               "\n\n         SeServiceLogonRight  SeCreateTokenPrivilege",
               "\n         SeDenyInteractiveLogonRight  SeTcbPrivilege",
               "\n         SeAssignPrimaryTokenPrivilege",
               "\n\n   Use:  /bin/editrights -u $sshd_account -l",
               "\n\n   to manually inspect these privileges.",
               "\n\n   Some corporate environments enforce strict group",
               "\n   rights from the Domain Controller, and these",
               "\n   privileges may be surreptiously removed from the",
               "\n   $sshd_account account without notice. Check with your",
               "\n   Microsoft Infrastructure Admins if you suspect this",
               "\n   may be a possibility with your setup. You will need",
               "\n   to get an exception added to their configuration.\n\n";
         print "   Press ANY key to continue . . . ";<STDIN>;
         my $remove_out=`net user /delete cyg_server 2>&1`;
         if (-1<index $remove_out,"command completed successfully") {
            my $return=&remove_sshd($sshd_account);
            return $return;
         } else {
            print "\n      FullAuto Install attempted to remove the ID ",
                  "before",
                  "\n   trying a re-install but was unsuccessful:",
                  "\n\n   $remove_out",
                  "\n\n   Please remedy the situtation before trying FullAuto",
                  "\n     Install again.",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
         }
      }
      unless (-e "$cygwin_location\\var\\empty") {
         my $remove_out=`net user /delete $sshd_account 2>&1`;
         if (-1<index $remove_out,"command completed successfully") {
            my $return=&remove_sshd($sshd_account);
            return $return;
         } else {
            print "\n\n   FullAuto Install has determined that the.",
                  "\n   current sshd service setup was not completed",
                  "\n   correctly with the user ID \"cyg_server\":",
                  "\n\n      The directory: $cygwin_location\\var\\empty",
                  "\n\n      does NOT exist.", 
                  "\n\n      FullAuto Install attempted to remove",
                  "\n   the ID before trying a re-install but",
                  "\n   was unsuccessful:\n\n   $remove_out.\n\n",
                  "\n\n   Please remedy the situtation before trying.",
                  "\n   FullAuto Install again.",
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit 1;
         }
      }
      return 0;
   } else {
      return 0;
   }
}

sub windows_ver {
   # Thanks - http://ss64.org/viewtopic.php?id=879
   # and    - http://en.wikipedia.org/wiki/Ver_(command)
   my $output=`cmd /c ver`;
   if (-1<index $output,'4.0.950') {
      return 'Windows 95';
   } elsif (-1<index $output,'4.0.950') {
      return 'Windows 98';
   } elsif (-1<index $output,'4.10.2222') {
      return 'Windows 98 SE';
   } elsif (-1<index $output,'4.90.3000') {
      return 'Windows ME';
   } elsif (-1<index $output,'NT') {
      return 'Windows NT';
   } elsif (-1<index $output,'5.0.2195') {
      return 'Windows 2000';
   } elsif (-1<index $output,'5.1.2600') {
      return 'Windows XP';
   } elsif (-1<index $output,'5.2.3790') {
      return 'Windows Server 2003';
   } elsif (-1<index $output,'5.2.4500') {
      return 'Windows Home Server'; # aka Windows XP 64-Bit Edition
   } elsif (-1<index $output,'6.0.6001') {
      return 'Windows Vista';
   } elsif (-1<index $output,'6.0.6002') {
      return 'Windows Server 2008';
   } elsif (-1<index $output,'6.1.7600') {
      return 'Windows Server 2008 R2'
   } elsif (-1<index $output,'6.1.7601') {
      return 'Windows 7 SP1';
   } else {
      $output=~s/\s*\[.*$//s;
      return $output;
   }
}

if ($^O eq 'cygwin' && &windows_ver=~/XP|2000|NT/) {
   my $regc='regtool -v check "/HKLM/Software/Microsoft/'.
            'Windows/CurrentVersion/Explorer/AlwaysUnloadDLL" 2>&1';
   my $outp=`$regc`;
   my $notthere=0;
   if ($outp=~/key\s+exists/s) {
      my $regc='regtool -v list "/HKLM/Software/Microsoft/'.
            'Windows/CurrentVersion/Explorer/AlwaysUnloadDLL" 2>&1';
      my $outp=`$regc`;
      if ($outp!~/\(REG_SZ\) = \"1\"/) {
         $notthere=1; 
      }
   } else { $notthere=1 }
   if ($notthere) {
      eval {
         my $timeout=120;
         local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
         alarm $timeout;
         print "\n       *** THIS SCREEN WILL TIMEOUT IN 2 MINUTES ***\n".
               "\n       IMPORTANT! : FullAuto is VERY Memory Intensive.".
               "\n                  Setup has detected that a recommended".
               "\n                  Windows XP registry setting does NOT".
               "\n                  exist. As a result, Windows XP does".
               "\n                  not remove DLL's from memory when an".
               "\n                  an application exits, but keeps them".
               "\n                  in memory for a time in order to speed".
               "\n                  up application startup *in case* the".
               "\n                  the app is restarted. Cygwin and ssh".
               "\n                  load DLLs and with repeated invocation".
               "\n                  (which is common FullAuto usage),".
               "\n                  memory can 'max' out and cause all".
               "\n                  active FullAuto and Cygwin processes".
               "\n                  to freeze and hang.".
               "\n\n       Therefore, it is *HIGHLY* recommended that this".
               "\n       registry setting exist:\n".
               "\n       /HKLM/Software/Microsoft/Windows/CurrentVersion/".
               "Explorer/AlwaysUnload DLL\n".
               "\n       FullAuto setup can do this for you, but only with".
               "\n       your approval. Would you like FullAuto setup to".
               "\n       attempt to insert this registry setting?".
               "\n\n       (If you do not wish FullAuto setup to".
               "\n       perform this step, type 'N' and setup will".
               "\n       continue WITHOUT modifying the Windows registry.)".
               "\n\n";
         print "Type <Y> if you wish to FullAuto setup to modify ",
               "the registry,\nor 'N' to proceed without this step ",
               ". . . [N] ";
         $a=<STDIN>;
         alarm 0;
      };
      if ($@) {
         # timed out
         # exit;
      } elsif ($a=~/^[Yy]$/s) {
         $regc='cmd /c "REG ADD HKLM\\Software\\Microsoft\\Windows\\'.
               'CurrentVersion\\Explorer\\AlwaysUnloadDLL '.
               '/ve /t REG_SZ /d 1" 2>&1';
         $outp=`$regc`;
         print $outp."\n";
      } alarm 0;

   }
}

#Specific dependencies
requires        'Cache::Cache'              => 0;
requires        'CHI'                       => 0;

auto_install();

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
      local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      my $menu1 = [
                  $banner,
                  [ "Yes", sub{ return 'Yes' } ],
                  [ "No   (FullAuto install will exit)", sub{ return 'No' } ],
                  #[ "Quit", sub {exit;} ],
                  ];
      $selection=&menu($menu1);
      exit if $selection eq ']quit[';
      alarm 0;
   };
   if ($@) {
      # timed out
      $selection = 'No';
   }
   if ($selection=~/No/) {
      exit;
   } alarm 0;
}

print "$main::curdir\n";
chdir $main::curdir;

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
"main(int argc, char *argv[])\n".
'{'."\n".
"\tsetuid(0);\n".
"\tseteuid(0);\n".
"\texecv(REAL_PL, argv);\n".
'}'."\n";

close FH;

my $timeout=120;my $selection='';
if (keys %main::amazon) {
   $selection='Install with Setuid Permissions (Recommended Default)';
} elsif (!exists $ENV{FA_BERKELEY}) {
   eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      my @list=();
      my %perms_menu=();
      unless ($^O eq 'cygwin') {
         @list=('Install with Setuid Permissions (Recommended Default)',
                'Install with Setgid Permissions',
                'Install with Owner Group Permissions',
                'Install with Full Access Permissions');
         my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE ".
               "\'Setuid\' IN 2 MINUTES ***\n".
               "\n   Choose a Permission Setting :\n\n";
         %perms_menu=(

            Name => 'perms_menu',
            Item_1 => {

               Text => ']C[',
               Convey => \@list,

            },
            Scroll => 1,
            Banner => $banner,

         ); 
      } else {
         @list=('Install with Full Access Permissions (Default)',
                'Install with Owner Group Permissions');
         my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE ".
               "\'Full-Access\' IN 2 MINUTES ***\n".
               "\n   Choose a Permission Setting :\n\n";
         %perms_menu=(

            Name => 'perms_menu',
            Item_1 => {

               Text => ']C[',
               Convey => \@list,

            },
            Scroll => 1,
            Banner => $banner,

         );
      }
      $selection=Term::Menus::Menu(\%perms_menu);
      alarm 0;
   };
   exit if $selection eq ']quit[';
   if ($@) {
      # timed out
      print "\n";
      $selection = 'Setuid';
      Term::ReadKey::ReadMode(0);
   } alarm 0;
} elsif (-1<index $ENV{FA_BERKELEY},'Owner Group') {
   $selection='Install with Owner Group Permissions';
} elsif (-1<index $ENV{FA_BERKELEY},'Full Access') {
   $selection='Install with Full Access Permissions (Default)';
}

my $permission = 'Setuid';
if (-1<index $selection,'Setuid') {
   $permission = 'Setuid';
} elsif (-1<index $selection,'Setgid') {
   $permission = 'Setgid';
} elsif (-1<index $selection,'Owner Group') {
   $permission = 'Owner-Group';
   $main::cygwin_berkeley_db_mode=770 if $^O eq 'cygwin';
} elsif (-1<index $selection,'Full Access') {
   $permission = 'Full-Access';
   $main::cygwin_berkeley_db_mode=777  if $^O eq 'cygwin';
} elsif (-1<index $selection,'quit') {
   exit;
} print "\n";

if ($^O eq 'cygwin') {
   open(FH,">bin/fullauto.exe");
   print FH "\n";
   close FH;
   install_script('bin/fullauto.exe');
   install_script('bin/install_mozrepl_plugin.exe');
   unlink "bin/fullauto.exe";
   &install_firefox() if -1<index $main::install_firefox,'Install';
} else {
   open(FH,">bin/fullauto");
   print FH "\n";
   close FH;
   install_script('bin/fullauto');
   unlink "bin/fullauto";
}
install_script('bin/fullauto.pl');

my $good_choice=<<'END';

     ___               _     ___ _        _        _ 
    / __| ___  ___  __| |   / __| |_  ___(_)__ ___| |
   | (_ |/ _ \/ _ \/ _` |  | (__| ' \/ _ \ / _/ -_)_|
    \___|\___/\___/\__,_|   \___|_||_\___/_\__\___(_)


   The Nano Editor is widely considered to be the easiest Terminal Editor to
   learn. Here are a couple of important things to remember. When you look at
   at the bottom of the screen, you will see character combinations like this:

   ^E ^W ^O  -->  the caret symbol (for Ctrl key) followed by a letter.

   Ctrl key is pressed with letter next to it. For example, to exit Nano (^E)
    ________     ____                    _______     ____ 
   || Ctrl ||   ||E ||                  || Alt ||   ||C ||
   ||______|| + ||__||  M-C  is  alt c  ||_____|| + ||__||
   |/______\|   |/__\|                  |/_____\|   |/__\|

END

my $nano_banner=<<END;

   .e.f8 ee.     88**8.  e888 88**8. .d88b.   GNU
   i '8f'  Q,    88  88 88 88 88  88 88  88
      8.   8:    88  88 "t888 88  88 "t88P"   Text Editor
      8.   8:
      W.   8:    In Terminal Environments, Documentation
           8:    for Nano can be seen anytime by typing:
           8:    
           tD    man nano    at the command line.


   You can also see online documentation at:

   http://www.nano-editor.org/docs.php
END

my $learn_nano=sub {

   my %learn_nano=(

      Name => 'learn_nano',
      Item_1 => {

         Text => "Go to Nano man page (type q to return)",
         Result => sub { system('man nano');return '<' },

      },
      Item_2 => {

         Text   => "Launch and explore Nano (type ctrl + e to return)",
         Result => sub { system('nano');return '<' },

      },
      Item_3 => {

         Text => "Continue Installing FullAuto",

      },
      Scroll => 3,
      Banner => $nano_banner,

   );
   return \%learn_nano;

};

my $goodchoice=sub {

   my %goodchoice=(

      Name => 'goodchoice',
      Item_1 => {

         Text   => "Learn more about Nano",
         Result => $learn_nano, 

      },
      Item_2 => {

         Text   => "Continue Installing FullAuto",

      },
      Scroll => 2,
      Banner => $good_choice,

   );
   return \%goodchoice;

};

sub fa_license {

   use if ($^O eq 'linux' || $^O eq 'freebsd'), "Term::Menus";

   my %read_license=(

      Name => 'read_license',
      Item_1 => {
         Text => "I accept the license provisions",
      },
      Item_2 => {
         Text => "I do *NOT* accept the license provisions ".
                 "(Install will Exit)",
      },
      Item_3 => {
         Text => "Review GNU Affero Public License Version 3\n".
                 "                   in its entirety".
                 " (type 'q' to return)",
         Result => sub { system('less LICENSE');return '<' },
      },
      Item_4 => {
         Text => "Return to previous screen",
         Result => sub { return '{license_agree}<' },
      },
      Scroll => 1,
      Banner => sub {
            my $linenumber="]P[";
            open (FH,"<LICENSE")
               or die "Cannot open LICENSE: $!\n";
            my @content=<FH>;
            close FH;
            my $co=$#content+1;
            my $endcount=(13<$co)?13:$co;
            if (-1==index $linenumber,'Review') {
               if ($linenumber=~/Next|Previous/) {
                  $linenumber=~s/^(?:Next|Previous) Page\s*//;
                }
               ($linenumber,$endcount)=split '-', $linenumber;
               my $tl=$#content+1;
               my $lt=$linenumber+13;
               $endcount=($lt<$tl)?$lt:$tl;
            } elsif (-1<index $linenumber,'WARRANTY') {
               $linenumber=588;
               $endcount=597;
            } else { $linenumber=1 }
            $linenumber=0 if $linenumber==1;
            --$endcount;
            my $banner=join "", @content[$linenumber..$endcount];
            $banner=~s/^/   /mg;
            return $banner;
         }

   );

   my $cryptography_banner=<<'END';
   __      __             _           _ 
   \ \    / /_ _ _ _ _ _ (_)_ _  __ _| |
    \ \/\/ / _` | '_| ' \| | ' \/ _` |_|
     \_/\_/\__,_|_| |_||_|_|_||_\__, (_)
                                |___/  

   Exporting, importing and/or using cryptography software, or even
   communicating technical details about cryptography software, is illegal
   in some parts of the world. You are strongly advised to investigate and
   adhere to any export/import and use laws which apply to you when you
   import a release of Net::FullAuto including cryptography modules like
   Crypt::CBC, Crypt::DES and Crypt::Rijndael to your country or
   re-distribute source code from them in any way.
END

   my $cryptography=sub {

      my %cryptography=(

         Name => 'cryptography',
         Result => sub { return '{license_agree}<' },
         Banner => $cryptography_banner,      

      );
      return \%cryptography

   };

   my $license_banner=<<END;

   *THANK YOU* For Trying FullAuto!   Net::FullAuto INSTALLATION PROGRAM

   Copyright (C) 2000-2014   Brian M. Kelly   Brian.Kelly\@fullautosoftware.net

   This program comes with ABSOLUTELY NO WARRANTY; for details select 2.
   This is free software, and you are welcome to redistribute it under certain
   conditions. Select 2 for full license. FullAuto uses  Crypt::DES  which is
   software developed by Systemics Ltd (http://www.systemics.com/). FullAuto
   uses the  Net::SSLeay  module which is software developed by the OpenSSL
   Project for use in the OpenSSL Toolkit. (http://www.openssl.org/) and
   includes cryptographic software written by Eric Young (eay\@cryptsoft.com)
   and Tim Hudson (tjh\@cryptsoft.com)

END

   my %license_agree=(

      Name => 'license_agree',
      Item_1 => {

         Text => "I agree to the license provisions\n\n",

      },
      Item_2 => {

         Text => "Review GNU Affero Public License WARRANTY DISCLAIMER\n",
         Result => \%read_license,
      },
      Item_3 => {

         Text => "*IMPORTANT* STRONG CRYPTOGRAPHY WARNING!",
         Result => $cryptography,

      },
      Item_4 => {

         Text => "I DO NOT AGREE to the license provisions\n".
                 "                   ( FullAuto Install will EXIT )",
      },
      Scroll => 1,
      Banner => $license_banner,

   );
   my $lic_sel=Menu(\%license_agree);
   chomp($lic_sel);
   exit if $lic_sel eq ']quit[';
   if (-1<index $lic_sel, 'NOT') {
      print "\n\n   You have elected *NOT* to install FullAuto.",
            "\n\n   Please report any bugs and send any",
            "\n   questions, thoughts or feedback to:",
            "\n\n      Brian.Kelly\@fullautosoftware.net.",
            "\n\n   Press ANY key to exit.\n\n";<STDIN>;
      exit;
   }

}

if (keys %main::amazon) {
   fa_license();
   my @editors=('vim     ( ViIMproved - enhanced vi editor )',
                "emacs   ( The extensible, customizable, ".
                "self-documenting\n           ".
                "               real-time display editor )",
                "joe     ( Fast and simple editor that emulates".
                "\n             ".
                '             5 other editors )',
               );
   my $banner=<<'END';
    ___      _        _      ___    _ _ _
   / __| ___| |___ __| |_   | __|__| (_) |_ ___ _ _
   \__ \/ -_) / -_) _|  _|  | _|/ _` | |  _/ _ \ '_|
   |___/\___|_\___\__|\__|  |___\__,_|_|\__\___/_|

   In order to use the integrated edit features you will need to choose
   an editor. You can later change the selection in the Admin menu.

END

   my %Menu_select_editor=();
   %Menu_select_editor=(

         Label  => 'Menu_select_editor',
         Item_1 => {
            Text    => "nano    ( Easiest - Recommended for Beginners )",
            Result  => $goodchoice,
         },
         Item_2 => {

            Text    => "]C[",
            Convey  => \@editors,

         },
         Scroll => 1,
         Banner => $banner,

   );
   my $selection=Term::Menus::Menu(\%Menu_select_editor);
   exit if $selection eq ']quit[';
   $editor='nano';
   if ($selection=~/joe/) {
      open(AG,"sudo apt-get -y install 'joe'|");
      while (my $line=<AG>) {
         print $line;
      }
      close AG;
      $editor='joe';
   } elsif ($selection=~/emacs/) {
      open(AG,"sudo apt-get -y install 'e3'|");
      while (my $line=<AG>) {
         print $line;
      }
      close AG;
      $editor='emacs';
   } elsif ($selection=~/vim/) {
      $editor='vi';
   }

}

WriteAll();

if (keys %main::amazon) {
   my $meminfo=`cat /proc/meminfo`;
   my $memtotal=$meminfo;
   my $memfree=$meminfo;
   $memtotal=~s/^.*MemTotal:\s*(\d+) kB.*$/$1/s;
   $memfree=~s/^.*MemFree:\s*(\d+) kB.*$/$1/s;
   if ($memfree<1000000) {

my $almost_there=<<'END';

       ___    __                     __     ________                   __
      /   |  / /___ ___  ____  _____/ /_   /_  __/ /_  ___  ________  / /
     / /| | / / __ `__ \/ __ \/ ___/ __/    / / / __ \/ _ \/ ___/ _ \/ / 
    / ___ |/ / / / / / / /_/ (__  ) /_     / / / / / /  __/ /  /  __/_/  
   /_/  |_/_/_/ /_/ /_/\____/____/\__/    /_/ /_/ /_/\___/_/   \___(_)   

   Normally, FullAuto is installed via the CPAN utility - but because of
   memory limits, you were instructed to setup via Makefile.PL. As a
   courtesy to advanced users, FullAuto setup offers the option to exit here.
END

      my %finish_setup=(

         Name => 'finish_setup',
         Item_1 => {

            Text => "Complete *ALL* FullAuto setup\n             ".
                    "            ( HIGHLY recommended for Beginners! )\n\n",

         },
         Item_2 => {

            Text => "Exit Makefile.PL ('make' must be run separately)",

         },
         Scroll => 1,
         Banner => $almost_there,

      );
      #my $selection=Menu(\%finish_setup);
      #if (-1<index $selection, 'Complete') {
         system('sudo make install');
         if (-1==$ENV{PATH},'/usr/local/bin') {

my $banner=<<END;
                         _     
   | | _  _| _ _|_ _    |_) _ _|_|_
   |_||_)(_|(_| |_(/_   |  (_| |_| |
      |

END

         }
         exec "/usr/local/bin/fa";
      #}
   }

}

sub fa_find_editor {
   my $editor=$_[0];
   $editor=~s/^.*\///;
   $editor=~s/[.]exe$//;
   return 0 unless $editor;
   foreach my $path (split ':', $ENV{PATH}) {
      $path=~s/[\/]*$/\//;
      if ($^O eq 'cygwin' && (-e $path.$editor.'.exe')) {
         return $path.$editor.'.exe';
      } elsif (-e $path.$editor) {
         return $path.$editor;
      }
   } return 0;
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
      $editor=~s/\//\\\//g;
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
   if (-1<index $main::install_firefox,'Install') {
      my $cygwin_loc=main::get_cygwin_location(1);
      $cygwin_loc=~s/\\/\//;
      $inherited .= "$Config{installsitelib}/Net/FullAuto/$main::mozrepl_file:".
                    "\n\t\$(CP) $cygwin_loc/$main::mozrepl_file \$@\n\n";
   }

   $inherited; 

}

package MY; # so that "SUPER" works right
sub MY::dist {

   use Config;

   my $inherited = shift->SUPER::dist(@_);

   if (grep { /-*add[-_]?dependencies/i } @ARGV) {

      $inherited =~ s/^(DISTVNAME.*Net-FullAuto)(.*)$/$1-Complete$2/m;

   }

   $inherited; 

}

package MY; # so that "SUPER" works right
sub MY::tools_other {

   use Config;

   my $inherited = shift->SUPER::tools_other(@_);

   $inherited =~
      s/^MV.*$/MV = mv -f/m;

   $inherited =~
      s/^(MV.*)$/$1\nSED = sed/m;

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
      s/(PERM_G_X = \d+)/$1\nPERM_S+X = 4555\n/m;
   $inherited =~
      s/(PERM_S[+]X = \d+)/$1\nPERM_R+X = 555\nPERM_R-X = 550\nPERM_R_X = 511/m;
   $inherited =~
      s/(PERM_R_X = \d+)/$1\nPERM_D-X = 750\nPERM_D_X = 700\nPERM_WRX = 777/m;
   $inherited =~
      s/(PERM_WRX = \d+)/$1\nPERM_OG_ = 770/m;

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
   } elsif ($permission eq 'Owner-Group') {
      if (-1<index $main::install_firefox,'Install') {
         my $mz="$Config{installsitelib}/Net/FullAuto/$main::mozrepl_file";
         $inherited =~
            s/(install ::.*)$/$1 owner_group_permissions $mz/m;
      } else {
         $inherited =~ s/(install ::.*)$/$1 owner_group_permissions/m;
      }
   } else {
      if (-1<index $main::install_firefox,'Install') {
         my $mz="$Config{installsitelib}/Net/FullAuto/$main::mozrepl_file";
         $inherited =~
            s/(install ::.*)$/$1 full_access_permissions $mz/m;
      } else {
         $inherited =~ s/(install ::.*)$/$1 full_access_permissions/m;
      }
   }

   if (-e '/usr/share/figlet') {
      $inherited =~ s/(install ::.*)$/$1 figlet_fonts/m;
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
         $link="\t\$(NOECHO) $lnpath -f -s ".
               "\$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT) ".
               "\$(DESTINSTALLSITESCRIPT)\/fa\n"; 
      }

   } 

   $inherited .= "\nsetuid_permissions ::\n".
     "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_S+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
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
   $inherited .= "\nowner_group_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Owner-Group Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_OG_) /var\n".
      $link;
   $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
      "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
      "cygwin_berkeley_db_mode = \$(PERM_OG_);/g\' ".
      "\$(DESTINSTALLSITELIB)/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
      "\t\$(MV) ./tmp_fa_core.pm \$(DESTINSTALLSITELIB)".
      "/Net/FullAuto/FA_Core.pm\n\n"
      if $^O eq 'cygwin';
   $inherited .= "\nfull_access_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Full-Access Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) /var\n".
      $link;
   $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
      "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
      "cygwin_berkeley_db_mode = \$(PERM_WRX);/g\' ".
      "\$(DESTINSTALLSITELIB)/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
      "\t\$(MV) ./tmp_fa_core.pm \$(DESTINSTALLSITELIB)".
      "/Net/FullAuto/FA_Core.pm\n\n"
      if $^O eq 'cygwin';
   $inherited .= "\nfiglet_fonts ::\n".
      "\t\$(NOECHO) \$(CP) dependencies/FIGlet_fonts/* /usr/share/figlet\n\n".
   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::dist_core {

   my $inherited = shift->SUPER::dist_core(@_);

   $inherited =~ s/tar$/tar\n\t\$(MV) \$(DISTVNAME).tar\$(SUFFIX) dist/m;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::clean {

   my $inherited = shift->SUPER::clean(@_);

   $inherited =~ s/blib\s*$/blib setup\$(EXE_EXT) /m;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::distdir {

   my $inherited = shift->SUPER::distdir(@_);

   $inherited =~ s/^(distdir .*)$/$1 distsignature/m;

   $inherited;

}

package MY; # so that "SUPER" works right
sub MY::pm_to_blib {

   use Config;

   my $inherited = shift->SUPER::pm_to_blib(@_);

   unless ((-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_host.pm") &&
         ($inherited !~ /Custom\/fa_host.pm/)) {
      my $fa_h="\t  lib\/Net\/FullAuto\/Custom\/fa_host.pm ".
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
      my $fa_p="\t  lib\/Net\/FullAuto\/Custom\/fa_maps.pm ".
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
      my $fa_g="\t  lib\/Net\/FullAuto\/Custom\/fa_conf.pm ".
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
      my $fa_m="\t  lib\/Net\/FullAuto\/Custom\/fa_menu.pm ".
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
      my $fa_c="\t  lib\/Net\/FullAuto\/Custom\/fa_code.pm ".
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
   $inherited =~ s/([\$][(]NOECHO[)] [\$])/-$1/s;
   my $newline_flag=0;
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $inherited .= "\t\$(SED) \'s/^#[ ]*our[ ]*\\(.\\)editor[ ]*[=].*/".
         'our \\1'."editor = \"$editor\";/g\' ".
         "blib/lib/Net/FullAuto/Custom/fa_conf.pm >tmp_conf.pm\n".
         "\t\$(MV) tmp_conf.pm blib/lib/Net/FullAuto/Custom/fa_conf.pm\n\n"
         if defined $editor and $editor;
   } else {
      $newline_flag=1;
      $inherited .= "\n";
   }

   unless (-e $Config{installsitelib}."/Net/FullAuto/FA_Core.pm") {
      $inherited .= "\t\$(SED) \'s/^[ ]*our[ ]*\\(.\\)".
         "cygwin_berkeley_db_mode[ ]*[=].*/".'our \\1'.
         "cygwin_berkeley_db_mode = $main::cygwin_berkeley_db_mode;/g\' ".
         "blib/lib/Net/FullAuto/FA_Core.pm >tmp_fa_core.pm\n".
         "\t\$(MV) ./tmp_fa_core.pm blib/lib".
         "/Net/FullAuto/FA_Core.pm\n\n"
         if $^O eq 'cygwin';
   } elsif (!$newline_flag) {
      $inherited .= "\n";
   }

   $inherited;

}

package FA::LWP::UserAgent;
use strict;
our @ISA = qw(LWP::UserAgent); # inherits from LWP::UserAgent
use vars qw(@ISA $USER $PASSWD $SETUPDONE);
# we delay requiring LWP::UserAgent and setting up inheritance until we need it

$FA::LWP::UserAgent::VERSION = "1.94";

sub config {
    return if $SETUPDONE;
    if ($CPAN::META->has_usable('LWP::UserAgent')) {
        require LWP::UserAgent;
        @ISA = qw(Exporter LWP::UserAgent); ## no critic
        $SETUPDONE++;
    } else {
        $CPAN::Frontend->mywarn("  LWP::UserAgent not available\n");
    }
}

sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    if ($USER && $PASSWD) {
        return ($USER, $PASSWD);
    }
    if ( $proxy ) {
        ($USER,$PASSWD) = $self->get_proxy_credentials();
    } else {
        ($USER,$PASSWD) = $self->get_non_proxy_credentials();
    }
    return($USER,$PASSWD);
}

sub get_proxy_credentials {
    my $self = shift;
    my ($user, $password);
    if ( defined $CPAN::Config->{proxy_user} ) {
        $user = $CPAN::Config->{proxy_user};
        $password = $CPAN::Config->{proxy_pass} || "";
        return ($user, $password);
    }
    my $username_prompt = "\nProxy authentication needed!
 (Note: to permanently configure username and password run
   o conf proxy_user your_username
   o conf proxy_pass your_password
     )\nUsername:";
    ($user, $password) =
        _get_username_and_password_from_user($username_prompt);
    return ($user,$password);
}

sub get_non_proxy_credentials {
    my $self = shift;
    my ($user,$password);
    if ( defined $CPAN::Config->{username} ) {
        $user = $CPAN::Config->{username};
        $password = $CPAN::Config->{password} || "";
        return ($user, $password);
    }
    my $username_prompt = "\nAuthentication needed!
     (Note: to permanently configure username and password run
       o conf username your_username
       o conf password your_password
     )\nUsername:";

    ($user, $password) =
        _get_username_and_password_from_user($username_prompt);
    return ($user,$password);
}

sub _get_username_and_password_from_user {
    my $username_message = shift;
    my ($username,$password);

    ExtUtils::MakeMaker->import(qw(prompt));
    $username = prompt($username_message);
        if ($CPAN::META->has_inst("Term::ReadKey")) {
            Term::ReadKey::ReadMode("noecho");
        }
    else {
        $CPAN::Frontend->mywarn(
            "Warning: Term::ReadKey seems not to be available, ".
            "your password will be echoed to the terminal!\n"
        );
    }
    $password = prompt("Password:");

        if ($CPAN::META->has_inst("Term::ReadKey")) {
            Term::ReadKey::ReadMode("restore");
        }
        $CPAN::Frontend->myprint("\n\n");
    return ($username,$password);
}

# mirror(): Its purpose is to deal with proxy authentication. When we
# call SUPER::mirror, we relly call the mirror method in
# LWP::UserAgent. LWP::UserAgent will then call
# $self->get_basic_credentials or some equivalent and this will be
# $self->dispatched to our own get_basic_credentials method.

# Our own get_basic_credentials sets $USER and $PASSWD, two globals.

# 407 stands for HTTP_PROXY_AUTHENTICATION_REQUIRED. Which means
# although we have gone through our get_basic_credentials, the proxy
# server refuses to connect. This could be a case where the username or
# password has changed in the meantime, so I'm trying once again without
# $USER and $PASSWD to give the get_basic_credentials routine another
# chance to set $USER and $PASSWD.

# mirror(): Its purpose is to deal with proxy authentication. When we
# call SUPER::mirror, we relly call the mirror method in
# LWP::UserAgent. LWP::UserAgent will then call
# $self->get_basic_credentials or some equivalent and this will be
# $self->dispatched to our own get_basic_credentials method.

# Our own get_basic_credentials sets $USER and $PASSWD, two globals.

# 407 stands for HTTP_PROXY_AUTHENTICATION_REQUIRED. Which means
# although we have gone through our get_basic_credentials, the proxy
# server refuses to connect. This could be a case where the username or
# password has changed in the meantime, so I'm trying once again without
# $USER and $PASSWD to give the get_basic_credentials routine another
# chance to set $USER and $PASSWD.

sub mirror {
    my($self,$url,$aslocal) = @_;
    my $result = $self->SUPER::mirror($url,$aslocal);
    if ($result->code == 407) {
        undef $USER;
        undef $PASSWD;
        $result = $self->SUPER::mirror($url,$aslocal);
    }
    $result;
}

1;
