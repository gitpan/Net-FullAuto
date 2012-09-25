### OPEN SOURCE LICENSE - GNU PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright (C) 2011, 2012  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################

################################################################
#
#  Makefile.PL for Net::FullAuto
#
################################################################

BEGIN {

$main::VERSION='0.999923';
my $fa_banner=<<END;



    __       __)
   (, )  |  /      /)
      | /| /   _  // _  ______    _    _/_ ___
      |/ |/  _(/_(/_(__(_) // (__(/_   (__(_)
      /  |



           _   _      _         _____      _ _    _         _
          | \\ | | ___| |_      |  ___|   _| | |  / \\  _   _| |_ ___
          |  \\| |/ _ \\ __| o o | |_ | | | | | | / _ \\| | | | __/ _ \\
          | |\\  |  __/ ||  o o |  _|| |_| | | |/ ___ \\ |_| | || (_) |
          |_| \\_|\\___|\\__|     |_|   \\__,_|_|_/_/   \\_\\__,_|\\__\\___/



   Copyright (C) 2011, 2012  Brian M. Kelly  Brian.Kelly\@fullautosoftware.net


END

   sub get_cygwin_location {
      my $cygwin_query=
            `REG QUERY HKEY_LOCAL_MACHINE\\SOFTWARE\\Cygwin\\setup 2>&1`;
      my $showcq=$cygwin_query;
      $showcq=~s/^/   /mg;chomp $showcq;
      if (-1<index $cygwin_query,'REG_SZ') {
         print "\n   REG QUERY RESULT:\n\n   $showcq";
         $cygwin_query=~s/^.*REG_SZ\s+(.*)\s*$/$1/s;
         $cygwin_query=~s/^\s*//s;
         $cygwin_query=~s/\s*$//s;
         unless (-W $cygwin_query) {
            print "\n\n   Fatal Error! - Write Access to $cygwin_query\n".
                  "   is needed in order to install FullAuto or OpenSSH.\n\n".
                  "   Please contact your Windows System Administrator\n".
                  "   to resolve.\n\n   PRESS ANY KEY to Exit Setup\n\n";
            <STDIN>;
            exit 1;
         }
         my $getver='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_query\\bin\\bash -lc ".
                '"cygcheck -c cygwin"';
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
         my $getid='SET CYGWIN=nodosfilewarning & '.
                "cmd /c $cygwin_query\\bin\\bash -lc ".
                '"id"';
         my $groups=`$getid`;
         unless (-1<index $groups,"(Administrators)") {
            print "\n\n   Fatal Error! - The User $ENV{'USERNAME'} needs to\n".
                  "   be a member of the Administrator's group in order\n".
                  "   to install FullAuto or OpenSSH.\n\n".
                  "   Please contact your Windows System Administrator\n".
                  "   to resolve.\n\n    PRESS ANY KEY to Exit Setup\n\n";
            <STDIN>;
            exit 1;
         }
         return $cygwin_query;
      } return 0
   }

   use Cwd qw/cwd/;
   use lib '.';
   use lib './inc';
   my $mycpantest=0; 
   $main::curdir=&cwd;
   $main::PARdir=$main::curdir;
   $main::domain_gr_flag=0;
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
   unless (exists $ENV{FA_EDITOR}) {
      print $fa_banner;
      sleep 2;
   }
   use CPAN;
   use File::Path;

   $main::root_dir=$main::curdir;

   my $incflag=0;my @drive_options=();
   if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
      if (-1==index $0,'Setup-FullAuto-v') {
         my $die="\n       FATAL ERROR! : Cygwin Linux Emulation Layer".
            "\n                      is required to use FullAuto".
            "\n                      on Windows - goto www.cygwin.com.".
            "\n\n           Be sure to install the following programs in ".
            "\n           addition to the base package:".
            "\n\n           inetutils and openssh [as provided by Cygwin]".
            "\n           perl [as provided by Cygwin] (*NOT* CPAN)".
            "\n           perl-libwin32 [as provided by Cygwin] (*NOT* CPAN)".
            "\n           ncurses, cron, and procps [as provided by Cygwin]".
            "\n           gcc4-core and gcc4-g++ [as provided by Cygwin]".
            "\n           Oracle Berkeley DB [as provided by Cygwin or Oracle]".
            "\n\n           **IMPORTANT** - the FullAuto install, either manual".
            "\n           or via CPAN, must be run *inside* a Cygwin bash shell".
            "\n           when installing FullAuto on Microsoft Windows.".
            "\n\n";
         unless ($ENV{'AUTOMATED_TESTING'}) {
            die $die;
         } else {
            print $die;
            exit;
         }
      }
      $incflag=1 if -e './inc';
      use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Win32::DriveInfo";
      use if ($^O eq 'MSWin32' || $^O eq 'MSWin64'), "Term::Menus";

      my %read_license=(

         Label => 'read_license',
         Item_1 => {

            Text => "]C[",
            Convey => sub {

               my $endcount=30;
               my @content=();my $tl=0;
               my $linenumber="]P[";
               $linenumber||=1;
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
                  $endcount=599;
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
         Item_2 => {
            Text => "I accept the license provisions",
         },
         Item_3 => {
            Text => "I do *NOT* accept the license provisions ".
                    "(Install will Exit)",
         },
         Banner => sub {
               my $linenumber="]P[";
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
                  $endcount=599;
               } else { $linenumber=1 }
               $linenumber=0 if $linenumber==1;
               --$endcount;
               return (join "", @content[$linenumber..$endcount]);
            }

      );
      my %license_agree=(
         Label => 'license_agree',
         Item_1 => {

            Text => "I agree to the license provisions",

         },
         Item_2 => {

            Text => "Review the GNU Public License Version 3\n".
                    "                   WARRANTY DISCLAIMER",
            Result => \%read_license,

         },
         Item_3 => {

            Text => "Review the GNU Public License Version 3\n".
                    "                   in its entirety",
            Result => \%read_license,

         },
         Item_4 => {

            Text => "I DO NOT AGREE to the license provisions\n".
                    "                   ( FullAuto Install will EXIT )",
         },
         Banner =>"      *THANK YOU* For Trying FullAuto!\n\n".
            "      Net::FullAuto INSTALLATION PROGRAM\n\n".
            "      Copyright (C) 2011, 2012  Brian M. Kelly\n\n".
            "      Contact: Brian.Kelly\@fullautosoftware.net\n\n".
            "   This program comes with ABSOLUTELY NO WARRANTY; for details\n".
            "   select  2.  This is free software, and you are welcome to\n".
            "   redistribute it under certain conditions; select  3  for\n".
            "   details.\n",

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
         my $banner="\n".
                    "    ___                     _            _     _ \n".
                    "   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  | |\n".
                    "    | || '  \\| '_ \\/ _ \\ '_|  _/ _` | ' \\  _| |_|\n".
                    "   |___|_|_|_| .__/\\___/_|  \\__\\__,_|_||_\\__| (_)\n".
                    "             |_|\n".
                    "\n".
                    "   FullAuto Setup has detected a Cygwin installation\n".
                    "   at $cygwin_loc. Setup has also determined that\n".
                    "   there is ".&size_fmt($file_size)." Free Space on".
                    " the Drive $drv Volume.\n".
                    "   It is IMPORTANT TO NOTE that FullAuto Setup will\n".
                    "   attempt to use this installation. If this is\n".
                    "   undesirable, then select choice '2' and FullAuto\n".
                    "   Setup will EXIT. It is recommended that you use the\n".
                    "   cpan utility to install or update FullAuto, if there\n".
                    "   is more than one Cygwin installation on your system.\n".
                    "\n   If you're sure you wish to proceed with your\n".
                    "   $cygwin_loc setup, then select choice '1' and\n".
                    "   FullAuto Setup will continue ...";
         my %cygchoice=(

               Label => 'cygchoice',
               Item_1 => {
                  Text => 'Continue with FullAuto Setup',
               },
               Item_2 => {
                  Text => 'CANCEL FullAuto Setup and EXIT',
               },
               Banner => $banner,
         );
         my $selection=Menu(\%cygchoice);
         chomp($selection);
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
                  "\n\n   Please report any bugs and send any",
                  "\n   questions, thoughts or feedback to:",
                  "\n\n      Brian.Kelly\@fullautosoftware.net.",
                  "\n\n   Press ANY key to exit.\n\n";<STDIN>;
            exit;
         }
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
      $look='libwww' if $look eq 'LWP';
      $look='MIME-tools' if $look eq 'MIME-Entity';
      $look='TermReadKey' if $look eq 'Term-ReadKey';
      $look='IO-Tty' if $look eq 'IO-Pty';
      $look='MailTools' if $look eq 'Mail-Internet';
      print "***** Looking for Most Recent \"$look Dir\" \n";
      my $d = $CPAN::Config->{build_dir};
      if (!(defined $d) || !(-d $d)) {
         $d=(getpwuid $>)[7].'/.cpan/build';
         unless (-d $d) {
            die "ERROR - Can't locate .cpan/build directory";
         }
      }
      my $new='';my $file='';
      opendir(DH,$d) or
         die "ERROR - Can't read Directory $d: $!\n";
      while ($_ = readdir(DH)) {
         next if ($_ eq ".") || ($_ eq "..");
         next unless -d $d.'/'.$_;
         next if $_!~/^$look/;
         $file=sprintf("%s/%s",$CPAN::Config->{build_dir},$_);
         my @attrs = stat $file;
         my $diff = time()-$attrs[9];
         if ($temp == 0 && $_=~/^$look/) {
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
   
   sub fa_install_mod {
   
      my $p=$_[0];
      my $task=$_[1];
      my $butil=$_[2]||'';
      my $force=$_[3]||'';
      my $version=$_[4]||'';
      my $dir='';
      my $cpan_error='';
      eval "require $p;1";
      unless ($@) {
         if ($version) {
            my $ttmp='$ver=$'.$p.'::VERSION';
            eval $ttmp;
            $ver=eval $ver;
            $force=1 if $ver<$version;
         } 
      }
      if ($@ || $force) {
         if ($ENV{'AUTOMATED_TESTING'}) {
            print "Automated Testing Detected: FullAuto needs $p\n",
                  "   to continue, but $p was not detected on this\n",
                  "   host.\n\n";
                  "FullAuto Install will EXIT.";
            exit;
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
            print "CPAN Error: $cpan_error => will attempt CPANPLUS\n";
            do {
               print"==> $p required."
               and print "*** Installing $p via CPANPLUS\n"
               and
               do {
                  eval {
                     require CPANPLUS::Backend;
                     my $cb  = CPANPLUS::Backend->new;
                     my $mod = $cb->parse_module(module=>$p);
                     my $where = $cb->_fetch(module=>$mod,verbose=>1);
                     $dir - $cb->_extract(module=>$mod,verbose=>1);
                  };
                  die "CPANPLUS Error: $@ $! and CPAN Error: $cpan_error" if $@;
               }; 
            };
         }
         if ($task eq 'install') {
            $dir||=&fa_find_latest($p);
            print "*** Running $butil.PL\n";
            system("cd \"$dir\";$^X $butil.PL");
            if ($butil eq 'Makefile') {
               print "*** Running make install\n";
               system("cd \"$dir\";make install");
            } else {
               print "*** Running Build install\n";
               system("cd \"$dir\";./Build install");
            }
         }
         chdir $main::curdir;
      } else { print "*** $p Loaded Successfully\n" }
   }
   
   sub fa_install_module {
       my $stdout='';my $stderr='';
       eval { require IO::CaptureOutput };
       if ($@) {
          eval { &fa_install_mod(@_) };
          if ($@) {
             return '',$@;
          } else {
             return '','';
          }
       } else {
          eval {
             require IO::CaptureOutput;
             IO::CaptureOutput::capture {
                &fa_install_mod(@_)
             } \$stdout, \$stderr;
          };
          return $stdout,$stderr;
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
   ($stdout,$stderr)=&fa_install_module(
      'ExtUtils::MakeMaker','install','Makefile','','6.59');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'ExtUtils::MakeMaker') if $stderr;
   ($stdout,$stderr)=&fa_install_module('YAML','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'YAML') if $stderr;
   eval { require Module::Build };
   if ((!($@) && $Module::Build::VERSION<=.3601) || $@) {
      ($stdout,$stderr)=&fa_install_mod(
         'CPAN::Meta','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'CPAN::Meta') if $stderr;
      ($stdout,$stderr)=&fa_install_mod(
         'ExtUtils::ParseXS','install','Makefile','force');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'ExtUtils::ParseXS') if $stderr;
      ($stdout,$stderr)=&fa_install_mod(
         'Parse::CPAN::Meta','install','Makefile','force');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Parse::CPAN::Meta') if $stderr;
      ($stdout,$stderr)=&fa_install_mod(
         'Perl::OSType','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Perl::OSType') if $stderr;
      ($stdout,$stderr)=&fa_install_mod(
         'version','install','Makefile','force');
      print $stdout if $stdout;
      ($stdout,$stderr)=&fa_install_mod(
         'Module::Metadata','install','Makefile','force');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'version') if $stderr;
      ($stdout,$stderr)=&fa_install_mod(
         'Module::Build','install','Build','force');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Module::Build') if $stderr;
   }
   ($stdout,$stderr)=&fa_install_module('IO::CaptureOutput','install','Build');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'IO::CaptureOutput') if $stderr;
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64') {
      ($stdout,$stderr)=&fa_install_module('IO::Pty','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'IO::Pty') if $stderr;
      my $argv0=$ARGV[0]||'';
      exit if $argv0 eq 'install_IO_Pty_from_CPAN';
   }
   ($stdout,$stderr)=&fa_install_module('HTML::Tagset','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTML::Tagset') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTML::Parser','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTML::Parser') if $stderr;
   ($stdout,$stderr)=&fa_install_module('URI','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'URI') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTTP::Message','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTTP::Message') if $stderr;
   ($stdout,$stderr)=&fa_install_module('File::Listing','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'File::Listing') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTTP::Cookies','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTTP::Cookies') if $stderr;
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64' && $^O ne 'cygwin') {
      ($stdout,$stderr)=&fa_install_module('HTTP::Daemon','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'HTTP::Daemon') if $stderr;
      ($stdout,$stderr)=&fa_install_module(
         'Encode::Locale','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Encode::Locale') if $stderr;
      ($stdout,$stderr)=&fa_install_module(
         'WWW::RobotRules','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'WWW::RobotRules') if $stderr;
      ($stdout,$stderr)=&fa_install_module(
         'Mail::Internet','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Mail::Internet') if $stderr;
      ($stdout,$stderr)=&fa_install_module('MIME::Entity','install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'MIME::Entity') if $stderr;
   }
   ($stdout,$stderr)=&fa_install_module('LWP::MediaTypes','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'LWP::MediaTypes') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTTP::Date','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTTP::Date') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTTP::Negotiate','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTTP::Negotiate') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Net::HTTP','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Net::HTTP') if $stderr;
   ($stdout,$stderr)=&fa_install_module('LWP','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'LWP') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Task::Weaken','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Task::Weaken') if $stderr;
   ($stdout,$stderr)=&fa_install_module(
      'ExtUtils::Depends','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'ExtUtils::Depends') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Digest::MD5','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Digest::MD5') if $stderr;
   ($stdout,$stderr)=&fa_install_module('B::Utils','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'B::Utils') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Algorithm::Diff','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Algorithm::Diff') if $stderr;
   eval { require Data::Dump::Streamer };
   if ($@) {
      ($stdout,$stderr)=&fa_install_module('Data::Dump::Streamer','get');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Data::Dump::Streamer') if $stderr;
      my $dir=&fa_find_latest('Data-Dump-Streamer');
      system("cd \"$dir\";$^X Build.PL NODDS;");
      system("cd \"$dir\";./Build install;");
   }
   ($stdout,$stderr)=&fa_install_module('Term::ReadKey','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Term::ReadKey') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Term::RawInput','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Term::RawInput') if $stderr;
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=&fa_install_module('Win32::API',
         'install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Win32::API') if $stderr;
      ($stdout,$stderr)=&fa_install_module('Win32::DriveInfo',
         'install','Makefile');
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Win32::DriveInfo') if $stderr;
   }
   my $cpanvalue=$ENV{PERL5_CPAN_IS_RUNNING}||'';
   my $cpanmvalue=$ENV{PERL5_CPANM_IS_RUNNING}||'';
   undef $ENV{PERL5_CPAN_IS_RUNNING};
   undef $ENV{PERL5_CPANM_IS_RUNNING};
   ($stdout,$stderr)=&fa_install_module('JSON::XS','install','Makefile');
   &fa_err_exit($stderr,'JSON::XS') if $stderr;
   print $stdout if $stdout;
   ($stdout,$stderr)=&fa_install_module('JSON','install','Makefile');
   &fa_err_exit($stderr,'JSON') if $stderr;
   print $stdout if $stdout;
   $ENV{PERL5_CPAN_IS_RUNNING}=$cpanvalue if $cpanvalue;
   $ENV{PERL5_CPANM_IS_RUNNING}=$cpanmvalue if $cpanmvalue;
   #($stdout,$stderr)=&fa_install_module('IPC::ShareLite','install','Makefile');
   #&fa_err_exit($stderr,'IPC::ShareLite') if $stderr;
   #print $stdout if $stdout;
   #($stdout,$stderr)=&fa_install_module('Digest::SHA1','install','Makefile');
   #&fa_err_exit($stderr,'Digest::SHA1') if $stderr;
   #print $stdout if $stdout;
   #($stdout,$stderr)=&fa_install_module('Error','install','Makefile');
   #&fa_err_exit($stderr,'Error') if $stderr;
   #print $stdout if $stdout;
   #($stdout,$stderr)=&fa_install_module('Cache::Cache','install','Makefile');
   #&fa_err_exit($stderr,'Cache::Cache') if $stderr;
   #print $stdout if $stdout;
   ($stdout,$stderr)=&fa_install_module('Term::Menus','install','Makefile');
   &fa_err_exit($stderr,'Term::Menus') if $stderr;
   print $stdout if $stdout;
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
   if (-e $cygwin_loc) {
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
         if (0<$#{$linn}) {
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
            $s--;my $adjust=0;
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
         `echo \"$npass\" > /etc/passwd`;
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
      my %cygsrvs=();
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
            my $npass=join "\n",@newpassw;
            `echo \"$npass\" > /etc/passwd`;
         }

         test_windows_user_rights('cyg_server');
      } 
   }
   my $found_dotted=0;
   my $domain='';
   $domain=' /domain' if $_[0];
   my $server='';
   foreach my $line (split "\n", `net user$domain`) {
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
   foreach my $line (@output) {
      my ($on,$tw,$th)=unpack("a$one a$mid a$two",$line);
      $on=~s/\s*$//;$tw=~s/\s*$//;$th=~s/\s*$//;
      last if -1<index $on,'The command compl';
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
      if ($cyg_id eq 'cyg_server') {
         my $o=`net user cyg_server`;
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
         } else {
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
         test_windows_user_rights($selection);
      } elsif (-1<index $selection, 'Use Domain') {
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
use inc::Module::Install;

# Define metadata
version         $main::VERSION;
name            'Net-FullAuto';
sign;
author          'Brian M. Kelly <Brian.Kelly@fullautosoftware.net>';
license         'GPL-3.0';
perl_version    '5.006';

#unshift @INC, $main::PARdir if $main::unshift_incdir;

use Config;
use File::stat;
CPAN::HandleConfig->load;
use POSIX qw/strftime/;

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

if (exists $Config{prefix} &&
      $Config{prefix}) {
   $PREFIX=$Config{prefix};
}

foreach my $arg (@ARGV) {
   if ($arg=~/INSTALL_*CYGWIN\s*=\*1/i) {
      $install_cygwin_without_asking=1;
      last;
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
         my @editors=('vim     ( ViIMproved - enhanced vi editor )',
                      "emacs   ( The extensible, customizable,\n           ".
                      "              self-documenting real-time\n         ".
                      "                display editor )",
                      'mc      ( Midnight Commander visual shell )',
                      "joe     ( Fast and simple editor that\n             ".
                      '            emulates 5 other editors )', 
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
                  Banner => $banner,

            );
         } else {
            %Menu_select_editor=(

                  Label  => 'Menu_select_editor',
                  Item_1 => {

                     Text    => "]C[",
                     Convey  => \@editors,

                  },
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
            $editor='/bin/vim-nox.exe';
         } elsif ($selection=~/(emacs)/) {
            $selection=$1;
            $editor='/bin/emacs-nox.exe';
         } elsif ($selection=~/(joe)/) {
            $selection=$1;
            $editor='/bin/joe.exe';
         } elsif ($selection=~/(mc)/) {
            $selection=$1;
            $editor='/bin/mc.exe';
         }
      }
      my $url='http://www.cygwin.com/setup.exe';
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
               exit;
            }
            open(CP,">$main::root_dir\\setup.exe") || die $!;
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
            $url='http://www.fullautosoftware.net/download/setup.exe'; 
            $req = HTTP::Request->new(GET => $url);
            $req->header('Accept' => 'text/html');
            $res = $Ua->request($req);
            if ($res->is_success) {
               print " + request successful.\n"
                  if $CPAN::DEBUG;
               mkpath($main::root_dir,1) unless -d $main::root_dir;
               open(CP,">$main::root_dir\\setup.exe") || die $!;
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
         chmod 0755, "$main::root_dir\\setup.exe";
         
         my $setup_cmd='';
         my $drlet=substr($main::root_dir,0,2);
         if ($selection!~/[Ww]ordpad|MINIMAL/s) {
            if ($selection eq 'vim') {
               $selection='';
            } else {
               $selection=",$selection";
            }
            $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup.exe -P gcc4-core,'
                      .'gcc4-g++,make,openssh,perl,perl-libwin32,db4.5,'
                      .'libdb4.5-devel,ncurses,cron,inetutils,procps,vim,unzip'
                      .$selection.' -X -A -q '."-R $main::root_dir "
                      .'-s http://cygwin.mirrors.pair.com';
         } elsif ($selection!~/MINIMAL/s) {
            $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup.exe -P gcc4-core,'
                      .'gcc4-g++,make,openssh,perl,perl-libwin32,db4.5,'
                      .'libdb4.5-devel,ncurses,cron,inetutils,procps,vim,unzip'
                      .' -X -A -q '."-R $main::root_dir "
                      .'-s http://cygwin.mirrors.pair.com';
         } else {
            $setup_cmd="$drlet & cd \"$main::root_dir\" & "
                      .'setup.exe -P openssh,ncurses,inetutils,procps,vim '
                      .'-X -A -q '."-R $main::root_dir ".'-s '
                      .'http://cygwin.mirrors.pair.com';
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
          
                      Text => "Use separate user account for sshd service",
                      Default => "*",
         
                   },
                   Item_2 => {
 
                     Text => "Use LocalSystem account for sshd service",
         
                   },
                   Banner => $banner,
         
               );
               $account_type=Term::Menus::Menu(\%Menu_select_account_type);
               chomp($account_type);
               exit if $account_type eq ']quit[';
               $privl=' --privileged' if -1<index $account_type,'separate';
            }
            $domain_user=&ws_info($domain) unless $wver=~/XP|2000|NT/;
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
                  <STDIN>;exit;
               }
               print "\n";
            } elsif ((-1<index $account_type,'separate') &&
                     (&test_windows_user($sshd_account))) {
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
                  <STDIN>;exit;
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
                       '"/usr/bin/cygrunsrv -L"';
            my $cygsrvs=`$srvcmd 2>&1`;
            if (-1==index $cygsrvs,'sshd') {
               if ($domain_user) {
                  system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                  unless ($main::domain_gr_flag) {
                     system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
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
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net start sshd 2>&1"';
               my $netout=`$netstart`;
               if (-1<index $netout,'System error') {
                  my $netdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net user sshd /DELETE 2>&1"';
                  my $ndout=`$netdel`;
                  my $cygdel='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"net user cyg_server /DELETE 2>&1"';
                  my $cgout=`$cygdel`;
                  my $netrm='SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $clo\\\\bin\\\\bash -lc ".
                    '"/usr/bin/cygrunsrv -R sshd 2>&1"';
                  my $rmout=`$netrm`;
                  if ($domain_user) {
                     system('export CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/mkpasswd -u \"'.$domain_user.'\" '.
                         '-d \"'.$domain.'\" >> /etc/passwd"');
                     unless ($main::domain_gr_flag) {
                        system('export CYGWIN=nodosfilewarning & '.
                            "cmd /c $clo\\\\bin\\\\bash -lc ".
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
               system('SET CYGWIN=nodosfilewarning & '.
                    "cmd /c $cygwin_loc\\bin\\dash -lc ".
                    '"/bin/rebaseall -v"');
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
                      '"/usr/bin/perl -e \"eval { require IO::Pty;1 }'.
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
               my $par_dir='export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$main::PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);
               system('export CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      #'/usr/bin/echo y|/usr/bin/cpan -i Net::FullAuto"');
                      '/usr/bin/echo y|/usr/bin/cpan -i '.
                      "REEDFISH/Net-FullAuto-$main::VERSION.tar.gz\"");
            } else {
               my $build_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/perl -e '.
                      '\"require CPAN and CPAN::HandleConfig-^^^>load and '.
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
                         '\"require CPAN and CPAN::HandleConfig-^^^>load and '.
                         'print \$CPAN::Config-^^^>{build_dir}\""';
                  my $stmout=`$streamdir`;
                  chomp($stmout);
                  $streamdir='SET CYGWIN=nodosfilewarning & '.
                         "cmd /c $clo\\\\bin\\\\bash -lc ".
                         '"/usr/bin/cygpath -lm \"'.$stmout.'\""';
                  $stmout=`$streamdir`;
                  chomp($stmout);
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
               my $par_dir='SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $clo\\\\bin\\\\bash -lc ".
                      '"/usr/bin/cygpath -lm \"'.$main::PARdir.'\""';
               my $pardir=`$par_dir`;
               chomp($pardir);
               system('SET CYGWIN=nodosfilewarning & '.
                      "cmd /c $cygwin_loc\\bin\\bash -lc ".
                      '"export PERL_MM_USE_DEFAULT=1;'.
                      'export FA_EDITOR=\\"'.$editor.'\\";'.
                      'export PARdir=\\"'.$pardir.'\\";'.
                      #'/usr/bin/cpan -i Net::FullAuto"');
                      '/usr/bin/echo y|/usr/bin/cpan -i '.
                      "REEDFISH/Net-FullAuto-$main::VERSION.tar.gz\"");
            }
         }
         my $rmdir_out=rmdir $main::curdir.'/inc/.author'; 
         #print "ERROR $main::curdir/inc/.author: $!\n" unless $rmdir_out;
         my $un_out=unlink $main::curdir.'/inc/Module/Install/Base.pm';
         #print "ERROR $main::curdir/inc/Module/Install/Base.pm: $!\n"
         #   unless $un_out;
         $un_out=unlink $main::curdir.'/inc/Module/Install/Metadata.pm';
         #print "ERROR $main::curdir/inc/Module/Install.pm: $!\n"
         #   unless $un_out;
         $un_out=unlink $main::curdir.'/inc/Module/Install.pm';
         #print "ERROR $main::curdir/inc/Module/Install.pm: $!\n"
         #   unless $un_out;
         $rmdir_out=rmdir $main::curdir.'/inc/Module/Install';
         #print "ERROR /inc/Module/Install: $!\n" unless $rmdir_out;
         $rmdir_out=rmdir $main::curdir.'/inc/Module';
         #print "ERROR $main::curdir/inc/Module: $!\n" unless $rmdir_out;
         unless ((exists $ENV{PARdir} && (-f $ENV{PARdir}.'/inc_exists.txt'))) {
            $rmdir_out=rmdir $main::curdir.'/inc';
            #print "ERROR $main::curdir/inc: $!\n" unless $rmdir_out;
         } else {
            $un_out=unlink $ENV{PARdir}.'/inc_exists.txt';
            #print "ERROR $ENV{PARdir}/inc_exists.txt: $!\n" unless $un_out;
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
         print "\n\n   FullAuto Installation has completed",
               "\n\n   Thank you!",
               "\n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@fullautosoftware.net.",
               "\n\n   Press ANY key to exit.\n\n";<STDIN>;
         exit;
      }
   } elsif ($process_id) {
      exit;
   }
   my $die="\n       FATAL ERROR! : Cygwin Linux Emulation Layer".
           "\n                      is required to use FullAuto".
           "\n                      on Windows - goto www.cygwin.com.".
           "\n\n           Be sure to install the following programs in ".
           "\n           addition to the base package:".
           "\n\n           inetutils and openssh [as provided by Cygwin]".
           "\n           perl [as provided by Cygwin] (*NOT* CPAN)".
           "\n           perl-libwin32 [as provided by Cygwin] (*NOT* CPAN)".
           "\n           ncurses, cron, and procps [as provided by Cygwin]".
           "\n           gcc4-core and gcc4-g++ [as provided by Cygwin]".
           "\n           Oracle Berkeley DB [as provided by Cygwin or Oracle]".
           "\n\n           **IMPORTANT** - the FullAuto install, either manual".
           "\n           or via CPAN, must be run *inside* a Cygwin bash shell".
           "\n           when installing FullAuto on Microsoft Windows.".
           "\n\n";
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
            if (-e '/bin/vim-nox.exe') {
               push @editors,'vim';
            }
            if (-e '/bin/emacs-nox.exe') {
               push @editors, 'emacs';
            }
            if (-e '/bin/joe.exe') {
               push @editors, 'joe';
            }
            if (-e '/bin/mc.exe') {
               push @editors, 'mc';
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
               $editor='/bin/vim-nox.exe';
            } elsif ($selection=~s/(emacs)/$1/) {
               $editor='/bin/emacs-nox.exe';
            } elsif ($selection=~s/(joe)/$1/) {
               $editor='/bin/joe.exe';
            } elsif ($selection=~s/(mc)/$1/) {
               $editor='/bin/mc.exe';
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

if ($^O eq 'cygwin' && !can_cc()) {
   my $die="\n       FATAL ERROR! : The Gnu C Compiler 'gcc'".
           "\n                      version 4 as provided by Cygwin".
           "\n                      is required to install FullAuto".
           "\n                      on Windows.".
           "\n(Hint: Run Cygwin setup.exe and install 'gcc4-core' ".
           "and 'gcc4-g++' under the Category 'Devel' ).".
           "\n\n";
   die $die;
} elsif (!can_cc()) {

   my $moreinfo='';
   if ($Config{cc} and $Config{cc}!~/^\s*$/) {
      $moreinfo="\n\n                      You are running $^X version $].\n".
           "\n                      The Config.pm file for this perl installation".
           "\n                      contains \"$Config{cc}\" as the compiler used".
           "\n                      to build this perl, but this compiler does not".
           "\n                      exist in the PATH and may not be installed on".
           "\n                      this host.\n";
           "\n                      Retrofitting an existing perl installation to".
           "\n                      work properly with a new compiler for building".
           "\n                      CPAN modules, is tricky and NOT recommended.".
           "\n                      Often the available perl (especially on Unix".
           "\n                      systems) is highly integrated with the host".
           "\n                      OS and many of its features and utilities.".
           "\n                      Upgrading the perl, but not the overall OS".
           "\n                      is risky and may result in more than a few".
           "\n                      system problems and instabilities.\n".
           "\n                      The recommended approach is build a NEW perl".
           "\n                      from source with your choice of newly installed".
           "\n                      compiler (such as gcc) in a different location".
           "\n                      (such as /usr/local/lib) or your home directory".
           "\n                      if you lack root/admin privileges."
   }

   my $die="\n       FATAL ERROR! : A C Compiler (such as cc or gcc version 4)".
           "\n                      is required to install FullAuto";
           $moreinfo.
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
      print "Press <ENTER> if you wish to continue, or 'N' to quit . . . [Y] ";
      $a=<STDIN>;
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
#if ($get_BerkeleyDB) {
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
      my $find_cmd2=" -name \"*.h\" ".
                   "| ${xargspath}xargs ${greppath}grep ".
                   "${grepopt}DB_VERSION_STRING";
      print "\nSearching for latest verison of BerkeleyDB.\n".
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
      if ($ENV{AUTOMATED_TESTING} || ($berkeleydb && $major_minor_ver>=5.1)) {
         $berkeleydb=~s/^(.*)\/.*$/$1/;
         $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
         $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
         $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
         $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
         $ENV{'DB_FILE_LIB'}=$berkeleydb;
         $ENV{'DB_FILE_NAME'}="-ldb-$ver";
         $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
      } else {
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
               my $timeout=120;my $a='';
               eval {
                  $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                  alarm $timeout;
                  print "\n       *** THIS SCREEN WILL TIMEOUT AND PROCEED WITH".
                        "\n           BerkeleyDB INSTALLATION IN 2 MINUTES ***\n".
                        "\n       IMPORTANT! : BerkeleyDB - a C Library used".
                        "\n                  by FullAuto to create a binary".
                        "\n                  file-based (lightweight) database".
                        "\n                  for storing and retrieving".
                        "\n                  credentials and persistance data,".
                        "\n                  was not located on this ".
                        "host/system.".
                        "\n\n       IMPORTANT! : This FullAuto setup process".
                        " will".
                        "\n                  now attempt to download ".
                        "BerkeleyDB".
                        "\n                  source code from Oracle.com and".
                        "\n                  and compile it for use by ".
                        "FullAuto.\n";
                  my $pre="/usr/local/BerkeleyDB.$ver";
                  $pre=$PREFIX."BerkeleyDB$ver" if $PREFIX;
                  print "\n       IMPORTANT! : BerkeleyDB will be installed".
                        "\n                  in $pre".
                        "\n\n       If you do not wish FullAuto setup to".
                        "\n       perform this step, type 'N' and setup will".
                        "\n       will exit. Please install BerkeleyDB manually".
                        "\n       before attempting another installation of".
                        "\n       FullAuto.\n\n";
                  print "Press <ENTER> if you wish to continue, ".
                        "or 'N' to quit . . . [Y] ";$
                  a=<STDIN>;
                  alarm 0;
               };
               if ($@) {
                  # timed out
                  #exit;
               } elsif ($a=~/^[Nn]$/s) {
                  exit;
               }
               my $fh='';my $filename='';
               if ($CPAN::META->has_usable("File::Temp")) {
                  $fh = File::Temp->new(
                        dir      => cwd(),
                        template => "${file}_XXXXXX",
                        suffix => ".tar.gz",
                        unlink => 0,
                       );
                  $filename = $fh->filename;
               } else {
                  $fh = FileHandle->new;
                  $filename = "${file}_$$.tar.gz";
               }
               chomp($filename);
               my $end_flag=0;
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
                           $end_flag=1;
                           $source=~
                              s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
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
                  my $md5fh='';my $md5filename='';
                  if ($CPAN::META->has_usable("File::Temp")) {
                     $md5fh = File::Temp->new(
                           dir      => cwd(),
                           template => "${file}_XXXXXX",
                           suffix => ".tar.gz.md5",
                           unlink => 0,
                     );
                     $md5filename = $md5fh->filename;
                  } else {
                     $md5fh = FileHandle->new;
                     $md5filename = "${file}_$$.tar.gz.md5";
                  }
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
                           $end_flag=1;
                           $source=~
                              s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
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
                  my $digestmd5=Digest::MD5->new->addfile(*FILE)->hexdigest;
                  if ($checksum eq $digestmd5) {
                     print(qq{ + CHECKSUM Test for $filename *PASSED* \n})
                     if $CPAN::DEBUG;
                  } else {
                     print "CHECKSUM test for $filename *FAILED*\n";
                     print "CALCULATED=$digestmd5 and DOWNLOADED=$checksum\n";
                     print "\nPress ANY key to terminate FullAuto ",
                           "installation ...\n";
                     <STDIN>;
                     die "FATAL ERROR! : ".
                         "CHECKSUM Test for $filename *FAILED*\n";
                  }
                  close(FILE);
                  last;
               }
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
                        exit;
                  }
               }
               open(FH, $CPAN::Config->{gzip}." -d $filename|");
               while (my $line=<FH>) {
                  print $line;
               }
               close FH;
               unless ($CPAN::Config->{tar}) {
                  if (-e '/usr/bin/tar') {
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
                        exit;
                  }
               }
               $filename=~s/\.gz$//;
               open(FH, $CPAN::Config->{tar}." xvf $filename|");
               while (my $line=<FH>) {
                  print $line;
               }
               close FH;
               my $uniq='';
               $filename=~/^.*(......).tar$/;
               my $uniq=$1;
               $filename=~s/........tar$//;
               `mv -f $filename ${filename}_$uniq`;
               my $args='';
               if ($PREFIX) {
                  $args=' --prefix="'.$PREFIX.'"';
               }
               open(FH,"cd ${filename}_$uniq/build_unix;../dist/configure$args|")
                  || warn $!;
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
               open(FH,"cd ${filename}_$uniq/build_unix;".
                   $CPAN::Config->{make}." install|")
                  || warn $!;
               my $cnt=0;
               my @savlines=();
               while (my $line=<FH>) {
                  print $line;
                  unless ($cnt<=50) { 
                     $cnt++;
                  } else {
                     shift @savlines;
                  } push @savlines,$line;
               }
               close FH;
               if (-1==index $savlines[$#savlines],
                     'Installing documentation:') {
                  die join "\n", @savlines;
               } else {
                  $ver=$filename;
                  $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
                  my $prefx=$savlines[$#savlines];
                  $prefx=~s/^Installing documentation: //;
                  $prefx=~s/docs \.\.\.\s*$//;
                  $berkeleydb=$prefx.'lib';
                  $header_to_use=$prefx."include";
                  $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
                  $ENV{'BERKELEYDB_LIB'}=$berkeleydb;
                  $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
                  $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
                  $ENV{'DB_FILE_LIB'}=$berkeleydb;
                  $ENV{'DB_FILE_NAME'}="-ldb-$ver";
                  $ENV{'LD_LIBRARY_PATH'}=$berkeleydb;
               }
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
         unless (exists $ENV{'BERKELEYDB_INCLUDE'} && $ENV{'BERKELEYDB_INCLUDE'}) {
            my $BerkDownload='http://www.oracle.com/technetwork/products/'.
                             'berkeleydb/downloads/index.html';
            my $PackManagers='http://en.wikipedia.org/wiki/'.
                             'List_of_software_package_management_systems';
            my $die="\n       FATAL ERROR! : Cannot locate 'BerkeleyDB'. This C Library ".
                    "\n                      is required to install FullAuto".
                    "\n                      (Hint: goto\n".
                    "\n       $BerkDownload\n".
                    "\n                       for BerkeleyDB Source Code. Binary versions".
                    "\n                       of the Library are widely available via".
                    "\n                       package managers such as yum and apt-get".
                    "\n                       See:\n".
                    "\n       $PackManagers).".
                    "\n\n";
            die $die;
         }
      }
   }
} elsif ($^O eq 'cygwin') {
   $ENV{'BERKELEYDB_INCLUDE'}='/usr/include';
   $ENV{'BERKELEYDB_LIB'}='/usr/lib';
   $ENV{'BERKELEYDB_NAME'}='-ldb-4.5';
   $ENV{'DB_FILE_INCLUDE'}='/usr/include';
   $ENV{'DB_FILE_LIB'}='/usr/lib';
   $ENV{'DB_FILE_NAME'}='-ldb-4.5';
}

chdir $main::curdir;

if ($get_BerkeleyDB) {

   #($stdout,$stderr)=&fa_install_module('BerkeleyDB','install','Makefile');
   #print $stdout if $stdout;
   #&fa_err_exit($stderr,'BerkeleyDB') if $stderr;

   do {
      my $p='BerkeleyDB';
      eval "use $p;1" or
      do {
         print"==> $p required."
         and print "*** Installing $p\n"
         and
         do {
            if (-f '/etc/redhat-release' || -f '/etc/fedora-release') {
               $ENV{LD_RUN_PATH}=$ENV{LD_LIBRARY_PATH};
            }
            if (eval '$>' and lc(`sudo -V`) =~ /version/) {
               system(
                  'sudo',$^X,"-MCPANPLUS","-e","install $p");
               eval "use $p;1" ||
                   system('sudo', $^X, "-MCPAN", "-e",
                     "CPAN::Shell->force('install',$p)")
            }
            eval {
               require CPANPLUS::Shell;
               my $u=CPANPLUS::Shell->new();
               $u->shell;
               $u->dispatch_on_input(input=>'o conf force 1');
               $u->dispatch_on_input(input=>"install $p")
            };
            eval "use $p;1"
            or eval{
                  require CPAN;
                  CPAN::Shell->force('install',$p)
               };
            eval "use $p;1" ||
               die "*** Please manually install $p from cpan.org first...\n"
         }
      }
   }
}

chdir $main::curdir;

my %hash=();
eval {
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
   my $die="\n$@\n".
           "\n       FATAL ERROR! : Cannot create 'fullauto_test_for_db_creation.db'".
           "\n                      You may be missing the Berkeley DB 'c' library.".
           "\n                      This 'c' library is required to install FullAuto\n";
   if ($^O eq 'cygwin') {
      $die.="\n(Hint: Run Cygwin setup.exe and install Oracle Berkley DB ".
           "under the Category 'Database' ).";
   } else {
      $die.="\n(Hint: goto ->  http://www.oracle.com/technetwork/".
           "products/berkeleydb/downloads/index.html ).";
   }
   $die.="\n\n";
   die $die;
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
         exit;
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
            exit;
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
            exit;
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
            exit;
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
         $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
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
         print "Type <Y> if you wish to FullAuto setup to modify the registry,\n".
               "or 'N' to proceed without this step . . . [N] ";$
         a=<STDIN>;
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
      }

   }
}

#Specific dependencies
requires        'Module::Build'             => 0.3601;
requires        'Module::Load::Conditional' => 0;
requires        'Task::Weaken'              => 0;
requires        'ExtUtils::Depends'         => 0;
requires        'ExtUtils::MakeMaker'       => 6.59;
requires        'B::Utils'                  => 0;
requires        'Data::Dump::Streamer'      => 0;
requires        'Digest::SHA'               => 0;
requires        'Digest::MD5'               => 0;
requires        'Term::Menus'               => 2.16;
requires        'Tie::Cache'                => 0;
requires        'Sort::Versions'            => 0;
requires        'Crypt::CBC'                => 0;
requires        'Crypt::DES'                => 0;
requires        'Cache::Cache'              => 0;
requires        'HTTP::Date'                => 0;
requires        'JSON'                      => 2.14;
requires        'IO::Pty'                   => 0;
requires        'IO::Capture::Stderr'       => 0;
requires        'Capture::Tiny'             => 0;
requires        'Net::Telnet'               => 0;
requires        'Term::RawInput'            => 0;
requires        'Term::ReadKey'             => 0;
requires        'Test::Deep'                => 0;
requires        'URI'                       => 0;
requires        'Email::Sender'             => 0;
requires        'MIME::Entity'              => 0;
requires        'Data::Password::Check'     => 0;
requires        'String::Random'            => 0;
requires        'YAML'                      => 0;
recommends      'Crypt::Rijndael'           => 0;

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
      $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
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
"main(int argc, char *argv[])\n".
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
   my @list=('Install with Setuid Permissions (Recommended Default)',
             'Install with Setgid Permissions',
             'Install with Non-Privileged Permissions');
   my $banner="\n   *** THIS SCREEN WILL TIMEOUT AND CHOOSE 'Setuid' IN 2 MINUTES ***\n".
           "\n   Choose a Permission Setting :\n\n";
   @selection=&pick(\@list,$banner);
   alarm 0;
};
if ($@) {
   # timed out
   print "\n";
   $selection = 'Setuid';
}

my $permission = 'Setuid';
#print "SELECTION = $selection<==\n";sleep 3;
if (-1<index $selection,'Setuid') {
   $permission = 'Setuid';
} elsif (-1<index $selection,'Setgid') {
   $permission = 'Setgid';
} elsif (-1<index $selection,'Non-Privileged') {
   $permission = 'Non-Privileged';
} elsif (-1<index $selection,'quit') {
   exit;
} print "\n"; 

if ($^O eq 'cygwin') {
   open(FH,">bin/fullauto.exe");
   print FH "\n";
   close FH;
   install_script('bin/fullauto.exe');
   unlink "bin/fullauto.exe";
} else {
   open(FH,">bin/fullauto");
   print FH "\n";
   close FH;
   install_script('bin/fullauto');
   unlink "bin/fullauto";
}
install_script('bin/fullauto.pl');

WriteAll();

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
      s/(PERM_R_X = \d+)/$1\nPERM_D-X = 750\nPERM_D_X = 700\nPERM_WRX = 755/m;

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
      $inherited =~ s/(install ::.*)$/$1 non_privileged_permissions/m;
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
         $link="\t\$(NOECHO) $lnpath -f -s \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT) ".
               "\$(DESTINSTALLSITESCRIPT)\/fa\n"; 
      }

   } 

   if ($^O eq 'cygwin') {

      $inherited .= "\nsetuid_permissions ::\n".
         "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_S+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_D_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
         $link;

   } else {

      $inherited .= "\nsetuid_permissions ::\n".
         "\t\$(NOECHO) \$(ECHO) \"Applying Setuid Permissions\"\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_S_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_D_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
         "\t\$(NOECHO) \$(CHMOD) \$(PERM_R_X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
         $link;

   }
   $inherited .= "\nsetgid_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Setgid Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_G_X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_D-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R-X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      $link;
   $inherited .= "\nnon_privileged_permissions ::\n".
      "\t\$(NOECHO) \$(ECHO) \"Applying Non-Privileged Permissions\"\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT)\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITESCRIPT)\/fullauto.pl\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto.pm\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_DIR) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_R+X) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/*\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\n".
      "\t\$(NOECHO) \$(CHMOD) \$(PERM_WRX) \$(DESTINSTALLSITELIB)\/Net\/FullAuto\/Custom\/*\n".
      $link; 

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
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $inherited .= "\t\$(SED) \'s/^#[ ]*our[ ]*\\(.\\)editor[ ]*[=].*/".
         'our \\1'."editor = \"$editor\";/g\' ".
         "<blib/lib/Net/FullAuto/Custom/fa_conf.pm >tmp_conf.pm\n".
         "\t\$(MV) tmp_conf.pm blib/lib/Net/FullAuto/Custom/fa_conf.pm\n\n"
         if defined $editor and $editor;
   } else {
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
