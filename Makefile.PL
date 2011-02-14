# Load the Module::Install bundled in ./inc/
BEGIN {
   use CPAN;
   my $mycpantest=0;
   my $cpantest=0;
   $mycpantest=1 if -e $cpandir."/CPAN/MyConfig.pm";
   $cpantest=1 unless $mycpantest;
   use if ($mycpantest), "CPAN::MyConfig";
   use if ($cpantest), "CPAN::Config";
};
use Cwd qw/cwd/;
use lib '.';
use inc::Module::Install;
use Config;
use DirHandle;
use File::stat;
CPAN::HandleConfig->load;
use POSIX qw/strftime/;

# Define metadata
name            'Net-FullAuto';
sign;
version         '0.9917';
author          'Brian M. Kelly <Brian.Kelly@fullautosoftware.net>';
license         'gpl';
perl_version    '5.006';

BEGIN {

   $main::curdir=&cwd;

   sub fa_find_latest {
      my $temp=0;
      my $look=shift||'';
      unless ($look) {
         die "ERROR - No argument provided to &fa_find_latest().\n";
      }
      $look=~s/::/-/g;
      $look='libwww' if $look eq 'LWP';
      $look='TermReadKey' if $look eq 'Term-ReadKey';
      print "***** Looking for Most Recent \"$look Dir\" \n";
      my $d = new DirHandle $CPAN::Config->{build_dir};
      if (!(defined $d) || !(-d $d)) {
         $d=(getpwuid $>)[7].'/.cpan/build';
         unless (-d $d) {
            die "ERROR - Can't locate .cpan/build directory";
         }
      }
      my $new='';my $file='';
      if (defined $d) {
         while (defined($_ = $d->read)) {
            next if ($_ eq ".") || ($_ eq "..");
            next if $_!~/^$look/;
            next if $_=~/yml$/;
            $file=sprintf("%s/%s",$CPAN::Config->{build_dir},$_);
            my $attrs = stat $file;
            my $diff = time()-$attrs->mtime;
            if ($temp == 0 && $_=~/^$look/) {
              $temp=$diff;
              $new=$file;
            }
            if ($diff<$temp) {
               $temp=$diff;
               $new=$_;
            }
         }
         $new=$file if !$new && $file;
         print "***** Module Directory ",$new,"\n";
         undef $d;
      } return $new; 
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

   sub fa_install_module {
       my $stdout='';my $stderr='';
       eval { require IO::CaptureOutput };
       if ($@ || (!defined $_[4] || !$_[4])) {
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

   sub fa_install_mod {

      my $p=$_[0];
      my $task=$_[1];
      my $butil=$_[2]||'';
      my $skiptest=$_[3]||'';
      my $getflag=0;
      eval "require $p";
      if ($@) {
         $getflag=1;
         do {
            eval "use $p;1" or
            do {
               print"==> $p required."
               and print "*** Installing $p\n"
               and
               do {
                  eval {
                     require CPANPLUS;
                     my $u=CPANPLUS::Shell->new();
                     $u->shell;
                     $u->dispatch_on_input(input=>'o conf notest 1');
                     $u->dispatch_on_input(input=>'o conf force 1');
                     $u->dispatch_on_input(input=>"fetch $p")
                  };
                  eval "use $p;1"
                  or eval{
                        require CPAN;
                        CPAN::Shell->notest('get',$p)
                     };
               }
            }
         };
         die $@ if $@;
         if (($task eq 'install') && $getflag) {
            my $dir=&fa_find_latest($p);
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

   sub fa_err_exit {
       die "$_[0]\n\n*** Please manually install $_[1]".
           " from cpan.org first...\n"
   }

   my $stdout='';my $stderr='';
   ($stdout,$stderr)=&fa_install_module('IO::CaptureOutput','install','Build');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'IO::CaptureOutput') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTML::Tagset','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTML::Tagset') if $stderr;
   ($stdout,$stderr)=&fa_install_module('HTML::Parser','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'HTML::Parser') if $stderr;
   ($stdout,$stderr)=&fa_install_module('URI','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'URI') if $stderr;
   ($stdout,$stderr)=&fa_install_module('LWP','install','Makefile',1);
   print $stdout if $stdout;
   &fa_err_exit($stderr,'LWP') if $stderr;
   ($stdout,$stderr)=&fa_install_module('Task::Weaken','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Task::Weaken') if $stderr;
   ($stdout,$stderr)=&fa_install_module('ExtUtils::Depends','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'ExtUtils::Depends') if $stderr;
   ($stdout,$stderr)=&fa_install_module('B::Utils','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'B::Utils') if $stderr;
   eval { require Data::Dump::Streamer };
   if ($@) {
      ($stdout,$stderr)=&fa_install_module('Data::Dump::Streamer','get','',1);
      print $stdout if $stdout;
      &fa_err_exit($stderr,'Data::Dump::Streamer') if $stderr;
      my $dir=&fa_find_latest('Data::Dump::Streamer');
      system("cd \"$dir\";$^X Build.PL NODDS;");
      system("cd \"$dir\";./Build install;");
   }
   ($stdout,$stderr)=&fa_install_module('Term::ReadKey','install','Makefile');
   print $stdout if $stdout;
   &fa_err_exit($stderr,'Term::ReadKey') if $stderr;
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
   ($stdout,$stderr)=&fa_install_module('JSON','install','Makefile');
   &fa_err_exit($stderr,'JSON') if $stderr;
   print $stdout if $stdout;
   $ENV{PERL5_CPAN_IS_RUNNING}=$cpanvalue if $cpanvalue;
   $ENV{PERL5_CPANM_IS_RUNNING}=$cpanmvalue if $cpanmvalue;
   ($stdout,$stderr)=&fa_install_module('Term::Menus','install','Makefile');
   &fa_err_exit($stderr,'Term::Menus') if $stderr;
   print $stdout if $stdout;
};

require Term::Menus;

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

my $editor='';my $selection='';
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
   if ($install_cygwin_without_asking) {
      $selection='Install';
   } else {
      $selection=Term::Menus::Menu(\%Menu_win_to_cyg);
   }
   exit if $selection eq ']quit[';
   if ($selection!~/NOT/) {
      my @editors=('vim     (ViIMproved - enhanced vi editor)',
                   "emacs   (The extensible, customizable,\n           ".
                   "              self-documenting real-time\n         ".
                   "                display editor)",
                   'mc      (Midnight Commander visual shell)',
                   "joe     (Fast and simple editor that\n             ".
                   '            emulates 5 other editors)', 
                  );
      my $tp='';
      unless ($tp=&fa_find_editor('TextPad.exe')) {
         if (-e "C:\\Program Files\\TextPad 5\\TextPad.exe") {
            $tp='default';
         }
      }
      if ($tp) {
         push @editors, 'TextPad (The Text Editor for Windows)';
      }

      my $banner="   In order is use the integrated edit features\n".
                 "   you will need to choose an editor.";
      my %Menu_select_editor=();
      if (-e "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe") {
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
         if (-e "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe") {
            $selection='wordpad';
            $editor="\"/cygdrive/c/Program Files/Windows NT/".
                    "Accessories/wordpad.exe\"";
         }
      } elsif (0<$#editors) {
         $selection=Term::Menus::Menu(\%Menu_select_editor);
         if ($selection=~/TextPad/) {
            if ($tp eq 'default') {
               $editor="\"/cygdrive".
                  "/c/Program Files/TextPad 5/TextPad.exe\"";
            } else {
               $tp=~s/\\/\//g;
               $tp=~s/^([A-Za-z]):(.*)/$1$2/;
               $editor="\"/cygdrive/$tp\"";
            }
         } elsif ($selection=~/vim/) {
            $editor='"/bin/vim-nox.exe"';
         } elsif ($selection=~/emacs/) {
            $editor='"/bin/emacs-nox.exe"';
         } elsif ($selection=~/joe/) {
            $editor='"/bin/joe.exe"';
         } elsif ($selection=~/mc/) {
            $editor='"/bin/mc.exe"';
         }
      } elsif (0==$#editors) {
         $selection=$editors[0];
      }
      exit if $selection eq ']quit[';
      my $url='http://www.cygwin.com/setup.exe';
      if ($CPAN::META->has_usable('LWP')) {
         FA::LWP::UserAgent->config;
         print "Fetching with LWP:\n  $url\n";
         my $Ua;
         eval { $Ua = FA::LWP::UserAgent->new; };
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
         $Ua->show_progress('true value');
         my $req = HTTP::Request->new(GET => $url);
         $req->header('Accept' => 'text/html');
         my $res = $Ua->request($req);
         if ($res->is_success) {
            print " + request successful.\n"
               if $CPAN::DEBUG;
            open(CP,">setup.exe") || die $!;
            binmode(CP);
            print CP $res->content;
         } elsif ($res->status_line=~/403/) {
            $url='http://www.fullautosoftware.net/download/setup.exe'; 
            $req = HTTP::Request->new(GET => $url);
            $req->header('Accept' => 'text/html');
            $res = $Ua->request($req);
            if ($res->is_success) {
               print " + request successful.\n"
                  if $CPAN::DEBUG;
               open(CP,">setup.exe") || die $!;
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
                  open(CP,">setup.tar.gz") || die $!;
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
         chmod 0755, 'setup.exe';
         my $setup_cmd='';
         if ($selection!~/[Ww]ordpad/s) {
            $setup_cmd='cmd /c ".\\setup.exe -P gcc4-core,gcc4-g++,'
                      .'make,openssh,perl,perl-libwin32,db4.5,'
                      .'libdb4.5-devel,ncurses,cron'
                      .$selection.' -X -A -q '
                      .'-s http://cygwin.mirrors.pair.com"';
         } else {
            $setup_cmd='cmd /c ".\\setup.exe -P gcc4-core,gcc4-g++,'
                      .'make,openssh,perl,perl-libwin32,db4.5,'
                      .'libdb4.5-devel,ncurses,cron'
                      .' -X -A -q -s http://cygwin.mirrors.pair.com"';
         }
         if ($selection=~/[Ww]ordpad/) {
            $editor='"'.'/cygdrive'.
               '/c/Program Files/Windows NT/Accessories/wordpad.exe'.'"';
         } else {
            $editor="/bin/${selection}.exe";
         }
         my $pwd=`cmd /c chdir`;
         chmod($pwd);
         my $cygpath=$pwd;
         $cygpath=~s/^(.):/\/cygdrive\/$1/;
         $cygpath=~s/\\/\//g;
         system($setup_cmd);
         if ($^O eq 'cygwin') {
            system('cmd /c C:\\\\cygwin\\\\bin\\\\bash -lc '.
                   '"/usr/bin/cpan -i Net::FullAuto"');
         } else {
            system('cmd /c C:\\cygwin\\bin\\bash -lc '.
                   '"/usr/bin/cpan -i Net::FullAuto"');
         }
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

unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
   my @editors=();
   my $banner="   In order is use the integrated edit features\n".
              "   you will need to choose an editor.";
   if ($^O eq 'cygwin') {
      my $tp='';
      my $mount=`/bin/mount -p`;
      $mount=~s/^.*(\/\S+).*$/$1/s;
      unless ($tp=&fa_find_editor('TextPad.exe')) {
         if (-e $mount."/c/Program Files/TextPad 5/TextPad.exe") {
            $tp='default';
         }
      }
      if ($tp) {
         push @editors, 'TextPad (The Text Editor for Windows)';
      }
      my $wordpad=0;
      if (-e $mount.
             "/c/Program Files/Windows NT/Accessories/wordpad.exe") {
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
      }
      if ($selection=~/TextPad/) {
         if ($tp eq 'default') {
            $editor="\"$mount".
               "/c/Program Files/TextPad 5/TextPad.exe\"";
         } else {
            $tp=~s/\\/\//g;
            $tp=~s/^([A-Za-z]):(.*)/$1$2/;
            $editor="\"$mount/$tp\"";
         }
      } elsif ($selection=~/vim/) {
         $editor='"/bin/vim-nox.exe"';
      } elsif ($selection=~/emacs/) {
         $editor='"/bin/emacs-nox.exe"';
      } elsif ($selection=~/joe/) {
         $editor='"/bin/joe.exe"';
      } elsif ($selection=~/mc/) {
         $editor='"/bin/mc.exe"';
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
         if ($selection=~/vi/) {
            $editor='"/usr/bin/vi"';
         } elsif ($selection=~/emacs/) {
            $editor='"/usr/bin/emacs"';
         }
      } elsif (1==$#editors) {
         $editor=$editors[0];
      } else {
         $editor='\'\'';
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
if ($get_BerkeleyDB) {
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
      my $header_to_use='';my $dblib='';my $ver='';
      foreach my $vr (reverse sort keys %verhash) {
         $header_to_use=$verhash{$vr};
         $vr=~s/^(^\d+[.]\d+).*$/$1/;
         chomp($vr);
         $ver=$vr;
         my $find_cmd="${findpath}find /usr -name \"libdb-".$ver.".a\"";
         my @lib=`$find_cmd`;
         chomp($lib[0]);$dblib=$lib[0];last;
      }
      my $major_minor_ver=substr($ver,0,(rindex $ver,'.'));
      if ($ENV{AUTOMATED_TESTING} || ($dblib && $major_minor_ver>=5.1)) {
         $dblib=~s/^(.*)\/.*$/$1/;
         $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
         $ENV{'BERKELEYDB_LIB'}=$dblib;
         $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
         $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
         $ENV{'DB_FILE_LIB'}=$dblib;
         $ENV{'DB_FILE_NAME'}="-ldb-$ver";
         $ENV{'LD_LIBRARY_PATH'}=$dblib;
      } else {
         my $url=
            'http://www.oracle.com/technetwork/'.
            'database/berkeleydb/downloads/index.html';
         if ($CPAN::META->has_usable('LWP')) {
            FA::LWP::UserAgent->config;
            print "Fetching with LWP:\n  $url\n";
            my $Ua;
            eval { $Ua = FA::LWP::UserAgent->new; };
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
               $req = HTTP::Request->new(GET => $source);
               $req->header('Accept-Encoding' => 'gzip, compress');
               $Ua->show_progress('true value');
               $res = $Ua->request($req);
               if ($res->is_success) {
                  print " + request successful.\n"
                     if $CPAN::DEBUG;
                  print $fh $res->content;
                  close $fh;
               } elsif ($res->is_error(500)) {
                  print(sprintf(
                     "LWP failed with code[%s], message[%s]\n".
                     "Please check your connection to the Internet!\n",
                     $res->code,
                     $res->message,
                  ));
               }
               print(qq{ + saved content to $file \n})
               if $CPAN::DEBUG;
               `$CPAN::Config->{gzip} -d $filename`;
               unless ($CPAN::Config->{gzip}) {
                  if (-e '/usr/bin/gzip') {
                     $CPAN::Config->{gzip}='/usr/bin/gzip';
                  } elsif (-e '/usr/local/bin/gzip') {
                     $CPAN::Config->{gzip}='/usr/local/bin/gzip';
                  }
               }
               unless ($CPAN::Config->{tar}) {
                  if (-e '/usr/bin/tar') {
                     $CPAN::Config->{tar}='/usr/bin/tar';
                  } elsif (-e '/usr/local/bin/tar') {
                     $CPAN::Config->{tar}='/usr/local/bin/tar';
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
                  $dblib=$prefx.'lib';
                  $header_to_use=$prefx."include";
                  $ENV{'BERKELEYDB_INCLUDE'}=$header_to_use;
                  $ENV{'BERKELEYDB_LIB'}=$dblib;
                  $ENV{'BERKELEYDB_NAME'}="-ldb-$ver";
                  $ENV{'DB_FILE_INCLUDE'}=$header_to_use;
                  $ENV{'DB_FILE_LIB'}=$dblib;
                  $ENV{'DB_FILE_NAME'}="-ldb-$ver";
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
            my $BerkDownload='http://www.oracle.com/technetwork/database/'.
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
            if (eval '$>' and lc(`sudo -V`) =~ /version/) {
               system(
                  'sudo',$^X,"-MCPANPLUS","-e","install $p");
               eval "use $p;1" ||
                   system('sudo', $^X, "-MCPAN", "-e",
                     "CPAN::Shell->force('install',$p)")
            }
            eval {
               require CPANPLUS;
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
           "database/berkeleydb/downloads/index.html ).";
   }
   $die.="\n\n";
   die $die;
}

sub windows_xp {
   my $output=`cmd /c ver`;
   if ($output=~/Windows XP/s) {
      return 1;
   } else {
      return 0;
   }
}

if ($^O eq 'cygwin' && &windows_xp) {
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
         #exit;
      } elsif ($a=~/^[Yy]$/s) {
         $regc='cmd /c "REG ADD HKLM\\Software\\Microsoft\\Windows\\'.
               'CurrentVersion\\Explorer\\AlwaysUnloadDLL /ve /t REG_SZ /d 1" 2>&1';
         $outp=`$regc`;
         print $outp."\n";
      }

   }
}

#Specific dependencies
requires        'Module::Load::Conditional' => 0;
requires        'Task::Weaken'              => 0;
requires        'ExtUtils::Depends'         => 0;
requires        'B::Utils'                  => 0;
requires        'Data::Dump::Streamer'      => 0;
requires        'Digest::SHA'               => 0;
requires        'Digest::MD5'               => 0;
requires        'Term::Menus'               => 1.68;
requires        'Tie::Cache'                => 0;
requires        'Sort::Versions'            => 0;
requires        'Crypt::CBC'                => 0;
requires        'Crypt::DES'                => 0;
requires        'HTTP::Date'                => 0;
requires        'JSON'                      => 2.14;
requires        'IO::Pty'                   => 1.09;
requires        'IO::Capture::Stderr'       => 0;
requires        'IO::CaptureOutput'         => 0;
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
recommends      'Crypt::Rijndael'           => 0;

auto_install;

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
   open(FH,">bin/fullauto.exe");
   print FH "\n";
   close FH;
   install_script 'bin/fullauto.exe';
   unlink "bin/fullauto.exe";
} else {
   open(FH,">bin/fullauto");
   print FH "\n";
   close FH;
   install_script 'bin/fullauto';
   unlink "bin/fullauto";
}
install_script 'bin/fullauto.pl';

WriteAll;

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
      s/(PERM_G_X = \d+)/$1\nPERM_R+X = 555\nPERM_R-X = 550\nPERM_R_X = 500/m;
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
         $link="\t\$(NOECHO) $lnpath -f -s \$(DESTINSTALLSITESCRIPT)\/fullauto\$(EXE_EXT) ".
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
   unless (-e $Config{installsitelib}."/Net/FullAuto/Custom/fa_conf.pm") {
      $inherited .= "\t\$(SED) \'s/^#[ ]*our[ ]*\\(.\\)editor[ ]*[=].*/".
                 '\\1'."editor = $editor;/g\' ".
                 "<blib/lib/Net/FullAuto/Custom/fa_conf.pm >tmp_conf.pm\n".
                 "\t\$(MV) tmp_conf.pm blib/lib/Net/FullAuto/Custom/fa_conf.pm\n\n";
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

$FA::LWP::UserAgent::VERSION = $FA::LWP::UserAgent::VERSION = "1.94";

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
            "Warning: Term::ReadKey seems not to be available, your password will be echoed to the terminal!\n"
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
