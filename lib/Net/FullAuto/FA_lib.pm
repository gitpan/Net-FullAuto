package Net::FullAuto::FA_lib;

################################################################
#
#   WARNING:  THIS IS A ***BETA*** RELEASE OF Net::FullAuto
#
#   Net::FullAuto is powerful network process automation
#   software that has been in un-released development for
#   more than seven years. For this reason, you may find
#   it to be useful for many process automation projects.
#   Because it has been worked on for so long, it may appear
#   to work well, and pass a number of non-intensive tests.
#
#   DO NOT - I REPEAT - DO !!NOT!! USE IN A PRODUCTION
#   ENVIRONMENT! This is newly released software that has
#   not had the benefit of wide exposure - and the presence
#   of here-to-now undetected bugs and design flaws is a
#   virtual certainty. DO NOT USE IN IN/FOR A PROCESS WHERE
#   DATA LOSS IS UNRECOVERABLE. DO NOT USE IN/FOR A PROCESS
#   WHERE DATA INTEGRITY IS CRITICAL. DO NOT USE IN/FOR A
#   PROCESS THAT IS TIME SENSITIVE, UNMONITORED, OR
#   PERSISTENCE CRITICAL. DO NOT USE THIS SOFTWARE WITHOUT
#   ANOTHER METHOD FOR RUNNING THE PROCESS YOU WISH TO
#   AUTOMATE WITH Net::FullAuto. DO NOT USE IN/FOR A PROCESS
#   WHERE FAILURE OF "ANY KIND" IS UNACCEPTABLE.
#
################################################################

## For Testing Multiple Iterations in a BASH shell environment
#
#  num=0; while (( $num < 1000 )); do ./fullauto.pl --login *******
#  --password ******** --usr_code test_this --log; let num+=1; done

BEGIN {

   our $progname=substr($0,(rindex $0,'/')+1);
   our $OS=$^O;

   if ($^O eq 'cygwin') {
      require Win32::Semaphore;
   } else {
      if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
         print "\n       FATAL ERROR! : Cygwin Linux Emulation Layer".
               "\n                      is required to use FullAuto".
               "\n                      on Windows - goto www.cygwin.com.".
               "\n\n       \(Be sure to install OpenSSH and the sshd ".
               "service\).\n\n";
         exit;
      }
      require IPC::Semaphore;
      require IPC::SysV;import IPC::SysV qw(IPC_CREAT SETVAL);
   }
}

use warnings;
{
   no warnings;
   use Socket;
   require Exporter;
}

our @ISA     = qw(Exporter Net::Telnet Cwd);
our @EXPORT  = qw(%Hosts $localhost getpasswd
                  connect_host get_all_hosts
                  $username connect_ftp $cron
                  connect_telnet connect_sftp
                  send_email $log connect_ssh
                  connect_secure connect_insecure
                  connect_reverse $prod $random
                  freemem @invoked $cleanup pick
                  $progname memnow take_semaphore
                  give_semaphore $savetran %hours
                  $increment %month ls_timestamp
                  $clear cleanup $dest_first_hash
                  test_file test_dir timelocal
                  %GLOBAL @GLOBAL $MRLOG $OS
                  $funkyprompt handle_error $quiet);

{
   no warnings;
   use Sys::Hostname;
   our $local_hostname=hostname;
   use MLDBM::Sync;                      # this gets the default, SDBM_File
   use MLDBM qw(MLDBM::Sync::SDBM_File); # ext SDBM_File, handles values > 1024
   use Fcntl qw(:DEFAULT);               # import symbols O_CREAT & O_RDWR
   use Time::Local;
   use Crypt::CBC;
   use Crypt::DES;
   use Cwd qw(getcwd);
   use English;
   use Fcntl qw(:DEFAULT :flock);
   use Mail::Internet;
   use Mail::Sender;
   use Net::Telnet;
   use Getopt::Long;
   use Pod::Usage;
   use Term::ReadKey;
   use LWP::UserAgent ();
   use LWP::MediaTypes qw(guess_media_type media_suffix);
   use URI ();
   use HTTP::Date ();
   use IO::Handle;
   use IO::Select;
   use Symbol qw(qualify_to_ref);
   use Tie::Cache;
   use IO::Pty;
   use POSIX qw(setsid uname);
   use strict;
};

BEGIN {
   $ENV{OS}='' if !$ENV{OS};
   our $freemem_time=$^T;
   my $md_='';our $thismonth='';our $thisyear='';
   ($md_,$thismonth,$thisyear)=(localtime)[3,4,5];
   my $mo_=$thismonth;my $yr_=$thisyear;
   $md_="0$md_" if $md_<10;
   $mo_++;$mo_="0$mo_" if $mo_<10;
   my $yr__=sprintf("%02d",$yr_%100);
   my $yr____=(1900+$yr_);
   my $mdy="$mo_$md_$yr__";
   my $mdyyyy="$mo_$md_$yr____";
   my $tm=scalar localtime($^T);
   my $hms=substr($tm,11,8);
   $hms=~s/^(\d\d):(\d\d):(\d\d)$/h${1}m${2}s${3}/;
   my $hr=$1;my $mn=$2;my $sc=$3;
   our @invoked=($^T, $tm, $mdy, $hms, $hr, $mn, $sc, $mdyyyy);
   our @tran=('','',0,$$."_".$^T,'',0);
   our $curyear=$thisyear + 1900;
   our $curcen=unpack('a2',$curyear);

   our $home_dir=(getpwuid($<))[7];
   if ($home_dir eq '/' && defined $ENV{HOME}
         && $ENV{HOME} ne '/') {
      $home_dir=$ENV{HOME};
   }

   our $fa_hosts='';
   if (defined $main::fa_hosts) {
      if (-1<index $main::fa_hosts,'/') {
         require $main::fa_hosts;
         my $mc=substr($main::fa_hosts,
                (rindex $main::fa_hosts, '/')+1,-3);
         import $fh;
         $fa_hosts=$fh.'.pm';
      } else {
         require $main::fa_hosts;
         my $fh=substr($main::fa_hosts,0,-3);
         import $fh;
         $fa_hosts=$main::fa_hosts;
      }
   } else {
      require 'Net/FullAuto/fa_hosts.pm';
      import fa_hosts;
      $fa_hosts='fa_hosts.pm';
   }

   our $fa_maps='';
   if (defined $main::fa_maps) {
      if (-1<index $main::fa_maps,'/') {
         require $main::fa_maps;
         my $fm=substr($main::fa_maps,
                (rindex $main::fa_maps, '/')+1,-3);
         import $fm;
         $fa_maps=$fm.'.pm';
      } else {
         require $main::fa_maps;
         my $fm=substr($main::fa_maps,0,-3);
         import $fm;
         $fa_maps=$fm.'.pm';
      }
   } else {
      require 'Net/FullAuto/fa_maps.pm';
      import fa_maps;
      $fa_maps='fa_maps.pm';
   }

   our $fasetuid='fasetuid.pm';
   if (-f substr($0,0,(rindex $0,'/')+1).$fasetuid) {
      if ($> ne $< || $<==(stat $0)[4]) {
         require $fasetuid;
      } else {
         die "FATAL ERROR! - ".substr($0,0,(rindex $0,'/')+1).
             "$fasetuid exists but $0 is NOT running with setuid"
      }
   } elsif ($> ne $<) {
      die "FATAL ERROR! - ".Cannot Locate substr($0,0,(rindex $0,'/')+1).
          "$fasetuid required when $0 is running with setuid"
   } else { $fasetuid='' }

   our $bashpath='';
   if (-e '/usr/bin/bash') {
      $bashpath='/usr/bin/';
   } elsif (-e '/bin/bash') {
      $bashpath='/bin/';
   } elsif (-e '/usr/local/bin/bash') {
      $bashpath='/usr/local/bin/';
   }

   our $sedpath='';
   if (-e '/usr/bin/sed') {
      $sedpath='/usr/bin/';
   } elsif (-e '/bin/sed') {
      $sedpath='/bin/';
   } elsif (-e '/usr/local/bin/sed') {
      $sedpath='/usr/local/bin/';
   }

   our $pspath='';
   if (-e '/usr/bin/ps') {
      $pspath='/usr/bin/';
   } elsif (-e '/bin/ps') {
      $pspath='/bin/';
   } elsif (-e '/usr/local/bin/ps') {
      $pspath='/usr/local/bin/';
   }

   our $sshpath='';
   if (-e '/usr/bin/ssh') {
      $sshpath='/usr/bin/';
   } elsif (-e '/bin/ssh') {
      $sshpath='/bin/';
   } elsif (-e '/usr/local/bin/ssh') {
      $sshpath='/usr/local/bin/';
   }

   our $telnetpath='';
   if (-e '/usr/bin/telnet') {
      $telnetpath='/usr/bin/';
   } elsif (-e '/bin/telnet') {
      $telnetpath='/bin/';
   } elsif (-e '/usr/local/bin/telnet') {
      $telnetpath='/usr/local/bin/';
   }

   our $sftppath='';
   if (-e '/usr/bin/sftp') {
      $sftppath='/usr/bin/';
   } elsif (-e '/bin/sftp') {
      $sftppath='/bin/';
   } elsif (-e '/usr/local/bin/sftp') {
      $sftppath='/usr/local/bin/';
   }

   our $ftppath='';
   if (-e '/usr/bin/ftp') {
      $ftppath='/usr/bin/';
   } elsif (-e '/bin/ftp') {
      $ftppath='/bin/';
   } elsif (-e '/usr/local/bin/ftp') {
      $ftppath='/usr/local/bin/';
   }

   our $mountpath='';
   if (-e '/usr/bin/mount') {
      $mountpath='/usr/bin/';
   } elsif (-e '/bin/mount') {
      $mountpath='/bin/';
   } elsif (-e '/usr/local/bin/mount') {
      $mountpath='/usr/local/bin/';
   }

   our $killpath='';
   if (-e '/usr/bin/kill') {
      $killpath='/usr/bin/';
   } elsif (-e '/bin/kill') {
      $killpath='/bin/';
   } elsif (-e '/usr/local/bin/kill') {
      $killpath='/usr/local/bin/';
   }

   our $clearpath='';
   if (-e '/usr/bin/clear') {
      $clearpath='/usr/bin/';
   } elsif (-e '/bin/clear') {
      $clearpath='/bin/';
   } elsif (-e '/usr/local/bin/clear') {
      $clearpath='/usr/local/bin/';
   }

   our $tarpath='';
   if (-e '/usr/bin/tar') {
      $tarpath='/usr/bin/';
   } elsif (-e '/bin/tar') {
      $tarpath='/bin/';
   } elsif (-e '/usr/local/bin/tar') {
      $tarpath='/usr/local/bin/';
   }

   our $pingpath='';
   if ($OS eq 'cygwin') {
      my $windir=$ENV{'WINDIR'};
      $windir=~s/\\/\//g;
      $pingpath="$windir/system32/";
   } elsif (-e '/usr/bin/ping') {
      $pingpath='/usr/bin/';
   } elsif (-e '/bin/ping') {
      $pingpath='/bin/';
   } elsif (-e '/usr/local/bin/ping') {
      $pingpath='/usr/local/bin/';
   } elsif (-e '/etc/ping') {
      $pingpath='/etc/';
   }

}
our $blanklines='';our $clear='';our $oldpasswd='';
our $scrub=0;our $pcnt=0;our $chk_id='';our $d_sub='';
our $deploy_info='';our $f_sub='';our $updatepw=0;
our $shown='';our $websphere_not_running=0;
our $master_hostlabel='';our $cron=0;our $random=0;
our $parent_menu='';our @menu_args=();our $savetran=0;
our $MRLOG='';our @pid_ts=();our %drives=();
our $username='';our @passwd=('','');our $usr_code='';
our $localhost='';our %localhost=();
our @RCM_Link=();our @FTM_Link=();our $cleanup=0;
our $starting_memory=0;our $sub_module='';
our %sync_dbm_obj=();our %tiedb=();our @ascii_que=();
our %Connections=();our $tranback=0;our @ascii=();
our %base_excluded_dirs=();our %base_excluded_files=(); 
our %hours=();our %month=();our %Hosts=();our %Maps=();
our %same_host_as_Master=("__Master_${$}__"=>'-','localhost'=>'-');
our @same_host_as_Master=();our $dest_first_hash='';
our %file_rename=();our %rename_file=();our $quiet='';
our %filerename=();our %renamefile=();our $log='';
our %Processes=();our %shellpids=();our %ftpcwd=();
our @DeploySMB_Proxy=('');our @DeployRCM_Proxy=('');
our @DeployFTM_Proxy=('');our $master_transfer_dir='';
our %perms=();our @ApacheNode=();our $test=0;
our $prod=0;our $force_pause_for_exceed=0;
our $timeout=30;our $cltimeout='X';our $slave=0;
our %email_defaults=();our $increment=0;
our $email_defaults='';our %semaphores=();
our %base_shortcut_info=();our @dhostlabels=();
our $funkyprompt='\\\\137\\\\146\\\\165\\\\156\\\\153\\\\171\\\\120'.
                 '\\\\162\\\\157\\\\155\\\\160\\\\164\\\\137';
our $tieperms='0666';
our $tieflags=O_CREAT|O_RDWR;
our $specialperms='none';
{
   my $ex=$0;
   if ($^O eq 'cygwin') {
      $ex=~s/\.pl$/\.exe/;
   } else {
      $ex=~s/\.pl$//;
   }
   if (-u $ex) {
      umask(077);
      $tieperms=0;
      $specialperms='setuid';
   } elsif (-g $ex) {
      umask(007);
      $tieperms=0;
      $specialperms='setgid';
   }
};

%hours=('01'=>'01a','02'=>'02a','03'=>'03a','04'=>'04a',
        '05'=>'05a','06'=>'06a','07'=>'07a','08'=>'08a',
        '09'=>'09a','10'=>'10a','11'=>'11a','00'=>'12a',
        '13'=>'01p','14'=>'02p','15'=>'03p','16'=>'04p',
        '17'=>'05p','18'=>'06p','19'=>'07p','20'=>'08p',
        '21'=>'09p','22'=>'10p','23'=>'11p','12'=>'12p',
        '01a'=>'01','02a'=>'02','03a'=>'03','04a'=>'04',
        '05a'=>'05','06a'=>'06','07a'=>'07','08a'=>'08',
        '09a'=>'09','10a'=>'10','11a'=>'11','12a'=>'00',
        '01p'=>'13','02p'=>'14','03p'=>'15','04p'=>'16',
        '05p'=>'17','06p'=>'18','07p'=>'19','08p'=>'20',
        '09p'=>'21','10p'=>'22','11p'=>'23','12p'=>'12');

%month=('01'=>'Jan','02'=>'Feb','03'=>'Mar','04'=>'Apr',
        '05'=>'May','06'=>'Jun','07'=>'Jul','08'=>'Aug',
        '09'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec',
        'Jan'=>'01','Feb'=>'02','Mar'=>'03','Apr'=>'04',
        'May'=>'05','Jun'=>'06','Jul'=>'07','Aug'=>'08',
        'Sep'=>'09','Oct'=>'10','Nov'=>'11','Dec'=>'12');

%perms=('rwx'=>'7','rw-'=>'6','r-x'=>'5','r--'=>'4',
        '-wx'=>'3','-w-'=>'2','--x'=>'1','---'=>'0',
        'rwt'=>'7','rwT'=>'6','r-t'=>'5','r-T'=>'4',
        '-wt'=>'3','-wT'=>'2','--t'=>'1','--T'=>'0',
        'rws'=>'7','rwS'=>'6','r-s'=>'5','r-S'=>'4',
        '-ws'=>'3','-wS'=>'2','--s'=>'1','--S'=>'0');

@ascii=(['10','012','061','060'],['11','013','061','061'],
        ['12','014','061','062'],['13','015','061','063'],
        ['14','016','061','064'],['15','017','061','065'],
        ['16','020','061','066'],['17','021','061','067'],
        ['18','022','061','070'],['19','023','061','071'],
        ['20','024','062','060'],['21','025','062','061'],
        ['22','026','062','062'],['23','027','062','063'],
        ['24','030','062','064'],['25','031','062','065'],
        ['26','032','062','066'],['27','033','062','067'],
        ['28','034','062','070'],['29','035','062','071'],
        ['30','036','063','060'],['31','037','063','061'],
        ['32','040','063','062'],['33','041','063','063'],
        ['34','042','063','064'],['35','043','063','065'],
        ['36','044','063','066'],['37','045','063','067'],
        ['38','046','063','070'],['39','047','063','071'],
        ['40','050','064','060'],['41','051','064','061'],
        ['42','052','064','062'],['43','053','064','063'],
        ['44','054','064','064'],['45','055','064','065'],
        ['46','056','064','066'],['47','057','064','067'],
        ['48','060','064','070'],['49','061','064','071'],
        ['50','062','065','060'],['51','063','065','061'],
        ['52','064','065','062'],['53','065','065','063'],
        ['54','066','065','064'],['55','067','065','065'],
        ['56','070','065','066'],['57','071','065','067'],
        ['58','072','065','070'],['59','073','065','071'],
        ['60','074','066','060'],['61','075','066','061'],
        ['62','076','066','062'],['63','077','066','063'],
        ['64','100','066','064'],['65','101','066','065'],
        ['66','102','066','066'],['67','103','066','067'],
        ['68','104','066','070'],['69','105','066','071'],
        ['70','106','067','060'],['71','107','067','061'],
        ['72','110','067','062'],['73','111','067','063'],
        ['74','112','067','064'],['75','113','067','065'],
        ['76','114','067','066'],['77','115','067','067'],
        ['78','116','067','070'],['79','117','067','071'],
        ['80','120','070','060'],['81','121','070','061'],
        ['82','122','070','062'],['83','123','070','063'],
        ['84','124','070','064'],['85','125','070','065'],
        ['86','126','070','066'],['87','127','070','067'],
        ['88','130','070','070'],['89','131','070','071'],
        ['90','132','071','060'],['91','133','071','061'],
        ['92','134','071','062'],['93','135','071','063'],
        ['94','136','071','064'],['95','137','071','065'],
        ['96','140','071','066'],['97','141','071','067'],
        ['98','142','071','070'],['99','143','071','071']);

@ascii_que=@ascii;

#if ($OS ne 'cygwin') {
                        # If using an exceed X-window launched from
                        # a desktop icon and configured to launch
                        # this script/program automatically, then
                        # set $force_pause_for_exceed to pause the
                        # script before a forced exit following an
                        # error condition.
#print "HOMEDIR=$home_dir and UID=$UID and EUID=$EUID\n";<STDIN>;
#   open (FH,"<$home_dir/.sh_history") ||
#                    warn "Cannot open .sh_history file! : $!";
#   my @command_history=<FH>;
#   CORE::close(FH);
#   foreach (@command_history) {
#      if (/xterm/ and /$0/) {
#         $force_pause=1;last;
#      }
#   }
#}

our $version='Revision 051807';
# our $maintainer='Brian Kelly';
# our $maintainer_phone='';
#@RCM_Link=('telnet');
#@RCM_Link=('ssh','telnet');
#@RCM_Link=('telnet','http');
                                       # Options: telnet, ssh,
                                       #   telnet_proxy, ssh_proxy
                                       #   Order from left to right
                                       #   determines attempt order.
                                       #   Only one method is required.
#@FTM_Link=('ftp');
@FTM_Link=('sftp','ftp');
#@FTM_Link=('ftp','http');
                                       # Options: ftp sftp
                                       #   ftp_proxy sftp_proxy
                                       #   Same as above.
# Set clear
$clear=&setuid_cmd(["${clearpath}clear"],qr/\033.*J/);
my $count=0;

# Set Blanklines
if ($OS eq 'cygwin') {
   while ($count++!=5) { $blanklines.="\n" }
} else {
   while ($count++!=5) { $blanklines.="\n" }
}

# cleanup subroutine called during normal & abnormal terminations
sub cleanup {

   my @topcaller=caller;
   print "cleanup() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "cleanup() CALLER=",
      (join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::log &&
         -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   $log=(defined $_[1] && $_[1]) ? 1 : 0
      if !$log;
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }

   if ($OS eq 'cygwin') {
      if (keys %semaphores) {
         foreach my $ipc_key (keys %semaphores) {
            $semaphores{$ipc_key}->release(1);
            delete $semaphores{$ipc_key};
         }
      }
   } else {
      semctl(34, 0, SETVAL, -1);
   } my $tm='';my $ob='';my %cleansync=();
   my @clkeys=();$_[0]||='';
   foreach my $key (keys %sync_dbm_obj) {
      if (index $key,'_') {
         ($tm,$ob)=split /_/, $key;
         push @clkeys, $key;
      }
   }
   foreach my $key (@clkeys) {
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$key};
   }
   foreach my $key (keys %sync_dbm_obj) {
      $Net::FullAuto::FA_lib::sync_dbm_obj{$key}->UnLock;
   }
   my $new_cmd='';my $cmd='';my $clean_master='';
   my @cmd=();my %did_tran=();
   foreach my $hostlabel (keys %Processes) {
      foreach my $id (keys %{$Processes{$hostlabel}}) {
         foreach my $type (reverse sort keys
                           %{$Processes{$hostlabel}{$id}}) {
            my ($cnct_type,$id_type)=split /_/, $type;

my $show1="CNCT_TYPE=$cnct_type and HOSTLABEL=$hostlabel "
         ."and PROCESS=".$Processes{$hostlabel}{$id}{$type}
         ." and DeploySMB=$DeploySMB_Proxy[0]<==\n"; 
print $show1 if $debug;
print $Net::FullAuto::FA_lib::MRLOG $show1 if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

            if ($cnct_type eq 'cmd'
                    && $hostlabel eq $DeploySMB_Proxy[0]) {
print "WE ARE HERE\n";
               my ($cmd_fh,$cmd_pid,$shell_pid,$cmd)=
                  @{$Processes{$hostlabel}{$id}{$type}};
               if (defined fileno $cmd_fh) {
                  $cmd_fh->print("\004");
                  my $next=0;
                  eval {
                     while (my $line=$cmd_fh->get) {
print $Net::FullAuto::FA_lib::MRLOG "cleanup() LINE_1=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $line=~s/\s*$//s;
                        last if $line=~/_funkyPrompt_$/s;
                        last if $line=~/Killed by signal 2\.$/s;
                        ($stdout,$stderr)=&kill($shell_pid,9)
                           if &testpid($shell_pid);
                        if ($cmd_pid) {
                           if (&testpid($cmd_pid)) {
                              ($stdout,$stderr)=&kill($cmd_pid,9);
                              $next=1;return;
                           }
                        }
print "ONE003\n";
                        $cmd_fh->print("\003");
                     }
                  }; next if $next;
               }
               if ($@) {
print "clean_ERRORRRRR=$@\n" if $debug;
               } 
               if (exists $Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}) {
                  my $tmpdir=${$Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}}[0];
                  my $tdir=${$Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}}[1];
                  ($output,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$cmd_fh,
                    _hostlabel=>[ $hostlabel,'' ] },"cd $tmpdir");
                  ($output,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$cmd_fh,
                    _hostlabel=>[ $hostlabel,'' ] },"rm -rf $tdir");
               }
               foreach my $pid_ts (@pid_ts) {
                  $cmd_fh->cmd("rm -f *${pid_ts}*");
               }
               if ($cmd) {
                  # DO ps cmd and find pid and then kill
               }
               if ($tran[0] && !exists $did_tran{$hostlabel}) {
                  $clean_master=1;
                  $clean_master=2 if $tran[2];
                     if ($tran[1] eq $hostlabel &&
                        $tran[1] ne "__Master_${$}__" && !exists
                        $same_host_as_Master{$tran[1]}) {
                     my $cmd="cd $tran[0] | sed -e "
                            ."\'s/^/stdout: /\' 2>&1";
                     $cmd_fh->cmd($cmd);
                     $cmd_fh->cmd("rm -f transfer$tran[3]*tar");
                     if ($tran[2]) {
                        $cmd_fh->cmd('cd ..');
                     }
                     if ($tran[4] && !$savetran) {
                        $cmd_fh->cmd(
                           "cmd /c rmdir /s /q transfer$tran[3]");
                        if (&test_dir($cmd_fh,"transfer$tran[3]")) {
                           $cmd_fh->cmd(
                              "chmod -R 777 transfer$tran[3]");
                           $cmd_fh->cmd(
                              "cmd /c rmdir /s /q transfer$tran[3]");
                        }
                     }
                  } $did_tran{$hostlabel}='-';
               } ($stdout,$stderr)=&kill($shell_pid,9) if &testpid($shell_pid);
            }
            if ($cnct_type eq 'ftm') {
               my ($ftp_fh,$ftp_pid,$shell_pid,$ig_nore)=
                  @{$Processes{$hostlabel}{$id}{$type}};
#$ftp_fh->print("quote stat");
#while ($line=$ftp_fh->get) {
#   print "LINE=$line\n";
#   last if $line=~/ftp>\s*$/;
#};<STDIN>;
               if (defined fileno $ftp_fh) {
                  eval {
                     SC: while (defined fileno $ftp_fh) {
                        $ftp_fh->print("\004");
print "FTP_FH_ERRMSG=",$ftp_fh->errmsg,"\n" if $ftp_fh->errmsg;
                        while (my $line=$ftp_fh->get) {
print $Net::FullAuto::FA_lib::MRLOG "cleanup() LINE_2=$line\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "cleanup() LINE_2=$line<==\n";
                           last if $line=~/_funkyPrompt_$|
                              logout|221\sGoodbye/sx;
                           last SC if $line=~/Connection.*closed|Exit\sstatus\s0/s;
                           if ($line=~/^\s*$|^\s*exit\s*$/s) {
                              last SC if $count++==20;
                           } else { $count=0 }
                           if ($OS eq 'cygwin' ||
                                 (-1<index $line,'password:')) {
                              $ftp_fh->print("\004");
                           } else {
                              $ftp_fh->print('exit');
                              select(undef,undef,undef,0.02);
                              # sleep for 1/50th second;
                           }
                        }
                     }
                  };
                  if ($@) {
print "WHAT IS THE LINE_2 EVALERROR=$@<====\n" if $debug;
                     if ((-1<index $@,'read error: Connection aborted')
                           || (-1<index $@,'read timed-out')
                           || (-1<index $@,'filehandle isn')
                           || (-1<index $@,'input or output error')) {
                        $@='';
                     } else { die "$@       $!" }
                  }
               }
               if (($tran[0] || $hostlabel eq "__Master_${$}__")
                      && !exists $did_tran{$hostlabel}) {
                  $clean_master=1;
                  if ($OS eq 'cygwin') {
                     $clean_master=2 if $tran[2];
                     $clean_master=3 if $tran[4]
                        && $clean_master!=2;
                  } $did_tran{$hostlabel}='-';
               }
               ($stdout,$stderr)=&kill($shell_pid,9) if &testpid($shell_pid);
               ($stdout,$stderr)=&kill($ftp_pid,9) if &testpid($ftp_pid);
            } else {
               my ($cmd_fh,$cmd_pid,$shell_pid,$cmd)=
                  @{$Processes{$hostlabel}{$id}{$type}};
               if (defined fileno $cmd_fh) {
                  my $gone=1;my $was_a_local=0;
                  eval {
                     CC: while (defined fileno $cmd_fh) {
                        $cmd_fh->print("printf $funkyprompt");
                        while (my $line=$cmd_fh->get) {
print $Net::FullAuto::FA_lib::MRLOG "cleanup() LINE_3=$line\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "cleanup() LINE_3=$line<==\n";
                           last if $line=~/logout|221\sGoodbye/sx;
                           if (($line=~/Killed|_funkyPrompt_/s) ||
                                 ($line=~/[$%>#-:] ?$/s) ||
                                 ($line=~/sion denied.*[)][.]\s*$/s)) {
print $Net::FullAuto::FA_lib::MRLOG "cleanup() SHOULD BE LAST CC=$line\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "cleanup() SHOULD BE LAST CC=$line<==\n";
                              $gone=0;last CC;
                           } elsif (-1<index $line,
                                 'Connection to localhost closed') {
                              $was_a_local=1;
                              last CC;
                           } elsif ($line=~/Connection.*closed/s) {
                              last CC;
                           }
                           if ($line=~/^\s*$|^\s*exit\s*$/s) {
                              last CC if $count++==20;
                           } else { $count=0 }
                           #if ($OS eq 'cygwin' ||
                           if (-1<index $line,'password:'
                              || -1<index $line,'Permission denied') {
                              $cmd_fh->print("\004");
print "DO WE ESCAPE\n";
                           }
                        }
                     }
#print $Net::FullAuto::FA_lib::MRLOG "cleanup() SHOULD BE OUT OF CC\n";
#print "cleanup() SHOULD BE OUT OF CC<==\n";
                  };
print "WOW I ACTUALLY GOT OUT3 and GONE=$gone and WASALOCAL=$was_a_local AND CMD_ERR=",
   $cmd_fh->errmsg,"<==\n" if $debug;
#print "cleanup() I AM OUT OF CC\n";
print $Net::FullAuto::FA_lib::MRLOG
   "cleanup() I AM OUT OF CC and EVALERR=$@ ".
   "and WAS=$was_a_local and GONE=$gone<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($@) {
#print "WHAT IS THE LINE_3 EVALERROR=$@<====\n";
                     if ((-1<index $@,'read error: Connection aborted')
                           || (-1<index $@,'read timed-out')
                           || (-1<index $@,'filehandle isn')
                           || (-1<index $@,'input or output error')) {
                        $@='';
                     } else { die "$@       $!" }
                  }
print $Net::FullAuto::FA_lib::MRLOG "cleanup() I GOT TO WAS A LOCAL\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if (!$was_a_local && !$gone &&
                        exists $Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}) {
print $Net::FullAuto::FA_lib::MRLOG "IN !WASALOCAL AND !GONE<====\n";
print "IN !WASALOCAL AND !GONE<====\n";
                     my $tmpdir=${$Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}}[0];
                     my $tdir=${$Net::FullAuto::FA_lib::tmp_files_dirs{$cmd_fh}}[1];
                     ($output,$stderr)=Rem_Command::cmd(
                     { _cmd_handle=>$cmd_fh,
                       _hostlabel=>[ $hostlabel,'' ] },"cd $tmpdir");
                     ($output,$stderr)=Rem_Command::cmd(
                     { _cmd_handle=>$cmd_fh,
                       _hostlabel=>[ $hostlabel,'' ] },"rm -rf $tdir");
                  }
                  if ($tran[0] && !exists $did_tran{$hostlabel}) {
                     $clean_master=1;
                     if ($OS eq 'cygwin') {
                        $clean_master=2 if $tran[2];
                        $clean_master=3 if $tran[4]
                           && $clean_master!=2;
                     }
                     if (!$was_a_local && !$gone
                           && $tran[1] eq $hostlabel &&
                           $tran[1] ne "__Master_${$}__" && !exists
                           $same_host_as_Master{$tran[1]}) {
                        my $cmd="cd $tran[0] | sed -e "
                               ."\'s/^/stdout: /\' 2>&1";
                        $cmd_fh->print($cmd);
                        while (my $line=$cmd_fh->get) {
                           last if $line=~/_funkyPrompt_/;
                        }
                        $cmd_fh->cmd("rm -f transfer$tran[3]*tar")
                           if !$savetran;
                        if ($tran[2]) {
                           $cmd_fh->cmd('cd ..');
                        }
                        if ($tran[4]) {
                           $cmd_fh->cmd(
                              "cmd /c rmdir /s /q transfer$tran[3]")
                              if !$savetran;
                           if (&test_dir($cmd_fh,"transfer$tran[3]")) {
                              $cmd_fh->cmd(
                                 "chmod -R 777 transfer$tran[3]");
                              $cmd_fh->cmd(
                                 "cmd /c rmdir /s /q transfer$tran[3]")
                                 if !$savetran;
                           }
                        }
                     } $did_tran{$hostlabel}='-';
                  } elsif ($tran[3] && !$savetran) {
#print "ARE WE HERE??? and GONE=$gone and WASALOCAL=$was_a_local\n";
                     if ($was_a_local) {
                        $localhost->cmd("rm -f transfer$tran[3]*tar");
                     } elsif (!$gone) {
                        if ($alarm_sounded) {
                           print "WE ARE TRYING SOMETHING and ALRM SOUNDED\n";
                           $cmd_fh->print("\003");
                           print "WOW - GOT TO CLEAN_FILEHANDLE\n";
                           my $c_out='';my $c_err='';
                           #($c_out,$c_err)=&clean_filehandle($cmd_fh);
                           #if ($c_err) {
                              ($stdout,$stderr)=&kill($shell_pid,9);
                              ($stdout,$stderr)=&kill($cmd_pid,9);
                              #last;
                           #}
                           print "GOT OUT OF CLEAN_FILEHANDLE\n";
                           last;
                        }
                        $cmd_fh->print("rm -f transfer$tran[3]*tar");
                        my $lin='';my $cownt=0;
                        eval {
                           while (my $line=$cmd_fh->get) {
                              $lin.=$line;
                              $lin=~s/\s*$//s;
                           if ($lin=~/_funkyPrompt_/s ||
                                    $lin=~/assword: ?$/m ||
                                    $lin=~/Exit\sstatus\s0/m ||
                                    $lin=~/sion denied.*[)][.]\s*$/s ||
                                    $lin=~/[$|%|>|#|-|:] ?$/s) {
                                 last;
                              } elsif ($lin=~/(Connection.+close.+)$|
                                    Exit\sstatus\s-1$|
                                    Killed\sby\ssignal\s2\.$/xm) {
                                 my $one=$1;$one||='';
                                 if ($one=~/local.+close/) {
                                    $was_a_local=1;last;
                                 } elsif ($one=~/Connection clo/) {
                                    $gone=1;last;
                                 }
                              } elsif ($cownt++<20) {
                                 $gone=1;last;
                              } else { print "TWO003\n";$cmd_fh->print("\003") }
                           }
                        };
                     }
                  }
print $Net::FullAuto::FA_lib::MRLOG "GOT EVEN FARTHER HERE\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($was_a_local) {
                     foreach my $pid_ts (@pid_ts) {
                        $localhost->cmd("rm -f *${pid_ts}*");
                     }
                  } elsif (!$gone) {
                     foreach my $pid_ts (@pid_ts) {
                        $cmd_fh->cmd("rm -f *${pid_ts}*");
                     }
                  }
                  if (!$was_a_local && !$gone) {
                     $cmd_fh->autoflush(1);
                     eval {
                        $cmd_fh->print('exit');
                        while (my $line=$cmd_fh->get) {
                           $line=~s/\s//g;
                           if ($line=~/onnection.*close/
                                 || $line=~/_funkyPrompt_/
                                 || $line=~/siondenied.*[)][.]$/
                                 || $line=~/logout/
                                 || $line=~/cleanup/
                                 || $line=~/Exitstatus(0|-1)/
                                 || $line=~/[$|%|>|#|-|:]$/) {
                              $cmd_fh->close;last;
                           }
                        }
                     };
                  }
                  if (&testpid($shell_pid)) {
                     eval {
                        print $Net::FullAuto::FA_lib::MRLOG
                           "WHAT IS SHELL_PID=$shell_pid "
                           if $Net::FullAuto::FA_lib::log &&
                           -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     };
                     print $Net::FullAuto::FA_lib::MRLOG
                        "LINE ".__LINE__." ERROR=$@\n"
                        if $@ && $Net::FullAuto::FA_lib::log &&
                        -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     eval {
                        print $Net::FullAuto::FA_lib::MRLOG
                           "and \$\$=$$ and ".
                           "$localhost->{_shell_pid}\n"
                           if $Net::FullAuto::FA_lib::log &&
                           -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     };
                     print $Net::FullAuto::FA_lib::MRLOG
                        "LINE ".__LINE__." ERROR=$@\n"
                        if $@ && $Net::FullAuto::FA_lib::log &&
                        -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     ($stdout,$stderr)=&kill($shell_pid,9)
                  }
print $Net::FullAuto::FA_lib::MRLOG "GETTING READY TO KILL!!!!! CMD\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  ($stdout,$stderr)=&kill($cmd_pid,9) if &testpid($cmd_pid);
               }
            }
         }
      }
   }
   if ($clean_master) {
print $Net::FullAuto::FA_lib::MRLOG "cleanup() GOING TO CLEAN MASTER"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "GOING TO CLEAN MASTER\n";
      if ($tran[3]) {
         $localhost->{_cmd_handle}->print("\003");
         ($output,$stderr)=&clean_filehandle($localhost->{_cmd_handle});
         if (!$stderr) {
            ($output,$stderr)=$localhost->cmd("cd $master_transfer_dir");
         }
         &handle_error("CLEANUP ERROR -> $stderr",'-1')
            if $stderr;
         ($output,$stderr)=
            $localhost->cmd("rm -f transfer${tran[3]}*tar");
         ($output,$stderr)=
            $localhost->cmd("rm -f transfer${tran[3]}*tar")
            if $stderr;
         &handle_error("CLEANUP ERROR -> $stderr",'-1')
            if $stderr;
         if ($OS eq 'cygwin') {
            if ($clean_master==2) {
               $localhost->cmd('cd ..');
            }
            if ($clean_master==2 || $clean_master==3) {
               $localhost->cmd(
                  "cmd /c rmdir /s /q transfer$tran[3]");
               if (&test_dir($localhost->{_cmd_handle},
                      "transfer$tran[3]")) {
                  $localhost->cmd(
                     "chmod -R 777 transfer$tran[3]");
                  $localhost->cmd(
                     "cmd /c rmdir /s /q transfer$tran[3]")
                     if !$savetran;
               }
            }
         }
      }
      foreach my $pid_ts (@pid_ts) {
         $localhost->cmd("rm -f *${pid_ts}*");
      }
   }
   ($stdout,$stderr)=&kill($localhost->{_cmd_pid},9);
   ($stdout,$stderr)=&kill($localhost->{_sh_pid},9);
   %{$localhost}=();$localhost='';
   %Processes=();
   %Connections=();
   @pid_ts=();
   if (defined $master_hostlabel &&
         defined $username) {
      &scrub_passwd_file($master_hostlabel,
         $username);
   }
   if ((!$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug)
         && !$Net::FullAuto::FA_lib::quiet) {
      if ($OS ne 'cygwin') {
         print "\n";
      } else {
         print "\n\n";
      }
   } ReadMode 0;
print $Net::FullAuto::FA_lib::MRLOG "GOING TO CLOSE LOG\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   $MRLOG||='';
   CORE::close($MRLOG) if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   $MRLOG='';
   if (!$Net::FullAuto::FA_lib::log && exists $Hosts{"__Master_${$}__"}{'LogFile'}
         && $Hosts{"__Master_${$}__"}{'LogFile'}) {
      unlink $Hosts{"__Master_${$}__"}{'LogFile'};
   }
   print "FULLAUTO COMPLETED SUCCESSFULLY on ".localtime()."\n"
      if (!$Net::FullAuto::FA_lib::cron && !$Net::FullAuto::FA_lib::stdio)
         && !$Net::FullAuto::FA_lib::quiet;
   return 1 if $_[0];
   exit 0;

};

# Handle INT SIGNAL interruption
$SIG{ INT } = sub{ print "CAUGHT A SIG!!\n";$log=1;$cleanup=1;&cleanup() };
our $alarm_sounded=0;
$SIG{ ALRM } = sub{ open(AL,">>ALRM.txt");
                    print AL scalar(localtime())."\n";
                    close AL;
                    $alarm_sounded=1;
                    print "CAUGHT AN ALRM!!\n";
                    $log=1;$cleanup=1;&cleanup() };
$SIG{ CHLD } = 'IGNORE';
#$SIG{ INT } = sub{ &cleanup() };

my @Hosts_tmp=@{&check_Hosts($fa_hosts)};
my @Hosts=();
if ($fasetuid) {
   my %setuid_hash=();my %labels=();
   foreach my $setuid (@{&check_Hosts($fasetuid)}) {
      if (exists $labels{${$setuid}{'Label'}}) {
         &handle_error(
            "DUPLICATE LABEL DETECTED - ${$setuid}{'Label'}".
            "\n       In File - $fasetuid");
      } $labels{${$setuid}{'Label'}}='';
      $setuid_hash{${$setuid}{'Label'}}=$setuid;
   }
   foreach my $host (@Hosts_tmp) {
      my %tmphash=();
      if (exists $setuid_hash{${$host}{'Label'}}) {
         foreach my $key (keys %{$host}) {
            if (exists ${$setuid_hash{${$host}{'Label'}}}{$key}) {
               $tmphash{$key}=
                  ${$setuid_hash{${$host}{'Label'}}}{$key};
            } else {
               $tmphash{$key}=${$host}{$key};
            }
         }
         foreach my $key (keys %{$setuid_hash{${$host}{'Label'}}}) {
            if (!exists $tmphash{$key}) {
               $tmphash{$key}=${$setuid_hash{${$host}{'Label'}}}{$key};
            }
         }
         push @Hosts, \%tmphash if keys %tmphash;
      } else {
         push @Hosts, {%{$host}};
      }
   }
   foreach my $hash (@Hosts_tmp) {
      foreach my $key (keys %{$hash}) {
         if (ref $hash{$key} eq ARRAY) {
            undef @{$hash{$key}};
            delete $hash{$key};
         } elsif (ref $hash{$key} eq HASH) {
            undef %{$hash{$key}};
            delete $hash{$key};
         } else {
            undef $hash{$key};
            delete $hash{$key};
         }
      } undef %{$hash};
   } undef @Hosts_tmp;
} else { @Hosts=@Hosts_tmp;undef @Hosts_tmp }

sub pick
{
   return &Menus::pick(@_);
}

sub ls_timestamp
{

   my $line=$_[0];my $size='';
   my $mn='';my $dy='';my $time='';my $fileyr='';
   my $rx1=qr/\d+\s+\w\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
   my $rx2=qr/\d+\s+\w\w\w\s+\d+\s+\d\d\d\d\s+.*/;
   if ($line=~s/^.*\s+($rx1|$rx2)$/$1/) {
      $line=~/^(\d+)\s+(\w\w\w)\s+(\d+)\s+(\d\d:\d\d\s+|\d\d\d\d\s+)+.*$/;
      $size=$1;$mn=$Net::FullAuto::FA_lib::month{$2};$dy=$3;$time=$4;
   }
   my $hr=12;my $mt='00';
   if (length $time==4) {
      $fileyr=$time;
   } else {
      ($hr,$mt)=unpack('a2 @3 a2',"$time");
      my $yr=unpack('x1 a2',"$Net::FullAuto::FA_lib::thisyear");
      $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
      if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
         --$yr;
         $yr="0$yr" if 1==length $yr;
         $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
      } elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
         my $filetime=&Net::FullAuto::FA_lib::timelocal(
            0,$mt,$hr,$dy,$mn-1,$fileyr);
         if (time()<$filetime) {
            --$yr;
            $yr="0$yr" if 1==length $yr;
            $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
         }
      }
   }
   return $size, timelocal(0,$mt,$hr,$dy,$mn-1,$fileyr);

}

sub sysreadline(*;$) {
   my($handle, $timeout) = @_;
   $handle = qualify_to_ref($handle, caller());
   my $infinitely_patient = (@_ == 1 || $timeout < 0);
   my $start_time = time();
   my $selector = IO::Select->new();
   $selector->add($handle);
   my $line = '';
SLEEP:
   until (at_eol($line)) {
      unless ($infinitely_patient) {
         return $line if time() > ($start_time + $timeout);
      }
      #sleep only 1 second before checking again
      next SLEEP unless $selector->can_read(1.0);
INPUT_READY:
      while ($selector->can_read(0.0)) {
         my $was_blocking = $handle->blocking(0);
CHAR:    while (sysread($handle, my $nextbyte, 1)) {
            $line .= $nextbyte;
            last CHAR if $nextbyte eq "\n"; 
         }
         $handle->blocking($was_blocking);
         # if incomplete line, keep trying
         next SLEEP unless at_eol($line);
         last INPUT_READY;
      }
   }
   return $line;
} sub at_eol($) { $_[0] =~ /\n\z/ }

sub give_semaphore
{
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }
   my @topcaller=caller;
   print "give_semaphore() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "give_semaphore() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#$Net::FullAuto::FA_lib::log=0 if $logreset;
   $semnum=$_[0];
   $semnum||=0;
   $sem=$_[1];
   $semflag=$_[2];
   $semflag||=0;
   if ($^O eq 'cygwin' && exists $Net::FullAuto::FA_lib::semaphores{$semnum}) {

      # Decrement the semaphore count

      $Net::FullAuto::FA_lib::semaphores{$semnum}->release(1);
      delete $Net::FullAuto::FA_lib::semaphores{$semnum};

   } elsif (0) {

      # Decrement the semaphore count
      $semop = -1;
      my $opstring = pack("sss", $semnum, $semop, $semflag);

      semop($sem,$opstring) || die "$!";

   }
}

sub test_semaphore
{
   my @topcaller=caller;
   print "test_semaphore() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "test_semaphore() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   #my $sem=$_[0];
   #$sem||='';
   my $IPC_KEY=$_[0];
   $IPC_KEY||=1234;

   my $opstring='';
   my $opstring1='';
   my $opstring2='';
   my $semnum=0;
   my $semop=0;
   my $semflag=0;
   if ($^O eq 'cygwin') {

      # try to open a semaphore
      if (Win32::Semaphore->open($IPC_KEY)) {
         return 1;
      } else {
         return 0;
      }

   } elsif (0) {

   }

}

sub take_semaphore
{
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }

   my @topcaller=caller;
   print "take_semaphore() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "take_semaphore() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#$Net::FullAuto::FA_lib::log=0 if $logreset;
   $sem='';
   my $IPC_KEY=(defined $_[0] && $_[0])?$_[0]:'1234';
   my $opstring='';
   my $opstring1='';
   my $opstring2='';
   my $semnum=0;
   my $semop=0;
   my $semflag=0;
   if ($^O eq 'cygwin') {
      # try to open a semaphore
      my $sem=Win32::Semaphore->open($IPC_KEY);
      if (defined $sem && $sem) {
         # wait for semaphore to be zero
         $sem->wait($timeout * 2000) ||
            die "Win32 Semaphore Timed Out:\n\n       Called by "
                . join ' ', @topcaller;
      }

      # create a semaphore
      $Net::FullAuto::FA_lib::semaphores{$IPC_KEY}=Win32::Semaphore->new(0,10,$IPC_KEY);

   } elsif (0) {
      # create a semaphore
      $sem = semget($IPC_KEY, 10, $Net::FullAuto::FA_lib::tieperms | IPC_CREAT ) || die "$!";

      # 'take' semaphore
      # wait for semaphore to be zero
      $opstring1 = pack("sss", $semnum, $semop, $semflag);

      # Increment the semaphore count
      $semop = -1;
      $opstring2 = pack("sss", $semnum, $semop,  $semflag);
      $opstring = $opstring1 . $opstring2;

      semop($sem,$opstring) || die "$!";

   }
#$Net::FullAuto::FA_lib::log=0 if $logreset;
 return $sem
}

sub kill
{
   my @topcaller=caller;
   print "kill() CALLER="
      ,(join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "kill() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   $pid=$_[0];$arg=$_[1];$arg||='';my $cmd='';
   my $stdout='';my $ignore='';
   if (exists $Hosts{"__Master_${$}__"}{'kill'}) {
      $killpath=$Hosts{"__Master_${$}__"}{'kill'};
      $killpath.='/' if $killpath!~/\/$/;
   }
   if (exists $Hosts{"__Master_${$}__"}{'bash'}) {
      $bashpath=$Hosts{"__Master_${$}__"}{'bash'};
      $bashpath.='/' if $bashpath!~/\/$/;
   }
   if (exists $Hosts{"__Master_${$}__"}{'sed'}) {
      $sedpath=$Hosts{"__Master_${$}__"}{'sed'};
      $sedpath.='/' if $sedpath!~/\/$/;
   }
   if ($pid) {
      if ($arg) {
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            $cmd=[ "${killpath}kill -$arg $pid 2>&1" ]
                   #." | ${sedpath}sed -e 's/^/stdout: /' 2>&1" ]
         } else {
            $cmd=[ "${bashpath}bash",'-c',"${killpath}kill -$arg $pid 2>&1" ]
                   #." | ${sedpath}sed -e 's/^/stdout: /' 2>&1" ]
         }
         #$cmd="${killpath}kill $arg $pid 2> /dev/null";
      } else {
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            $cmd=[ "${killpath}kill $pid 2>&1" ]
                   #." | ${sedpath}sed -e 's/^/stdout: /' 2>&1" ]
         } else {
            $cmd=[ "${bashpath}bash",'-c',"${killpath}kill $pid 2>&1" ]
                   #." | ${sedpath}sed -e 's/^/stdout: /' 2>&1" ]
         }
         #$cmd="${killpath}kill $pid";
      }
   }
print $Net::FullAuto::FA_lib::MRLOG "BEFOREKILL -> ",join ' ',@{$cmd},"\n"
      if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   ($ignore,$stdout)=&setuid_cmd($cmd,5);
   $stdout||='';
print $Net::FullAuto::FA_lib::MRLOG "KILL -> ",join ' ',@{$cmd},
      " and STDOUT=$stdout<==\n"
      if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if (wantarray) {
      return $stdout,'';
   } elsif ($stderr) {
      &Net::FullAuto::FA_lib::handle_error($stderr);
   } else { return $stdout }
}

sub testpid
{
   my @topcaller=caller;
   print "testpid() CALLER="
      ,(join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "testpid() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   $pid=$_[0];
   if (!$pid) {
      if (wantarray) {
         return 0,'';
      } else { return 0 }
   }
   if (exists $Hosts{"__Master_${$}__"}{'kill'}) {
      $killpath=$Hosts{"__Master_${$}__"}{'kill'};
      $killpath.='/' if $killpath!~/\/$/;
   }
   if (exists $Hosts{"__Master_${$}__"}{'bash'}) {
      $bashpath=$Hosts{"__Master_${$}__"}{'bash'};
      $bashpath.='/' if $bashpath!~/\/$/;
   }
   if (exists $Hosts{"__Master_${$}__"}{'sed'}) {
      $sedpath=$Hosts{"__Master_${$}__"}{'sed'};
      $sedpath.='/' if $sedpath!~/\/$/;
   }
   $cmd=[ "${bashpath}bash",'-c',"if ${killpath}kill -0 $pid"
          ." 2> /dev/null\012then echo 1\012else echo 0\012fi"
          ." | ${sedpath}sed -e \'s/^/stdout: /' 2>&1" ];
   my $stdout=0;my $stderr='';
   ($stdout,$stderr)=&setuid_cmd($cmd,5);
   chomp $stdout;chomp $stderr;
print $Net::FullAuto::FA_lib::MRLOG "TESTPIDCMD=${$cmd}[0] and STDOUT=$stdout<== and STDERR=$stderr<==\n"
      if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if (wantarray) {
      return $stdout, $stderr;
   } elsif ($stdout==1) {
      return $stdout;
   } elsif ($stderr) {
      &Net::FullAuto::FA_lib::handle_error($stderr);
   } else { return $stdout }
}

sub get_master_info
{

   my $Local_HostName='';my $Local_FullHostName='';
   my $Local_IP_Address='';
   $Local_HostName=(uname)[1];
   $Local_HostName=hostname if !$Local_HostName;
   my $addr='';
   if ($OS ne 'cygwin') {
      $addr=gethostbyname($Local_HostName) ||
          &handle_error(
          "Couldn't Resolve Local Hostname $Local_HostName : ");
      my $gip=sprintf "%vd", $addr;
      $same_host_as_Master{$gip}='-';
      ${$Local_IP_Address}{$gip}='-';
      $Local_FullHostName=gethostbyaddr($addr,AF_INET) ||
         handle_error(
         "Couldn't Re-Resolve Local Hostname $Local_HostName : ");
   } else {
      my $route=cmd('cmd /c route print',3);
      my $getip=0;
      foreach my $line (split /^/, $route) {
         if (!$getip) {
            if (-1<index $line, 'Metric') {
               $getip=1;
            } else { next }
         } else {
            my $gip=(split ' ', $line)[3];
            next if !$gip;
            $Local_IP_Address=$gip if !$Local_IP_Address;
            $same_host_as_Master{$gip}='-';
            next if $gip=~/\d+\.0\.0\.1/;
            ${$Local_IP_Address}{$gip}='-';
         }
      }
   }
   $Local_FullHostName=$Local_HostName if !$Local_FullHostName;

   $same_host_as_Master{"$Local_HostName"}='hostname';
   $same_host_as_Master{"$Local_FullHostName"}='fullhostname';
   return $Local_HostName,$Local_FullHostName,$Local_IP_Address;

}

sub check_Hosts
{

   our ($Local_HostName,$Local_FullHostName,$Local_IP_Address)=
      &get_master_info;
   my $chk_hostname='';my $chk_ip='';my $trandir_flag='';
   my $name=substr($_[0],0,-3);
   my @Hosts=eval "\@${name}::Hosts";
   foreach my $host (@Hosts) {
      my $hostn=(exists ${$host}{'HostName'})?lc(${$host}{'HostName'}):'';
      my $ipn=(exists ${$host}{'IP'})?${$host}{'IP'}:''; 
      if ($hostn eq lc($Local_FullHostName)) {
         $chk_hostname=$Local_FullHostName;
      } elsif ($hostn eq lc($Local_HostName)) {
         $chk_hostname=$Local_HostName;
      } elsif (exists ${$Local_IP_Address}{$ipn}) {
         $chk_ip=$ipn;
      } else { next }
      if ($chk_hostname || $chk_ip) {
         my $hash="\'Label\'=>\'__Master_${$}__\'\,";
         $same_host_as_Master{"${$host}{'Label'}"}='-';
         foreach my $key (keys %{$host}) {
            if ($key eq 'Label' || $key eq 'SMB_Proxy'
                  || $key eq 'RCM_Proxy'
                  || $key eq 'FTM_Proxy') {
               next;
            } elsif ($key eq 'HostName' && !$chk_hostname) {
               if (defined $Local_HostName) {
                  $hash.="\'HostName'=>\'".$Local_HostName."\'\,";
               } elsif (defined $Local_FullHostName) {
                  $hash.="\'HostName'=>\'".$Local_FullHostName."\'\,";
               } next;
            } elsif ($key eq 'IP' && !$chk_hostname && keys
                     %{$Local_IP_Address}) {
               $hash.="\'IP'=>\'".(keys %{$Local_IP_Address})[0]."\'\,";
               next;
            } elsif ($key eq 'TransferDir') {
               $hash.="\'TransferDir'=>\'".${$host}{$key}."\'\,";
               next;
            } 
            $hash.="\'$key'=>\'".${$host}{$key}."\'\,";
         } $hash.="\'Uname'=>\'".(uname)[0]."\'\,";
         unshift @Hosts, eval "\{ $hash \}";last;
      }
   }
   if (!$chk_hostname && !$chk_ip) {
      my $hostn='';my $ip='';my $label='';
      my $uname='';my $trandir='';
      if ($Local_FullHostName) {
         $hostn="\'HostName'=>\'$Local_FullHostName\'\,";
      } elsif ($Local_HostName) {
         $hostn="\'HostName'=>\'$Local_HostName\'\,";
      }
      if (keys %{$Local_IP_Address}) {
         $ip="'IP'=>\'(keys %{$Local_IP_Address})[0]\',";
      } $label="\'Label\'=>\'__Master_${$}__\',";
      $uname="'Uname'=>'".(uname)[0]."',";
      $local="'Local'=>'connect_ssh_telnet',";
      $remote="'Remote'=>'connect_host',";
      unshift @Hosts,
          eval "\{ $ip$hostn$label$uname$local \}";
   } return \@Hosts;

}

$Hosts{"__Master_${$}__"}{'HostName'}='' if
   !exists $Hosts{"__Master_${$}__"}{'HostName'};
$Hosts{"__Master_${$}__"}{'IP'}='' if
   !exists $Hosts{"__Master_${$}__"}{'IP'};
if (!exists $Hosts{"__Master_${$}__"}{'Cipher'}) {
   $Hosts{"__Master_${$}__"}{'Cipher'}='DES';
} else {
   eval "require " . $Hosts{"__Master_${$}__"}{'Cipher'};
   &handle_error($@) if $@;
}   

#sub check_Maps
#{
#   foreach my $map (@fa_maps::Maps) {
#      my $RCM_map=(exists ${$map}{'RCM'})?lc(${$map}{'RCM'}):'';
#      my $FCM_map=(exists ${$map}{'FCM'})?${$map}{'FCM'}:'';
#   }
#   unshift @fa_maps::Maps, eval "\{ $map \}";last;
#   unshift @fa_maps::Maps, eval "\{ $map \}";last;
#}

my %msproxies=();my %uxproxies=();my %labels=();
my %DeploySMB_Proxy=();my %DeployFTM_Proxy=();
my %DeployRCM_Proxy=();my $msflag='';my $uxflag='';
foreach my $host (@Hosts) {
   if (exists $labels{${$host}{'Label'}}) {
        &handle_error("DUPLICATE LABEL DETECTED - ${$host}{'Label'}");
   } $labels{${$host}{'Label'}}='';
   if (exists ${$host}{'SMB_Proxy'}) {
      if (exists $msproxies{${$host}{'SMB_Proxy'}} &&
            ${$msproxies{${$host}{'SMB_Proxy'}}}[0] eq ${$host}{'SMB_Proxy'}
            && ${$msproxies{${$host}{'SMB_Proxy'}}}[1] eq 'SMB_Proxy') {
         my $die="\n       FATAL ERROR! - Duplicate \"'SMB_Proxy' =>"
                ." \" Values Detected.\n\n       Hint:  No Host "
                ."Unit in $fa_hosts should have\n              "
                ."the same value for 'SMB_Proxy' =>\n\n       {\n"
                ."          ...\n\n          'SMB_Proxy' => 1,"
                ."\n          ...\n       },\n       {\n          "
                ."...\n\n          'SMB_Proxy' => 2,\n          ..."
                ."\n       },\n";
         &handle_error($die);
      } else {
         $msproxies{${$host}{'SMB_Proxy'}}
            =["${$host}{'SMB_Proxy'}",'SMB_Proxy'];
      }
   }
   if (exists ${$host}{'RCM_Proxy'}) {
      if (exists $uxproxies{${$host}{'RCM_Proxy'}} &&
            ${$uxproxies{${$host}{'RCM_Proxy'}}}[0] eq ${$host}{'RCM_Proxy'}
            && ${$uxproxies{${$host}{'RCM_Proxy'}}}[1] eq 'RCM_Proxy') {
         &handle_error("DUPLICATE \"RCM_Proxy\" HOSTUNIT DETECTED");
      } else {
         $uxproxies{${$host}{'RCM_Proxy'}}
            =["${$host}{'RCM_Proxy'}",'RCM_Proxy'];
      }
   }
   if (exists ${$host}{'FTM_Proxy'}) {
     if (exists $uxproxies{${$host}{'FTM_Proxy'}} &&
           ${$uxproxies{${$host}{'FTM_Proxy'}}}[0]
              eq ${$host}{'FTM_Proxy'}
           && ${$uxproxies{${$host}{'FTM_Proxy'}}}[1] eq 'FTM_Proxy') {
         &handle_error("DUPLICATE \"RCM_Proxy\" HOSTUNIT DETECTED");
      } else {
         $uxproxies{${$host}{'FTM_Proxy'}}
                =[${$host}{'FTM_Proxy'},'FTM_Proxy'];
      }
   }
   foreach my $key (keys %{$host}) {
#print "KEY=$key and LABEL=${$host}{'Label'}\n";
#print "VALUE=${$host}{$key}\n";
#print "CHK_HOST=${$host}{'Label'}\n";
      ${$Hosts{${$host}{'Label'}}}{$key}=${$host}{$key};
      if ($key eq 'SMB_Proxy') {
         if (exists $same_host_as_Master{${$host}{'Label'}}) {
            if (${$host}{'SMB_Proxy'}=~/^(\d+)$/) {
               $DeploySMB_Proxy{${$host}{'SMB_Proxy'}}
                  ="__Master_${$}__";
            } else { push @DeploySMB_Proxy, "__Master_${$}__" }
         } elsif (&ping(${$host}{'IP'},'__return__') ||
                  &ping(${$host}{'HostName'},'__return__')) {
            if (${$host}{'SMB_Proxy'}=~/^(\d+)$/) {
               $DeploySMB_Proxy{${$host}{'SMB_Proxy'}}
                  =${$host}{'Label'};
            } else { push @DeploySMB_Proxy, ${$host}{'Label'} }
         }
      }
      if ($key eq 'RCM_Proxy') {
         if (exists $same_host_as_Master{${$host}{'Label'}}) {
            if (exists ${$host}{'RCM_Proxy'} &&
                  ${$host}{'RCM_Proxy'}=~/^(\d+)$/) {
               $DeployRCM_Proxy{${$host}{'RCM_Proxy'}}
                  ="__Master_${$}__";
            } else { push @DeployRCM_Proxy, "__Master_${$}__" }
         } elsif ((exists ${$host}{'IP'} &&
                  &ping(${$host}{'IP'},'__return__')) ||
                  (exists ${$host}{'HostName'} &&
                  &ping(${$host}{'HostName'},'__return__'))) {
            if (exists ${$host}{'RCM_Proxy'} &&
                  ${$host}{'RCM_Proxy'}=~/^(\d+)$/) {
                  $DeployRCM_Proxy{${$host}{'RCM_Proxy'}}
                  =${$host}{'Label'};
            } else { push @DeployRCM_Proxy, ${$host}{'Label'} }
         }
      }
      if ($key eq 'FTM_Proxy') {
         if (exists $same_host_as_Master{${$host}{'Label'}}) {
            if (${$host}{'FTM_Proxy'}=~/^(\d+)$/) {
               $DeployFTM_Proxy{${$host}{'FTM_Proxy'}}
                  ="__Master_${$}__";
            } else { push @DeployFTM_Proxy, "__Master_${$}__" }
         } elsif (&ping(${$host}{'IP'},'__return__') ||
                  &ping(${$host}{'HostName'},'__return__')) {
            if (${$host}{'FTM_Proxy'}=~/^(\d+)$/) {
               $DeployFTM_Proxy{${$host}{'FTM_Proxy'}}
                  =${$host}{'Label'};
            } else { push @DeployFTM_Proxy, ${$host}{'Label'} }
         }
      }
   }
}

if (keys %DeploySMB_Proxy) {
   foreach my $key (reverse sort keys %DeploySMB_Proxy) {
      unshift @DeploySMB_Proxy, $DeploySMB_Proxy{$key};
   }
}
if (keys %DeployRCM_Proxy) {
   foreach my $key (reverse sort keys %DeployRCM_Proxy) {
      unshift @DeployRCM_Proxy, $DeployRCM_Proxy{$key};
   }
}
if (keys %DeployFTM_Proxy) {
   foreach my $key (reverse sort keys %DeployFTM_Proxy) {
      unshift @DeployFTM_Proxy, $DeployFTM_Proxy{$key};
   }
}

#my $ps__=($OS eq 'cygwin')?'ps':$pspath.'ps';
my $ps_stdout=&cmd($pspath.'ps');

sub get_all_hosts
{
   return keys %Hosts;
}

sub connect_sftp
{
   push @_, '__sftp__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_ftp
{
   push @_, '__ftp__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_ftp_sftp
{
   push @_, '__ftp__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_sftp_ftp
{
   push @_, '__ftp__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_ssh
{
   my @topcaller=caller;
   print "connect_ssh() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_ssh() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   push @_, '__ssh__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE1\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return $handle,$stderr;
   } elsif ($stderr) {
print $Net::FullAuto::FA_lib::MRLOG "GOTSSHCONNECTERRORDYING\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      &handle_error($stderr,'-4');
   } else {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE2\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return $handle;
   }
}

sub connect_ssh_telnet
{
   my @topcaller=caller;
   print "connect_ssh-telnet() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_ssh-telnet() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   push @_, '__ssh_telnet__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE1\n";
      return $handle,$stderr;
   } elsif ($stderr) {
print $Net::FullAuto::FA_lib::MRLOG "GOTSSHCONNECTERRORDYING\n";
      &handle_error($stderr,'-4');
   } else {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE2\n";
      return $handle;
   }
}

sub connect_telnet_ssh
{
   my @topcaller=caller;
   print "connect_ssh-telnet() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_ssh-telnet() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   push @_, '__ssh_telnet__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE1\n";
      return $handle,$stderr;
   } elsif ($stderr) {
print $Net::FullAuto::FA_lib::MRLOG "GOTSSHCONNECTERRORDYING\n";
      &handle_error($stderr,'-4');
   } else {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE2\n";
      return $handle;
   }
}

sub connect_secure
{
   my @topcaller=caller;
   print "connect_secure() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_ssh() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   push @_, '__secure__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE1\n";
      return $handle,$stderr;
   } elsif ($stderr) {
print $Net::FullAuto::FA_lib::MRLOG "GOTSSHCONNECTERRORDYING\n";
      &handle_error($stderr,'-4');
   } else {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE2\n";
      return $handle;
   }
}

sub connect_insecure
{
   my @topcaller=caller;
   print "connect_insecure() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_insecure() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   push @_, '__insecue__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE1\n";
      return $handle,$stderr;
   } elsif ($stderr) {
print $Net::FullAuto::FA_lib::MRLOG "GOTSSHCONNECTERRORDYING\n";
      &handle_error($stderr,'-4');
   } else {
print $Net::FullAuto::FA_lib::MRLOG "RETURNINGSSH_HANDLE2\n";
      return $handle;
   }
}

sub connect_telnet
{
   push @_, '__telnet__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_reverse
{
   push @_, '__reverse__';
   ($handle,$stderr)=connect_host(@_);
   if (wantarray) {
      return $handle,$stderr;
   } elsif ($stderr) {
      &handle_error($stderr,'-4');
   } else {
      return $handle;
   }
}

sub connect_host
{
   my @topcaller=caller;
   print "connect_host() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "connect_host() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $caller=(caller(1))[3];
   substr($caller,0,(index $caller,'::')+2)='';
   my $sub='';my $_connect='connect_host';
   if ((-1<index $caller,'connect_ftp')
         || (-1<index $caller,'connect_telnet')
         || (-1<index $caller,'connect_ssh')
         || (-1<index $caller,'connect_sftp')
         || (-1<index $caller,'connect_secure')
         || (-1<index $caller,'connect_insecure')
         || (-1<index $caller,'connect_reverse')) {
      $_connect=(split '::', $caller)[2];
      ($caller,$sub)=split '::', (caller(2))[3];
      $caller.='.pm';
   } else {
      my @called=caller(2);
      if ((-1<index $caller,'mirror') || (-1<index $caller,'login_retry')) {
         $sub=$called[3]
      } else {
         $caller=$called[3];
         $caller=(caller(0))[0] if $caller=~/[(]eval[)]/;
         $called[6]||='';
         $sub=($called[6])?$called[6]:$called[3];
         $sub=~s/^.*:://;
      } $sub=~s/\s*\;\n*//
   }
   my $hostlabel=$_[0];
   $Net::FullAuto::FA_lib::cltimeout||='X';
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $timeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (defined $_[1] && $_[1]=~/^[1-9]+/) {
      $timeout=$_[1];
   } elsif ((-1==index $caller,'mirror') &&
         (-1==index $caller,'login_retry')) {
      my $time_out='$' . (caller)[0] . '::timeout';
      $time_out= eval $time_out;
      if ($@ || $time_out!~/^[1-9]+/) {
         $timeout=30;
      } else { $timeout=$time_out }
   } else { $timeout=30 }
   if (defined $_[2] && lc($_[2]) ne '__telnet__' && lc($_[2]) ne '__ftp__') {
      $Net::FullAuto::FA_lib::test=$_[2];
   } else {
      my $tst='$' . (caller)[0] . '::test';
      $tst= eval $tst;
      if ($@ || $tst!~/^[1-9]+/) {
         $Net::FullAuto::FA_lib::test=0;
      } else { $Net::FullAuto::FA_lib::test=$tst }
   }
   unless (exists $Hosts{$hostlabel}) {
      my $die="\n       FATAL ERROR - The First Argument to "
             ."&connect_host()\n              ->  \"$hostlabel"
             ."\"\n              Called from the User Defined "
             ."Subroutine\n              -> \&$sub\n       "
             ."       in the \"user subs\" subroutine file"
             ."\n              ->   ${caller}.pm   is NOT a\n"
             ."              Valid Host Label\n\n"
             ."              Be sure there is Valid Host "
             ."Block\n              Entry in the Hosts file\n"
             ."              ->   $fa_hosts .\n\n";
      print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      print $die if (!$Net::FullAuto::FA_lib::cron
                   || $Net::FullAuto::FA_lib::debug)
                   && !$Net::FullAuto::FA_lib::quiet;
      &handle_error($die,'__cleanup__');
   }
   my $new_handle='';my $stderr='';
   if ($_connect eq 'connect_ssh'
         || $_connect eq 'connect_telnet') {
      ($new_handle,$stderr)=new Rem_Command($hostlabel,
                                '__new_master__',$_connect);
print $Net::FullAuto::FA_lib::MRLOG "connect_host()1 STDERRFOR1011=$stderr<==\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   } else {
      ($new_handle,$stderr)=new File_Transfer($hostlabel,
                                '__new_master__',$_connect);
print $Net::FullAuto::FA_lib::MRLOG "connect_host()2 STDERRFOR1011=$stderr<==\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   }
   if (wantarray) {
      print $Net::FullAuto::FA_lib::MRLOG "RETURNING1\n"
         if $Net::FullAuto::FA_lib::log &&
         -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return $new_handle,$stderr }
   elsif (!$stderr) {
      print $Net::FullAuto::FA_lib::MRLOG "RETURNING2\n"
         if $Net::FullAuto::FA_lib::log &&
         -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return $new_handle }
   else {
     print $Net::FullAuto::FA_lib::MRLOG "DIEINGNOWHERE\n"
        if $Net::FullAuto::FA_lib::log &&
        -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
     &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__');
   }

}

sub memnow
{
   my $stdout='';my $stderr='';my $all=0;
   $all=1 if $_[0] && grep { /__all__/i } @_;
   if ($_[0] && ref $_[0] eq 'HASH') {
      if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
         ($stdout,$stderr)=&Net::FullAuto::FA_lib::cmd($self,"cat /proc/meminfo");
         &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__') if $stderr
            && !wantarray
      }
   } else {
      if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
         ($stdout,$stderr)=&Net::FullAuto::FA_lib::cmd("cat /proc/meminfo");
         &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__') if $stderr
            && !wantarray
      }
   }
   if (!$all && $Net::FullAuto::FA_lib::OS eq 'cygwin') {
      my $cnt=0;
      foreach my $line (split /^/, $stdout) {
         next if !$cnt++;
         $stdout=substr($line,(rindex $line,' ')+1,-1);
         last;
      }
   }
   if (wantarray) {
      return $stdout, $stderr;
   } else {
      return $stdout;
   }
}

sub freemem
{
   $self=$_[0];
   if (exists $self->{_freemem}) {
      ($freememy=${$self->{_freemem}}[0])=~s/\\/\\\\/g;
   } else {
      $freememy='rr.exe';
   }
   $str="cmd /c \"$freememy\" 2>&1";
   $self->{_cmd_handle}->print($str);
   sleep 1;
   $self->{_cmd_handle}->print("\003");
   $self->{_cmd_handle}->get;
   while (my $line=$self->{_cmd_handle}->get) {
       last if $line=~/_funkyPrompt_$/s;
   }
   $str="cmd /c \"$freememy\" 2>&1";
   $self->{_cmd_handle}->print($str);
   sleep 1;
   $self->{_cmd_handle}->print("\003");
   $self->{_cmd_handle}->get;
   while (my $line=$self->{_cmd_handle}->get) {
       last if $line=~/_funkyPrompt_$/s;
   } #select((select($self->{_cmd_handle}),$|=1)[0]);
   $self->{_cmd_handle}->print("\012");
   while (my $line=$self->{_cmd_handle}->get) {
      chomp $line;
      next if $line=~/^\s*$/s;
      last;
   } my $local_host_flag=0;
   if (!$Net::FullAuto::FA_lib::cron) {
      my $memhost=($self->{_hostlabel}->[1])?
                  !$self->{_hostlabel}->[1]:
                  $self->{_hostlabel}->[0];
      if ($memhost eq "__Master_${$}__") {
         foreach my $hostlab (keys %same_host_as_Master) {
            next if $hostlab eq "__Master_${$}__";
            $memhost=$hostlab;
            $local_host_flag=1;
            last;
         }
         if (!$local_host_flag) {
            $memhost=$local_hostname;
            $local_host_flag=1;
         }
      } elsif (exists $same_host_as_Master{$memhost}) {
         $local_host_flag=1;
      }
      print "Recovering Memory on $memhost"
            ,"  . . .\n";
   }
   $str="echo cmd /c \\\"$freememy\\\" dir"
       ." >> freemem$freemem_time.bat";
   $self->{_cmd_handle}->print($str);
   while (my $line=$self->{_cmd_handle}->get) {
      last if $line=~/_funkyPrompt_$/s;
   }
   $self->{_cmd_handle}->print(
      "cmd /c freemem$freemem_time.bat");
   &clean_filehandle($self->{_cmd_handle});
   $str="echo \"del freemem$freemem_time.bat\""
       ." >> rm$freemem_time.bat";
   $self->{_cmd_handle}->print($str);
   &clean_filehandle($self->{_cmd_handle});
   $str="echo \"del rm$freemem_time.bat\""
       ." >> rm$freemem_time.bat";
   $self->{_cmd_handle}->print($str);
   &clean_filehandle($self->{_cmd_handle});
   $str="cmd /c rm$freemem_time.bat";
   $self->{_cmd_handle}->print($str);
   &clean_filehandle($self->{_cmd_handle});
   $Net::FullAuto::FA_lib::freemem_time=time;

}

sub handle_error
{
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }
   my @topcaller=caller;
   print "FA_lib::handle_error() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "FA_lib::handle_error() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#$Net::FullAuto::FA_lib::log=0 if $logreset;
   my $return=0;
   my $line_adjust=0;my $warn=0;
   my $error=$_[0];my $track='';
   my $cleanup=0;my $debug=0;
   my $mail='';my $new_invoked='';
   if (defined $_[1] && $_[1]) {
      if (ref $_[1] eq 'HASH') {
         $mail=$_[1];
      } elsif (ref $_[1] eq 'ARRAY') {
         $track=$_[1];
      } else {
         if ($_[1] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[1] eq '__debug__') {
            $debug=1;
         } elsif ($_[1] eq '__return__') {
            $return=1;
         } elsif ($_[1] eq '__warn__') {
            $warn=1;
         } elsif ($_[1]=~/^\s*-(\d+)\s*$/) {
            $line_adjust=-$1;
         } else {
            print "ARG1 is NOT recognized\n==>$_[1]<==\n";
         }
      }
   }
   if (defined $_[2] && $_[2]) {
      if (ref $_[2] eq 'HASH') {
         $mail=$_[2];
      } elsif (ref $_[2] eq 'ARRAY') {
         $track=$_[2];
      } else {
         if ($_[2] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[2] eq '__debug__') {
            $debug=1;
         } elsif ($_[2] eq '__return__') {
            $return=1;
         } elsif ($_[2] eq '__warn__') {
            $warn=1;
         } elsif ($_[2]=~/^\s*-(\d+)\s*/) {
            $line_adjust=-$1;
         } else {
            print "ARG2 is NOT recognized\n==>$_[2]<==\n";
         }
      }
   }
   if (defined $_[3] && $_[3]) {
      if (ref $_[3] eq 'HASH') {
         $mail=$_[3];
      } elsif (ref $_[3] eq 'ARRAY') {
         $track=$_[3];
      } else {
         if ($_[3] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[3] eq '__debug__') {
            $debug=1;
         } elsif ($_[3] eq '__return__') {
            $return=1;
         } elsif ($_[3] eq '__warn__') {
            $warn=1;
         } elsif ($_[3]=~/^-(\d+)/) {
            $line_adjust=-$1;
         } else {
            print "ARG3 is NOT recognized\n==>$_[3]<==\n";
         }
      }
   }
   if (defined $_[4] && $_[4]) {
      if (ref $_[4] eq 'HASH') {
         $mail=$_[4];
      } elsif (ref $_[4] eq 'ARRAY') {
         $track=$_[4];
      } else {
         if ($_[4] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[4] eq '__debug__') {
            $debug=1;
         } elsif ($_[4] eq '__return__') {
            $return=1;
         } elsif ($_[4] eq '__warn__') {
            $warn=1;
         } elsif ($_[4]=~/^\s*-(\d+)\s*/) {
            $line_adjust=-$1;
         } else {
            print "ARG4 is NOT recognized\n==>$_[4]<==\n";
         }
      }
   }
   if (defined $_[5] && $_[5]) {
      if (ref $_[5] eq 'HASH') {
         $mail=$_[5];
      } elsif (ref $_[5] eq 'ARRAY') {
         $track=$_[5];
      } else {
         if ($_[5] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[5] eq '__debug__') {
            $debug=1;
         } elsif ($_[5] eq '__return__') {
            $return=1;
         } elsif ($_[5] eq '__warn__') {
            $warn=1;
         } elsif ($_[5]=~/^\s*-(\d+)\s*/) {
            $line_adjust=-$1;
         } else {
            print "ARG5 is NOT recognized\n==>$_[5]<==\n";
         }
      }
   }
   if (defined $_[6] && $_[6]) {
      if (ref $_[6] eq 'HASH') {
         $mail=$_[6];
      } elsif (ref $_[6] eq 'ARRAY') {
         $track=$_[6];
      } else {
         if ($_[6] eq '__cleanup__') {
            $cleanup=1;
         } elsif ($_[6] eq '__debug__') {
            $debug=1;
         } elsif ($_[6] eq '__return__') {
            $return=1;
         } elsif ($_[6] eq '__warn__') {
            $warn=1;
         } elsif ($_[6]=~/^\s*-(\d+)\s*/) {
            $line_adjust=-$1;
         } else {
            print "ARG6 is NOT recognized\n==>$_[6]<==\n";
         }
      }
   } my $line='';
   if ($line_adjust) {
      if (unpack('a1',$line_adjust) eq '-') {
         $line_adjust=unpack('x1 a*',$line_adjust);
         $line=$topcaller[2]-$line_adjust;
      } else {
         $line=$topcaller[2]+$line_adjust;
      }
   } else { $line=$topcaller[2] }
   my $tie_err='';my $trackdb='';my $hostlabel='';
   if ($track) {
      ($trackdb=${$track}[0])=~s/\.db$//;
      $hostlabel=${$track}[1];
      $command=${$track}[2];
      $suberr=${$track}[3] if defined ${$track}[3] && ${$track}[3];
      $suberr||='';
      $tie_err="can't open tie to ${trackdb}.db";
      my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
         %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
        'MLDBM::Sync',
         "${trackdb}.db",
         $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
         &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
print $Net::FullAuto::FA_lib::MRLOG "GOT THIS FAR INTO TRACKBEFLOCK\n";
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
print $Net::FullAuto::FA_lib::MRLOG "GOT THIS FAR INTO TRACKAFTLOCK\n";
      my $tref=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$invoked[2]};
      if (exists ${$tref}{"${hostlabel}_$command"}
            && ${$tref}{"${hostlabel}_$command"}
            eq $error) {
         foreach my $key (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}}) {
            if ($key!=$invoked[2]) {
                delete ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$key};
            }
         }
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            if (keys %Net::FullAuto::FA_lib::semaphores) {
               foreach my $ipc_key (keys %Net::FullAuto::FA_lib::semaphores) {
                  $Net::FullAuto::FA_lib::semaphores{$ipc_key}->release(1);
                  delete $Net::FullAuto::FA_lib::semaphores{$ipc_key};
               }
            }
         } else {
            semctl(34, 0, SETVAL, -1);
         } return 1,'';
      } elsif ($suberr && exists ${$tref}{"${hostlabel}_$suberr"}
            && ${$tref}{"${hostlabel}_$suberr"}
            eq $suberr) {
         foreach my $key (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}}) {
            if ($key!=$invoked[2]) {
               delete ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$key};
            }
         }
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            if (keys %Net::FullAuto::FA_lib::semaphores) {
               foreach my $ipc_key (keys %Net::FullAuto::FA_lib::semaphores) {
                  $Net::FullAuto::FA_lib::semaphores{$ipc_key}->release(1);
                  delete $Net::FullAuto::FA_lib::semaphores{$ipc_key};
               }
            }
         } else {
            semctl(34, 0, SETVAL, -1);
         } return 1,'';
      } else {
         ${$tref}{"${hostlabel}_$command"}=$error;
         ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$invoked[2]}=$tref;
         $return=1;
      }
      foreach my $key (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}}) {
         if ($key!=$invoked[2]) {
            delete ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$key};
         }
      }
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   } my $errtxt='';
   if (10<length $error && unpack('a11',$error) ne 'FATAL ERROR') {
      $error=~s/\s*$//s;$error=~s/^\s*//s;
      $errtxt="$error\n\n       at $topcaller[0] "
             ."$topcaller[1] line $line.\n";
   } else {
      $errtxt=$error
   }
#print $Net::FullAuto::FA_lib::MRLOG "HANDLE_ERROR ERRTXT=$errtxt<==\n";
   if ($errtxt=~/^You have mail/) {
      print $Net::FullAuto::FA_lib::MRLOG "\nAttn: --> $errtxt\n\n"
         if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      print "\nAttn: --> $errtxt\n\n";
      return
   } elsif ($track || $return || $cleanup) {
      print $Net::FullAuto::FA_lib::MRLOG "\n       $errtxt"
         if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      print "\n       $errtxt"
   }
   if ($mail) {
      if ($warn) {
         send_email($mail,$debug,'__warn__');
      } else { send_email($mail,$debug) }
   } elsif (!$mail && exists $email_defaults{Usage} &&
         lc($email_defaults{Usage}) eq 'notify_on_error'
         && ($track && ($cleanup || $return))) {
         #|| ($cleanup || $return)) {
      #if ($debug) {
      #   my $txxt.="\n\n"
      #           ."##########   BEGIN DEBUGGING OUTPUT"
      #           ."   ##########\n\n\n$Net::FullAuto::FA_lib::fa_debug\n"; 
      #}
      my %mail=(Body=>"       $errtxt");
      if ($warn) {
         send_email(\%mail,$debug,'__warn__');
      } else { send_email(\%mail,$debug) }
   }
   if ($track) {
      if (wantarray) {
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            if (keys %Net::FullAuto::FA_lib::semaphores) {
               foreach my $ipc_key (keys %Net::FullAuto::FA_lib::semaphores) {
                  $Net::FullAuto::FA_lib::semaphores{$ipc_key}->release(1);
                  delete $Net::FullAuto::FA_lib::semaphores{$ipc_key};
               }
            }
         } else {
            semctl(34, 0, SETVAL, -1);
         } return 0,$errtxt;
      } else {
         if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
            if (keys %Net::FullAuto::FA_lib::semaphores) {
               foreach my $ipc_key (keys %Net::FullAuto::FA_lib::semaphores) {
                  $Net::FullAuto::FA_lib::semaphores{$ipc_key}->release(1);
                  delete $Net::FullAuto::FA_lib::semaphores{$ipc_key};
               }
            }
         } else {
            semctl(34, 0, SETVAL, -1);
         } return 0,'';
      }
   } elsif ($cleanup) {
      &cleanup($return,1);
   } else {
      #my $die="$error\n       at $topcaller[0] $topcaller[1] line $line.\n";
      #if ($debug) {
      #   die "$die"."\n\n"
      #             ."##########   BEGIN DEBUGGING OUTPUT"
      #             ."   ##########\n\n\n$Net::FullAuto::FA_lib::fa_debug\n";
      #} else { die "$die" }
      #die "$die"
print "WE ARE GOING TO DIE IN HANDLE_ERROR\n";
print $Net::FullAuto::FA_lib::MRLOG "WE ARE GOING TO DIE IN HANDLE_ERROR\n"
if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      if ($return && $warn) {
         print "\n       $errtxt\n";
      } else { die $errtxt }
   }
}

sub lookup_hostinfo_from_label
{
   my @topcaller=caller;
   print "lookup_hostinfo_from_label() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "lookup_hostinfo_from_label() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $ip='';my $hostname='';my $use='';my $ms_share='';
   my $ms_domain='';my $cmd_cnct=[''];my $ftr_cnct=[''];
   my $login_id='';my $su_id='';my $chmod='';my $ping='';
   my $owner='';my $group='';my $transfer_dir='';
   my $rcm_chain='';my $rcm_map='';my $uname='';
   my $ip_flag='';my $hn_flag='';
   my $hostlabel=$_[0];my $_connect=$_[1]||'';
   my $freemem='';my $timeout=0;
   $use=$Hosts{$hostlabel}{'Use'} if exists
        $Hosts{$hostlabel}{'Use'} &&
        $Hosts{$hostlabel}{'Use'};
   my $defined_use=0;
   $defined_use=$use if $use;
   $ping=$Hosts{$hostlabel}{'Ping'} if exists
        $Hosts{$hostlabel}{'Ping'} &&
        $Hosts{$hostlabel}{'Ping'};
   foreach my $key (keys %{$Hosts{$hostlabel}}) {
print $Net::FullAuto::FA_lib::MRLOG "KEY FROM HOST HASH=$key and USE=$use\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

      if (!$use || (!$defined_use && $ip && !$hostname)) {
         if ($key eq 'IP') {
            $ip=$Hosts{$hostlabel}{$key};
            if (exists $same_host_as_Master{$ip} || $ping) {
               if (exists $same_host_as_Master{$ip}
                     || &ping($ip,'__return__')) {
                  $use='ip';
               } else { print "DAMN\n";$ip_flag=1 }
            }
         } elsif (lc($key) eq 'hostname') {
            $hostname=$Hosts{$hostlabel}{$key};
            if ($hostname && $ping) {
               if (&ping($hostname,'__return__')) {
                  $use='hostname';
               } else {
                  my $pinghost=$hostname;
                  $pinghost=substr($hostname,0,
                     (index $hostname,'.'))
                     if -1<index $hostname,'.';
                  if (&ping($pinghost,'__return__')) {
                     $Hosts{$hostlabel}{'HostName'}=$pinghost;
                     $hostname=$pinghost;
                     $use='hostname';
                  } else { $hn_flag=1 }
               }
            }
         }
      } elsif (lc($key) eq 'ip') {
         $ip=$Hosts{$hostlabel}{$key};
         if (!exists $same_host_as_Master{$ip} && $ping) {
            unless (&ping($ip,'__return__')) {
               if ($defined_use eq 'ip') {
                  $ip_flag=1;$defined_use=0;$use=0;
               }
            }
         }
      } elsif (lc($key) eq 'hostname') {
         $hostname=$Hosts{$hostlabel}{$key};
         if ($ping) {
            my $pinghost=$hostname;
            $pinghost=substr($hostname,0,
               (index $hostname,'.'))
               if -1<index $hostname,'.';
            unless (&ping($pinghost,'__return__')) {
               if ($defined_use eq 'hostname') {
                  $hn_flag=1;$defined_use=0;$use=0;
               }
            }
         }
      }
      if (lc($key) eq 'ms_share') {
         $ms_share=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'MS_Domain') {
         $ms_domain=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Remote') {
         my $rem_cnct=$Hosts{$hostlabel}{$key};
         if (!exists $same_host_as_Master{$hostlabel}) {
            if ($_connect && $rem_cnct ne $_connect) {
               if (($rem_cnct eq 'connect_ssh'
                     || $rem_cnct eq 'connect_telnet'
                     || $rem_cnct eq 'connect_sftp'
                     || $rem_cnct eq 'connect_ftp')
                     || (($_connect eq 'connect_secure'
                     || $_connect eq 'connect_insecure')
                     && ($rem_cnct ne 'connect_host'
                     && $rem_cnct ne 'connect_reverse'))) {
                  $die.="\n              \"Remote\" Value:  \'$rem_cnct\'"
                      ."\n              for Host Block  --> $hostlabel"
                      ."\n              in file $fa_hosts"
                      ."\n              conflicts with calling connect"
                      ."\n              method:  $_connect";
                  &handle_error($die);          
               } elsif ($_connect eq 'connect_secure') {
                  $ftr_cnct=[ 'sftp' ];
                  $cmd_cnct=[ 'ssh' ];
               } elsif ($_connect eq 'connect_insecure') {
                  $ftr_cnct=[ 'ftp' ];
                  $cmd_cnct=[ 'telnet' ];
               } elsif ($_connect eq 'connect_host') {
                  $ftr_cnct=[ 'sftp','ftp' ];
                  $cmd_cnct=[ 'ssh','telnet' ];
               } elsif ($_connect eq 'connect_reverse') {
                  $ftr_cnct=[ 'ftp','sftp' ];
                  $cmd_cnct=[ 'telnet','ssh' ];
               }
            }
         } else {
            if ($rem_cnct eq 'connect_secure') {
               $ftr_cnct=[ 'sftp' ];
               $cmd_cnct=[ 'ssh' ];
            } elsif ($rem_cnct eq 'connect_ssh') {
               $cmd_cnct=[ 'ssh' ];
            } elsif ($rem_cnct eq 'connect_sftp') {
               $ftr_cnct=[ 'sftp' ]; 
            } elsif ($rem_cnct eq 'connect_host') {
               $ftr_cnct=[ 'sftp','ftp' ];
               $cmd_cnct=[ 'ssh','telnet' ];
            } elsif ($rem_cnct eq 'connect_insecure') {
               $ftr_cnct=[ 'ftp' ];
               $cmd_cnct=[ 'telnet' ];
            } elsif ($rem_cnct eq 'connect_telnet') {
               $cmd_cnct=[ 'telnet' ];
            } elsif ($rem_cnct eq 'connect_ftp') {
               $ftr_cnct=[ 'ftp' ];
            } elsif ($ftr_cnct eq 'connect_reverse') {
               $ftr_cnct=[ 'ftp','sftp' ];
               $cmd_cnct=[ 'telnet','ssh' ];
            }
         }
      } elsif ($key eq 'LoginID') {
         $login_id=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'SU_ID') {
         $su_id=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Chmod') {
         $chmod=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Owner') {
         $owner=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Group') {
         $group=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Timeout') {
         $timeout=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'TransferDir') {
         $transfer_dir=$Hosts{$hostlabel}{$key};
         $transfer_dir=~s/[\/\\]*$//;
      } elsif ($key eq 'RCM_Chain') {
         $rcm_chain=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'RCM_Map') {
         $rcm_map=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'Uname') {
         $uname=$Hosts{$hostlabel}{$key};
      } elsif ($key eq 'FreeMem') {
         $freemem=$Hosts{$hostlabel}{$key};
      }
print $Net::FullAuto::FA_lib::MRLOG "GOING BACK TO TOP OF FOR LOOP\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   }
   if (!$#{$ftr_cnct}) {
      if ($_connect eq 'connect_secure') {
         $ftr_cnct=[ 'sftp' ];
         $cmd_cnct=[ 'ssh' ];
      } elsif ($_connect eq 'connect_host') {
         $ftr_cnct=[ 'sftp','ftp' ];
         $cmd_cnct=[ 'ssh','telnet' ];
      } elsif ($_connect eq 'connect_ssh') {
         $cmd_cnct=[ 'ssh' ];
      } elsif ($_connect eq 'connect_sftp') {
         $ftr_cnct=[ 'sftp' ];
      } elsif ($_connect eq 'connect_telnet') {
         $cmd_cnct=[ 'telnet' ];
      } elsif ($_connect eq 'connect_ftp') {
         $ftr_cnct=[ 'ftp' ];
      } elsif ($_connect eq 'connect_insecure') {
         $ftr_cnct=[ 'ftp' ];
         $cmd_cnct=[ 'telnet' ];
      } elsif ($_connect eq 'connect_reverse') {
         $ftr_cnct=[ 'ftp','sftp' ];
         $cmd_cnct=[ 'telnet','ssh' ];
      }
   }
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS USE?=$use\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if (!$use || (!$ip && !$hostname)) {
      my $die="Cannot Contact Server \'$hostlabel\' -";
      if ($ip_flag) {
         $die.="\n              1ping failed for ip address $ip";
         if ($hn_flag) {
            $die.="\n              and hostname: $hostname\n" if $hostname;
         } &handle_error($die);
      } elsif ($hn_flag) {
         $die.="\n              2ping failed for hostname: $hostname  &"
             ."\n              No ip address if defined for Server"
             ."\n              --> $hostlabel  in $fa_hosts file.";
         &handle_error($die);
      } elsif ($hostname || ($use eq 'ip' && !$ip)) {
         $use='hostname';
      } elsif ($ip) {
         $use='ip';
      } else {
         $die.="\n              No ip address or hostname defined for Server"
             ."\n              --> $hostlabel  in $fa_hosts file.";
         &handle_error($die);
      }
   } elsif ($use eq 'hostname' && !$hostname && $ip) {
      $use='ip';
   } elsif ($use eq 'ip' && !$ip && $hostname) {
      $use='hostname';
   }
   return ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$timeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem);

}

sub pty_do_cmd
{
#print "PTY_CALLER=",caller,"\n";
   my ($cmd,@args)=@_;
   my $pty = IO::Pty->new or &Net::FullAuto::FA_lib::handle_error("can't make Pty: ".($!));
   my $try=0;my $child='';
   my $cmd_err=join ' ',@{$cmd};
   my $one=shift @{$cmd};my $two='';my $three='';my $four='';
   if (-1<$#{$cmd}) {
      $two=shift @{$cmd};
      if (-1<$#{$cmd}) {
         $three=shift @{$cmd};
         if (-1<$#{$cmd}) {
            $four=shift @{$cmd};
         }
      }
   }
#print "WHAT IS ARG4=$four<==";
   while (1) {
      my $m="Hint: Try Rebooting the Local Host";
      eval {
         defined ($child = fork) or
            &handle_error("Can't fork: ");
      };
      if ($@) {
         if ($@=~/temporarily unavailable/ && $try++!=4) {
            sleep 5;next;
         } else {
            &handle_error($@);
         }
      } else { last }
   }
   return $pty,$child if $child;
   POSIX::setsid or &handle_error("setsid failed: ".($!));
   my $tty = $pty->slave;
   $pty->make_slave_controlling_terminal
      if $Net::FullAuto::FA_lib::OS eq 'cygwin' || $four;
   CORE::close $pty;

   STDIN->fdopen($tty,"<")  or &handle_error("STDIN: ".($!));
   STDOUT->fdopen($tty,">") or &handle_error("STDOUT: ".($!));
   STDERR->fdopen($tty,">") or &handle_error("STDERR: ".($!));
   CORE::close $tty;
   $| = 1;
   #my $flag='';
   #if (!$flag || lc($flag) ne '__use_parent_env__') {
   if ($^O ne 'cygwin' && $Net::FullAuto::FA_lib::specialperms eq 'setgid') {
      $ENV{PATH} = '';
      $ENV{ENV}  = '';
   } else {
      $ENV{PATH}=~/^(.*)$/;
      $ENV{PATH}=$1;
      $ENV{ENV}||='';
      $ENV{ENV}=~/^(.*)$/;
      $ENV{ENV}=$1;
   }
   print "\n";

   if ($three) {
      exec $one, $two, $three ||
         &handle_error("Couldn't exec: $cmd_err".($!),'-1');
   } elsif ($two) {
      exec $one, $two ||
         &handle_error("Couldn't exec: $cmd_err".($!),'-1');
   } else {
      exec $one ||
         &handle_error("Couldn't exec: $cmd_err".($!),'-1');
   }

}

sub apache_login
{
print "APACHE_LOGINCALLER=",caller,"\n";
   my ($ip,$hostlabel,$hostname,$info,$apache_handle,$ua)=@_;
   my @info=@{$info};
   my %apache_handle=%{$apache_handle};
   my %ua=%{$ua};
   my $node=substr(${$DeploySMB_Proxy[0]}{'HostName'},0,
                  (index ${$DeploySMB_Proxy[0]}{'HostName'},'.'));
   my $an="${$DeploySMB_Proxy[0]}{'IP'}:80";
   eval {
      #$apache_handle{$info[2]} = new LWP::UserAgent;
      my $un=$username;
#print "GP1\n";
      $apache_handle{$info[2]}->credentials(
         $an,'WebRSH',$un,&getpasswd($hostlabel,$un));
      $apache_handle{$info[2]}->agent(
            "mvcode.pl/$version" . $ua->agent);
   };
   if ($@) {
      return $@;
   }
}

sub test_file
{

   my ($cmd_handle,$tfile)=@_;my $test_result=0;
   my $shell_cmd="if\n[[ -f $tfile ]]\nthen\nif\n[[ -w $tfile ]]"
                ."\nthen\necho WRITE\nelse\necho READ\nfi\n"
                ."else\necho NOFILE\nfi";
   $cmd_handle->print($shell_cmd);
   my $leave=0;
   TF: while (1) {
      while (my $line=$cmd_handle->get) {
         if ($line=~/^WRITE/m) {
            $test_result='WRITE';
            $leave=1;
         } elsif ($line=~/^READ/m) {
            $test_result='READ';
            $leave=1;
         } elsif ($line=~/^NOFILE/m) {
            $test_result=0;
            $leave=1;
         }
         if ($line=~/_funkyPrompt_/s) {
            last TF;
         }
      } last if $leave;
      $cmd_handle->print;
   } return $test_result;

}

sub test_dir
{

   my ($cmd_handle,$tdir)=@_;my $test_result=0;
   my $shell_cmd="if\n[[ -d $tdir ]]\nthen\nif\n[[ -w $tdir ]]"
                ."\nthen\necho WRITE\nelse\necho READ\nfi\n"
                ."else\necho NODIR\nfi;printf \\\\055";
   $cmd_handle->print($shell_cmd);
   my $leave=0;my $l='';
   TD: while (1) {
      while (my $line=$cmd_handle->get) {
         $l.=$line;
         if ($l=~/printf/s) {
            if ($line=~/^WRITE/m) {
               $test_result='WRITE';
               $leave=1;
            } elsif ($line=~/^READ/m) {
               $test_result='READ';
               $leave=1;
            } elsif ($line=~/^NODIR/m) {
               $test_result=0;
               $leave=1;
            }
         }
         if ($l=~/-\s*_funkyPrompt_/s) {
            last TD;
         }
      } last if $leave;
      $cmd_handle->print;
   } return $test_result;

}

sub inc_oct
{
   my $num=$_[0];
   while (1) {
      $num++;
      return $num if (-1==index $num,'8') && (-1==index $num,'9')
   }
}

sub get_prompt {
   unless ($#ascii_que) {
      @ascii_que=@ascii;
   } return shift @ascii_que;
}

sub clean_filehandle
{

my $logreset=1;my $onemore=0;
if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
else { $Net::FullAuto::FA_lib::log=1 }
   my @topcaller=caller;
   print "clean_filehandle() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "clean_filehandle() CALLER=",
      (join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#$Net::FullAuto::FA_lib::log=0 if $logreset;
#print "FILEHANDLE FOR CLEAN_FILEHANDLE=$_[0]<==\n";
   my $filehandle=$_[0];
   my $cmd_prompt=(defined $_[1] && $_[1]) ? $_[1] : '';
   #$filehandle->autoflush(1);
   $cmd_prompt=quotemeta $cmd_prompt;
   $cmd_prompt||=qr/_funkyPrompt_/;
   if (-1==index $filehandle,'GLOB' || !defined fileno $filehandle) {
      if (-1==index $filehandle,'GLOB') {
         eval {
            $filehandle=$filehandle->{_cmd_handle};
            $filehandle=$filehandle->{_cmd_handle}->{_cmd_handle}
               if -1==index $filehandle,'GLOB';
         };
         if (($@ && -1==index $filehandle,'GLOB') ||
               !defined fileno $filehandle) {
            if (wantarray) {
               return '','Connection closed';
            } else {
               &Net::FullAuto::FA_lib::handle_error($@,'__cleanup__')
            }
         }
      } else {
         if (wantarray) {
            return '','Connection closed';
         } else {
            &Net::FullAuto::FA_lib::handle_error(
               "$filehandle is NOT a valid filehandle",'__cleanup__')
         }
      }
   } my $uhray='';$loop=0;my $sec=0;my $ten=0;my $hun=5;
   while (1) {
      $uhray=&Net::FullAuto::FA_lib::get_prompt();
      $filehandle->print('cmd /Q /C "set /A '.${$uhray}[1].'&echo _-"'.
                         '|| printf \\\\'.${$uhray}[2].'\\\\'.${$uhray}[3].
                         '\\\\137\\\\055 2>/dev/null');
      if ($loop==100) {
         if (wantarray) {
            return '',$die;
         } else { &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__') }
      }
      $wait=$sec.'.'.$ten.$hun;
      if ($wait!=3.00) {
         if ($hun==9) {
            if ($ten==9) {
               $sec++;$ten=0;$hun=0;
            } else {
               $ten++;$hun=0;
            }
         } else { $hun++ }
      }
      select(undef,undef,undef,$wait)
         if $loop++!=1; # sleep;
      eval {
         my $all_lines='';
         while (my $line=$filehandle->get(Timeout=>5)) {
            chomp($line=~tr/\0-\11\13-\37\177-\377//d);
            $all_lines.=$line;
#print "ALL_LINES_FOR_CLEAN_FILEHANDLE=$all_lines and UHRAY=${$uhray}[0]_-<==\n";
#            my $cmd_p=$cmd_prompt;
#            if (-1==index $cmd_prompt,'_funkyPrompt_') {
#               $cmd_p=~s/(.)/\[$1\]/g;
#            }
#print "WHAT NOW=$cmd_p<==\n";sleep 3;
#            last if $all_lines=~/${$uhray}[0]_-\s*$cmd_p\s*$/s;
            last if $all_lines=~/${$uhray}[0]_-.+$/s;
            if ($all_lines=~/Connection.*closed|filehandle.*isn/s) {
               $closederror='Connection closed';
               last;
            }
         }
      };
      if ($@) {
         if (!$onemore) {
            #print "CLEANFILEHANDLE_EVAL_ERROR=$@<==\n";
            my $eval_error=$@;
            if (wantarray) {
               return '',$eval_error;
            }
         } else {
            $onemore=1;
         }
         &Net::FullAuto::FA_lib::handle_error($eval_error,'__cleanup__');
      } elsif ($closederror) {
         if (wantarray) {
            return '',$closederror;
         }
         &Net::FullAuto::FA_lib::handle_error($closederror,'__cleanup__');
      } else { return '','' }
   }
}

sub push_cmd
{
   my $cmd_handle=$_[0];
   my $cmd=$_[1];
   if (-1==index $cmd_handle,'GLOB' || !defined fileno $cmd_handle) {
      if (-1==index $cmd_handle,'GLOB') {
         eval {
            $cmd_handle=$cmd_handle->{_cmd_handle};
            $cmd_handle=$cmd_handle->{_cmd_handle}->{_cmd_handle}
               if -1==index $cmd_handle,'GLOB';
         };
         if (($@ && -1==index $cmd_handle,'GLOB') ||
               !defined fileno $cmd_handle) {
            if (wantarray) {
               return '','Connection closed';
            } else {
               &Net::FullAuto::FA_lib::handle_error($@,'__cleanup__')
            }
         }
      } else {
         if (wantarray) {
            return '','Connection closed';
         } else {
            &Net::FullAuto::FA_lib::handle_error(
               "$filehandle is NOT a valid filehandle",'__cleanup__')
         }
      }
   }
   $hostlabel=$_[2];
   my $cou=100;
   my $output='';my $stderr='';
   while ($cou--) {
      ($output,$stderr)=Rem_Command::cmd(
         { _cmd_handle=>$cmd_handle,
           _hostlabel=>[ $hostlabel,'' ] },
           $cmd,__live__);
print "XXXXXXXXXXXXXXOUT=$output<==\n";
      if (!$output) {
         #&Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
         select(undef,undef,undef,0.02);
         $cmd_handle->print(
            'printf \\\\041\\\\041;$cmd;printf \\\\045\\\\045');
         my $allins='';my $ct=0;
         while (my $line=$cmd_handle->get) {
            chomp($line=~tr/\0-\37\177-\377//d);
            $allins.=$line;
print $Net::FullAuto::FA_lib::MRLOG "PUSH_CMD_LINE_QQQQQQQQQQQ=$allins<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if ($allins=~/!!(.*)%%/) {
               $output=$1;
               last;
            } else {
               $cmd_handle->
                  print('printf \\\\055');
            }
            if ($ct++==10) {
               $cmd_handle->print;
               last;
            }
         } &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
      } else { last }
   }
   &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
   return $output;
}

sub master_transfer_dir
{

   my $localhost=$_[0];
   my $tdir='';my $transfer_dir='';my $curdir='';
   my $output='';my $stderr='';my $work_dirs={};my $endp=0;
   while (1) {
      if ($OS eq 'cygwin') {
         $curdir=&Net::FullAuto::FA_lib::push_cmd($localhost,'cmd /c chdir',
                 $localhost->{'hostlabel'}[0]);
         my ($drive,$path)=unpack('a1 x1 a*',$curdir);
         ${$work_dirs}{_pre_mswin}=$curdir.'\\';
         $path=~s/\\/\//g;
         ${$work_dirs}{_pre}=$localhost->{_cygdrive}.'/'
                            .lc($drive).$path.'/';
      } else {
         ($curdir,$stderr)=$localhost->cmd('pwd');
         ${$work_dirs}{_pre}=$curdir.'/' if $curdir ne '/';
      }
      if (!$curdir || $curdir=~/^\s*$/s ||
            256<length $curdir || $curdir=~/\n/s) {
print "WHAT IS SCREWED CURDIR=$curdir<====\n";
         &clean_filehandle($localhost);next;
      } &handle_error($stderr,'-6','__cleanup__') if $stderr;
      $stderr='';last if $curdir;
   }
   if (exists $Hosts{"__Master_${$}__"}{'TransferDir'}) {
      $master_transfer_dir=$tdir=$Hosts{"__Master_${$}__"}{'TransferDir'};
      if ($OS eq 'cygwin' && $tdir=~/^[\\|\/]/
            && $tdir!~/$localhost->{_cygdrive_regex}/o) {
         if ((${$work_dirs}{_tmp},${$work_dirs}{_tmp_mswin})
               =&File_Transfer::get_drive(
               $tdir,'Target','',"__Master_${$}__")) {
            my $testd=&test_dir($localhost->{_cmd_handle},
                      ${$work_dirs}{_tmp});
            if ($testd eq 'WRITE') {
               if (lc(${$work_dirs}{_tmp_mswin}) ne lc($curdir)) {
                  ($output,$stderr)=$localhost->cmd(
                     'cd '.${work_dirs}{_tmp});
                  &handle_error($stderr,'-2','__cleanup__') if $stderr;
               }
               ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_tmp_mswin};
               $master_transfer_dir=${$work_dirs}{_cwd}
                  =${$work_dirs}{_tmp};
            } else {
               &Net::FullAuto::FA_lib::handle_error('TransferDir not Writable');
            }
         }
      } elsif ($tdir=~/^[a-zA-Z]:/) {
         if ($OS eq 'cygwin') {
            my ($drive,$path)=unpack('a1 x1 a*',$tdir);
            $path=~tr/\\/\//;
            ${$work_dirs}{_cwd}=$localhost->{_cygdrive}
                               .'/'.lc($drive).$path.'/';
            my $testd=&test_dir($localhost->{_cmd_handle},
                      ${$work_dirs}{_cwd});
            if ($testd eq 'WRITE') {
               if ($tdir ne $curdir) {
                  ($output,$stderr)=$localhost->cmd(
                     'cd '.${$work_dirs}{_cwd});
                  &handle_error($stderr,'-2','__cleanup__') if $stderr;
                  ${$work_dirs}{_cwd_mswin}=$tdir.'\\';
               } else {
                  ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_pre_mswin};
                  ${$work_dirs}{_cwd}=${$work_dirs}{_pre};
               }
               ${$work_dirs}{'_tmp_mswin'}=${$work_dirs}{'_cwd_mswin'};
               $master_transfer_dir=${$work_dirs}{'_tmp'}=${$work_dirs}{'_cwd'};
               return $work_dirs;
            } else {
               &Net::FullAuto::FA_lib::handle_error(
                  "TransferDir not Writable and TESTD=$testd<==".
                  " and work_dirs-_cwd=${$work_dirs}{_cwd}<==");
            }
         }
         my $warn="Cannot cd to $tdir\n\tOperating " .
                 "System is $OS - NOT cygwin!";
         warn "$warn       $!";
      } $tdir=~tr/\\/\//;
      my $testd=&test_dir($localhost->{_cmd_handle},$tdir);
      if ($testd eq 'WRITE') {
         my $drive='';my $path='';
         if ($OS eq 'cygwin') {
            $tdir=~s/$localhost->{_cygdrive_regex}//;
            ($drive,$path)=unpack('a1 a*',$tdir);
            $tdir=$drive.':'.$path;
            $tdir=~tr/\//\\/;
            $tdir=~s/\\/\\\\/g;
         }
         if ($tdir ne $curdir) {
            if ($OS eq 'cygwin') {
               ${$work_dirs}{_cwd}=$localhost->{_cygdrive}
                                  .'/'.lc($drive).$path.'/';
               ($output,$stderr)=$localhost->cmd(
                  'cd '.${$work_dirs}{_cwd});
               &handle_error($stderr,'-2','__cleanup__') if $stderr;
               ${$work_dirs}{_cwd_mswin}=$tdir.'\\';
            } else {
               ($output,$stderr)=$localhost->cmd("cd $tdir");
               &handle_error($stderr,'-2','__cleanup__') if $stderr;
               ${$work_dirs}{_cwd}=$tdir.'/';
            } 
         } else {
            ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_pre_mswin}
               if $OS eq 'cygwin';
            ${$work_dirs}{_cwd}=${$work_dirs}{_pre};
         }
         ${$work_dirs}{_tmp_mswin}=${$work_dirs}{_cwd_mswin}
            if $OS eq 'cygwin';
         $master_transfer_dir=${$work_dirs}{_tmp}
                             =${$work_dirs}{_cwd};
         return $work_dirs;
      }
   }
   if ($OS eq 'cygwin') {
      ($output,$stderr)=$localhost->cmd("cd /tmp");
      if (!$stderr) {
         $curdir=&Net::FullAuto::FA_lib::push_cmd($localhost,'cmd /c chdir',
                 $localhost->{'hostlabel'}[0]);
         my ($drive,$path)=unpack('a1 x1 a*',$curdir);
         my $tdir=$localhost->{_cygdrive}.'/'
                 .lc($drive).$path.'/';
         $tdir=~tr/\\/\//;
         my $testd=&test_dir($localhost->{_cmd_handle},$tdir);
         if ($testd eq 'WRITE') {
            ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_tmp_mswin}=$curdir.'\\';
            ${$work_dirs}{_cwd}=${$work_dirs}{_tmp}=$tdir;
            return $work_dirs;
         } else {
            ($output,$stderr)=$localhost->cmd('cd -')
            &handle_error($stderr,'-2','__cleanup__') if $stderr;
         }
      }
      if ((${$work_dirs}{_tmp},${$work_dirs}{_tmp_mswin})
            =&File_Transfer::get_drive(
            '/tmp','Target','',"__Master_${$}__")) {
         my $testd=&test_dir($localhost->{_cmd_handle},
                   ${$work_dirs}{_tmp});
         if ($testd eq 'WRITE') {
            if (lc(${$work_dirs}{_tmp_mswin}) ne lc($curdir)) {
               ($output,$stderr)=$localhost->cmd(
                  'cd '.${$work_dirs}{_tmp});
               &handle_error($stderr,'-2','__cleanup__') if $stderr;
            }
            ${$work_dirs}{_tmp_mswin}=${$work_dirs}{_cwd_mswin};
            $master_transfer_dir=${$work_dirs}{_tmp}
                                =${$work_dirs}{_cwd};
            return $work_dirs;
         }
      }
      if ((${$work_dirs}{_tmp},${$work_dirs}{_tmp_mswin})
            =&File_Transfer::get_drive(
            '/temp','Target','',"__Master_${$}__")) {
         my $testd=&test_dir($localhost->{_cmd_handle},
                   ${$work_dirs}{_tmp});
         if ($testd eq 'WRITE') {
            if (lc(${$work_dirs}{_tmp_mswin}) ne lc($curdir)) {
               ($output,$stderr)=$localhost->cmd(
                  'cd '.${$work_dirs}{_tmp});
               &handle_error($stderr,'-2','__cleanup__') if $stderr;
            }
            ${$work_dirs}{_tmp_mswin}=${$work_dirs}{_cwd_mswin};
            $master_transfer_dir=${$work_dirs}{_tmp}
                                =${$work_dirs}{_cwd};
            return $work_dirs;
         }
      }
      ($output,$stderr)=$localhost->cmd("cd $home_dir");
      &Net::FullAuto::FA_lib::clean_filehandle($local_host);
      if (!$stderr) {
         $curdir=&Net::FullAuto::FA_lib::push_cmd($localhost,'cmd /c chdir',
                 'cmd /c chdir',$localhost->{'hostlabel'}[0]);
         #my $cou=2;
         #while ($cou--) {
         #   ($curdir,$stderr)=$localhost->cmd('cmd /c chdir',__live__);
         #   &Net::FullAuto::FA_lib::handle_error($stderr,'-1','__cleanup__') if $stderr;
         #   if (!$curdir) {
         #      ($output,$stderr)=
         #         &Net::FullAuto::FA_lib::clean_filehandle($localhost);
         #      &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__') if $stderr;
         #   } else { last }
         #}
         my ($drive,$path)=unpack('a1 x1 a*',$curdir);
         $path=~tr/\\/\//;
         $tdir=$localhost->{_cygdrive}.'/'.lc($drive).$path.'/';
         my $testd=&test_dir($localhost->{_cmd_handle},$tdir);
         if ($testd eq 'WRITE') {
            ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_tmp_mswin}=$curdir.'\\';
            ${$work_dirs}{_cwd}=${$work_dirs}{_tmp}=$tdir;
            return $work_dirs;
         } else {
            ($output,$stderr)=$localhost->cmd('cd -')
            &handle_error($stderr,'-2','__cleanup__') if $stderr;
         }
      }
      $testd=&test_dir($localhost->{_cmd_handle},$curdir);
      if ($testd eq 'WRITE') {
         ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_pre_mswin};
         ${$work_dirs}{_tmp_mswin}=${$work_dirs}{_pre_mswin};
         ${$work_dirs}{_cwd}=${$work_dirs}{_tmp}=${$work_dirs}{_pre};
         return $work_dirs;
      } else {
         my $die="\n       FATAL ERROR - Cannot Write to "
                ."Local Host $Local_HostName!";
         &handle_error($die,'__cleanup__');
      }
   } $testd=&test_dir($localhost->{_cmd_handle},'/tmp');
   if ($testd eq 'WRITE') {
      ($output,$stderr)=$localhost->cmd('cd /tmp')
         if '/tmp' ne $curdir;
      &handle_error($stderr,'-2','__cleanup__') if $stderr;
      $master_transfer_dir=${$work_dirs}{_cwd}
         =${$work_dirs}{_tmp}='/tmp/';
      return $work_dirs;
   } $testd=&test_dir($localhost->{_cmd_handle},$home_dir);
   if ($testd eq 'WRITE') {
      ($output,$stderr)=$localhost->cmd("cd $home_dir")
         if $home_dir ne $curdir;
      &handle_error($stderr,'-2','__cleanup__') if $stderr;
      $master_transfer_dir=${$work_dirs}{_cwd}
         =${$work_dirs}{_tmp}=$home_dir.'/';
      return $work_dirs;
   }
   my $testd=&test_dir($localhost->{_cmd_handle},$curdir);
   if ($testd eq 'WRITE') {
      $master_transfer_dir=${$work_dirs}{_cwd}
         =${$work_dirs}{_tmp}=$cur_dir.'/';
      return $work_dirs;
   } else {
      my $die="\n       FATAL ERROR - Cannot Write to "
             ."Local Host $Local_HostName!";
      &handle_error($die,'__cleanup__');
   }

}

sub master_transfer_dir_no_telnet_login
{

   #my $transfer_dir='';
   my $curdir=Cwd::getcwd();
   if (exists $Hosts{"__Master_${$}__"}{'TransferDir'}
         && -d $Hosts{"__Master_${$}__"}{'TransferDir'}
         && -w _) {
      $master_transfer_dir=$Hosts{"__Master_${$}__"}{'TransferDir'};
print "HEREWEARE\n";<STDIN>;
      if (unpack('x1 a1',"$master_transfer_dir") eq ':') {
         my ($drive,$path)=unpack('a1 @2 a*',$master_transfer_dir);
         $path=~tr/\\/\//;
         $master_transfer_dir=$localhost->{_cygdrive}."/$drive$path/";
      }
   } elsif ($OS ne 'cygwin' &&
               $OS ne 'MSWin32' &&
               $OS ne 'MSWin64' &&
               $ENV{OS} ne 'Windows_NT' &&
               -d '/tmp' && -w _) {
      $master_transfer_dir="/tmp/";
   } elsif ($OS eq 'cygwin' &&
                        -d $localhost->{_cygdrive}.'/c/tmp' && -w _) {
      $master_transfer_dir=$localhost->{_cygdrive}.'/c/tmp/';
   } elsif ($OS eq 'cygwin' &&
                       -d $localhost->{_cygdrive}.'/c/temp' && -w _) {
      $master_transfer_dir=$localhost->{_cygdrive}.'/c/temp/';
   } elsif (-d $home_dir && -w _) {
      $master_transfer_dir=$home_dir;
      if (unpack('@1 a1',$master_transfer_dir) eq ':') {
         my ($drive,$path)=unpack('a1 x1 a*',$master_transfer_dir);
         $path=~tr/\\/\//;
         $master_transfer_dir=$localhost->{_cygdrive}.'/'.lc($drive).$path.'/';
      }
   } elsif (!(-w $curdir)) {
      my $die="\n       FATAL ERROR - Cannot Write to "
             ."Local Host $Local_HostName!\n";
      print $die if (!$Net::FullAuto::FA_lib::cron
                   || $Net::FullAuto::FA_lib::debug)
                   && !$Net::FullAuto::FA_lib::quiet;
      print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
   } else {
print "GETTING CURDIR FOR TRANSFER=",cwd(),"\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "GETTING CURDIR FOR TRANSFER=",cwd(),"\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      $master_transfer_dir=$curdir;
   }
   ${$localhost}{_cwd}{_cwd}=Cwd::getcwd();
   return $master_transfer_dir;

}

sub getpasswd
{
   my @topcaller=caller;
   print "main::getpasswd() CALLER="
      ,(join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "main::getpasswd() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $passlabel=$_[0];$passlabel||='';my $use='';
   if (exists $Hosts{$passlabel}) {
      if (exists $Hosts{$passlabel}{'HostName'}) {
         if (exists $Hosts{$passlabel}{'IP'}) {
            if (exists $Hosts{$passlabel}{'Use'}) {
               if (lc($Hosts{$passlabel}{'Use'}) eq 'ip') {
                  $host=$Hosts{$passlabel}{'IP'};
                  $use='ip';
               } else {
                  $host=$Hosts{$passlabel}{'HostName'};
                  $use='hostname';
               }
            } else {
               $host=$Hosts{$passlabel}{'HostName'};
               $use='hostname';
            }
         } else {
            $host=$Hosts{$passlabel}{'HostName'};
            $use='hostname';
         }
      } elsif (exists $Hosts{$passlabel}{'IP'}) {
         $host=$Hosts{$passlabel}{'IP'};
         $use='ip';
      }
   }
     
   my $login_id=$_[1];
   my $force=0;my $su_login=0;
   my $ms_domain='';my $errmsg='';
   my $track='';my $prox='';
   my $pass='';my $save_passwd='';
   my $cmd_type='';
   if (defined $_[2] && $_[2]) {
      if ($_[2] eq '__force__') {
         $force=1;
      } elsif ($_[2] eq '__su__') {
         $su_login=1;
      } else {
         $ms_domain=$_[2];
      }
   }
   if (defined $_[3] && $_[3]) {
      if ($_[3] eq '__force__') {
         $force=1;
      } elsif ($_[3] eq '__su__') {
         $su_login=1;
      } else {
         $errmsg=$_[3];
         $errmsg=~s/\s+$//s;
         $errmsg.="\n";
         $force=1;
      }
   }
   if (defined $_[4] && $_[4]) {
      if ($_[4] eq '__force__') {
         $force=1;
      } elsif ($_[4] eq '__su__') {
         $su_login=1;
      } else {
         $track=$_[4];
      }
   }
   if (defined $_[5] && $_[5]) {
      if ($_[5] eq '__force__') {
         $force=1;
      } elsif ($_[5] eq '__su__') {
         $su_login=1;
      } else {
         $cmd_type=$_[5];
         $prox='SMB_Proxy' if $cmd_type eq 'smb';
      }
   }
   if (defined $_[6] && $_[6]) {
      if ($_[6] eq '__force__') {
         $force=1;
      } elsif ($_[6] eq '__su__') {
         $su_login=1;
      }
   }
   if (defined $_[7] && $_[7]) {
      if ($_[7] eq '__force__') {
         $force=1;
      } elsif ($_[7] eq '__su__') {
         $su_login=1;
      }
   }
   my $cipher = new Crypt::CBC($Net::FullAuto::FA_lib::passwd[1],
      $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
   my $local_host_flag=0;my $href='';
   if ($passlabel eq "__Master_${$}__") {
      foreach my $hostlab (keys %same_host_as_Master) {
         next if $hostlab eq "__Master_${$}__";
         $passlabel=$hostlab;
         $local_host_flag=1;
         last;
      }
      if (!$local_host_flag) {
         $passlabel=$local_hostname;
         $local_host_flag=1;
      }
   } elsif (exists $same_host_as_Master{$passlabel}) {
      $local_host_flag=1;
   }
   if (!$passlabel) {
      my $herr="HOSTLABEL or LABEL needed for first arguement to &getpasswd()"
              ."\n\n              Called from ".(caller(0))[1]." line "
              .(caller(0))[2]." :\n       ";
      &handle_error($herr.($!));
   }
   if ($Net::FullAuto::FA_lib::scrub) {
      if ($passlabel eq "__Master_${$}__") {
         foreach my $hostlab (keys %same_host_as_Master) {
            next if $hostlab eq "__Master_${$}__";
            &scrub_passwd_file($hostlab,$login_id)
         }
      } else {
         &scrub_passwd_file($passlabel,$login_id)
      } $force=1;
   }
   my $kind='prod';
   $kind='test' if $Net::FullAuto::FA_lib::test &&
           !$Net::FullAuto::FA_lib::prod;
   print $MRLOG "PASSWDDB=",
      "${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db","<==\n"
      if -1<index $MRLOG,'*';
   my $tie_err="can't open tie to "
           . $Hosts{"__Master_${$}__"}{'FA_Secure'}
           ."${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db";
   my $ct=0;my $key='';my $to=2;
   if ($local_host_flag && $username eq $login_id) {
      $key="${username}_X_${passlabel}_X_${$}_X_$invoked[0]";
   } elsif ($cmd_type) {
      $key="${username}_X_${login_id}_X_${passlabel}_X_${cmd_type}";
   } else {
      $key="${username}_X_${login_id}_X_${passlabel}";
   }
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
      %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},'MLDBM::Sync',
      $Hosts{"__Master_${$}__"}{'FA_Secure'}.
      "${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db",
      $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
      &handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');

   eval {
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   };
   if ($@) { &Net::FullAuto::FA_lib::handle_error('DYING FROM PASSWORD LOCK') }

   $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel};
   $href||={};
   print $MRLOG "HREF=$href and KEY=$key and KEYS=",
      (join "\n",keys %{$href}),"<==\n" 
      if -1<index $MRLOG,'*';
   if (exists ${$href}{$key} && !$force) {
      if (exists $Hosts{"__Master_${$}__"}{'ps'}) {
         $pspath=$Hosts{"__Master_${$}__"}{'ps'};
         $pspath.='/' if $pspath!~/\/$/;
      }
      my $stdout='';my $stderr='';
      ($stdout,$stderr)=
         &Net::FullAuto::FA_lib::cmd("${pspath}ps -e",'__escape__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__') if $stderr;
      foreach my $ky (keys %{$href}) {
         if ($ky=~/_X_(\d+)_X_\d+$/) {
            my $one=$1;
            delete ${$href}{$ky} if (-1==index $stdout,$one);
         }
      }
      my $encrypted_passwd=
         ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel}{$key};
      ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel}=$href;
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};$pass='';
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
      eval {
         $pass=$cipher->decrypt($encrypted_passwd);
         chop $pass if $pass eq substr($pass,0,(rindex $pass,'.')).'X';
      };
#print $Net::FullAuto::FA_lib::MRLOG "WAHT THE HECK IS PASSWD=$pass<==\n";
      return $pass if $pass && $pass!~tr/\0-\37\177-\377//;
      if (!$pass && $oldpasswd) {
         my $cipher = new Crypt::CBC($oldpasswd,
            $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
         $save_passwd=$cipher->decrypt($encrypted_passwd);
      }
   } elsif (keys %{$href}) {
      $ct=3;
      foreach my $ky (keys %{$href}) {
         if ($ky=~/_X_(\d+)_X_\d+$/) {
            unless (&Net::FullAuto::FA_lib::testpid($1)) {
               delete ${$href}{$ky} unless &Net::FullAuto::FA_lib::testpid($1);
            }
         }
      }
      ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel}=$href;
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   } else {
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   }
   &scrub_passwd_file($passlabel,$login_id);
#print $Net::FullAuto::FA_lib::MRLOG "WAHT THE HECK IS SAVE_PASSWD=$save_passwd<==\n";
   if (!$save_passwd) {
      if ($Net::FullAuto::FA_lib::cron) {
         if ($host) {
            my $die="Invalid Password Stored for\n\n              Hostlabel:  "
                   ." $passlabel\n              Login ID:    $login_id\n    "
                   ."          Needed For:  $host\n\n        "
                   ."      &getpasswd() Called from ".(caller(0))[1]." line "
                   .(caller(0))[2]."\n"
                   ."\n       - Run $Net::FullAuto::FA_lib::progname outside "
                   ."of cron and enter "
                   ."\n         the correct Password when prompted.\n";
            &handle_error($die,'',$track);
            return '',$die;
         } else {
            my $die="Invalid Password Stored for\n\n              Label:"
                   ."   $passlabel\n              Login ID:    $login_id"
                   ."\n\n              "
                   ."&getpasswd() Called from ".(caller(0))[1]." line "
                   .(caller(0))[2]."\n"
                   ."\n       - Run $Net::FullAuto::FA_lib::progname "
                   ."outside of cron and enter "
                   ."\n         the correct Password when prompted.\n";
            &handle_error($die,'',$track);
            return '',$die;
         }
      }
      while (1) {
         print $blanklines;
         print "\n  ERROR MESSAGE-> $errmsg" if $errmsg;
         my $print1='';
         if ($ms_domain) {
            if ($local_host_flag) {
               $print1="\n  Please Enter the MS Domain password for $login_id"
                      ."\n  (XNeeded for Local Host \'$passlabel\' - $host)\n"; 
            } elsif ($host) {
               $print1="\n  Please Enter the MS Domain password for $login_id"
                      ."\n  (Needed for HostLabel \'$passlabel\' - $host)\n";
            } else {
               $print1="\n  Please Enter authentication password."
                      ."\n  (Needed for Label \'$passlabel\')\n";
            }
         } elsif ($login_id eq 'root') {
            if ($local_host_flag) {
               $print1="\n  Please Enter the \'root\' password for $host."
                      ."\n  (ZNeeded for Local Host, "
                      ."HostLabel \'$passlabel\')\n";
            } elsif ($host) {
               $print1="\n  Please Enter the \'root\' password for $host."
                      ."\n  (Needed for HostLabel \'$passlabel\')\n";
            } else {
               $print1="\n  Please Enter authentication password."
                      ."\n  (Needed for Label \'$passlabel\')\n";
            }
         } else {
            if ($local_host_flag) {
               $print1="\n  Please Enter $login_id\'s password for $host."
                      ."\n  (WNeeded for ${prox}Local Host \'$host\')\n";
            } elsif ($host) {
               $print1="\n  Please Enter $login_id\'s password for $host."
                      ."\n  (Needed for ${prox}HostLabel \'$passlabel\')\n";
            } else {
               $print1="\n  Please Enter authentication password."
                      ."\n  (Needed for ${prox}Label \'$passlabel\')\n";
            }
         }
         print $print1;
         print "\n  Password: ";
         ReadMode 2;
         $save_passwd=<STDIN>;
         ReadMode 0;
         chomp($save_passwd);
         print "\n\n";
         if (exists $email_defaults{Usage} &&
               lc($email_defaults{Usage}) eq 'notify_on_error') {
            my $body='';
            $body="\n  ERROR MESSAGE-> $errmsg" if $errmsg;
            $body.=$print1;my $subject='';
            if ($host) {
               $subject="Login Failed for $login_id on $host";
            } else {
               $subject="Authentication Failed";
            }
            my %mail=(
               'Body'    => $body,
               'Subject' => $subject
            );
            &Net::FullAuto::FA_lib::send_email(\%mail);
         }
         last if $save_passwd;
      }
   }
   $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
      %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},'MLDBM::Sync',
      $Hosts{"__Master_${$}__"}{'FA_Secure'}.
      "${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db",
      $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
      &handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel};
   while (delete ${$href}{$key}) {}
   $save_passwd.='X' if $save_passwd
      eq substr($Net::FullAuto::FA_lib::progname,0,
      (rindex $Net::FullAuto::FA_lib::progname,'.'));
   $cipher = new Crypt::CBC($Net::FullAuto::FA_lib::passwd[1],
      $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
   my $new_encrypted=$cipher->encrypt($save_passwd);
   ${$href}{$key}=$new_encrypted;
   ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel}=$href;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   return $save_passwd;

}

sub chgdir
{
   my $pwd='';my $destdir=$_[1];
   my $cmd_handle=$_[0];
   $cmd_handle->cmd("cd $destdir");
   ($pwd)=$cmd_handle->cmd('pwd');
   $pwd=~s/^(.*)?{\n}.*$/$1/;
   chomp($pwd);
#print "PWD=$pwd and DEST=$_[1]\n";<STDIN>;
   if ($pwd eq $_[1] or "$pwd/" eq "$_[1]") { return 1 }
   else {
      print "FATAL ERROR! The directory \"$_[1]\" does NOT exist!";
      return 0;
   }
}

sub runcmd # USAGE: &runcmd(FileHandle, "command_to_run_string")
{

    my @output=${$_[0]}->cmd($_[1]);
    foreach (@output) {
       if (/Execute permiss/) {
          print "FATAL ERROR! Execute permission denied for command:";
          print "--> $_[1]\n";
          return 0;
       }
    } return \@output;
        
}

sub check_if_websphere_is_running
{

   my ($cmd_handle,$applic)=@_;
   return if $websphere_not_running==1;
   my @ls=$cmd_handle->cmd("ls -C1 /usr/WebSphere/AppServer/bin");
   @ls=grep { /^wscp/ } @ls;
   print "--> Verifying that WebSphere is Offline ...\n";
   my $wscp_sub = sub {
      my $wscp_copy=$wscp_UX;
      substr($wscp_copy,(index $wscp_UX,'__JVM__'),7)=$_[1];
      #&chgdir($cmd_handle,"/usr/WebSphere/AppServer/bin")
      #   || handle_error(
      #         "Cannot &chgdir /usr/WebSphere/AppServer/bin");
      my ($output,$stderr)=$cmd_handle->cwd(
            "/usr/WebSphere/AppServer/bin");
      &handle_error($stderr,'-1') if $stderr;
      my $app='';
      $output=&runcmd($_[0],$wscp_copy) ||
         &handle_error("Cannot &runcmd $wscp_copy");
      my @output=@{$output};
      if ($applic eq 'member') { $app='Empire' }
      elsif ($applic eq 'provider') { $app='Provider' }
      foreach (@output) {
         if (/Running|Initializing/ &&
               (($app eq 'Empire' && /(EmpireServer.*)}/m) ||
               ($app eq 'Provider' && /(ProviderServer.*)}/m))) {
            my $serv="";($serv=$1)=~s/}.*$//;
            my $die="\n       FATAL ERROR! - \"$serv\" is RUNNING!\n\n";
            print $die if (!$Net::FullAuto::FA_lib::cron
                         || $Net::FullAuto::FA_lib::debug)
                         && !$Net::FullAuto::FA_lib::quiet;
            print $Net::FullAuto::FA_lib::MRLOG $die
               if $Net::FullAuto::FA_lib::log
               && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
         }
      }
   };
   foreach (@ls) {
      chomp;
      my $num='';
      ($num=$_)=~s/^wscp(\d+)\.sh$/$1/;
      $num='' if substr($num,0,4)=='wscp';
      $wscp_sub->($cmd_handle,$num);
   } $websphere_not_running=1;

}

sub apache_download
{

   $| = 1;  # autoflush
   my $ua = new LWP::UserAgent;
   my ($file,$host,$hostlabel)=@_;
   my ($size,$start_t,$length,$flength,$last_dur)='';

   $ua->agent("mvcode.pl/$version " . $ua->agent);
   my $un=$username;
#print "GP3\n";
   $ua->credentials("$Hosts{\"__Master_${$}__\"}{'IP'}:80",'WebRSH',
                       "$un",&getpasswd($hostlabel,$un));
   $ua->env_proxy;

   my $url="http://${$ApacheNode[0]}[0]/download/$_[0]";
   my $req = new HTTP::Request GET => $url;
   my $shown = 0; # have we called the show() function yet
   my $res = $ua->request($req,
      sub {
         my $res = $_[1];
         open(FILE, ">$file") ||
            &handle_error("Can't open $file: ");
         binmode FILE;
         $length = $res->content_length;
         $flength = fbytes($length) if defined $length;
         $start_t = time;
         $last_dur = 0;
         $size += length($_[0]);
         print FILE $_[0];
         if (defined $length) {
             my $dur  = time - $start_t;
             if ($dur != $last_dur) {  # don't update too often
                $last_dur = $dur;
                my $perc = $size / $length;
                my $speed = fbytes($size/$dur) . "/sec" if $dur > 3;
                my $secs_left = fduration($dur/$perc - $dur);
                $perc = int($perc*100);
                my $show = "$perc% of $flength";
                $show .= " (at $speed, $secs_left remaining)" if $speed;
                show($show, 1);
            }
         } else {
            show( fbytes($size) . " received");
         }
      }
   );

   if ($res->is_success || $res->message =~ /^Interrupted/) {
      show("");  # clear text
      print "\r";
      print fbytes($size);
      print " of ", fbytes($length) if defined($length) && $length != $size;
      print " received";
      my $dur = time - $start_t;
      if ($dur) {
         my $speed = fbytes($size/$dur) . "/sec";
         print " in ", fduration($dur), " ($speed)";
      }
      print "\n";
      my $died = $res->header("X-Died");
      if ($died || !$res->is_success) {
         if (-t) {
            print "Transfer aborted.  Delete $file? [n] ";
            my $ans = <STDIN>;
            unlink($file) if defined($ans) && $ans =~ /^y\n/;
         } else {
            print "Transfer aborted, $file kept\n";
         }
      }
   } else {
      print "\n" if $shown;
      print "$Net::FullAuto::FA_lib::progname: ", $res->status_line, "\n";
      exit 1;
   }

}

sub fbytes
{
   my $n = int(shift);
   if ($n >= 1024 * 1024) {
      return sprintf "%.3g MB", $n / (1024.0 * 1024);
   } elsif ($n >= 1024) {
      return sprintf "%.3g KB", $n / 1024.0;
   } else {
      return "$n bytes";
   }
}

sub fduration
{
   use integer;
   my $secs = int(shift);
   my $hours = $secs / (60*60);
   $secs -= $hours * 60*60;
   my $mins = $secs / 60;
   $secs %= 60;
   if ($hours) {
      return "$hours hours $mins minutes";
   } elsif ($mins >= 2) {
      return "$mins minutes";
   } else {
      $secs += $mins * 60;
      return "$secs seconds";
   }
}

BEGIN {

    my @ani = qw(- \ | /);
    my $ani = 0;

    sub show
    {
        my($mess, $show_ani) = @_;
        print "\r$mess" . (" " x (75 - length $mess));
        print $show_ani ? "$ani[$ani++]\b" : " ";
        $ani %= @ani;
        $shown++;
    }

}

sub Net::Telnet::select_dir
{
print "NetSELECTDIRCALLER=",caller,"\n";#<STDIN>;
   return File_Transfer::select_dir(@_);
}

sub Net::Telnet::mirror
{
   return File_Transfer::mirror(@_);
}

sub send_email
{
   my @topcaller=caller;
   print "send_email() CALLER=",(join ' ',@topcaller),"\n";
      #if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "send_email() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $usage='notify_on_error';my $mail_module='Mail::Sender';
   my $mail_method='';my $mail_server='';my $body='';
   my $bcc='';my $cc='';my $content_type='';my $priority='';
   my $content_transfer_encoding='';my $content_disposition='';
   my $date='';my $from='';my $keywords='';my $message_id='';
   my $mime_version='';my $organization='';my $received='';
   my $references='';my $reply_to='';my $resent_from='';
   my $return_path='';my $sender='';my $subject='';
   my $to='';my $sendemail=0;my $done_warning=0;
   my $head='';my $mail_sender='';my %mail_sender_defaults=();
   my $mail_info=$_[0];my $debug=$_[1];$debug||=0;
   my $warn=1 if grep { lc($_) eq '__warn__' } @_;
   tie *debug, "MemoryHandle";
   if (ref $mail_info eq 'HASH') {
      if (exists ${$mail_info}{Usage}) {
         $usage=${$mail_info}{Usage};
      } elsif ($email_defaults &&
           (exists $email_defaults{Usage})) {
         $usage=$email_defaults{Usage};
      }
      if ($usage ne 'notify_on_error'
               && (caller(1))[3] eq 'FA_lib::handle_error') {
         return 0;
      }
      if (exists ${$mail_info}{Mail_Module}) {
         $mail_module=${$mail_info}{Mail_Module};
      } elsif ($email_defaults &&
           (exists $email_defaults{Mail_Module})) {
         $mail_module=$email_defaults{Mail_Module};
      }
      if ($mail_module eq 'Mail::Internet') {
         $head=Mail::Header->new;
      }
      if ($mail_module ne 'Mail::Sender') {
         if (exists ${$mail_info}{Mail_Method}) {
            $mail_method=${$mail_info}{Mail_Method};
         } elsif ($email_defaults &&
              (exists $email_defaults{Mail_Method})) {
            $mail_method=$email_defaults{Mail_Method};
         }
      } else {
         %mail_sender_defaults=%Mail::Sender::default;
         $Mail::Sender::default{debug}=\*debug;
         #$Mail::Sender::default{debug}='/tmp/maildebug.log';
      }
      if (exists ${$mail_info}{Mail_Server}) {
         $mail_server=${$mail_info}{Mail_Server};
         if ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{smtp}=$mail_server;
         }
      } elsif ($email_defaults &&
           (exists $email_defaults{Mail_Server})) {
         $mail_server=$email_defaults{Mail_Server};
         if ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{smtp}=$mail_server;
         }
      }
      if (exists ${$mail_info}{Bcc}) {
         $bcc=${$mail_info}{Bcc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $bcc eq 'ARRAY') {
               $head->add(Bcc => $bcc);
            } else {
               $head->add(Bcc => "$bcc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{bcc}=$bcc;
         }
         $sendemail=1;
      } elsif ($email_defaults &&
            (exists $email_defaults{Bcc})) {
         $bcc=$email_defaults{Bcc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $bcc eq 'ARRAY') {
               $head->add(Bcc => $bcc);
            } else {
               $head->add(Bcc => "$bcc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{bcc}=$bcc;
         }
         $sendemail=1;
      }
      if (exists ${$mail_info}{Cc}) {
         $cc=${$mail_info}{Cc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $bcc eq 'ARRAY') {
               $head->add(Cc => $cc);
            } else {
               $head->add(Cc => "$cc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{cc}=$cc;
         }
         $sendemail=1;
      } elsif ($email_defaults &&
            (exists $email_defaults{Cc})) {
         $cc=$email_defaults{Cc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $cc eq 'ARRAY') {
               $head->add(Cc => $cc);
            } else {
               $head->add(Cc => "$cc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{cc}=$cc;
         }
         $sendemail=1;
      }
      if (exists ${$mail_info}{Reply_To}) {
         $reply_to=${$mail_info}{Reply_To};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Reply-To => "$reply_to");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{replyto}=$reply_to;
         }
      } elsif ($email_defaults &&
            (exists $email_defaults{Reply_To})) {
         $reply_to=$email_defaults{Reply_To};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Reply-To => "$reply_to");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{replyto}=$reply_to;
         }
      }
      if (exists ${$mail_info}{Priority}) {
         $priority=${$mail_info}{Priority};
         if ($mail_module eq 'Mail::Internet') {
            #$head->add(Reply-To => $priority);
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{priority}=1;
            $Mail::Sender::default{headers}="Importance: 1";
         }
      } elsif ($email_defaults &&
            (exists $email_defaults{Reply_To})) {
         $reply_to=$email_defaults{Reply_To};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Reply-To => "$reply_to");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{replyto}=$reply_to;
         }
      }
      if (exists ${$mail_info}{From}) {
         $from=${$mail_info}{From};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(From => "$from");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{from}=$from;
         }
      } elsif ($email_defaults &&
            (exists $email_defaults{From})) {
         $from=$email_defaults{From};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $from eq 'ARRAY') {
               $head->add(From => $from);
            } else {
               $head->add(From => "$from");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{from}=$from;
         }
      } else {
         if (!$Net::FullAuto::FA_lib::username) {
            $Net::FullAuto::FA_lib::username=getlogin || getpwuid($<)
         }
         $from="$Net::FullAuto::FA_lib::progname\@$Net::FullAuto::FA_lib::local_hostname";
         if ($mail_module eq 'Mail::Internet') {
            if (ref $from eq 'ARRAY') {
               $head->add(From => $from);
            } else {
               $head->add(From => "$from");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{from}=$from;
         }
      }
      if (exists ${$mail_info}{Subject}) {
         $subject=${$mail_info}{Subject};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Subject => "$subject");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{subject}=$subject;
         }
      } elsif ($email_defaults &&
            (exists $email_defaults{Subject})) {
         $subject=$email_defaults{Subject};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Subject => "$subject");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{subject}=$subject;
         }
      } elsif ($usage eq 'notify_on_error') {
         if ($warn) {
            $subject="WARNING! from $Net::FullAuto::FA_lib::local_hostname";
         } else {
            $subject="FATAL ERROR! from $Net::FullAuto::FA_lib::local_hostname";
         }
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Subject => "$subject");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{subject}=$subject;
            $Mail::Sender::default{priority}=1;
            $Mail::Sender::default{headers}="Importance: 1" if !$warn;
         }
      }
      if (exists ${$mail_info}{To}) {
         if ($email_defaults &&
               (exists $email_defaults{To})) {
            $to=[];
            push @{$to}, @{$email_defaults{To}};
         }
         if (exists ${$mail_info}{To} && ${$mail_info}{To}) {
            if (ref ${$mail_info}{To} eq 'ARRAY') {
               if ($to) {
                  push @{$to}, @{${$mail_info}{To}};
               } else { $to=${$mail_info}{To} }
            } else {
               if ($to) {
                  push @{$to}, ${$mail_info}{To};
               } else { $to=${$mail_info}{To} }
            }
         }
         if (!$Net::FullAuto::FA_lib::username) {
            $Net::FullAuto::FA_lib::username=getlogin || getpwuid($<)
         }
         if (ref $to eq 'ARRAY') {
            if ($mail_module eq 'Mail::Internet') {
               my @holder=();
               foreach my $item (@{$to}) {
                  if ($item=~/(__|\])USERNAME(\[|__)/i) {
                     push @holder, $email_addresses{$Net::FullAuto::FA_lib::username}
                        if exists $email_addresses{$Net::FullAuto::FA_lib::username};
                     next;
                  } push @holder, $item;
               } @{$to}=@holder;
            } elsif ($mail_module eq 'Mail::Sender') {
               my $going_to='';
               foreach my $item (@{$to}) {
                  if ($item=~/(__|\])USERNAME(\[|__)/i) {
                     $going_to.="$email_addresses{$Net::FullAuto::FA_lib::username}\\\,"
                        if exists $email_addresses{$Net::FullAuto::FA_lib::username};
                     next;
                  } $going_to.="$item\\\,";
               } $to=substr($going_to,0,-2);
            }
         } elsif ($to=~/(__|\])USERNAME(\[|__)/i) {
            $to=$email_addresses{$Net::FullAuto::FA_lib::username}
               if exists $email_addresses{$Net::FullAuto::FA_lib::username};
         }
         if ($mail_module eq 'Mail::Internet') {
            if (ref $to eq 'ARRAY') {
               $head->add(To => $to);
            } else {
               $head->add(To => "$to");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{to}=$to;
         }
         $sendemail=1;
      } elsif ($email_defaults &&
            (exists $email_defaults{To})) {
         $to=$email_defaults{To};
         if (!$Net::FullAuto::FA_lib::username) {
            $Net::FullAuto::FA_lib::username=getlogin || getpwuid($<)
         }
         if (ref $to eq 'ARRAY') {
            if ($mail_module eq 'Mail::Internet') {
               my @holder=();
               foreach my $item (@{$to}) {
                  if ($item=~/(__|\])USERNAME(\[|__)/i) {
                     push @holder, $email_addresses{$Net::FullAuto::FA_lib::username}
                        if exists $email_addresses{$Net::FullAuto::FA_lib::username};
                     next;
                  } push @holder, $item;
               } @{$to}=@holder;
            } elsif ($mail_module eq 'Mail::Sender') {
               my $going_to='';
               foreach my $item (@{$to}) {
                  if ($item=~/(__|\])USERNAME(\[|__)/i) {
                     $going_to.="$email_addresses{$Net::FullAuto::FA_lib::username}\\\,"
                        if exists $email_addresses{$Net::FullAuto::FA_lib::username};
                     next;
                  } $going_to.="$item\\\,";
               } $to=substr($going_to,0,-2);
            }
         } elsif ($to=~/(__|\])USERNAME(\[|__)/i) {
            $to=$email_addresses{$Net::FullAuto::FA_lib::username}
               if exists $email_addresses{$Net::FullAuto::FA_lib::username};
         }
         if ($mail_module eq 'Mail::Internet') {
            if (ref $to eq 'ARRAY') {
               $head->add(To => $to);
            } else {
               $head->add(To => "$to");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{to}="$to";
         }
         $sendemail=1;
      }
   } elsif ($email_defaults) {
      $usage=$email_defaults{Usage}
         if (exists $email_defaults{Usage});
      if ($usage ne 'notify_on_error'
               && (caller(1))[3] eq 'FA_lib::handle_error') {
         return 0;
      }
      if ($mail_module eq 'Mail_Sender') {
         %mail_sender_defaults=%Mail::Sender::default;
         $Mail::Sender::default{debug}=\*debug;
         #$Mail::Sender::default{debug}='/tmp/maildebug.log';
      }
      $mail_method=$email_defaults{Mail_Method}
         if ($mail_module ne 'Mail::Sender' &&
         exists $email_defaults{Mail_Method});
      if (exists $email_defaults{Mail_Server}) {
         $mail_server=$email_defaults{Mail_Server};
         if ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{smtp}=$mail_server;
         }
      }
      if (exists $email_defaults{Bcc}) {
         $bcc=$email_defaults{Bcc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $bcc eq 'ARRAY') {
               $head->add(Bcc => $bcc);
            } else {
               $head->add(Bcc => "$bcc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{bcc}=$bcc;
         }
         $sendemail=1;
      }
      if (exists $email_defaults{Cc}) {
         $cc=$email_defaults{Cc};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $bcc eq 'ARRAY') {
               $head->add(Cc => $cc);
            } else {
               $head->add(Cc => "$cc");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{bcc}=$bcc;
         }
         $sendemail=1;
      }
      if (exists $email_defaults{From}) {
         $from=$email_defaults{From};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $from eq 'ARRAY') {
               $head->add(From => $from);
            } else {
               $head->add(From => "$from");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{from}=$from;
         }
      }
      if (exists $email_defaults{Subject}) {
         $subject=$email_defaults{Subject};
         if ($mail_module eq 'Mail::Internet') {
            $head->add(Subject => "$subject");
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{subject}=$subject;
         }
      }
      if (exists $email_defaults{To}) {
         $to=$email_defaults{To};
         if ($mail_module eq 'Mail::Internet') {
            if (ref $to eq 'ARRAY') {
               $head->add(To => $to);
            } else {
               $head->add(To => "$to");
            }
         } elsif ($mail_module eq 'Mail::Sender') {
            $Mail::Sender::default{to}=$to;
         }
         $sendemail=1;
      }
   } else {
      warn "EMAIL ERROR - no email information defined       $!";
      $done_warning=1;
   }
   if (!$sendemail && !$done_warning) {
      warn "EMAIL ERROR - no recipients defined       $!";
   }
#print "KEYSS=",keys %Mail::Sender::default,"\n";<STDIN>;
   if ($sendemail) {
      if (ref $mail_info eq 'HASH') {
         if (exists ${$mail_info}{Body}) {
            $body=${$mail_info}{Body};
         } elsif ($email_defaults &&
              (exists $email_defaults{Body})) {
            $body=$email_defaults{Body};
         } elsif (exists ${$mail_info}{Msg}) {
            $body=${$mail_info}{Msg};
         } elsif ($email_defaults &&
              (exists $email_defaults{Msg})) {
            $body=$email_defaults{Msg};
         } elsif (exists ${$mail_info}{Message}) {
            $body=${$mail_info}{Message};
         } elsif ($email_defaults &&
              (exists $email_defaults{Message})) {
            $body=$email_defaults{Message};
         }
      } elsif ($email_defaults &&
           (exists $email_defaults{Body})) {
         $body=$email_defaults{Body};
      } elsif ($email_defaults &&
           (exists $email_defaults{Msg})) {
         $body=$email_defaults{Msg};
      }
      if ($mail_module eq 'Mail::Sender') {
         $body=join '',@{$body} if ref $body eq 'ARRAY';
         $Mail::Sender::NO_X_MAILER=1;
         my $mail_err=0;
         while (1) {
            $mail=new Mail::Sender;
            $body.="\n\n\n##########   BEGIN DEBUGGING OUTPUT"
                 ."##########\n\n\n$Net::FullAuto::FA_lib::debug\n"
                 if $debug;
            $body="\n" if !$body;
            if (ref ($mail->MailMsg({msg=>$body}))) {
               if (wantarray) {
                  if ($debug) {
                     my $dbug='';
                     while (<debug>) { $dbug.=$_ }
                     print $Net::FullAuto::FA_lib::MRLOG $dbug
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     %Mail::Sender::default=%mail_sender_defaults;
                     return 'Mail sent OK.','',"$dbug";
                  } else {
                     %Mail::Sender::default=%mail_sender_defaults;
                     return 'Mail sent OK.','','';
                  }
               } elsif ((!$Net::FullAuto::FA_lib::cron ||
                         $Net::FullAuto::FA_lib::debug) &&
                         !$Net::FullAuto::FA_lib::quiet) {
                  if ($debug) {
                     while (my $line=<debug>) {
                        print $line;
                        print $Net::FullAuto::FA_lib::MRLOG $line
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     }
                  }
                  print "\nMail sent OK.\n";
               } last
            } elsif (wantarray) {
               if ($debug) {
                  my $dbug='';
                  while (<debug>) { $dbug.=$_ }
                  print $Net::FullAuto::FA_lib::MRLOG $dbug
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  %Mail::Sender::default=%mail_sender_defaults;
                  return '',"$Mail::Sender::Error","$dbug";
               } else {
                  %Mail::Sender::default=%mail_sender_defaults;
                  return '',"$Mail::Sender::Error",'';
               }
            } elsif (!$mail_err && $Mail::Sender::Error && -1<index
                  $Mail::Sender::Error,'Address already in use') {
               sleep $timeout;$mail_err=1;
            } else {
               if ($debug &&
                     (!$Net::FullAuto::FA_lib::cron ||
                      $Net::FullAuto::FA_lib::debug) &&
                      !$Net::FullAuto::FA_lib::quiet) {
                  while (my $line=<debug>) {
                     print $line;
                     print $Net::FullAuto::FA_lib::MRLOG $line
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  }
                  my $m_err="Error From Perl CPAN Module \'Mail::Sender\':\n"
                           . "       $Mail::Sender::Error\n";
                  print $Net::FullAuto::FA_lib::MRLOG $m_err if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  die "$m_err"; 
               }
            }
         }
      } elsif ($mail_module eq 'Mail::Internet') {
         $body=[$body] if ref $body ne 'ARRAY';
         $mail=Mail::Internet->new(Header => $head,
                                   Body   => $body,
                                   Modify => 1);
         if ($mail_server) {
            if (ref $mail_server eq 'ARRAY') {
               print $mail->send($mail_method,Server => $mail_server);
            } else {
               print $mail->send($mail_method,Server => "$mail_server");
            }
         } else {
            print $mail->send($mail_method);
         }
      }
   } %Mail::Sender::default=%mail_sender_defaults;

}

sub fa_login
{

   if (defined $_[0] && $_[0]=~/^\d+$/) {
      $timeout=$_[0];
   } else {
      my $time_out='$' . (caller)[0] . '::timeout';
      $time_out= eval $time_out;
      if ($@ || $time_out!~/^[1-9]+/) {
         $timeout=30;
      } else { $timeout=$time_out }
   } $test=0;$prod=0;
   $log_='$' . (caller)[0] . '::log';
   $log_= eval $log_;
   $log_=0 if $@ || !$log_;
   my $fhtimeout='X';
   my $fatimeout=$timeout;
   my $tst='$' . (caller)[0] . '::test';
   $tst=eval $tst;
   $test=$tst if !$@ || $tst=~/^[1-9]+/;
   my $_connect='connect_ssh_telnet';
   if (exists $Hosts{"__Master_${$}__"}{'Local'}) {
      my $loc=$Hosts{"__Master_${$}__"}{'Local'};
      unless ($loc eq 'connect_ssh'
             || $loc eq 'connect_telnet'
             || $loc eq 'connect_ssh_telnet'
             || $loc eq 'connect_telnet_ssh') {
          my $die="\n       FATAL ERROR - \"Local\" has "
                 ."*NOT* been Properly\n              Defined in the "
                 ."\"$fa_hosts\" File.\n              This "
                 ."Element must have one of the following\n"
                 ."              Values:\n\n       "
                 ."          'connect_ssh'or 'connect_telnet'\n       "
                 ."          'connect_ssh_telnet' or\n       "
                 ."          'connect_telnet_ssh'\n\n"
                 ."       \'$loc\' is INCORRECT.\n\n";
          print $Net::FullAuto::FA_lib::MRLOG $die
             if $Net::FullAuto::FA_lib::log &&
             -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
          &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
      } elsif ($loc eq 'connect_ssh') {
          $_connect=$loc;
          @RCM_Link=('ssh');
      } elsif ($loc eq 'connect_telnet') {
          $_connect=$loc;
          @RCM_Link=('telnet');
      } elsif ($loc eq 'connect_ssh_telnet') {
          $_connect=$loc;
          @RCM_Link=('ssh','telnet');
      } else {
          $_connect=$loc;
          @RCM_Link=('telnet','ssh');
      }
   } else { @RCM_Link=('ssh','telnet') }
   $email_defaults='%' . (caller)[0] . '::email_defaults';
   %email_defaults=eval $email_defaults;
   if ($@) {
      $email_defaults=0;
      %email_defaults=();
   } else { $email_defaults=1 }
   my $email_addresses='%' . (caller)[0] . '::email_addresses';
   %email_addresses=eval $email_addresses;
   %email_addresses=() if $@;
   $sub_module='$' . (caller)[0] . '::sub_module';
   $sub_module=eval $sub_module;
   if ($@) {
      my $die="Cannot Locate the 'user-subroutine-module-file'.pm file"
              . "\n\t< original default name 'usr_code.pm' >\n\n\t$@";
      &handle_error($die,'-3');
   } my $submodule=substr($sub_module,0,-3).'=s';
   my $submodarg=substr($sub_module,0,-3).'-arg=s';

   my $man=0;my $help=0;my $userflag=0;my $passerror=0;
   my $test_arg=0;my $oldcipher='';
   our $debug=0;my @holdARGV=@ARGV;@menu_args=();

   &GetOptions(
                'debug'            => \$debug,
                'scrub'            => \$scrub,
                'help|?'           => \$help,
                'log'              => \$log,
                 man               => \$man,
                'password=s'       => \$passwd[0],
                'quiet'            => \$quiet,
                'oldpassword=s'    => \$oldpasswd,
                'oldcipher=s'      => \$oldcipher,
                'updatepw'         => \$updatepw,
                'local-login-id=s' => \$username,
                'login=s'          => \$username,
                'usr-code=s'       => \$usr_code,
                'usr_code=s'       => \$usr_code,
                $submodule         => \$usr_code,
                'user-arg=s'       => \@menu_args,
                'user_arg=s'       => \@menu_args,
                $submodarg         => \@menu_args,
                'cron'             => \$cron,
                'random'           => \$random,
                'timeout=i'        => \$cltimeout,
                'prod'             => \$prod,
                'test'             => \$test_arg,
              ) or pod2usage(2);
   pod2usage(1) if $help;
   pod2usage(-exitstatus => 0, -verbose => 2) if $man;
   @ARGV=@holdARGV;undef @holdARGV;
   $random='__random__' if $random;
   $log=$log_ if !$log;
   if ($test_arg) {
      $prod=0;$test=1;
   } elsif ($prod) {
      $test=0;
   }
   if (-1<$#_ && $_[0] && $_[0]!~/^\d+$/) {
      if ($#_ && $#_%2!=0) {
         my $key='';my $margs=0;
         foreach my $arg (@_) {
            if (!$key) {
               $key=$arg;next;
            } else {
               if ($key eq 'local-login-id') {
                  $username=$arg;
               } elsif ($key eq 'login') {
                  $username=$arg;
               } elsif ($key eq 'password') {
                  $arg=~/^(.*)$/;
                  $passwd[0]=$1;
               } elsif ($key eq 'user_arg' ||
                     $key eq 'user-arg' ||
                     $key eq $submodarg) {
                  @menu_args=() if !$margs;
                  $margs=1;
                  push @menu_args, $arg;
               } elsif ($key ne 'test' || $prod==0) {
                  ${$key}=$arg;
               } $key='';
            }
         }
      } else {
         &handle_error("Wrong Number of Arguments to &fa_login");
      }
   } elsif (!$prod && defined $_[1] &&
           (!defined $_[0] || !$_[0] || $_[0]=~/^\d+$/)) {
      $test=$_[1];
   }
   $passwd[1]=$passwd[0];
   if ($Hosts{"__Master_${$}__"}{'Cipher'}=~/DES/
         && 7<length $passwd[0]) {
      $passwd[1]=unpack('a8',$passwd[0])
   }

   print "\n  Starting $progname . . .\n" if (!$cron || $debug)
         && !$quiet;
   sleep 2 if $debug;

   if ($username) {
      $userflag=1;
   } else {
      $username=getlogin || getpwuid($<);
   }
   my $su_scrub='';my $login_Mast_error='';my $id='';my $use='';
   my $hostlabel='';my $mainuser='';my $ignore='';my $retrys='';
   my $su_err='';my $su_id='';my $stdout='';my $stderr='';
   my $ip='';my $hostname='';my $fullhostname='';my $passline='';
   my $host=''; my $cmd_type='';my $cmd_pid='';my $login_id;
   my $password='';
   if (-1<index $Hosts{"__Master_${$}__"}{'HostName'},'.') {
      $hostname=substr($Hosts{"__Master_${$}__"}{'HostName'},0
              ,(index $Hosts{"__Master_${$}__"}{'HostName'},'.'));
      $fullhostname=$Hosts{"__Master_${$}__"}{'HostName'};
   } else {
      $fullhostname=$hostname=$Hosts{"__Master_${$}__"}{'HostName'};
   } my $suroot='';
   foreach my $host (keys %same_host_as_Master) {
      next if $host eq "__Master_${$}__";
      if (exists $Hosts{$host}{'LoginID'} &&
            ($Hosts{$host}{'LoginID'} eq $username)) {
         $su_id='' if !$mainuser;
         $fhtimeout=$Hosts{$host}{'Timeout'}
            if exists $Hosts{$host}{'Timeout'};
         $mainuser=1;
         if (exists $Hosts{$host}{'SU_ID'}) {
            $su_id=$Hosts{$host}{'SU_ID'};
            $hostlabel=$host;
            $suroot=(getgrnam('suroot'))[3];
            last if $su_id eq 'root';
         } next
      } elsif (!$mainuser && exists $Hosts{$host}{'SU_ID'}) {
         $su_id=$Hosts{$host}{'SU_ID'};
         $suroot=(getgrnam('suroot'))[3];
         $fhtimeout=$Hosts{$host}{'Timeout'}
            if exists $Hosts{$host}{'Timeout'};
         $hostlabel=$host;
      } else {
         $fhtimeout=$Hosts{$host}{'Timeout'}
            if exists $Hosts{$host}{'Timeout'};
      } $hostlabel=$host if !$hostlabel;
   } $hostlabel="__Master_${$}__" if !$hostlabel;
   $master_hostlabel=$hostlabel;$hostlabel="__Master_${$}__";
   $Hosts{$hostlabel}{'Uname'}=$OS;
   if ($cltimeout ne 'X') {
      $fatimeout=$fhtimeout=$cltimeout;
   } elsif ($fhtimeout ne 'X') {
      $fatimeout=$fhtimeout;
   } $retrys=0;

   foreach my $key (keys %same_host_as_Master) {
      if (exists $Hosts{$key}{'FA_Secure'}) {
         $Hosts{$key}{'FA_Secure'}.='/' if
            substr($Hosts{$key}{'FA_Secure'},-1) ne '/';
         $Hosts{"__Master_${$}__"}{'FA_Secure'}=
            $Hosts{$key}{'FA_Secure'};
#print "FA_SUCURE2=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
         last
      }
   } my $FA_lib_path='';
   foreach my $key (keys %INC) {
      if (-1<index $key,'FA_lib.pm') {
         $FA_lib_path=substr($INC{$key},0,(rindex $INC{$key},'/')+1);
         last;
      }
   } $Hosts{"__Master_${$}__"}{'FA_lib'}=$FA_lib_path;
   if (!exists $Hosts{"__Master_${$}__"}{'FA_Secure'}) {
      #if (-d $FA_lib_path && -w _) {
      if (-d "/etc" && -w _) {
         #$Hosts{"__Master_${$}__"}{'FA_Secure'}=$FA_lib_path;
         $Hosts{"__Master_${$}__"}{'FA_Secure'}="/etc/";
#print "FA_SUCURE3=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
      } else {
         $Hosts{"__Master_${$}__"}{'FA_Secure'}=(getpwuid($<))[7].'/';
#print "FA_SUCURE4=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
         if (!(-d $Hosts{"__Master_${$}__"}{'FA_Secure'} && -w _)) {
            handle_error("Cannot Write to Encrypted Passwd Directory :".
               "\n\n             ".
               $Hosts{"__Master_${$}__"}{'FA_Secure'});
         }
      }
   } elsif (!(-d $Hosts{"__Master_${$}__"}{'FA_Secure'} && -w _)) {
      handle_error("Cannot Write to Encrypted Passwd Directory :".
         "\n\n             ".
         $Hosts{"__Master_${$}__"}{'FA_Secure'});
   } else {
      $Hosts{"__Master_${$}__"}{'FA_Secure'}.='/' if
         substr($Hosts{"__Master_${$}__"}{'FA_Secure'},-1) ne '/';
print "FA_SUCURE5=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
   }
#&handle_error("THIS IS SO STUPID");

   if ($updatepw) {
      my $uid=$username;
      while (1) {
         if ($OS ne 'cygwin') {
            print $blanklines;
            #print $clear,"\n";
         } else {
            print "$blanklines\n";
         }
         if ($login_Mast_error) {
            print "ERROR MESSAGE-> $login_Mast_error\n";
         }
         if ($test && !$prod) {
            print "\n  Running in TEST mode\n";
         } else { print "\n  Running in PRODUCTION mode\n" }
         print "\n  $hostname Login <$uid> : ";
         &give_semaphore(1234);
         my $usrname=<STDIN>;
         &take_semaphore(1234);
         chomp $usrname;
         $usrname=~s/^\s*//;
         $usrname=~s/\s*$//;
         next if $usrname=~/^\d/ || !$usrname && !$uid;
         $username= ($usrname) ? $usrname : $uid;
         $userflag=1;
         last;
      }
      while (1) {
         print "\n  Enter Old Password: ";
         ReadMode 2;
         &give_semaphore(1234);
         my $pas=<STDIN>;
         $pas=~/^(.*)$/;
         $passwd[0]=$1;
         $sem=take_semaphore(1234);
         ReadMode 0;
         chomp($passwd[0]);
         print "\n\n";
         $passwd[1]=$passwd[0];
         if ($Hosts{"__Master_${$}__"}{'Cipher'}=~/DES/
               && 7<length $passwd[0]) {
            $passwd[1]=unpack('a8',$passwd[0])
         }
         print "  Please Enter Old Password Again: ";
         ReadMode 2;
         &give_semaphore(1234);
         $pas=<STDIN>;
         $pas=~/^(.*)$/;
         $passwd[3]=$1;
         $sem=take_semaphore(1234);
         ReadMode 0;
         chomp($passwd[3]);
         print "\n\n";
         $passwd[4]=$passwd[3];
         if ($Hosts{"__Master_${$}__"}{'Cipher'}=~/DES/
               && 7<length $passwd[3]) {
            $passwd[4]=unpack('a8',$passwd[3])
         }
         if ($passwd[1] eq $passwd[4]) {
            last;
         } else {
            if ($OS ne 'cygwin') {
               print $blanklines;
               #print $clear,"\n";
            } else {
               print "$blanklines\n";
            } print "\n  Passwords did not match!\n";
         }
      }
      while (1) {
         print "\n  Enter New Password: ";
         ReadMode 2;
         &give_semaphore(1234);
         $passwd[5]=<STDIN>;
         $sem=take_semaphore(1234);
         ReadMode 0;
         chomp($passwd[5]);
         print "\n\n";
         $passwd[6]=$passwd[5];
         if ($Hosts{"__Master_${$}__"}{'Cipher'}=~/DES/
               && 7<length $passwd[5]) {
            $passwd[6]=unpack('a8',$passwd[5])
         }
         print "  Please Enter New Password Again: ";
         ReadMode 2;
         &give_semaphore(1234);
         $passwd[7]=<STDIN>;
         $sem=take_semaphore(1234);
         ReadMode 0;
         chomp($passwd[7]);
         print "\n\n";
         $passwd[8]=$passwd[7];
         if ($Hosts{"__Master_${$}__"}{'Cipher'}=~/DES/
              && 7<length $passwd[7]) {
            $passwd[8]=unpack('a8',$passwd[7])
         }
         if ($passwd[6] eq $passwd[8]) {
            last;
         } else {
            if ($OS ne 'cygwin') {
               print $blanklines;
               #print $clear,"\n";
            } else {
               print "$blanklines\n";
            } print "\n  Passwords did not match!\n";
         }
      }
      my $cipher_algorithm=($oldcipher)?$oldcipher:
         $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'};
#print "WHAT IS THE PASS=$passwd[8]\n";
      my $cipher = new Crypt::CBC($passwd[8],
         $cipher_algorithm);
      my $kind='prod';
      $kind='test' if $Net::FullAuto::FA_lib::test
         && !$Net::FullAuto::FA_lib::prod;
      my $tie_err="can't open tie to "
                 . $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'FA_Secure'}
                 ."${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db";
      my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
print $Net::FullAuto::FA_lib::MRLOG "FA_SUCURE6=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
           %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
           'MLDBM::Sync',
           $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'FA_Secure'}.
           "${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db",
           $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
           &handle_error($tie_err);
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
      foreach my $hostn (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}}) {
         my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostn};
         foreach my $key (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}{$hostn}}) {
            if ($key=~/\d+$/) {
               while (delete $href->{$key}) {}
               next
            }
            my $encrypted_passwd=
               ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostn}{$key};
            $pass=$cipher->decrypt($encrypted_passwd);
            if ($pass && $pass!~tr/\0-\37\177-\377//) {
               print "Updated $key\n";
               while (delete $href->{$key}) {}
print "CRUD\n";
               my $cipher = new Crypt::CBC($passwd[8],
                  $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
               my $new_encrypted=$cipher->encrypt($pass);
               $href->{$key}=$new_encrypted;
               #${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostn}=$href;
            } else { print "Skipping $key\n" }
         } ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostn}=$href;
      }
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
      &cleanup();
   }
      
   while (1) {
      eval { # eval is for error trapping. Any errors are
             # handled by the "if ($@)" block at the bottom
             # of this routine.

         if (!$MRLOG) {
            if (exists $Hosts{"__Master_${$}__"}{'LogFile'}
                  && $Hosts{"__Master_${$}__"}{'LogFile'}) {
               if (substr($Hosts{"__Master_${$}__"}{'LogFile'},0,1) eq '~') {
                  $Hosts{"__Master_${$}__"}{'LogFile'}=~s/^[~]/$home_dir/;
               }
               $MRLOG=*MRLOG;
               my $die="Cannot Open LOGFILE - \"" .
                       $Hosts{"__Master_${$}__"}{'LogFile'} . "\"";
               open ($MRLOG, ">$Hosts{\"__Master_${$}__\"}{'LogFile'}")
                  || &handle_error($die);
               $MRLOG->autoflush(1);
               print $MRLOG "\n\n#### NEW PROCESS - ",
                  scalar localtime(time)," #####\n\n";
            } elsif ($log) {
               $MRLOG=*MRLOG;
               open ($MRLOG, ">$home_dir/FAlog${$}d".
                  $Net::FullAuto::FA_lib::invoked[2].
                  $Net::FullAuto::FA_lib::invoked[3].".txt")
                  || &handle_error($die);
               $MRLOG->autoflush(1);
               print $MRLOG "\n\n#### NEW PROCESS - ",
                  scalar localtime(time)," #####\n\n";
            }
         }

         if ($localhost && -1<index $login_Mast_error,'invalid log'
               && -1<index $login_Mast_error,'ogin incor'
               && -1<index $login_Mast_error,'sion den') {
            if ($cmd_type eq 'telnet' &&
                  defined fileno $localhost->{_cmd_handle}) {
               $localhost->{_cmd_handle}->print("\003");
               $localhost->{_cmd_handle}->print('exit');
               while (defined fileno $localhost->{_cmd_handle}) {
                  while (my $line=$localhost->{_cmd_handle}->get) {
print $MRLOG "FA_LOGINTRYINGTOKILL=$line\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $line=~s/\s//g;
                     $allout.=$line;
                     last if $allout=~/logout|closed/s;
                  } $localhost->{_cmd_handle}->close;
               }
            } elsif ($cmd_type eq 'ssh') {
               $localhost->{_cmd_handle}->print("\003");
               $localhost->{_cmd_handle}->print("\003");
               $localhost->{_cmd_handle}->close; 
            } else { $localhost->{_cmd_handle}->close }
         }

         if ($login_Mast_error) {
            if ($login_Mast_error=~/[Ll]ogin|sion den/) {
               $userflag='';$username='';@passwd=();
               chomp($login_Mast_error);
            } else {
               chomp($login_Mast_error);
               #print "ERROR MESSAGE-> $login_Mast_error\n";<STDIN>;
            }
         }

         #&take_semaphore(1234);
         if (!$userflag && !$cron || !$username) {
            my $uid=$username;
            if (!$cron) {
               while (1) {
                  if ($OS ne 'cygwin') {
                     print $blanklines;
                     #print $clear,"\n";
                  } else {
                     print "$blanklines\n";
                  }
                  if ($login_Mast_error) {
                     print "ERROR MESSAGE-> $login_Mast_error\n";
                  }
                  if ($test && !$prod) {
                     print "\n  Running in TEST mode\n";
                  } else { print "\n  Running in PRODUCTION mode\n" }
                  print "\n  $hostname Login <$uid> : ";
                  &give_semaphore(1234);
                  my $usrname=<STDIN>;
                  &take_semaphore(1234);
                  chomp $usrname;
                  $usrname=~s/^\s*//;
                  $usrname=~s/\s*$//;
                  next if $usrname=~/^\d/ || !$usrname && !$uid;
                  $username= ($usrname) ? $usrname : $uid;
                  $userflag=1;
                  last;
               }
            } else {
               &handle_error($login_Mast_error);
            }
         }

         if (!$passwd[0] && !$cron) {
            print "\n  Password: ";
            ReadMode 2;
            &give_semaphore(1234);
            my $pas=<STDIN>;
            $pas=~/^(.*)$/;
            $passwd[0]=$1;
            $sem=take_semaphore(1234);
            ReadMode 0;
            chomp($passwd[0]);
            print "\n\n";
            $passwd[1]=$passwd[0];
            $passwd[1]=unpack('a8',$passwd[0])
               if 7<length $passwd[0];
         }
         $login_id=$username;
         $password=$passwd[0];
         $passwd[2]='';

         $host='localhost';
         my $lc_cnt=-1;
         $localhost={};my $local_host='';
         $localhost=bless $localhost, 'Rem_Command';
         bless $localhost, substr($sub_module,0,-3);

         foreach $connect_method (@RCM_Link) {
            $lc_cnt++;
            if (lc($connect_method) eq 'telnet') {
               $cmd_type='telnet';
               my $telnetpath='';
               if (exists $Hosts{"__Master_${$}__"}{'telnet'}) {
                  $telnetpath=$Hosts{"__Master_${$}__"}{'telnet'};
                  $telnetpath.='/' if $telnetpath!~/\/$/;
               }
               ($local_host,$cmd_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                  ["${telnetpath}telnet",'localhost'])
                  or &Net::FullAuto::FA_lib::handle_error(
                  "couldn't launch telnet subprocess");
#print "CMD_PID=$cmd_pid<======\n";
               $localhost->{_cmd_pid}=$cmd_pid;
               $localhost->{_cmd_type}=$cmd_type;
               $localhost->{_connect}=$_connect;
               $localhost->{_uname}=$OS;
               $local_host=Net::Telnet->new(Fhopen => $localhost,
                  Timeout => $fatimeout);
               $local_host->telnetmode(0);
               $local_host->binmode(1);
               $local_host->output_record_separator("\r");
               $localhost->{_cmd_handle}=$local_host;
               while (my $line=$local_host->get) {
                  chomp($line=~tr/\0-\37\177-\377//d);
print "OUTPUT FROM NEW::TELNET=$line<==\n";
#print $Net::FullAuto::FA_lib::MRLOG "OUTPUT FROM NEW::TELNET=$line<==\n";
#      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if (7<length $line && unpack('a8',$line) eq 'Insecure') {
                     $line=~s/^Insecure/INSECURE/s;
                     if (wantarray) {
                        return '',$line;
                     } else { die $line }
                  }
                  last if $line=~
                     /(?<!Last )login[: ]*$|username[: ]*$/i;
               }

               $local_host->print($login_id);
               &handle_error($local_host->errmsg,'-1') if $local_host->errmsg;
               ## Wait for password prompt.
               ($ignore,$stderr)=
                  &File_Transfer::wait_for_ftr_passwd_prompt($localhost);
               if ($stderr) {
                  if ($lc_cnt==$#RCM_Link) {
                     die $stderr;
                  } else { next }
               } last 
            } elsif (lc($connect_method) eq 'ssh') {
               $cmd_type='ssh';
               if (exists $Hosts{"__Master_${$}__"}{'ssh'}) {
                  $sshpath=$Hosts{"__Master_${$}__"}{'ssh'};
                  $sshpath.='/' if $sshpath!~/\/$/;
               }
               my $try_count=0;
               while (1) {
                  ($local_host,$cmd_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                     ["${sshpath}ssh","$login_id\@localhost",
                      '',$Net::FullAuto::FA_lib::slave])
                     or &Net::FullAuto::FA_lib::handle_error(
                     "couldn't launch ssh subprocess");
                  $localhost->{_cmd_pid}=$cmd_pid;
                  print $Net::FullAuto::FA_lib::MRLOG
                     "SSH_Pid=$cmd_pid at Line ", __LINE__,"<==\n"
                     if $Net::FullAuto::FA_lib::log &&
                     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  $localhost->{_cmd_type}=$cmd_type;
                  $localhost->{_connect}=$_connect;
                  $localhost->{_uname}=$OS;
                  $local_host=Net::Telnet->new(Fhopen => $local_host,
                     Timeout => $fatimeout);
                  $local_host->telnetmode(0);
                  $local_host->binmode(1);
                  $local_host->output_record_separator("\r");
                  $localhost->{_cmd_handle}=$local_host;
                  ## Wait for password prompt.
                  ($ignore,$stderr)=
                     &File_Transfer::wait_for_ftr_passwd_prompt(
                        { _cmd_handle=>$local_host,
                          _hostlabel=>[ "__Master_${$}__",'' ],
                          _cmd_type=>'ssh',
                          _connect=>$_connect });
                  if ($stderr) {
                     if ($lc_cnt==$#RCM_Link) {
                        die $stderr;
                     } elsif (-1<index $stderr,'read timed-out:do_slave') {
                        ($stdout,$stderr)=&kill($cmd_pid,9)
                           if &testpid($cmd_pid);
                        $Net::FullAuto::FA_lib::slave=1;next
                     } elsif (3<$try_count++) {
                        &Net::FullAuto::FA_lib::handle_error($stderr)
                     } else { sleep 1;next }
                  } last
               } last
            }
         }

         ## Send password.
#print "WHAT IS THE PASSWORD=$password<==\n";
print $Net::FullAuto::FA_lib::MRLOG "PRINTING PASSWORD NOW<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         $local_host->print($password);

         if ((!$cron || $debug) && !$quiet) {
            if ($OS ne 'cygwin') {
               print $blanklines;
            } else { print "\n\n" }
            print "--> LoggingA into $host via $cmd_type  . . .\n\n";
         }

         my $newpw='';$passline=__LINE__+1;
         while (my $line=$local_host->get) {
print $Net::FullAuto::FA_lib::MRLOG "WAITING FOR CMDPROMPT=$line<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            my $output='';
            ($output=$line)=~s/login:.*//s;
            if ($OS eq 'cygwin' && $line=~/^$password\n/) {
               $local_host->print("\032");
               $local_host->close;
               $passerror=1;&give_semaphore(1234);
               return;
            }
            if ($line=~/Permission denied/s) {
               #$local_host->print("\032");
               #$local_host->close;
               die "Permission denied";
            }
            &handle_error($output,'__cleanup__')
               if $line=~/(?<!Last )login[: ]*$/m ||
                  (-1<index $line,' sync_with_child: ');
            if ($line=~/new password: ?$/is) {
               $newpw=$line;last;
            }
            if ($OS eq 'cygwin') {
               last if $line=~/[$%>#-:] ?$/m &&
                    unpack('a10',$line) ne 'Last Login'
            } elsif ($line=~/[$|%|>|#|-|:] ?/m) { last }
         }
print $Net::FullAuto::FA_lib::MRLOG "GOT OUT OF COMMANDPROMPT<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

         #&give_semaphore(1234);

         &change_pw($localhost) if $newpw;

         ## Make sure prompt won't match anything in send data.
         $local_host->prompt("/_funkyPrompt_\$/");
         $local_host->print("export PS1=_funkyPrompt_;unset PROMPT_COMMAND");
         $localhost->{_ftm_type}='';
         $localhost->{_cwd}='';
         $localhost->{_hostlabel}=[ "__Master_${$}__",'' ];
         $localhost->{_hostname}=$hostname;
         $localhost->{_ip}=$ip;
         $localhost->{_connect}=$_connect;
         ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($local_host);
         my $wloop=0;
         while (1) {
            my $_sh_pid='';
            ($_sh_pid,$stderr)=Rem_Command::cmd(
               $localhost,'echo $$');
print $Net::FullAuto::FA_lib::MRLOG "LOCAL_sh_pid=$localhost->{_sh_pid}\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $_sh_pid||=0;
            $_sh_pid=~/^(.*)$/;
            $_sh_pid=$1;
            chomp($_sh_pid=~tr/\0-\11\13-\37\177-\377//d);
            $localhost->{_sh_pid}=$_sh_pid;
            if (!$localhost->{_sh_pid}) {
               $localhost->print;
               $localhost->print(
                  'printf \\\\041\\\\041;echo $$;printf \\\\045\\\\045');
               my $allins='';my $ct=0;
               while (1) {
                  eval {
                     while (my $line=$localhost->get(
                              Timeout=>5)) {
                        chomp($line=~tr/\0-\37\177-\377//d);
                        $allins.=$line;
print $Net::FullAuto::FA_lib::MRLOG "PID_line_sh_pid_1=$allins<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        if ($allins=~/!!(.*)%%/) {
                           $localhost->{_sh_pid}=$1;
print $Net::FullAuto::FA_lib::MRLOG
   "PID_line_sh_pid_2=$localhost->{_sh_pid}<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           last;
                        }
                     }
                  };
print $Net::FullAuto::FA_lib::MRLOG "FORCING_sh_pid=$localhost->{_sh_pid}<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($@) {
                     $localhost->print;
                  } elsif (!$localhost->{_sh_pid} && $ct++<50) {
                     $localhost->print;
                  } else { last }
               }
print $Net::FullAuto::FA_lib::MRLOG
   "PID_out_of_WHILE_sh_pid=$localhost->{_sh_pid}<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            } else { last }
            last if $localhost->{_sh_pid} && $localhost->{_sh_pid}=~/^\d+$/;
            #($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($local_host);
            if ($stderr || $wloop++==10) {
               &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                  if $stderr=~/Connection closed/s;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
            }
            ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($local_host);
            if ($stderr) {
               &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                  if $stderr=~/Connection closed/s;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
            }

         }
 
         &su_scrub($hostlabel) if $su_scrub;

         my $switch_user='';
         if (!$mainuser && exists $Hosts{$hostlabel}{'LoginID'}) {
            $switch_user=$Hosts{$hostlabel}{'LoginID'};
            $passwd[0]=$passwd[2]=$password=&Net::FullAuto::FA_lib::getpasswd($hostlabel,
                       $switch_user,'',$ftm_errmsg,__su__);
            $passwd[1]=$passwd[0];
            $passwd[1]=unpack('a8',$passwd[0])
               if 7<length $passwd[0];
            $login_id=$username=$switch_user;
            ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($local_host);
            if ($stderr) {
               &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                  if $stderr=~/Connection closed/s;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
            }
         }

         my $kind='prod';
         $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
         my $tie_err="can't open tie to "
                 . $Hosts{"__Master_${$}__"}{'FA_Secure'}
                 ."${progname}_${kind}_passwds.db";
         my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
print $Net::FullAuto::FA_lib::MRLOG
   "FA_SUCURE7=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
              %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
              'MLDBM::Sync',
              $Hosts{"__Master_${$}__"}{'FA_Secure'}.
              "${progname}_${kind}_passwds.db",
              $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
              &handle_error($tie_err);
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
         my $local_host_flag=0;
         my $host__label='';
         if ($hostlabel eq "__Master_${$}__") {
            foreach my $hostlab (keys %same_host_as_Master) {
               next if $hostlab eq "__Master_${$}__";
               $host__label=$hostlab;
               $local_host_flag=1;
               last;
            }
            if (!$local_host_flag) {
               $host__label=$local_hostname;
               $local_host_flag=1;
            }
         } elsif (exists $same_host_as_Master{$hostlabel}) {
            $local_host_flag=1;
            $host__label=$hostlabel;
         } else { $host__label=$hostlabel }
         my $key='';
         if ($local_host_flag) {
            $key="${login_id}_X_"
                ."${host__label}_X_${$}_X_$invoked[0]";
         } else {
            $key="${username}_X_${login_id}_X_${host__label}";
         }
         my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$host__label};
         foreach my $ky (keys %{$href}) {
            if ($ky eq $key) {
               while (delete $href->{$key}) {}
            } elsif ($ky=~/_X_\d+_X_(\d+)$/ && $1+604800<$invoked[0]) {
               while (delete $href->{$ky}) {}
            }
         }
         my $cipher = new Crypt::CBC($passwd[1],
            $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
         my $new_encrypted=$cipher->encrypt($passwd[0]);
print $Net::FullAuto::FA_lib::MRLOG "FA_LOGIN__NEWKEY=$key<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         $href->{$key}=$new_encrypted;
         ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$host__label}=$href;
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
         undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
         delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
         if ($switch_user) {
            ($ignore,$su_err)=&su($local_host,$hostlabel,
                    $username,$switch_user,$hostname,
                    $ip,$use,$login_Mast_error);
            &handle_error($su_err,'-1') if $su_err;
         }

         if ($OS ne 'cygwin') {

            if ($su_id) {

               ($output,$stderr)=
                  &Net::FullAuto::FA_lib::clean_filehandle($local_host);
               if ($stderr) {
                  &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                     if $stderr=~/Connection closed/s;
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
               }
               ($ignore,$su_err)=&su($local_host,$hostlabel,
                       $login_id,$su_id,$hostname,
                       $ip,$use,$login_Mast_error);
               &handle_error($su_err,'-1') if $su_err;
            } else {
               ($output,$stderr)=
                  &Net::FullAuto::FA_lib::clean_filehandle($local_host);
            }

         }

         if ($OS eq 'cygwin') {
            if (exists $Hosts{"__Master_${$}__"}{'FreeMem'}) {
               $localhost->{_freemem}=$Hosts{"__Master_${$}__"}{'FreeMem'};
            }
            my $wloop=0;
            while (1) {
               ($localhost->{_cygdrive},$stderr)=Rem_Command::cmd(
                  $localhost,"${mountpath}mount -p");
               $localhost->{_cygdrive}=~s/^.*(\/\S+).*$/$1/s;
               last if $localhost->{_cygdrive} && unpack('a1',
                  $localhost->{_cygdrive}) eq '/';
               ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($localhost);
               if ($stderr || $wloop++==10) {
                  &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                     if $stderr=~/Connection closed/s;
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
               }
            } $localhost->{_cygdrive_regex}=qr/^$localhost->{_cygdrive}\//;
         }

         $localhost->{_work_dirs}=&master_transfer_dir($localhost);

         if ($su_id) {
            $Connections{"__Master_${$}____%-$su_id"}
               =$localhost;
         } else {
            $Connections{"__Master_${$}____%-$login_id"}
               =$localhost;
         }

      };
      if ($passerror) {
         $passerror=0;next;
      } elsif ($@) {
         if (7<length $@) {
            if (unpack('a8',$@) eq 'Insecure') {
               print $@;cleanup();
            } elsif (unpack('a8',$@) eq 'INSECURE') {
               $@=~s/INSECURE/Insecure/s;
            }
         }
         $username=getlogin() || (getpwuid($<))[0] || "Intruder!!"
            if !$username;
         $login_id=$username if !$login_id;
         $login_Mast_error=$@;
         if (-1<index $@,'Not a GLOB reference') {
            print $Net::FullAuto::FA_lib::MRLOG
               "$@ and SH_PID=$localhost->{_sh_pid}",
               " and CMD_PID=$localhost->{_cmd_pid}\n"
               if $Net::FullAuto::FA_lib::log &&
               -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            ($stdout,$stderr)=
               &Net::FullAuto::FA_lib::kill($localhost->{_sh_pid},9)
               if exists $localhost->{_sh_pid} &&
               &Net::FullAuto::FA_lib::testpid($localhost->{_sh_pid});
            ($stdout,$stderr)=
               &Net::FullAuto::FA_lib::kill($localhost->{_cmd_pid},9)
               if &Net::FullAuto::FA_lib::testpid($localhost->{_cmd_pid});
            $login_Mast_error='';$retrys++;next; 
         } elsif ((-1<index $@,'Address already in use' ||
               -1<index $@,'Connection refused') && $retrys<2) {
            my $warn="$@\n       Waiting ".int $fatimeout/3
                    ." seconds for re-attempt . . .\n       ".($!);
            warn $warn if (!$cron || $debug) && !$quiet;
            print $MRLOG $warn
               if $log && -1<index $MRLOG,'*';
            sleep int $fatimeout/3;$retrys++;next;
         } elsif (!$cron || (unpack('a3',$@) eq 'pid') ||
               (-1<index $login_Mast_error,$passline)) {
            if ($retrys<2 && -1<index $login_Mast_error,'timed-out') {
print $Net::FullAuto::FA_lib::MRLOG "WE ARE RETRYING LOGINMASTERERROR=$login_Mast_error\n";
               $retrys++;
               if (-1<index $login_Mast_error,'read') {
                  next;
               } else {
                  $login_Mast_error.="\n       $host - is visible on the "
                     ."network,\n       but the Telnet Server is NOT "
                     ."RESPONDING.\n       Check the availability of Telnet "
                     ."Service on\n       $host before continuing"
                     ." ...\n\n";
               }
            }
#print "LOGINMASTERERROR=$login_Mast_error\n";<STDIN>;
            if ($login_Mast_error=~/invalid log|ogin incor|sion den/) {
               if (($OS eq 'cygwin')
                     && 2<=$retrys) {
                  $login_Mast_error.="\n       WARNING! - You may be in"
                                   ." Danger of locking out MS Domain "
                                   ."ID - $login_id!\n\n";
                  if ($retrys==3) {
                     $su_scrub=&scrub_passwd_file(
                        $hostlabel,$login_id);
                  } else { $retrys++;next }
               } elsif (2<=$retrys) {
                  $login_Mast_error.="\n       WARNING! - You may be in"
                                   ." Danger of locking out $OS "
                                   ."localhost ID - $login_id!\n\n";
                  if ($retrys==3) {
                     $su_scrub=&scrub_passwd_file(
                        $hostlabel,$login_id);
                  } else { $retrys++;next }
               } else { $retrys++;next }
            } elsif ($su_id &&
                  -1<index($login_Mast_error,'ation is d')) {
               $su_scrub=&scrub_passwd_file($hostlabel,$su_id);
               next;
            } else {
               &passwd_db_update($hostlabel,$login_id,$password,$cmd_type);
            }
         }
         my $c_t=$cmd_type;$c_t=~s/^(.)/uc($1)/e;
         my $die="\n       FATAL ERROR! - The Host $host Returned"
            ."\n              the Following Unrecoverable Error Condition\,"
            ."\n              Rejecting the $c_t Login Attempt of the ID"
            ."\n              -> $login_id :\n\n       "
            ."$login_Mast_error\n";
         print $MRLOG $die if -1<index $MRLOG,'*';
         print $die if (!$cron || $debug) && !$quiet;
         print $MRLOG $die
            if $log && -1<index $MRLOG,'*';
         &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');

      } last;
   } return $usr_code, \@menu_args, $fatimeout;

}

sub passwd_db_update
{
   my @topcaller=caller;
   print "main::passwd_db_update() CALLER="
      ,(join ' ',@topcaller),"\n";# if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "main::passwd_db_update() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $hostlabel=$_[0];my $login_id=$_[1];my $passwd=$_[2];
   my $cmd_type=$_[3];
   my $kind='prod';
   $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
   my $tie_err="can't open tie to "
              . $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'FA_Secure'}
              ."${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db";
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
print $Net::FullAuto::FA_lib::MRLOG "FA_SUCURE8=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
        %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
        'MLDBM::Sync',
        $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'FA_Secure'}.
        "${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db",
        $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
        &handle_error($tie_err);
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   if ($hostlabel eq "__Master_${$}__") {
      foreach my $hostlab (keys %Net::FullAuto::FA_lib::same_host_as_Master) {
         next if $hostlab eq "__Master_${$}__";
         $hostlabel=$hostlab;
         $local_host_flag=1;
         last;
      }
      if (!$local_host_flag) {
         $hostlabel=$local_hostname;
         $local_host_flag=1;
      }
   } elsif (exists $Net::FullAuto::FA_lib::same_host_as_Master{$hostlabel}) {
      $local_host_flag=1;
   } my $key='';
   if ($local_host_flag) {
      $key="${username}_X_"
          ."${hostlabel}_X_${$}_X_$Net::FullAuto::FA_lib::invoked[0]";
   } elsif ($cmd_type) {
      $key="${username}_X_${login_id}_X_"
          ."${hostlabel}_X_$cmd_type";
   } else {
      $key="${username}_X_${login_id}_X_"
          .$hostlabel;
   }
print $Net::FullAuto::FA_lib::MRLOG "PASSWDUPDATE__NEWKEY=$key<==\n";
   my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel};
   foreach my $ky (keys %{$href}) {
      if ($ky eq $key) {
         while (delete $href->{"$key"}) {}
      } elsif ($ky=~/_X_\d+_X_(\d+)$/ && $1+604800<$invoked[0]) {
         while (delete $href->{"$ky"}) {}
      }
   }
   my $cipher = new Crypt::CBC($Net::FullAuto::FA_lib::passwd[1],
      $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
print "HOW ABOUT PASS NOW=$Net::FullAuto::FA_lib::passwd[1]\n";
   my $new_encrypted=$cipher->encrypt($passwd);
   $href->{$key}=$new_encrypted;
   ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel}=$href;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};

}

sub su_scrub
{
   my $hostlabel=$_[0];my $login_id='';my $cmd_type=$_[1];
   my $kind='prod';
   $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
   my $tie_err="can't open tie to "
              . $Hosts{"__Master_${$}__"}{'FA_Secure'}
              ."${progname}_${kind}_passwds.db";
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
print $Net::FullAuto::FA_lib::MRLOG "FA_SUCURE9=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
        %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
        'MLDBM::Sync',
        $Hosts{"__Master_${$}__"}{'FA_Secure'}.
        "${progname}_${kind}_passwds.db",
        $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) or
        &handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   my $local_host_flag=0;
   if ($hostlabel eq "__Master_${$}__") {
      foreach my $hostlab (keys %Net::FullAuto::FA_lib::same_host_as_Master) {
         next if $hostlab eq "__Master_${$}__";
         $local_host_flag=1;
      }
      if (!$local_host_flag) {
         $local_host_flag=1;
      }
   } elsif (exists $Net::FullAuto::FA_lib::same_host_as_Master{$hostlabel}) {
      $local_host_flag=1;
   }
   my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel};
   my $key='';
   if ($local_host_flag) {
      $key="${username}_X_"
          ."${hostlabel}_X_${$}_X_$Net::FullAuto::FA_lib::invoked[0]";
   } elsif ($cmd_type) {
      $key="${username}_X_${login_id}_X_"
          ."${hostlabel}_X_$cmd_type";
   } else {
      $key="${username}_X_${login_id}_X_"
          .$hostlabel;
   }
   foreach my $ky (keys %{$href}) {
      if ($ky eq $key) {
         while (delete $href->{$key}) {}
      } elsif ($ky=~/_X_\d+_X_(\d+)$/ && $1+604800<$invoked[0]) {
         while (delete $href->{$ky}) {}
      }
   }
   my $cipher = new Crypt::CBC($Net::FullAuto::FA_lib::passwd[1],
      $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'});
   my $new_encrypted=$cipher->encrypt($Net::FullAuto::FA_lib::passwd[0]);
   $href->{$key}=$new_encrypted;
   ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel}=$href;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};

}

sub su
{
   my @topcaller=caller;
   print "su() CALLER=", (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "su() CALLER=", (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $fh=$_[0];
   my $hostlabel=$_[1];
   my $username=$_[2];
   my $su_id=$_[3];
   my $hostname=$_[4];
   my $ip=$_[5];
   my $use=$_[6];
   my $errmsg=$_[7];
   my $pass_flag=0;
   my $id='';my $stderr='';
   if ($su_id eq 'root') {
      my $gids='';
      $fh->print('groups');
      while (my $line=$fh->get) {
         chomp($line=~tr/\0-\37\177-\377//d);
         $gids.=$line;
print $Net::FullAuto::FA_lib::MRLOG "su() GIDS=$gids<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         last if $gids=~s/_funkyPrompt_//gs;
      }
print $Net::FullAuto::FA_lib::MRLOG "su() DONEGID=$gids<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      $gids=unpack('x6 a*',$gids);
      unless (-1<index $gids,'suroot') {
         my $hostlb=$hostlabel;
         if ($hostlabel eq "__Master_${$}__") {
            foreach my $hostlab (keys %same_host_as_Master) {
               next if $hostlab eq "__Master_${$}__";
               $hostlb=$hostlab;
               last;
            }
         }
         my $die="\"$username\" does NOT have authorization to "
                ."run this\n       script on Host : $hostlb\n"
                ."       \"$username\" is not a member of the \"suroot\""
                ." UNIX group.\n       Contact your system administrator.\n";
         my $kind='prod';
         $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
         my $tdie="can't open tie to "
                 . $Hosts{"__Master_${$}__"}{'FA_Secure'}
                 ."${progname}_${kind}_passwds.db: ";
         my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
print $Net::FullAuto::FA_lib::MRLOG "FA_SUCURE10=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
              %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
              'MLDBM::Sync',
              $Hosts{"__Master_${$}__"}{'FA_Secure'}.
              "${progname}_${kind}_passwds.db",
              $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) or
              &handle_error($tdie);
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
         my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel};
         my $key="${username}_X_${su_id}_X_${hostlabel}";
         while (delete $href->{$key}) {}
         ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$hostlabel}=$href;
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
         undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
         delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   print $Net::FullAuto::FA_lib::MRLOG "DYING HERE WITH LOCK PROB" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         return '',"$die       $!";
      }
   }
   #if ($su_id eq 'root') {
      $fh->print("su - $su_id");
   #} else {
   #   $fh->print("login $su_id");
   #}
print $Net::FullAuto::FA_lib::MRLOG "CHECKING ERROR\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   return '', $fh->errmsg if $fh->errmsg;
   #$fh->print("su - $su_id");
   #print $Net::FullAuto::FA_lib::MRLOG "DONE CHECKING ERROR" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

   ## Wait for password prompt.
   my $lin='';
   while (my $line=$fh->get) {
print $Net::FullAuto::FA_lib::MRLOG "su() GETPASSPROMPTLINE=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      chomp($line=~tr/\0-\37\177-\377//d);
      $lin.=$line;
      if ($lin=~/password[: ]+$/si) {
         $pass_flag=1;last;
      } elsif (!$Net::FullAuto::FA_lib::cron && $lin=~/\[YOU HAVE NEW MAIL\]/m) {
         my $hostlab=$hostlabel;
         $hostlab=(keys %same_host_as_Master)[1]
            if $hostlabel eq "__Master_${$}__";
         print "\nAttn: $su_id on $hostlab --> [YOU HAVE NEW MAIL]\n\n";
         sleep 1;
      } last if $lin=~/[$|%|>|#|-|:] ?$/m;
   }

   ## Send password.
print $Net::FullAuto::FA_lib::MRLOG "su() PASSFLAG=$pass_flag\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if ($pass_flag) {
      $fh->print(&getpasswd(
         $hostlabel,$su_id,'',
         $errmsg,'__su__'));
   }

   ($id,$stderr)=&unix_id($fh,$su_id,$hostlabel,$errmsg);
   return '',$stderr if $stderr;

   $id=~s/^(.*)?\n.*$/$1/s;

   if ($id ne $su_id && $id ne 'root') {

      $fh->print("su - $su_id");

      return '',$fh->errmsg if $fh->errmsg;

      ## Wait for password prompt.
      while (my $line=$fh->get) {
         chomp($line=~tr/\0-\37\177-\377//d);
         if ($line=~/password[: ]*$/i) {
            $pass_flag=1;last;
         } elsif (!$Net::FullAuto::FA_lib::cron && $line=~/\[YOU HAVE NEW MAIL\]/m) {
            my $hostlab=$hostlabel;
            $hostlab=(keys %same_host_as_Master)[1]
               if $hostlabel eq "__Master_${$}__";
            print "\nAttn: $su_id on $hostlab --> [YOU HAVE NEW MAIL]\n\n";
            sleep 1;
         } last if $line=~/[$|%|>|#|-|:] ?$/m; 
      }

      ## Send password.
      if ($pass_flag) {
         $fh->print(&getpasswd(
              $hostlabel,$su_id,'',$errmsg,
              '__force__','__su__'));
      }
      ($id,$stderr)=&unix_id($fh,$su_id,$hostlabel,$errmsg);
      if (defined $stderr) {
         return '',$stderr;
      } elsif ($id ne $su_id) {
         return '', "Cannot Login as Alternate User -> $su_id";
      }
   }

   ## Make sure prompt won't match anything in send data.
   my $prompt = '_funkyPrompt_';
   $fh->prompt("/$prompt\$/");
   $fh->print("export PS1=$prompt;unset PROMPT_COMMAND");
   while (my $line=$fh->get) {
      last if $line=~/$prompt$/s;
   }

}

sub change_pw {

   my $cmd_handle=$_[0];
   print $blanklines;
   #print $clear,"\n";
   ## Send new passwd.
   ReadMode 2;
   my $npw=<STDIN>;
   ReadMode 0;
   PW: while (1) {
      chomp($npw);
      $cmd_handle->print("$npw");
      my ($output,$line)='';
      while ($line=$_[0]->get) {
         if ($line=~/changed/) {
            print $blanklines;
            #print $clear,"\n";
            last PW;
         }
         $output.=$line;
         if ($line=~/: ?$/i) {
            print $output;
            ReadMode 2;
            $npw=<STDIN>;
            ReadMode 0;
            $output='';
            print $blanklines;
            #print $clear,"\n";
            last;
         }
      }
   }
}

sub unix_id {
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }

   my @topcaller=caller;
   print "unix_id() CALLER=", (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "unix_id() CALLER=", (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $localhost=$_[0];
   my $su_id=$_[1];
   my $hostlabel=$_[2];
   my $die='';my $id='';
   my $prompt='';my $dieline='';
   eval {
      my $next=0;
      while (my $line=$localhost->get) {
print $Net::FullAuto::FA_lib::MRLOG "GETMAILLINE=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "GETMAILLINE=$line\n" if $debug;
         next if $line=~/^\s+$/s;
         if (!$Net::FullAuto::FA_lib::cron && $line=~/\[YOU/s) {
            my $hostlab=$hostlabel;
            $hostlab=(keys %same_host_as_Master)[1]
               if $hostlabel eq "__Master_${$}__";
            print "\nAttn: $su_id on $hostlab --> [YOU HAVE NEW MAIL]\n\n";
            $localhost->print;
            sleep 1;
         } elsif ($line=~/\d\d\d\d-\d\d\d /s) {
            $dieline=__LINE__;
            $die.=$line;
            $localhost->print;next;
         } else { $localhost->print }
         last
      } $localhost->print;
print $Net::FullAuto::FA_lib::MRLOG "OUTOFGETMAIL\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "OUTOFGETMAIL\n" if $debug;
      while (my $line=$localhost->get) {
print $Net::FullAuto::FA_lib::MRLOG "GETPROMPTLINE=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "GETPROMPTLINE=$line\n" if $debug;
         chomp($line=~tr/\0-\11\13-\37\177-\377//d);
         next if $line=~/^\s*$/s;
         ($prompt=$line)=~s/^.*\n(.*)$/$1/s;
         $prompt=~s/^\^C//;
         return if $prompt;
      }
   };
   my $cmd_prompt=quotemeta $prompt;
print $Net::FullAuto::FA_lib::MRLOG "PROMPT=$prompt<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "PROMPT=$prompt<==\n" if $debug;
   if ($die) {
      $die=~s/$cmd_prompt$//s;
      $die=~s/^/       /m;
      $die="       $hostlabel Login ERROR! :\n$die";
      $die.="       ".($!)." at Line $dieline";
   }
   if ($@) {
      if ($die) {
         return '',$die
      } else {
         return '',$@
      }
   }
   &clean_filehandle($localhost,$prompt);
   eval {
      $localhost->print('id -unr');
      select(undef,undef,undef,0.02); # sleep for 1/50th second;
      while (my $line=$localhost->get) {
print $Net::FullAuto::FA_lib::MRLOG "ID_PROMPTLINE=$line<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         $line=~tr/\0-\11\13-\37\177-\377//d;
         $id.=$line;
         $id=~s/id -unr\s*//s;
         next if $id!~s/\s*$cmd_prompt$//s;
         $id=~s/^\s*//;
         last
      }
   };
   if ($@) {
      if ($die) {
         return '',$die
      } else {
         return '',$@
      }
   } elsif ($die) {
      if (!$id) {
         return '',$die
      } else {
         &Net::FullAuto::FA_lib::handle_error($die,'__return__','__warn__'); 
         return $id
      }
   }
#$Net::FullAuto::FA_lib::log=0 if $logreset;
   return $id,''

}

sub ping
{
   my @topcaller=caller;
   print "ping() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   #print $Net::FullAuto::FA_lib::MRLOG "ping() CALLER=",
   #   (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   print $Net::FullAuto::FA_lib::MRLOG "ping() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $cmd='';my $stdout='';my $stderr='';
   if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
      $cmd=[ "${pingpath}ping -n 1 $_[0] 2>&1" ];
   } else {
      if (exists $Hosts{"__Master_${$}__"}{'bash'}) {
         $bashpath=$Hosts{"__Master_${$}__"}{'bash'};
         $bashpath.='/' if $bashpath!~/\/$/;
      }
      $cmd=[ "${bashpath}bash",'-c',"${pingpath}ping -c1 $_[0] 2>&1" ];
   } my $didping=10;
   eval {
      if (ref $localhost eq 'HASH') {
         ($stdout,$stderr)=$localhost->cmd(
            "${pingpath}ping $count \"$_[0]\"",5);
      } else {
         $didping=7;
#print $Net::FullAuto::FA_lib::MRLOG "ENTERING cmd() for PING and CMD=@{$cmd}\n"
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print $Net::FullAuto::FA_lib::MRLOG "ENTERING cmd() for PING and CMD=@{$cmd}\n"
   if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         ($stderr,$stdout)=&setuid_cmd($cmd,5);
print $Net::FullAuto::FA_lib::MRLOG "LEAVING cmd() for PING\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   #if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      }
   };
   if ($@) {
      if (wantarray) {
         return 0,"${pingpath}ping timed-out: $@";
      } else {
         &Net::FullAuto::FA_lib::handle_error("${pingpath}ping timed-out: $@","-$didping");
      }
   }
   $stdout=~s/^\s*//s;
   foreach my $line (split /^/, $stdout) {
      chomp($line=~tr/\0-\11\13-\37\177-\377//d);
      if (-1<index $line,' from ') {
         if (wantarray) {
            return $stdout,'';
         } else {
            return $stdout;
         }
      }
      $stderr=$stdout if (-1<index $line,'NOT FOUND')
         || (-1<index $line,'Request Timed Out')
         || (-1<index $line,'Bad IP')
         || (-1<index $line,'100% packet loss');
   }
   $stderr=~s/^/       /mg;
   if (wantarray) {
      return 0,$stderr;
   } elsif (defined $_[1] && $_[1] eq '__return__') {
      return 0;
   } else {
      $didping+=30;
      &Net::FullAuto::FA_lib::handle_error($stderr,"-$didping");
   }

}

sub work_dirs
{
   my @topcaller=caller;
   print "work_dirs() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "work_dirs() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $transfer_dir=$_[0];
   $transfer_dir||='';
   my $hostlabel=$_[1];
   my $cmd_handle=$_[2];
   bless $cmd_handle;
   my $cmd_type=$_[3];
   my $cygdrive=$_[4];
   $cygdrive||='';
   my $_connect=$_[5];
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$sdtimeout,$transferdir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   if (-1<index $cmd_handle,'HASH') {
      $regex=$cmd_handle->{_cygdrive_regex};
      $cygdrive=$cmd_handle->{_cygdrive}
         if exists $cmd_handle->{_cygdrive};
   } elsif ($cygdrive) {
      $regex=qr/^$cygdrive\//;
   }
   my $work_dirs={};
   if ($transfer_dir) {
      if (unpack('x1 a1',$transfer_dir) eq ':') {
         my ($drive,$path)=unpack('a1 x1 a*',$transfer_dir);
         $path=~tr/\\/\//;
         ${$work_dirs}{_tmp_mswin}=$transfer_dir.'\\';
         ${$work_dirs}{_tmp}=$cygdrive
                            .'/'.lc($drive).$path.'/';
      } elsif ($cygdrive && $transfer_dir=~/$regex/) {
         ${$work_dirs}{_tmp}=$transfer_dir.'/';
         (${$work_dirs}{_tmp_mswin}=$transfer_dir)
            =~s/$regex//;
         ${$work_dirs}{_tmp_mswin}=~s/^(.)/$1:/;
         ${$work_dirs}{_tmp_mswin}=~tr/\//\\/;
         ${$work_dirs}{_tmp_mswin}=~s/\\/\\\\/g;
         ${$work_dirs}{_tmp_mswin}.='\\';
      } elsif ($cygdrive && unpack('a1',$transfer_dir) eq '/' ||
            unpack('a1',$transfer_dir) eq '\\') {
         (${$work_dirs}{_tmp},${$work_dirs}{_tmp_mswin})
            =&File_Transfer::get_drive(
            $transfer_dir,'Transfer',
            { _cmd_handle=>$cmd_handle,_cmd_type=>$cmd_type },$hostlabel);
      } elsif (unpack('a1',$transfer_dir) eq '/') {
         ${$work_dirs}{_tmp}=$transfer_dir.'/';
         ${$work_dirs}{_tmp_mswin}='';
      } else {
         my $die="Cannot Locate Transfer Directory - $transfer_dir";
         if (wantarray) {
            return '',$die;
         } else { &Net::FullAuto::FA_lib::handle_error($die) }
      } ${$work_dirs}{_lcd}=${$work_dirs}{_tmp_lcd}
         =$localhost->{_work_dirs}->{_tmp};
      ${$work_dirs}{_pre_lcd}='';
      return $work_dirs;
   }
   if (&Net::FullAuto::FA_lib::test_dir($cmd_handle->{_cmd_handle},'/tmp')
         eq 'WRITE') {
      ${$work_dirs}{_tmp}='/tmp/';
      if ($cmd_handle->{_uname} eq 'cygwin') {
         my $pwd='';my $curdir='';
         ($output,$stderr)=
            &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle->{_cmd_handle});
         ($pwd,$stderr)=$cmd_handle->cmd('pwd');
         &handle_error($stderr,'-2','__cleanup__') if $stderr;
         ($output,$stderr)=$cmd_handle->cmd(
            'cd '.${$work_dirs}{_tmp});
         &handle_error($stderr,'-2','__cleanup__') if $stderr;
         $curdir=&Net::FullAuto::FA_lib::push_cmd($cmd_handle->{_cmd_handle},
                 'cmd /c chdir',$cmd_handle->{'hostlabel'}[0]);
         ${$work_dirs}{_tmp_mswin}=$curdir.'\\';
         ($output,$stderr)=$cmd_handle->cmd(
            'cd '.$pwd);
         &handle_error($stderr,'-2','__cleanup__') if $stderr;
      } ${$work_dirs}{_lcd}=${$work_dirs}{_tmp_lcd}
         =$localhost->{_work_dirs}->{_tmp};
      ${$work_dirs}{_pre_lcd}='';
      return $work_dirs;
   }
   if ($cmd_handle->{_uname} eq 'cygwin') {
      (${$work_dirs}{_tmp},${$work_dirs}{_tmp_mswin})
         =&File_Transfer::get_drive(
            'temp','Temp',
            $cmd_handle,$hostlabel);
      if ($ms_share) {
         my $host=($use eq 'ip')?$ip:$hostname;
         ${$work_dirs}{_cwd_mswin}="\\\\$host\\$ms_share\\";
      }
      return $work_dirs if ${$work_dirs}{_tmp};
   } ${$work_dirs}{_tmp}=${$work_dirs}{_tmp_mswin}='';
   ${$work_dirs}{_lcd}=$localhost->{_work_dirs}->{_tmp};
   ${$work_dirs}{_pre_lcd}='';
   return $work_dirs
}

sub close
{
   return &File_Transfer::close(@_);
}

sub cwd
{
   my @topcaller=caller;
   my $stdout='';my $stderr='';
print "INSIDE CWD3\n";
   print "main::cwd() CALLER=",(join ' ',@topcaller),"\n";
   #   if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "main::cwd() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if (!defined $_[1]) {
      return Cwd::getcwd();
   } else { 
      ($stdout,$stderr)=File_Transfer::cwd(@_);
      if (wantarray) {
         return $stdout,$stderr;
      } elsif ($stderr) {
         &handle_error($stderr,'-4');
      } return $stdout;
   }
}

sub setuid_cmd
{
   my @topcaller=caller;
   print "setuid_cmd() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "setuid_cmd() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      # if $Net::FullAuto::FA_lib::log &&
      # -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $cmd=shift;
   my $timeout=shift;
   $timeout||='';
   my $regex='';
   if ($timeout) {
      alarm($timeout+10);
      if (7<length $timeout &&
             unpack('a8',$timeout) eq '(?-xism:') {
         $regex=$timeout;
         $timeout=shift;
         $timeout||='';
      }
      if ($timeout!~/^\d+$/) {
         undef $timeout;
      }
   } else { alarm($Net::FullAuto::FA_lib::timeout) }
   my $flag=shift;
   $flag||='';
   my $cmd_err='';
   $cmd_err=join ' ',@{$cmd} if ref $cmd eq 'ARRAY';
   my $one=${$cmd}[0];my $two='';
   $two=${$cmd}[1] if 0<$#{$cmd};
   my $three='';
   $three=${$cmd}[2] if 1<$#{$cmd};
   my $four='';
   $four=${$cmd}[3] if 2<$#{$cmd};
   if (!$one && ref $cmd ne 'ARRAY') {
      $one=$cmd;$cmd_err=$cmd;
   }
   $regex||='';my $pid='';my $output='';
   my $stdout='';my $stderr='';
   &handle_error("Can't fork: $!") unless defined($pid=open(KID, "-|"));
   #die "Can't fork: $!" unless defined($pid=open(KID, "-|"));
   if ($pid) { # parent
      while (my $line=<KID>) {
         $output.=$line;
      }
      CORE::close(KID);
   } else { # child
      my @temp     = ($EUID, $EGID);
      my $orig_uid = $UID;
      my $orig_gid = $GID;
      $EUID = $UID;
      $EGID = $GID;
      # Drop privileges
      $UID  = $orig_uid;
      $GID  = $orig_gid;
      # Make sure privs are really gone
      ($EUID, $EGID) = @temp;
      #die "Can't drop privileges"
      #    unless $UID == $EUID  && $GID eq $EGID;
      if (!$flag || lc($flag) ne '__use_parent_env__') {
         $ENV{PATH} = '';
         $ENV{ENV}  = '';
      }
      if ($four) {
         exec $one, $two, $three, $four ||
            &handle_error("Couldn't exec: $cmd_err".($!),'-1');
      } elsif ($three) {
         exec $one, $two, $three ||
            &handle_error("Couldn't exec: $cmd_err".($!),'-1');
      } elsif ($two) {
         exec $one, $two ||
            &handle_error("Couldn't exec: $cmd_err".($!),'-1');
      } elsif ($one) {
         exec $one ||
            &handle_error("Couldn't exec: $cmd_err".($!),'-1');
      } else { alarm(0);return }
   }
   if ($regex && $output!~/$regex/s) {
      if (wantarray) {
         alarm(0);return '',"Cmd $cmd_err returned tainted data";
      } else {
         &Net::FullAuto::FA_lib::handle_error(
            "Cmd $cmd_err returned tainted data");
      }
   } $output=~s/^\s*//s;
   if ($one!~/^[^ ]*clear$/) {
      my @outlines=();my @errlines=();
      foreach my $line (split /^/,$output) {
         if ($line=~s/^[\t ]*stdout: //) {
            push @outlines, $line;
         } else { push @errlines, $line if $line!~/$one/s }
      } $stdout=join '', @outlines;$stderr=join '',@errlines;
   } else { $stdout=$output }
   chomp $stdout;chomp $stderr;
   alarm(0);
   if (wantarray) {
      return $stdout,$stderr;
   } else { return $stdout }
}

sub cmd
{
   my @topcaller=caller;
   print "main::cmd() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "main::cmd() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      # if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];my $escape=0;
   my $cmd='';my $cmtimeout=$timeout;
   if (defined $_[1] && $_[1]) {
      if ($_[1]=~/^[0-9]+$/) {
         $cmtimeout=$_[1];
         if (-1<index $self,'HASH') {
            $_[1]=$cmtimeout=$Hosts{$self->{_hostlabel}->[0]}{'Timeout'}
               if exists $Hosts{$self->{_hostlabel}->[0]}{'Timeout'};
         }
      } elsif ($_[1] eq '__escape__') {
         $escape=1;
      } else {
         $cmd=$_[1];
      }
   }
   if (defined $_[2] && $_[2]) {
      if ($_[2]=~/^[0-9]+$/) {
         $cmtimeout=$_[2];
         $_[1]=$cmtimeout=$Hosts{$self->{_hostlabel}->[0]}{'Timeout'}
            if exists $Hosts{$self->{_hostlabel}->[0]}{'Timeout'};
      } elsif ($_[2] eq '__escape__') {
         $escape=1;
      } else {
         if ($_[2]!~/^__[a-z]+__$/) {
            if ($wantarray) {
               return 0,'Third Argument for Timeout Value is not Whole Number';
            } else {
               &Net::FullAuto::FA_lib::handle_error(
                  'Third Argument for Timeout Value is not Whole Number')
            }
         }
      }
   }
   if (defined $_[3] && $_[3]) {
      if ($_[3] eq '__escape__') {
         $escape=1;
      }
   }
   my $stderr='';my $stdout='';my $pid_ts='';
   my $all='';my @outlines=();my @errlines=();
   if (!$escape) {
      if ((-1<index $self,'HASH')
            && exists $self->{_cmd_handle}
            && defined fileno $self->{_cmd_handle}) {
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }
         #&clean_filehandle($self->{_cmd_handle});
print $Net::FullAuto::FA_lib::MRLOG "main::cmd() CMD to Rem_Command=",
   (join ' ',@_),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         ($stdout,$stderr)=Rem_Command::cmd(@_);
         if (wantarray) {
            return $stdout,$stderr;
         } elsif ($stderr) {
            if (-1<index $self,'HASH') {
               &handle_error($stderr,'-19');
            } elsif (-1<index $self,'HASH') {
               &handle_error($stderr,'-19');
            } else {
               &handle_error($stderr,'-16');
            }
         } return $stdout;
#$Net::FullAuto::FA_lib::log=0 if $logreset;
      }
      if ((-1<index $localhost,'HASH')
            && exists $localhost->{_cmd_handle}
            && defined fileno $localhost->{_cmd_handle}) {
         ($stdout,$stderr)=&clean_filehandle($localhost->{_cmd_handle});
         if (!$stderr) {
            ($stdout,$stderr)=$localhost->cmd(@_);
            if (wantarray) {
               return $stdout,$stderr;
            } elsif ($stderr) {
               if (-1<index $self,'HASH') {
                  &handle_error($stderr,'-19');
               } elsif (-1<index $self,'HASH') {
                  &handle_error($stderr,'-19');
               } else {
                  &handle_error($stderr,'-16');
               }
            } return $stdout;
         }
      }
   }
   if ($OS eq 'cygwin') {
      if ($self!~/^cd[\t ]/) {
         $cmd="$self|perl -e \'\$o=join \"\",<STDIN>;\$o=~s/^/stdout: /mg;".
              "print \$o,\"__STOP--\"\' 2>&1";
      }
      my $cmd_handle='';my $cmd_pid='';my $next=10;
      while (1) {
         ($cmd_handle,$cmd_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
            [$cmd,'','','',$Net::FullAuto::FA_lib::slave])
            or &Net::FullAuto::FA_lib::handle_error("couldn't launch cmd subprocess");
         $cmd_handle=Net::Telnet->new(Fhopen => $cmd_handle,
            Timeout => $cmtimeout);
         $cmd_handle->telnetmode(0);
         $cmd_handle->binmode(1);
         #$cmd_handle->output_record_separator("\r");
         #$cmd_handle->autoflush(1);
#print "CMD_PIDFTPPPPPPP=$cmd_pid<==========\n";
         my $first=0;
         eval {
            while (my $line=$cmd_handle->get(Timeout=>10)) {
               chomp($line=~tr/\0-\11\13-\37\177-\377//d);
               next if $line=~/^\s*$/ && !$first;
               $first=1;
               $all.=$line;
               last if $all=~s/\n*_\s*_\s*S\s*T\s*O\s*P\s*-\s*-\s*$//s;
            }
         };
         if ($@) {
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($cmd_pid,9)
               if &Net::FullAuto::FA_lib::testpid($cmd_pid);
            $cmd_handle->close;
            if ($next--) {
               $all='';next;
            } else { &cleanup }
         } else { $cmd_handle->print("\004");last }
         #} else { $cmd_handle->print("\004") if $next!=10;last }
      } $cmd_handle->close;
   } else {
      if ($self!~/^cd[\t ]/) {
         $cmd="$self | ${sedpath}sed -e \'s/^/stdout: /\' 2>&1";
      }
      ($stdout,$stderr)=&setuid_cmd($cmd,$cmtimeout);
      &handle_error($stderr,'-1') if $stderr;
   }
   if ($all) {
      foreach my $line (split /^/, $all) {
         if ($line=~s/^[\t ]*stdout: //) {
            push @outlines, $line;
         } else { push @errlines, $line }
      } $stdout=join '', @outlines;$stderr=join '',@errlines;
   }
   if (wantarray) {
      return $stdout,$stderr;
   } elsif ($stderr) {
      if (-1<index $self,'HASH') {
         &handle_error($stderr,'-19');
      } elsif (-1<index $self,'HASH') {
         &handle_error($stderr,'-19');
      } else {
         &handle_error($stderr,'-16');
      }
   } return $stdout;

}

sub print
{
my @topcaller=caller;
print "PARENTPRINTCALLER=",(join ' ',@topcaller),"\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "PARENTPRINTCALLER=",(join ' ',@topcaller),
      "\nand ARGS=@_\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   return Net::Telnet::print(@_);
}

sub scrub_passwd_file
{
   my @topcaller=caller;
   print "scrub_passwd_file() CALLER=",(join ' ',@topcaller),"\n"
      if !$Net::FullAuto::FA_lib::cron && $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "scrub_passwd_file() CALLER=",
      (join ' ',@topcaller),"\n"
      if !$Net::FullAuto::FA_lib::cron && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';# && $Net::FullAuto::FA_lib::debug;
   $Net::FullAuto::FA_lib::fa_debug.=
      "scrub_passwd_file() CALLER=".(join ' ',@topcaller)."\n";
   my $passlabel=$_[0];my $login_id=$_[1];
   my $cmd_type=$_[2];
   my @passlabels=();
   my $local_host_flag=0;
   if ($passlabel eq "__Master_${$}__") {
      my $local_host_flag=0;
      foreach my $passlab (keys %same_host_as_Master) {
         next if $passlab eq "__Master_${$}__";
         push @passlabels, $passlab;
         $local_host_flag=1;
      }
      if (!$local_host_flag) {
         $passlabels[0]=$local_hostname;
         $local_host_flag=1;
      }
   } else {
      $passlabels[0]=$passlabel;
   }
   foreach my $passlabel (@passlabels) {
      my $key='';
      if ($local_host_flag) {
         $key="${username}_X_${passlabel}_X_${$}_X_$invoked[0]";
      } elsif ($cmd_type) {
         $key="${username}_X_${login_id}_X_${passlabel}_X_${cmd_type}";
      } else {
         $key="${username}_X_${login_id}_X_${passlabel}";
      }
print $Net::FullAuto::FA_lib::MRLOG "SCRUBBINGTHISKEY=$key<==\n"
         if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      my $kind='prod';
      $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
      return unless exists $Hosts{"__Master_${$}__"}{'FA_Secure'};
      my $tdie="can't open tie to "
              . $Hosts{"__Master_${$}__"}{'FA_Secure'}
              ."${progname}_${kind}_passwds.db: ";
      my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
#print $Net::FullAuto::FA_lib::MRLOG "FA_SUCURE11=",$Hosts{"__Master_${$}__"}{'FA_Secure'},"\n";
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
           %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
           'MLDBM::Sync',
           $Hosts{"__Master_${$}__"}{'FA_Secure'}.
           "${progname}_${kind}_passwds.db",
           $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) or
           &handle_error($tdie); 
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
      my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel};
      my $flag=0;my $successflag=0;
      foreach my $ky (keys %{$href}) {
         if ($ky eq $key) {
            while (delete $href->{$key}) {}
            $successflag=1;$flag=1;
         } elsif ($ky=~/_X_\d+_X_(\d+)$/ && $1+604800<$invoked[0]) {
            while (delete $href->{$ky}) {}
            $flag=1
         }
      }
      ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$passlabel}=$href if $flag;
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
      return $successflag;
   }

}

package File_Transfer;

use Time::Local;

sub new {
   my @topcaller=caller;
   print "File_Transfer::new() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::new() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   our $timeout=$Net::FullAuto::FA_lib::timeout;
   our $test=$Net::FullAuto::FA_lib::test;
   our $debug=$Net::FullAuto::FA_lib::debug;
   my $class = ref($_[0]) || $_[0];
   my $hostlabel=$_[1];
   my $new_master=$_[2]||'';
   my $_connect=$_[3]||'';
   my $self = { };
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my $host=($use eq 'ip') ? $ip : $hostname;
   my $chk_id='';
   if ($su_id) { $chk_id=$su_id }
   elsif ($login_id) { $chk_id=$login_id }
   else { $chk_id=$Net::FullAuto::FA_lib::username }
   if (!$new_master &&
         exists $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"}) {
      if ($ping) {
         if (&Net::FullAuto::FA_lib::ping($host,'__return__')) {
            return $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"},'';
         } else {
            delete $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"};
         }
      } else {
         return $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"},'';
      }
   }
   my ($ftp_handle,$ftp_pid,$work_dirs,$ftr_cmd,$ftm_type,
       $cmd_type,$smb,$fpx_handle,$fpx_pid,$stderr)=
       &ftm_login($hostlabel,$new_master,$_connect);
   if ($stderr) {
      my $die="\n       FATAL ERROR! - $stderr";
      print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return '',$die;
   }
   if ($smb) {
      $self->{_hostlabel}=[ $hostlabel,$Net::FullAuto::FA_lib::DeploySMB_Proxy[0] ];
      $self->{_smb}=1;
   } else {
      $self->{_hostlabel}=[ $hostlabel,'' ];
   }
   if ($ftr_cmd) {
      $self->{_cmd_handle}=$ftr_cmd->{_cmd_handle};
      $self->{_sh_pid}=$ftr_cmd->{_sh_pid};
      $self->{_cmd_pid}=$ftr_cmd->{_cmd_pid};
      $self->{_uname}=$ftr_cmd->{_uname};
      $self->{_luname}=$ftr_cmd->{_luname};
      $self->{_cmd_type}=$cmd_type;
      if ($ftr_cmd->{_cygdrive}) {
         $self->{_cygdrive}=$ftr_cmd->{_cygdrive};
         $self->{_cygdrive_regex}=$ftr_cmd->{_cygdrive_regex};
      }
   } else {
      $self->{_uname}=$uname;
      $self->{_luname}=$Net::FullAuto::FA_lib::OS;
      if (-1==$#{$cmd_cnct}) {
         $self->{_cmd_handle}=$ftp_handle;
         $self->{_cmd_type}=$ftm_type; 
      } else {
         $self->{_cmd_handle}='';
         $self->{_cmd_type}='';
      }
   }
   $self->{_ftp_handle}=$ftp_handle;
   $self->{_fpx_handle}=$fpx_handle
      if $self->{_fpx_handle};
   $self->{_hostname}=$hostname;
   $self->{_ip}=$ip;
   $self->{_ftm_type}=$ftm_type;
   $self->{_work_dirs}=$work_dirs;
   $self->{_ftp_pid}=$ftp_pid if $ftp_pid;
   $self->{_fpx_pid}=$fpx_pid if $fpx_pid;
   bless($self,$class);
   $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"}=$self;
   return $self,'';

}

sub handle_error
{
   my @topcaller=caller;
   print "File_Transfer::handle_error() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::handle_error() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log &&
      -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   return &Net::FullAuto::FA_lib::handle_error(@_);
}

sub close
{

   my $self=$_[0];
   if (exists $self->{_ftp_handle} &&
         defined fileno $self->{_ftp_handle}) {
      my $ftp_handle=$self->{_ftp_handle};
      my $count=0;
      eval {
         SC: while (defined fileno $self->{_ftp_handle}) {
            $self->{_ftp_handle}->print("\004");
            while (my $line=$self->{_ftp_handle}->get) {
               last if $line=~/_funkyPrompt_$|
                                Connection.*closed|logout|221\sGoodbye/sx;
               if ($line=~/^\s*$/s) {
                  last SC if $count++==20;
               } else { $count=0 }
               $self->{_ftp_handle}->print("\004");
            }
         }
      };
      eval { $self->{_ftp_handle}->close };
      ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($self->{_ftp_pid},9)
         if &Net::FullAuto::FA_lib::testpid($self->{_ftp_pid});
      foreach my $h_id (keys %Net::FullAuto::FA_lib::Connections) {
         if ($self eq $Net::FullAuto::FA_lib::Connections{$h_id}) {
            delete $Net::FullAuto::FA_lib::Connections{$h_id};
            last;
         }
      }
   }

}

sub get_vlabel
{
print "GET_VLABEL_CALLER=",caller,"\n";<STDIN>;
   my ($self,$deploy_type,$dest_hostlabel,
       $base_hostlabel,$archivedir) = @_;
   my ($archive_hostlabel,$version_label,$label1,$label2)='';
   my @output=();
   if ($deploy_type eq 'get') {
      $archive_hostlabel=$dest_hostlabel;
   } else {
      $archive_hostlabel=$base_hostlabel;
   }

   while ($Net::FullAuto::FA_lib::version_label eq '') {
      print $Net::FullAuto::FA_lib::blanklines;
      #print $Net::FullAuto::FA_lib::clear,"\n";
      print "\n\n\tPlease Type the Version Number of the\n";
      print "\tBuild being Deployed TO Host \"$dest_hostlabel\"\n";
      print "\tFROM Host \"$base_hostlabel\" : ";
      $label1=<STDIN>;chomp($label1);
      next if $label1 eq '';
      if ($label1 ne uc($label1)) {
         print $Net::FullAuto::FA_lib::blanklines;
         #print $Net::FullAuto::FA_lib::clear,"\n";
         print "\n\n\tERROR! - Use Only Upper Case Letters for Version Labels!";
         next;
      }
      print "\n\tPlease Re-Enter the Version Number : ";
      $label2=<STDIN>;chomp($label2);

      if ($label1 eq "") {
         print $Net::FullAuto::FA_lib::blanklines;
         #print $Net::FullAuto::FA_lib::clear,"\n";
         next;
      }
      if ($label1 eq $label2) {
         if (($deploy_type eq 'get' || ($deploy_type eq 'put' &&
                   ($dest_hostlabel ne "__Master_${$}__" &&
                    $base_hostlabel ne "__Master_${$}__")))
                    && $archivedir) {
            my $ignore='';my $chmod='';my $own='';my $grp='';
            my %settings=();
            if (($archive_hostlabel eq "__Master_${$}__"
                   && $Net::FullAuto::FA_lib::local_hostname eq substr(
                   $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'HostName'},
                   0,index
                   $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'HostName'},
                   '.')) || $deploy_type eq 'put') {
               if (defined $archivedir && $archivedir ne '') {
                  if (-1<index $archivedir,'__VLABEL__') {
                     $archivedir=~s/__VLABEL__/$label1/g;
                  }
                  if (-d "$archivedir") {
                     if (-f "$archivedir/mving.flg") {
                        $version_label=$label1;last;
                     } else {
                        my $target=$archive_hostlabel;
                        my $die="\n\nFATAL ERROR!!!\n\nThis Version "
                               ."- $label1 - already exists on $target"
                               ."!\n\nIf this is the right Version, "
                               ."move or delete the\ndirectory on $target "
                               ."before running this script\n\n";
                        &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
                     }
                  } elsif ($Net::FullAuto::FA_lib::OS ne 'cygwin'
                        && $Net::FullAuto::FA_lib::OS ne 'MSWin32'
                        && $Net::FullAuto::FA_lib::OS ne 'MSWin64'
                        && $ENV{OS} ne 'Windows_NT') {
#### DO ERROR TRAPPING!!!!!!!!!!!!
print "MKDIR1=$archivedir\n";
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                                              "mkdir \'/$archivedir\'");
                     my $chmod=$Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Chmod'};
                     my $own=$Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Owner'};
                     my $grp=$Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Group'};
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                        "chmod \"$chmod\" \'/$archivedir\'")
                        if $chmod;
                     @output=$Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                        "chown \"$own\" \'/$archivedir\'")
                        if $own;
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                        "chgrp \"$grp\" \'/$archivedir\'")
                        if $grp;
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                        "touch \"/$archivedir/mving.flg\"");
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                       "chmod \"$chmod\" \"/$archivedir/mving.flg\"")
                                                              if $chmod;
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                       "chown \"$own\" \"/$archivedir/mving.flg\"")
                                                              if $own;
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                       "chgrp \"$grp\" \"/$archivedir/mving.flg\"")
                                                              if $grp;
                     $version_label=$label1;last;
                  } elsif ($Net::FullAuto::FA_lib::OS eq 'cygwin'
                        || $Net::FullAuto::FA_lib::OS eq 'MSWin32'
                        || $Net::FullAuto::FA_lib::OS eq 'MSWin64'
                        || $ENV{OS} eq 'Windows_NT') {
print "DO MORE WORK ON MSWIN!\n";<STDIN>;
                     $Net::FullAuto::FA_lib::localhost->{_cmd_handle}->SUPER::cmd(
                        "mkdir $label1");
                     $version_label=$label1;last;
                  }
               }
            } else { $version_label=$label1;last }
         } else { $version_label=$label1;last }
      } else {
         print $Net::FullAuto::FA_lib::blanklines;
         #print $Net::FullAuto::FA_lib::clear,"\n";
         print "\n\n\tVersion Numbers Do NOT Match!";
      }
   } print "\n\n";
   $Net::FullAuto::FA_lib::version_label=$version_label;
   return $version_label;

}

sub select_dir
{
#print "SELECT_DIRCALLER=",caller,"\n";
   my $self=$_[0];my $dir='.';my $random=0;
   my $dots=0;my $dot=0;my $dotdot=0;
   if (defined $_[1] && $_[1]) {
      if ($_[1] eq '__random__') {
         $random=1;
      } elsif ($_[1] eq '__dots__') {
         $dots=1;
      } elsif ($_[1] eq '__dot__') {
         $dot=1;
      } elsif ($_[1] eq '__dotdot__') {
         $dotdot=1;
      } else {
         $dir=$_[1];
      }
   }
   if (defined $_[2] && $_[2]) {
      if ($_[2] eq '__random__') {
         $random=1;
      } elsif ($_[2] eq '__dots__') {
         $dots=1;
      } elsif ($_[2] eq '__dot__') {
         $dot=1;
      } elsif ($_[2] eq '__dotdot__') {
         $dotdot=1;
      }
   }
   if (defined $_[3] && $_[3]) {
      if ($_[3] eq '__random__') {
         $random=1;
      } elsif ($_[1] eq '__dots__') {
         $dots=1;
      } elsif ($_[1] eq '__dot__') {
         $dot=1;
      } elsif ($_[1] eq '__dotdot__') {
         $dotdot=1;
      }
   }
   my $caller=(caller)[2];
   my $hostlabel=$self->{_hostlabel}->[0];
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$sdtimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my $host= ($use eq 'ip') ? $ip : $hostname;
   $ms_share||='';my %output=();my $nt5=0;
   my $output='';my $stderr='';my $i=0;my @output=();
   if ($ms_share || $self->{_uname} eq 'cygwin') {
      my $test_chr1='';my $test_chr2='';
      if ($dir) {
         $test_chr1=unpack('a1',$dir);
         if (1<length $dir) {
            $test_chr2=unpack('a2',$dir);
         }
         if ($test_chr2) {
            if (($test_chr1 eq '/' && $test_chr2 ne '//')
                  || ($test_chr1 eq '\\' &&
                  $test_chr2 ne '\\\\')) {
               if ($dir=~s/^$self->{_cygdrive_regex}//) {
                  $dir=~s/^(.)/$1:/;
                  $dir=~tr/\//\\/;
                  $dir=~s/\\/\\\\/g;
               } elsif ($hostlabel eq "__Master_${$}__"
                     && $Net::FullAuto::FA_lib::OS eq 'cygwin') {
                  $dir=&File_Transfer::get_drive($dir,'Target',
                                  '',$hostlabel);
                  $dir=~s/^$self->{_cygdrive_regex}//;
                  $dir=~s/^(.)/$1:/;
                  $dir=~tr/\//\\/;
                  $dir=~s/\\/\\\\/g;
               } else {
                  $dir=~tr/\//\\/;
                  $dir="\\\\$host\\$ms_share\\"
                       . unpack('x1 a*',$dir);
               }
            } elsif ($test_chr2 eq '//' ||
                  $test_chr2 eq '\\\\' || $test_chr2=~/^[a-zA-Z]:$/) {
            } elsif ($test_chr1!~/\W/) {
               if ($hostlabel eq "__Master_${$}__"
                     && $Net::FullAuto::FA_lib::OS eq 'cygwin') {
                  #my $cou=2;my $curdir='';
                  my $curdir=&Net::FullAuto::FA_lib::push_cmd($self,
                             'cmd /c chdir',$hostlabel);
                  #while ($cou--) {
                  #   ($curdir,$stderr)=$self->cmd(
                  #      'cmd /c chdir',__live__);
                  #   &Net::FullAuto::FA_lib::handle_error($stderr,'-1','__cleanup__')
                  #      if $stderr;
                  #   if (!$curdir) {
                  #      ($output,$stderr)=
                  #         &Net::FullAuto::FA_lib::clean_filehandle($self);
                  #      &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__')
                  #         if $stderr;
                  #   } else { last }
                  #} $dir="$curdir\\$dir";
                  $dir="$curdir\\$dir";
               } else {
                  $dir="\\\\$host\\$ms_share\\$dir";
               }
            } else {
               &Net::FullAuto::FA_lib::handle_error(
                  "Target Directory - $dir CANNOT Be Located");
            }
         } elsif ($test_chr1 eq '/' || $test_chr1 eq '\\') {
            if (($hostlabel eq "__Master_${$}__"
                  && $Net::FullAuto::FA_lib::OS eq 'cygwin') ||
                  $self->{_work_dirs}->{_cwd}=~/$self->{_cygdrive_regex}/) {
               $dir=&File_Transfer::get_drive('/','Target',
                               '',$hostlabel);
               $dir=~s/^$self->{_cygdrive_regex}//;
               $dir=~s/^(.)/$1:/;
               $dir=~tr/\//\\/;
               $dir=~s/\\/\\\\/g;
            } else {
               $dir="\\\\$host\\$ms_share";
            }
         } elsif ($test_chr1=~/^[a-zA-Z]$/) {
            $dir=$test_chr1 . ':/';
         } else {
            &Net::FullAuto::FA_lib::handle_error(
               "Target Directory - $dir CANNOT Be Located");
         } $dir=~tr/\\/\//;$dir=~tr/\//\\/;$dir=~tr/\\/\\\\/;my $cnt=0;
      } else {
         if (($hostlabel eq "__Master_${$}__"
               && $Net::FullAuto::FA_lib::OS eq 'cygwin') ||
               $self->{_work_dirs}->{_cwd}=~/^$self->{_cygdrive_regex}/) {
            $dir=&File_Transfer::get_drive('/','Target','',$hostlabel);
            $dir=~s/^$self->{_cygdrive_regex}//;
            $dir=~s/^(.)/$1:/;
            $dir=~tr/\//\\/;
            $dir=~s/\\/\\\\/g;
         } else {
            $dir="\\\\$host\\$ms_share";
         }
      }
      my $cnt=0;
      while (1) {
         ($output,$stderr)=$self->cmd("cmd /c dir /-C \'$dir\'");
         if (!$stderr && $output!~/bytes free\s*$/s) {
prin $Net::FullAuto::FA_lib::MRLOG "sub select_dir Rem_Command::cmd() BAD output=$output\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            unless ($cnt++) { $output='';next }
            my $die="Attempt to retrieve output from the command:\n"
                   ."\n       cmd /c dir /-C \'$dir\'\n"
                   ."\n       run on the host $self->{_hostlabel}->[0] FAILED"
                   ."\n\n       BAD OUTPUT==>$output\n";
            &Net::FullAuto::FA_lib::handle_error($die,'-6');
         } else { last }
      }
      if (!$stderr) {
         $output=~s/^.*Directory of (.*)$/$1/s;
         my $mn=0;my $dy=0;my $yr=0;
         my $hr=0;my $mt='';my $pm='';my $size='';
         my $file='';my $filetime=0;my $cnt=0;
         foreach my $line (split /^/, $output) {
            next if $cnt++<4;
            next if -1==index $line,'<DIR>';
            chomp($line=~tr/\0-\37\177-\377//d);
            if (39<length $line) {
               if (unpack('x6 a4',$line)=~/^\d\d\d\d$/) {
                  ($mn,$dy,$yr,$hr,$mt,$pm,$size,$file)=
                   unpack('a2 x1 a2 x3 a2 x2 a2 x1 a2 a1 @24 a14 @39 a*'
                         ,"$line");
                  $nt5=1;
               } else {
                  ($mn,$dy,$yr,$hr,$mt,$pm,$size,$file)=
                   unpack('a2 x1 a2 x1 a2 x2 a2 x1 a2 a1 @24 a14 @39 a*'
                         ,"$line");
               }
               $filetime=timelocal(
                  0,$mt,$Net::FullAuto::FA_lib::hours{$hr.$pm},$dy,$mn-1,$yr);
            } push @{$output{$filetime}},
                  {$file=>"$mn/$dy/$yr  $hr:$mt$pm"};
         }
         foreach my $filetime (reverse sort keys %output) {
            foreach my $filehash (@{$output{$filetime}}) {
               foreach my $file (reverse sort keys %{$filehash}) {
                  push @output,${$filehash}{$file}."   $file";
               }
            }
         }
      }
   } else {
      ($output,$stderr)=$self->cmd("ls -lt $dir");
      if (!$stderr) {
         foreach my $line (split /\n/, $output) {
            next if unpack('a5',$line) eq 'total';
            my $lchar=substr($line,-1);
            if ($lchar eq '*' || $lchar eq '/' || $lchar eq ':') {
               if ($lchar eq ':' && !$lchar_flag) {
                  $len_dir--;
                  $lchar_flag=1;
               }
               chop $line;
            }
            my $endofline=substr($line,-2);
            if ($endofline eq '..' && !$dots && !$dotdot) { next }
            if ($endofline eq ' .' && !$dots && !$dot) { next }
            my $date=substr($line,41,13);
            my $file=unpack('x54 a*',$line);
            push @output,"$date   $file";
         }
      }
   } my $die='';
   if ($stderr) {
      my $caller=(caller(1))[3];
      substr($caller,0,(index $caller,'::')+2)='';
      my $sub='';
      if ($caller eq 'connect_ftp'
            || $caller eq 'connect_telnet') {
         ($caller,$sub)=split '::', (caller(2))[3];
         $caller.='.pm';
      } else {
         my @called=caller(2);
         if ($caller eq 'mirror' || $caller eq 'login_retry') {
            $sub=$called[3]
         } else {
            $caller=$called[3];
            $called[6]||='';
            $sub=($called[6])?$called[6]:$called[3];
         } $sub=~s/\s*\;\n*//
      }
      my $mod='';($mod,$sub)=split '::', $sub;
      $stderr=~s/\sat\s${progname}\s/\n       at ${progname} /;
      $die="Cannot change to directory:\n\n"
          ."       \"$dir\"\n\n       in the \"&select_dir()\" "
          ."Subroutine (or Method)\n       Called from the "
          ."User Defined Subroutine\n       -> $sub\n       "
          ."in the \"subs\" Subroutine File ->  "."${mod}.pm\n\n"
          ."       The Remote System $host Returned\n       "
          ."the Following Error Message:\n\n       $stderr";
   } elsif ($random) {
      $output=$output[rand $#output]; 
      chomp $output;
      if ($ms_share) {
         if ($nt5) {
            substr($output,0,19)="";
         } else {
            substr($output,0,21)="";
         }
      } else { substr($output,0,16)="" }
      $output=~s/\s*$//;
   } else {
      my $banner="\n   Please Pick a Directory :";
      $output=&Menus::pick(\@output,$banner);
      chomp $output;
      if ($output ne ']quit[') {
         if ($ms_share) {
            if ($nt5) {
               substr($output,0,19)="";
            } else {
               substr($output,0,21)="";
            }
         } else { substr($output,0,16)="" }
      } else { &Net::FullAuto::FA_lib::cleanup() }
      $output=~s/\s*$//;
   }
   if (wantarray) {
      return $output,$die;
   } elsif ($stderr) {
      &Net::FullAuto::FA_lib::handle_error($die);
   } else { return $output }

}

sub testfile
{
#print "TESTFILE_CALLER=",caller,"\n";
   my ($self, @args) = @_;
   my @output=();
   my $output="";
   eval {
      $output=$self->cmd("ls -l @args");
      print "OBJECT=$output\n";<STDIN>;
   }

}

sub testdir
{
print "TESTDIR_CALLER=",caller,"\n";
   my ($self, @args) = @_;
   my @output=();
   my $output="";
   #eval {

}

sub ftp
{
   my @topcaller=caller;
   print "File_Transfer::ftp() CALLER=",
      (join ' ',@topcaller),"\n";# if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::ftp() CALLER=",
      (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($host1,$host2,$ftpcmd) = @_;
   $ftpcmd=~s/^\s*//;
   my $output='';my $stderr='';
   my $gpcmd='';
   $gpcmd=unpack('a3',$ftpcmd) if 2<length $ftpcmd;
   eval {
      if ($host2) {
         if ($gpcmd eq 'get') {
            ($output,$stderr)=Rem_Command::cmd(
               $host2,$ftpcmd,'__ftp__');
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            ($output,$stderr)=Rem_Command::cmd(
               $host1,$ftpcmd,'__ftp__');
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         } elsif ($host2 && $gpcmd eq 'put') {
            ($output,$stderr)=Rem_Command::cmd(
               $host1,$ftpcmd,'__ftp__');
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            ($output,$stderr)=Rem_Command::cmd(
               $host2,$ftpcmd,'__ftp__');
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         }
      } else {
         $ftpcmd=~s/\\/\\\\/g if -1==index $ftpcmd,'\\\\';
         ($output,$stderr)=Rem_Command::cmd(
            $host1,$ftpcmd,'__ftp__');
         my $die='';
         if ($host1->{_hostlabel}->[1]) {
            $die="\n       FATAL ERROR! - The System "
                ."\"$host1->{_hostlabel}->[1]\" "
                ."Acting as an\n              MSWin Proxy for "
                ."the System \"$host1->{_hostlabel}->[0]\" Returned "
                ."\n              the Following Unrecoverable Error "
                ."Condition:\n\n       ";
         } else {
            $die="\n       FATAL ERROR! - The System "
                ."\"$host1->{_hostlabel}->[0]\" Returned "
                ."\n              the Following Unrecoverable Error "
                ."Condition:\n\n       ";
         }
         if ($output eq 'Not connected') {
            $die.="$output\n              ";
            return '',$die;
         } elsif ((-1<index($stderr,'530 '))
               || (-1<index($stderr,'421 ')
               && -1==index($stderr,'onnect'))
               || (-1<index($stderr,'425 ')
               && -1==index($stderr,'not avail'))) {
            $die.="$stderr\n              ";
            return '',$die;
         } elsif (-1<index($output,'No such file or directory')) {
            $die.="$output\n\n       From ftp CMD: $ftpcmd\n\n              ";
            &Net::FullAuto::FA_lib::handle_error($die,'-26');
         } $die.="$stderr\n              ";
         &Net::FullAuto::FA_lib::handle_error($die,'-28') if $stderr;
      }
   };
   $stderr=$@ if $@;
   if (wantarray) {
      return $output,$stderr;
   } else { return $output }

}

sub cmd
{
   my @topcaller=caller;
   print "File_Transfer::cmd() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::cmd() CALLER=",
      (join ' ',@topcaller),
      "\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      #"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self='';my $command='';my @arg=();
   ($self,@arg) = @_;
   $command=$arg[0];
   my @output=();my $cmdlin=0;
   my $output='';my $stderr='';
   eval {
#print "ALLARGSLITTLECMD=$command and SELF_TYPE=$self->{_cmd_type}",
#      " and SELF-HANDLE=$self->{_cmd_handle}\n";<STDIN>;
      if (ref $self eq 'File_Transfer' && (!exists $self->{_cmd_handle}
            || $self->{_cmd_handle} ne "__Master_${$}__")) {
#print "WHAT IS THIS=$self->{_cmd_type}\n";
         if ($self->{_cmd_type} eq 'telnet' ||
               $self->{_cmd_type} eq 'ssh' ||
               ($Net::FullAuto::FA_lib::OS eq 'cygwin' &&
               exists $self->{_smb})) {
            $cmdlin=29;
            ($output,$stderr)=Rem_Command::cmd($self,@arg);
         } elsif ($self->{_ftm_type} eq 'ftp' ||
               $self->{_ftm_type} eq 'sftp') {
            ($output,$stderr)=&Rem_Command::ftpcmd($self,$command);
            $cmdlin=26;
         } else {
            &Net::FullAuto::FA_lib::handle_error($self->{_cmd_type} .
               " protocol not supported for command interface: ");
         }
      } else {
         $cmdlin=9;
         ($output,$stderr)=&Net::FullAuto::FA_lib::cmd($command);
      } 
   };
   if ($@) {
      print "$self->{_cmd_type} CMD ERROR! - $@\n";exit;
   }
   if (wantarray) {
      return $output,$stderr;
   } elsif ($stderr) {
      &Net::FullAuto::FA_lib::handle_error($stderr,-$cmdlin) if $stderr;
   } else { return $output }

}

sub ls
{
   my @topcaller=caller;
   print "File_Transfer::ls() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::ls() CALLER=",
      (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($self, $options, $path) = @_;
   $path='' unless defined $path;
   $options='' unless defined $options;
   my $output='';my $stderr='';
   if ($path && unpack('a1',$path) eq '"') {
      $path=unpack('a1 a*',$path);
      substr($path,-1)='';
   }
   if ($path) {
      ($output,$stderr)=&Rem_Command::ftpcmd($self,"ls \"$path\"");
   } else {
      ($output,$stderr)=&Rem_Command::ftpcmd($self,'ls');
   }
   my $newout='';
   if ($options eq '1' || $options eq '-1') {
      foreach my $line (split /^/, $output) {
         my $rx1=qr/\d+\s+\w\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
         my $rx2=qr/\d+\s+\w\w\w\s+\d+\s+\d\d\d\d\s+.*/;
         if ($line=~s/^.*\s+($rx1|$rx2)$/$1/) {
            $line=~
               s/^\d+\s+\w\w\w\s+\d+\s+(?:\d\d:\d\d\s+|\d\d\d\d\s+)+(.*)$/$1/;
            $newout.=$line;
         }
      } $output=$newout if $newout;
   }
   return '',$stderr if $stderr;
   chomp($output=~tr/\0-\11\13-\37\177-\377//d);$output=~s/^\s+//;
   return $output,'';

}

sub lcd
{
   my @topcaller=caller;
   print "File_Transfer::lcd() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::lcd() CALLER=",
      (join ' ',@topcaller),
      "\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      #"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($self, $path) = @_;
   my $output='';my $stderr='';
   if (unpack('a1',$path) eq '"') {
      $path=unpack('a1 a*',$path);
      substr($path,-1)='';
   }
   $self->{_work_dirs}->{_pre_lcd}=$self->{_work_dirs}->{_lcd};
   $path=~s/\\/\\\\/g;
print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::lcd() PATH=$path<==\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   ($output,$stderr)=&Rem_Command::ftpcmd($self,"lcd \"$path\"");
   $self->{_work_dirs}->{_lcd}=$path;
   return '',$stderr if $stderr;
   return $output,'';

}

sub get
{
   my @topcaller=caller;
   print "File_Transfer::get() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::get() CALLER=",
      (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($self, @args) = @_;
   my $output='';my $stderr='';
   my $path='';my $file='';
   foreach my $file_arg (@args) {
      if ($self->{_ftp_handle} ne "__Master_${$}__") {
         if ($self->{_ftm_type} eq 'ftp') {
            if (-1<index $file_arg,'/') {
               $path=substr($file_arg,0,(rindex $file_arg,'/'));
               $file=substr($file_arg,(rindex $file_arg,'/')+1);
               #($output,$stderr)=ftp($self,'',"cd \"$path\"");
               ($output,$stderr)=&Rem_Command::ftpcmd($self,"cd \"$path\"");
               if ($stderr) {
                  if (wantarray) {
                     return '',$stderr;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }
               }
            } elsif (-1<index $file_arg,'\\') {
               $path=substr($file_arg,0,(rindex $file_arg,'\\'));
               $file=substr($file_arg,(rindex $file_arg,'\\')+1);
               ($output,$stderr)=&Rem_Command::ftpcmd($self,"cd \"$path\"");
               if ($stderr) {
                  if (wantarray) {
                     return '',$stderr;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }
               }
            } else { $file=$file_arg }
         } else { $file=$file_arg }
         if (&Net::FullAuto::FA_lib::take_semaphore($file_arg)) {
            return 'SEMAPHORE','' if wantarray;
            return 'SEMAPHORE';
         }
         ($output,$stderr)=&Rem_Command::ftpcmd($self,"get \"$file\"");
         &Net::FullAuto::FA_lib::give_semaphore($file_arg);
         if ($stderr) {
           if (wantarray) {
               return '',$stderr;
            } else {
               &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
            }
         }
      } elsif (wantarray) {
         return '',
            "YOU ARE TRYING TO FTP GET FILE TO THE SAME BOX :\n        ".($!);
      } else {
         &Net::FullAuto::FA_lib::handle_error(
            "YOU ARE TRYING TO FTP GET FILE TO THE SAME BOX :\n        ".($!));
      }
   } return $output,'' if wantarray;
   return $output;

}

sub put
{
   my @topcaller=caller;
   print "File_Transfer::put() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::put() CALLER=",
      (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($self, @args) = @_;
   my ($output,$stderr)='';
   foreach my $file (@args) {
      if ($self->{_ftp_handle} ne "__Master_${$}__") {
#print "FILEARGGGINT=",int $file,"\n";<STDIN>;
         return 'SEMAPHORE' if &Net::FullAuto::FA_lib::take_semaphore('',$file);
         ($output,$stderr)=&Rem_Command::ftpcmd($self,"put $file");
         &Net::FullAuto::FA_lib::give_semaphore($file);
         if ($stderr) {
            print "ERROR! - $stderr\n";
         } 
      } else {
         print "YOU ARE TRYING TO FTP PUT FILE TO THE SAME BOX\n$!";
      }
   }
}

sub size
{
   my @topcaller=caller;
   print "File_Transfer::size() CALLER=",
      (join ' ',@topcaller),"\n" if $debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::size() CALLER=",
      (join ' ',@topcaller),
      "\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($self, @args) = @_;
   my ($output,$stderr)='';
   foreach my $file (@args) {
      if ($self->{_ftp_handle} ne "__Master_${$}__") {
         ($output,$stderr)=&Rem_Command::ftpcmd($self,"get $file");
      } else {
         $output=(stat("$file"))[7] || ($stderr=
            "cannot stat and obtain file size for $file\n       $!");
      }
      if ($stderr) {
         print "ERROR! - $stderr\n";
      }
   }
}

sub ftr_cmd
{
   my @topcaller=caller;
   print "File_Transfer::ftr_cmd() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::ftr_cmd() CALLER=",
      (join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $hostlabel=$_[0];
   my $ftp_handle=$_[1];
   my $new_master=$_[2]||'';
   my $_connect=$_[3]||'';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$frtimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my $host= ($use eq 'ip') ? $ip : $hostname;
   $ms_share='' unless defined $ms_share;
   $ms_domain='' unless defined $ms_domain;
   $login_id=$Net::FullAuto::FA_lib::username if !defined $su_id;
   my $work_dirs={};my $ftr_cmd='';my $ms_su_id='';my $ms_login_id='';
   my $ms_hostlabel='';my $ms_host='';my $ms_ms_share='';
   my $local_transfer_dir='';my $cmd_type='';my $ms_ms_domain='';
   my $output='';my $stderr='';my $ms_transfer_dir='';
   my @output=();my $cw1='';my $cw2='';my $ftm_type='';
   foreach my $cnct (@{$cmd_cnct}) {
      $cmd_type=lc($cnct);
      if (!exists $Net::FullAuto::FA_lib::fa_maps{"localhost=->$hostlabel"}{'rcm'}
            && ($cmd_type eq 'telnet' || $cmd_type eq 'ssh')) {
            #${$ftr_cnct}[0] eq 'smb')) {
            #($cmd_type eq 'tn_proxy' || $cmd_type eq 'ssh' && exists
            #$Net::FullAuto::FA_lib::same_host_as_Master{"$Net::FullAuto::FA_lib::DeployRCM_Proxy[0]"})) {
         ($ftr_cmd,$stderr)=
               Rem_Command::new('Rem_Command',$hostlabel,
                                $new_master,$_connect);
         if ($stderr) {
            chomp $stderr;
            return '','','','',$stderr;
         }
         $cmd_type=$ftr_cmd->{_cmd_type};
         $ftr_cmd->{_ftp_handle}=$ftp_handle;
         if (defined $transfer_dir && $transfer_dir) {
            $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                          $hostlabel,$ftr_cmd,$cmd_type,'',$_connect);
            #my $curdir='';my $cw3='';my $cw_tmp='';my $cou=2;
            #while ($cou--) {
            my $curdir='';
            if ($ftr_cmd->{_uname}!~/[Cc][Yy][Gg]/) {
               #($curdir,$stderr)=$ftr_cmd->cmd('pwd',__live__);
               my $curdir=&Net::FullAuto::FA_lib::push_cmd($ftr_cmd,
                  'pwd',$hostlabel);
            } else {
               #($curdir,$stderr)=$ftr_cmd->cmd('cmd /c chdir',__live__);
               my $curdir=&Net::FullAuto::FA_lib::push_cmd($ftr_cmd,
                          'cmd /c chdir',$hostlabel);
            }
            #   #&Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            #   if (!$curdir) {
            #      $ftr_cmd->{_cmd_handle}->autoflush(1);
            #      $ftr_cmd->{_cmd_handle}->print;my $ct=0;
            #      if (!$curdir) {
            #         $ftr_cmd->{_cmd_handle}->print(
            #            'printf \\\\041\\\\041;pwd;printf \\\\045\\\\045');
            #         my $allins='';my $ct=0;
            #         while (1) {
            #            eval {
            #               while (my $line=$ftr_cmd->{_cmd_handle}->get(
            #                        Timeout=>5)) {
            #                  chomp($line=~tr/\0-\37\177-\377//d);
            #                  $allins.=$line;
#print $Net::FullAuto::FA_lib::MRLOG "CURDIRLINEEEE=$allins<==\n";
            #                  if ($allins=~/!!(.*)%%/) {
            #                     $curdir=$1;
#print $Net::FullAuto::FA_lib::MRLOG "CURDIRRRRRAAAAA=$curdir<==\n";
            #                     last;
            #                  }
            #               }
            #            };
#print $Net::FullAuto::FA_lib::MRLOG "CURDIRRRRRBBBB=$curdir<==\n";
            #            if ($@) {
            #               $ftr_cmd->{_cmd_handle}->print;
            #            } elsif (!$curdir && $ct++<50) {
            #               $ftr_cmd->{_cmd_handle}->print;
            #            } else { last }
            #         }
            #      }
#print $Net::FullAuto::FA_lib::MRLOG "CURDIRRRRRCCCC=$curdir<==\n";
            #      #($output,$stderr)=
            #      #   &Net::FullAuto::FA_lib::clean_filehandle($ftr_cmd);
            #      #&Net::FullAuto::FA_lib::handle_error($stderr) if $stderr; 
            #   } else { last }
            #}
print "CURDIRRRRR=$curdir<==\n";
            my ($drive,$path)=unpack('a1 x1 a*',$curdir);
            ${$work_dirs}{_pre_mswin}=$curdir.'\\';
            $path=~tr/\\/\//;
            $ftr_cmd->{_cygdrive}||='/';
            ${$work_dirs}{_pre}=$ftr_cmd->{_cygdrive}.'/'.lc($drive).$path.'/';
            ($output,$stderr)=$ftr_cmd->cmd('cd '.${$work_dirs}{_tmp});
            if ($stderr) {
               @FA_lib::tran=();
               my $die="Cannot cd to TransferDir -> ".${$work_dirs}{_tmp}
                      ."\n        $stderr";
               &Net::FullAuto::FA_lib::handle_error($die,'-5');
            }
            ($output,$stderr)=
               &Net::FullAuto::FA_lib::clean_filehandle($ftr_cmd->{_cmd_handle});
            &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
            $output=join '',
               $ftr_cmd->{_ftp_handle}->cmd('cd '.${$work_dirs}{_tmp});
            if ($output=~/^(5.*)$/m) {
               my $line=$1;
               chomp($line=~tr/\0-\37\177-\377//d);
               my $die="Cannot cd to TransferDir -> ".${$work_dirs}{_tmp}
                      ."\n        $line";
               &Net::FullAuto::FA_lib::handle_error($die,'-7');
            }
            ${$work_dirs}{_cwd}=${$work_dirs}{_tmp};
            ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_tmp_mswin};
            $Net::FullAuto::FA_lib::tran[0]=${$work_dirs}{_tmp};
            $Net::FullAuto::FA_lib::tran[1]=$hostlabel;
            $Net::FullAuto::FA_lib::ftpcwd{$ftr_cmd->{_ftp_handle}}{cd}
               =${$work_dirs}{_tmp};
         } elsif (${$ftr_cnct}[0] eq 'smb' && defined
               $Net::FullAuto::FA_lib::Hosts{$Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}
               {'TransferDir'} &&
               $Net::FullAuto::FA_lib::Hosts{$Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}
               {'TransferDir'}) {
            my $transfer_dir=$Net::FullAuto::FA_lib::Hosts{$Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}
               {'TransferDir'};
            $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                          $hostlabel,$ftr_cmd,$cmd_type,'',$_connect);
            ${$work_dirs}{_pre}=${$work_dirs}{_cwd}='';
            ${$work_dirs}{_pre_mswin}=${$work_dirs}{_cwd_mswin}=
               "\\\\$host\\$ms_share\\";
            ($output,$stderr)=$ftr_cmd->cmd('cd '.${$work_dirs}{_tmp});
            if ($stderr) {
               @FA_lib::tran=();
               my $die="Cannot cd to TransferDir -> ".${$work_dirs}{_tmp}
                      ."\n        $stderr";
               &Net::FullAuto::FA_lib::handle_error($die,'-5');
            }
            $output=join '',
               $ftr_cmd->{_ftp_handle}->cmd('cd '.${$work_dirs}{_tmp});
            if ($output=~/^(5.*)$/m) {
               my $line=$1;
               chomp($line=~tr/\0-\37\177-\377//d);
               my $die="Cannot cd to TransferDir -> ".${$work_dirs}{_tmp}
                      ."\n        $line";
               &Net::FullAuto::FA_lib::handle_error($die,'-7');
            } $Net::FullAuto::FA_lib::tran[0]=${$work_dirs}{_tmp};
            $Net::FullAuto::FA_lib::tran[1]=$hostlabel;
            $Net::FullAuto::FA_lib::ftpcwd{$ftr_cmd->{_ftp_handle}}{cd}=${$work_dirs}{_tmp};
            $smb=1;
         } else {
            if ($ftr_cmd->{_uname} eq 'cygwin') {
               $curdir=&Net::FullAuto::FA_lib::push_cmd($ftr_cmd,
                       'cmd /c chdir',$ftr_cmd->{'hostlabel'}[0]);
               my ($drive,$path)=unpack('a1 x1 a*',$curdir);
               ${$work_dirs}{_pre_mswin}=
                  ${$work_dirs}{_cwd_mswin}=$curdir.'\\';
               $path=~s/\\/\//g;
               ${$work_dirs}{_pre}=${$work_dirs}{_cwd}=
                                  $ftr_cmd->{_cygdrive}.'/'
                                  .lc($drive).$path.'/';
               ${$work_dirs}{_tmp}=$ftr_cmd->{_work_dirs}->{_tmp};
                ${$work_dirs}{_tmp_mswin}=
                   $ftr_cmd->{_work_dirs}->{_tmp_mswin};
            } else {
               ($curdir,$stderr)=$ftr_cmd->cmd('pwd');
               $curdir.='/' if $curdir ne '/';
               ${$work_dirs}{_pre}=${$work_dirs}{_cwd}=$curdir;
               ${$work_dirs}{_tmp}=$ftr_cmd->{_work_dirs}->{_tmp};
            }
         } return $work_dirs,$ftr_cmd,$cmd_type,$ftm_type,'' if $ftr_cmd;
      } elsif ($rcm_chain) {
         if ($rcm_map && ref $rcm_map ne 'ARRAY') {
            $rcm_map=[$rcm_map];
         } else { $rcm_map=[] }
         sub recurse_chain {
print "RECURSECALLER=",caller," and ZERO=$_[0]\n";<STDIN>;
print "ZERO=",join ' ',@{$_[0]}," and ONE=$_[1] and TWO=$_[2] and TEE=$_[3]\n";<STDIN>;
            my @rcm_chain=@{$_[0]};
            my $ftr_cmd = defined $_[1] ? $_[1] : '';;
            my $hostlabel=$_[2];
            my $new_master=$_[3];
            my $_connect=$_[4];
            my $host_label=$hostlabel;
            my $rcm_chain_link_num=-1;
            if (-1<$#rcm_chain) {
               $rcm_chain_link_num=shift @rcm_chain;
               $host_label=
                  $Net::FullAuto::FA_lib::DeployRCM_Proxy[$rcm_chain_link_num];
            } elsif (!$ftr_cmd) {
               if (defined $Net::FullAuto::FA_lib::DeployRCM_Proxy[0]
                    && $Net::FullAuto::FA_lib::DeployRCM_Proxy[0]) {
                  $rcm_chain_link_num=0;
                  $host_label=$Net::FullAuto::FA_lib::DeployRCM_Proxy[0];
               } else {
                  my $die="\n       FATAL ERROR - No \"RCM_Proxy\" has "
                         ."been Properly\n              Defined in the "
                         ."\"$fa_hosts\" File.\n              This "
                         ."Element must Appear in at least\n       "
                         ."       One Block with the Syntax:\n       "
                         ."       RCM_Proxy => \'<hostlabel>\'\, "
                         ."Option - ChainLink Number\n";
                  print $Net::FullAuto::FA_lib::MRLOG $die
                     if $Net::FullAuto::FA_lib::log &&
                     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
               }
            }
            my ($ip,$hostname,$use,$ms_share,$ms_domain,
               $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
               $owner,$group,$frtimeout,$transfer_dir,$rcm_chain,
               $rcm_map,$uname,$ping,$freemem)
               =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
                  $host_label,$_connect);
            my $host= ($use eq 'ip') ? $ip : $hostname;
#print "IP=$ip and HOSTNAME=$hostname and HOST=$host\n";
            if (!$login_id) {
               if ($host eq
                     "$Net::FullAuto::FA_lib::Hosts{\"__Master_${$}__\"}{'HostName'}") {
print "FTR_RETURN2\n";
                  return Rem_Command::new('Rem_Command',$hostlabel,
                                          $new_master,$_connect);
               } elsif ($host eq
                     "$Net::FullAuto::FA_lib::Hosts{\"__Master_${$}__\"}{'IP'}") {
print "FTR_RETURN3\n";
                  return Rem_Command::new('Rem_Command',$ip,
                                          $new_master,$_connect);
               } else {
                  $login_id=$Net::FullAuto::FA_lib::username;
               } 
            } my $ftr_cmd_error='';my $su_scrub='';my $retrys='';
            if ($ftr_cmd) {
#print "GOING TO TRY LOGIN=$login_id and IP=$ip and FTR_CMD=$ftr_cmd\n";
               $ftr_cmd->{_cmd_handle}->print("telnet $host");
#print "GOING TO LOG IN TO $hostname - USERNAME=$login_id\n";<STDIN>;
               my ($alloutput,$output,$cygwin)='';
               while (my $line=$ftr_cmd->{_cmd_handle}->get) {
                  if (-1<index $line,'CYGWIN') {   
                     if ($su_id) {
                        if ($su_id ne $login_id) {
                           $login_id=$su_id;$cygwin=1;
                        } else { $su_id='' }
                     }
                     $Net::FullAuto::FA_lib::Hosts{"$hostlabel"}{'Uname'}='cygwin';
                  } elsif (-1<index $line,'AIX') {
                     $Net::FullAuto::FA_lib::Hosts{"$hostlabel"}{'Uname'}='aix';
                  }
                  last if $line=~
                     /(?<!Last )login[: ]*$|username[: ]*$/i;
               }
               while (1) {
                  eval {

                     $ftr_cmd->{_cmd_handle}->print($login_id);

                     ## Wait for password prompt.
                     while (my $line=$ftr_cmd->{_cmd_handle}->get) {
                        last if $line=~/password[: ]*$/i;
                     }

                     ## Send password.
                     my $recurse_passwd=&Net::FullAuto::FA_lib::getpasswd($hostlabel,
                                $login_id,'',$ftr_cmd_error);
                     $ftr_cmd->{_cmd_handle}->print($recurse_passwd);

                     my $alloutput='';my $output='';my $stderr='';
                     my $cygwin='';my $newpw='';
                     while (my $line=$ftr_cmd->{_cmd_handle}->get) {
                        ($output=$line)=~s/login:.*//s;
                        &Net::FullAuto::FA_lib::handle_error($output)
                           if $line=~/(?<!Last )login[: ]*$/m;
                        if ($line=~/new password: ?$/is) {
                           $newpw=$line;last;
                        } last if $line=~/[$|%|>|#|-|:] ?$/s;
                     }

                     &Net::FullAuto::FA_lib::change_pw($ftr_cmd) if $newpw;

                     if ($su_scrub) {
                        my $kind='prod';
                        $kind='test' if $Net::FullAuto::FA_lib::test && !$Net::FullAuto::FA_lib::prod;
                        my $dbpath=$Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}
                                   {'FA_Secure'}
                                  ."${Net::FullAuto::FA_lib::progname}_${kind}_passwds.db";
print "DBPATHHHH=$dbpath<==\n";sleep 2;
                        my $tie_err="can't open tie to $dbpath";
                        my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
                        $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
                           %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
                           'MLDBM::Sync',$dbpath,
                           $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) or
                           &Net::FullAuto::FA_lib::handle_error("$tie_err: ");
                        $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->
                           SyncCacheSize('100K');
                        $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
                        my $href=${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$host};
                        my $key="${Net::FullAuto::FA_lib::username}_X_"
                               ."${Net::FullAuto::FA_lib::username}_X_${host}";
                        while (delete $href->{"$key"}) {}
                        my $cipher=Crypt::CBC->new({ 'key' => 
                              $Net::FullAuto::FA_lib::passwd[1], 'cipher' =>
                              $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'Cipher'} });
                        my $new_encrypted=$cipher->encrypt(
                              $recurse_passwd);
                        $href->{$key}=$new_encrypted;
                        ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$host}=$href;
                        $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
                        undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
                        delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
                        untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
                        delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
                     }
                     $ftr_cmd->{_cmd_handle}->cmd(
                        "export PS1='_funkyPrompt_';unset PROMPT_COMMAND");
                     $ftr_cmd->{_cmd_handle}->prompt("/_funkyPrompt_\$/");

                     ($output,$stderr)=
                        &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
                     if ($stderr) {
                        &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                           if $stderr=~/Connection closed/s;
                        &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                     }

                     my ($ignore,$su_err)=
                        &Net::FullAuto::FA_lib::su($ftr_cmd->{_cmd_handle},$host_label,
                           $Net::FullAuto::FA_lib::username,$su_id,$hostname,
                           $ip,$use,$ftr_cmd_error) if !$cygwin;
                     &Net::FullAuto::FA_lib::handle_error($su_err) if $su_err;

                  };
                  if ($@) {
                     $ftr_cmd_error=$@;
print "FTR_CMD_ERROR=$ftr_cmd_error\n";<STDIN>;
                     $ftr_cmd_error=~s/^[\012|\015]*//s;

                     if ($ftr_cmd_error=~/invalid log|ogin incor/) {
                        &Net::FullAuto::FA_lib::scrub_passwd_file(
                           $hostlabel,$Net::FullAuto::FA_lib::username);
                        if ($Net::FullAuto::FA_lib::OS eq 'cygwin' && $retrys==2) {
                           $ftr_cmd_error.="\nWARNING! - You may be in Danger"
                                         ." of locking out MS Domain ID - "
                                         ."$Net::FullAuto::FA_lib::username!\n\n";
                        }
                        next;
                     } elsif ($su_id &&
                           -1<index($ftr_cmd_error,'ation is d')) {
print "GOOD - SCRUBBING\n";
                        $su_scrub=
                           &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,
                           $su_id);
                        next;
                     }

                     my $c_t=$ftr_cmd->{_cmd_type};$c_t=~s/^(.)/uc($1)/e;
                     my $die="The System $host Returned\n       "
                            ."       the Following Unrecoverable"
                            ." Error Condition\,\n              "
                            ."Rejecting the $c_t Login Attempt"
                            ." of the ID\n              -> "
                            ."$login_id at ".(caller(0))[1]." line "
                            .(caller(0))[2]." :\n\n       "
                            ."$ftr_cmd_error\n";
                     print $Net::FullAuto::FA_lib::MRLOG $die
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     &Net::FullAuto::FA_lib::handle_error($die);

                  } last;

               }
               $ftr_cmd->{_cmd_handle}->cmd(
                  "export PS1='_funkyPrompt_';unset PROMPT_COMMAND");
               $ftr_cmd->{_cmd_handle}->prompt("/_funkyPrompt_\$/");
               if ($hostlabel eq $host_label) {
print "FTR_RETURN4\n";
                  return $ftr_cmd;
               } else {
print "FTR_RETURN4\n";
                  return &recurse_chain(\@rcm_map,$ftr_cmd,
                            $hostlabel,$_connect);
               }
            } elsif (&Net::FullAuto::FA_lib::ping($host)) {
               $ftr_cmd = Rem_Command::new('Rem_Command',$host_label,
                                           $new_master);
               if ($hostlabel eq $host_label) {
print "FTR_RETURN5\n";
                  return $ftr_cmd;
               } else {
print "FTR_RETURN6\n";
                  return &recurse_chain(\@rcm_map,$ftr_cmd,
                            $hostlabel,$_connect);
               }
            }
         } 
         ## End of &recurse_chain()
#print "CMD_TYPEBEFORERECURSE=$cmd_type\n";
         $ftr_cmd=&recurse_chain($rcm_map,'',$hostlabel,$_connect);
#print "CMD_TYPEAFTERRECURSE=$cmd_type\n";<STDIN>;
#print "RECURSED HOSTNAME=",$ftr_cmd->cmd('hostname'),"\n";
      }
   }
print "WHAT ARE WE DOING HERE SO THAT THINGS WORK and FTM_TYPE=$ftm_type\n";<STDIN>;
   if (!$ftr_cmd && ${$ftr_cnct}[0] eq 'smb' &&
         -1<$#FA_lib::DeploySMB_Proxy) {
      ($ftr_cmd,$stderr)=
            Rem_Command::new('Rem_Command',$hostlabel,
                             $new_master);
      if ($stderr) {
         chomp $stderr;
print "FTR_RETURN7\n";
         return '','','','',$stderr;
      }
      $cmd_type=$ftr_cmd->{_cmd_type};
      $ms_hostlabel=$hostlabel;
      $ms_host=$host;
      $ms_ms_share=$ms_share;
      $ms_ms_domain=$ms_domain;
      $ms_login_id=$login_id;
      $ms_su_id=$su_id;
      $ms_login_id=$su_id if $su_id;
      ($ip,$hostname,$use,$ms_share,$ms_domain,
         $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
         $owner,$group,$frtimeout,$transfer_dir,$rcm_chain,
         $rcm_map,$uname,$ping,$freemem)
         =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
         $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]);
      $host=($use eq 'ip') ? $ip : $hostname;
      $login_id=$Net::FullAuto::FA_lib::username if !$login_id;
      $login_id=$su_id if $su_id;
      $hostlabel=$Net::FullAuto::FA_lib::DeploySMB_Proxy[0];
      if (defined $transfer_dir && $transfer_dir) {
print "FTRTHREE\n";
         $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                    $hostlabel,$ftr_cmd,$cmd_type,'',$_connect);
         ${$work_dirs}{_cwd_mswin}=${$work_dirs}{_pre_mswin}
            ="\\\\$ms_host\\$ms_ms_share\\";
         ${$work_dirs}{_cwd}=${$work_dirs}{_pre}='';
         my ($output,$stderr)=$ftr_cmd->cmd('cd '.${$work_dirs}{_tmp});
         if ($stderr) {
            @FA_lib::tran=();
            my $die="Cannot cd to TransferDir -> ".${$work_dirs}{_tmp}
                   ."\n        $stderr";
            &Net::FullAuto::FA_lib::handle_error($die,'-5');
         }
         ($output,$stderr)=&ftpcmd($ftr_cmd,
                'cd '.${$work_dirs}{_tmp});#,$hostlabel,$ftm_type);
         my $die="Cannot cd to TransferDir -> $transfer_dir"
                ."\n        $stderr";
         &Net::FullAuto::FA_lib::handle_error($die,'-2') if $stderr;
         $Net::FullAuto::FA_lib::tran[0]=${$work_dirs}{_tmp};
         $Net::FullAuto::FA_lib::tran[1]=$hostlabel;
         $Net::FullAuto::FA_lib::ftpcwd{$ftr_cmd->{_ftp_handle}}{cd}=${$work_dirs}{_tmp};
      } else {
         #  ADD CODE HERE FOR DYNAMIC TMP DIR DISCOVERY
         &Net::FullAuto::FA_lib::handle_error("No TransferDir Defined for $hostlabel");
      }
   } return $work_dirs,$ftr_cmd,$cmd_type,$ftm_type,'';
         
}

sub ftm_login
{
   my @topcaller=caller;
   print "File_Transfer::ftm_login() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::ftm_login() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $hostlabel=$_[0];
   my $new_master=$_[1]||'';
   my $_connect=$_[2]||'';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my @connect_method=@{$ftr_cnct};
   my $host=($use eq 'ip') ? $ip : $hostname;
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $fttimeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (!$fttimeout) {
      $fttimeout=$timeout if !$fttimeout;
   }
   print $Net::FullAuto::FA_lib::MRLOG "NEWMASTER=$new_master<==\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if (!$new_master && ($hostlabel eq "__Master_${$}__"
          || exists $Net::FullAuto::FA_lib::same_host_as_Master{$hostlabel})) {
      return "__Master_${$}__",'','','','','','','','';
   }
   my $ftp_handle='';my $ftr_cmd='';my $su_login='';
   my $ftm_errmsg='';my $die='';my $s_err='';my $shell_pid=0;
   my $retrys=0;my $local_transfer_dir='';my $cmd_type='';
   my $ms_host='';my $ms_hostlabel='';my $fpx_handle='';
   my $work_dirs='';my $die_login_id='';my $output='';
   my $stderr='';my $ms_su_id='';my $ms_login_id='';
   my $ms_ms_domain='';my $ms_ms_share='';my $ftm_type='';
   my $desthostlabel='';my $p_uname='',my $fpx_passwd='';
   my $ftm_passwd=$Net::FullAuto::FA_lib::passwd[2]||$Net::FullAuto::FA_lib::passwd[0];
   my $ftp_pid='';my $fpx_pid='';my $smb=0;
   $login_id=$Net::FullAuto::FA_lib::username if !$login_id;
   while (1) {
      eval {
         if (lc(${$ftr_cnct}[0]) eq 'smb') {
            $smb=1;
            $ms_hostlabel=$hostlabel;
            $ms_host=$host;
            if (!exists $same_host_as_Master{$Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}) {
               if (!defined $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]) {
                  my $die="The Action You Selected Requires the Use of"
                         ."\n       an MSWin Proxy Host - and None are"
                         ."\n       Currently Available.";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
               ($ip,$hostname,$use,$ms_share,$ms_domain,
                  $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
                  $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
                  $rcm_map,$uname,$ping,$freemem)
                  =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
                  $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]);
               if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
                  $fttimeout=$Net::FullAuto::FA_lib::cltimeout;
               } elsif (!$fttimeout) {
                  $fttimeout=$timeout if !$fttimeout;
               }
               $hostname||='';$ms_share||='';
               $host=($use eq 'ip') ? $ip : $hostname;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST1111=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               $login_id=$Net::FullAuto::FA_lib::username if !$login_id;
               if ($su_id) {
                  $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $Net::FullAuto::FA_lib::DeploySMB_Proxy[0],$su_id,
                     $ms_share,$ftm_errmsg,'','','smb');
                  if ($ftm_passwd ne 'DoNotSU!') {
                     $su_login=1;
                  } else { $su_id='' }
               }
               if (!$su_id) {
                  $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $Net::FullAuto::FA_lib::DeploySMB_Proxy[0],$login_id,
                     $ms_share,$ftm_errmsg,'','','smb');
               }
               $ftm_errmsg='' unless defined $ftm_errmsg; 
               $hostlabel=$Net::FullAuto::FA_lib::DeploySMB_Proxy[0];
               @connect_method=@{$ftr_cnct};
            } else {
               ($work_dirs,$smb_type,$stderr)=
                     &connect_share($Net::FullAuto::FA_lib::localhost->{_cmd_handle},
                     $hostlabel);
               $cmd_type='';
               $ftm_type='';
               $smb=1;
               if (!$stderr) {
                  ${$work_dirs}{_tmp}=
                     $Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp};
                  ${$work_dirs}{_tmp_mswin}=
                     $Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp_mswin};
                  ${$work_dirs}{_pre_mswin}=${$work_dirs}{_cwd_mswin};
print "HOW ABOUT AN SMB UNAME???===$uname<===\n";<STDIN>;
                  my %cmd=(
                     _cmd_handle =>
                         $Net::FullAuto::FA_lib::localhost->{_cmd_handle},
                     _cmd_type   => $cmd_type,
                     _work_dirs  => $work_dirs,
                     _hostlabel  => [ $hostlabel,'' ],
                     _hostname   => $hostname,
                     _ip         => $ip,
                     _uname      => $uname,
                     _luname     => $Net::FullAuto::FA_lib::OS,
                     _cmd_pid    => $Net::FullAuto::FA_lib::localhost->{_cmd_pid},
                     _smb        => 1
                  );
                  $ftr_cmd=bless \%cmd, 'Rem_Command';
                  return '','',$work_dirs,$ftr_cmd,$ftm_type,
                         $cmd_type,$smb,'','','';
               } else {
                  &Net::FullAuto::FA_lib::handle_error($stderr);
               }
            }
         } elsif (${$ftr_cnct}[0] eq 'ftp_proxy' && 
               !exists $Net::FullAuto::FA_lib::same_host_as_Master{
               $Net::FullAuto::FA_lib::DeployFTM_Proxy[0]}) {
            if (!$ftp_handle) {
               $desthostlabel=$hostlabel;
               $hostlabel=$Net::FullAuto::FA_lib::DeployFTM_Proxy[0];
               ($ip,$hostname,$use,$ms_share,$ms_domain,
                  $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
                  $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
                  $rcm_map,$p_uname,$ping,$freemem)
                  =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel);
               if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
                  $fttimeout=$Net::FullAuto::FA_lib::cltimeout;
               } elsif (!$fttimeout) {
                  $fttimeout=$timeout if !$fttimeout;
               }
               $hostname||='';$ms_share||='';
               $host=($use eq 'ip') ? $ip : $hostname;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST2222=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               &Net::FullAuto::FA_lib::take_semaphore(1234);
               if ($su_id) {
                  $fpx_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $hostlabel,$su_id,$ms_share,
                     $ftm_errmsg,'__su__',$ftm_type);
                  if ($fpx_passwd ne 'DoNotSU!') {
                     $su_login=1;
                  } else { $su_id='' }
               }
               if (!su_id) {
                  $fpx_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $hostlabel,$login_id,
                     $ms_share,$ftm_errmsg,'',$ftm_type);
               }
               my $sftploginid=($su_id)?$su_id:$login_id;
               my $previous_method='';$stderr='';
               my $fm_cnt=-1;
               foreach my $connect_method (@connect_method) {
                  $fm_cnt++;
                  if ($stderr) {
                     print "Warning, Preferred Connection ",
                           "$previous_method Failed\n";
                  } else { $previous_method=$connect_method;$stderr='' }
                  if (lc($connect_method) eq 'ftp') {
                     if (exists $Hosts{"__Master_${$}__"}{'ftp'}) {
                        $Net::FullAuto::FA_lib::ftppath=$Hosts{"__Master_${$}__"}{'ftp'};
                        $Net::FullAuto::FA_lib::ftppath.='/' if $ftppath!~/\/$/;
                     }
                     ($fpx_handle,$fpx_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                        ["${Net::FullAuto::FA_lib::ftppath}ftp",$host,'',$Net::FullAuto::FA_lib::slave])
                        or &Net::FullAuto::FA_lib::handle_error(
                        "couldn't launch ftp subprocess");
                     $fpx_handle=Net::Telnet->new(Fhopen => $fpx_handle,
                        Timeout => $fttimeout);
                     if ($su_id) {
                        $Net::FullAuto::FA_lib::processes{$hostlabel}{$su_id}
                           {'ftm_su_'.++$Net::FullAuto::FA_lib::pcnt}=
                           [ $fpx_handle,$fpx_pid,'','' ];
                     } else {
                        $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                           {'ftm_id_'.++$Net::FullAuto::FA_lib::pcnt}=
                           [ $fpx_handle,$fpx_pid,'','' ];
                     }
                     $fpx_handle->telnetmode(0);
                     $fpx_handle->binmode(1);
                     $fpx_handle->output_record_separator("\r");
                     while (my $line=$fpx_handle->get) {
print "FTPLOGINLINE=$line and MS_SHARE=$ms_share\n";
print $Net::FullAuto::FA_lib::MRLOG "FTPLOGINLINE=$line and MS_SHARE=$ms_share\n";
                        if ((20<length $line && unpack('a21',$line)
                               eq 'A remote host refused')
                               || (31<length $line && unpack('a32',$line) eq
                               'ftp: connect: Connection refused')) {
                           while (my $ln=$fpx_handle->get) {
                              print "CHECLELINE=$ln\n";
                              last if $ln=~/_funkyPrompt_/s;
                           }
                           $line=~s/^(.*)?\n.*/$1/s;
                           $die=$line
                               ."Destination Host - $host, HostLabel "
                               ."- $hostlabel\n       refused an "
                               ."attempted connect operation.\n       "
                               ."Check for a running FTP daemon on "
                               ."$hostlabel";
                           &Net::FullAuto::FA_lib::handle_error($die);
                        } last if $line=~/Name.*[: ]*$/i;
                     } $ftm_type='ftp';
                  } elsif (lc($connect_method) eq 'sftp') {
                     if (exists $Hosts{"__Master_${$}__"}{'sftp'}) {
                        $Net::FullAuto::FA_lib::sftppath=$Hosts{"__Master_${$}__"}{'sftp'};
                        $Net::FullAuto::FA_lib::sftppath.='/' if $Net::FullAuto::FA_lib::sftppath!~/\/$/;
                     }
print "WHAT IS SLAVE=$Net::FullAuto::FA_lib::slave<==\n";
                     ($fpx_handle,$fpx_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                        ["${Net::FullAuto::FA_lib::sftppath}sftp","$sftploginid\@$host",
                         '',$Net::FullAuto::FA_lib::slave])
                        or &Net::FullAuto::FA_lib::handle_error(
                        "couldn't launch sftp subprocess");
                     $fpx_handle=Net::Telnet->new(Fhopen => $fpx_handle,
                        Timeout => $fttimeout);
                     if ($su_id) {
                        $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                           {'ftm_su_'.++$Net::FullAuto::FA_lib::pcnt}=
                           [ $fpx_handle,$fpx_pid,'','' ];
                     } else {
                        $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                           {'ftm_id_'.++$Net::FullAuto::FA_lib::pcnt}=
                           [ $fpx_handle,$fpx_pid,'','' ];
                     }
                     $fpx_handle->telnetmode(0);
                     $fpx_handle->binmode(1);
                     $fpx_handle->output_record_separator("\r");
                     $ftm_type='sftp';
                  }
               }
               if ($su_id) {
                  $fpx_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $hostlabel,$su_id,$ms_share,
                     $ftm_errmsg,'__su__',$ftm_type);
                  if ($fpx_passwd ne 'DoNotSU!') {
                     $su_login=1;
                  } else { $su_id='' }
               }
               if (!su_id) {
                  $fpx_passwd=&Net::FullAuto::FA_lib::getpasswd(
                     $hostlabel,$login_id,
                     $ms_share,$ftm_errmsg,'',$ftm_type);
               }
               ## Wait for password prompt.
               my $allines='';
               while (my $line=$fpx_handle->get) {
print "SFTPLINE=$line<==\n";
                  $allines.=$line;
                  if ($allines=~/password[: ]+$/si) {
                     last;
                  } elsif ((-1<index($line,'530 '))
                        || (-1<index($line,'421 '))) {
                     $line=~s/^(.*)?\n.*$/$1/s;
                     &Net::FullAuto::FA_lib::handle_error($line);
                  }
               }
               my %ftp=(
                  _ftp_handle => $fpx_handle,
                  _ftm_type   => $ftm_type,
                  _hostname   => $hostname,
                  _ip         => $ip,
                  _uname      => $uname,
                  _luname     => $Net::FullAuto::FA_lib::OS,
                  _hostlabel  => [ $hostlabel,
                                   $Net::FullAuto::FA_lib::localhost->{_hostlabel}->[0] ],
                  _ftp_pid    => $fpx_pid
               );
print "FPX_PID=$fpx_pid and TEL=$fpx_handle\n";
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,$fpx_passwd);
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               $fpx_handle->prompt("/s*ftp> ?\$/");
               ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'binary')
                  if $ftm_type ne 'sftp';
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               &Net::FullAuto::FA_lib::give_semaphore(1234);
               if (defined $transfer_dir && $transfer_dir) {
print "FTRFOUR\n";
                  $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                             $hostlabel,$fpx_handle,$ftm_type,'',$_connect);
                  ($output,$stderr)=Rem_Command::cmd(
                     { _cmd_handle=>$fpx_handle,
                       _hostlabel=>[ $hostlabel,'' ]
                     },'cd '.${$work_dirs}{_tmp});
                  if ($stderr) {
                     my $die="The FTP Service Cannot cd to "
                            ."TransferDir -> ".${$work_dirs}{_tmp}
                            ."\n\n       $stderr";
                     &Net::FullAuto::FA_lib::handle_error($die);
                  }
               }
            } $ftp_handle=1;
            my $ip='';my $hostname='';my $use='';my $ms_share='';
            my $ms_domain='';my $cmd_cnct='';my $ftr_cnct='';
            my $login_id='';my $su_id='';my $chmod='';
            my $owner='';my $group='';my $transfer_dir='';
            my $rcm_chain='';my $rcm_map='';my $p_uname='';
            my $cmd_type='';
            ($ftp_handle,$stderr)=new Rem_Command($hostlabel,
                                                  $new_master,$_connect);
            $shell_pid=$ftp_handle->{_sh_pid};
            $ftp_pid=$ftp_handle->{_cmd_pid};
            $cmd_type=$ftp_handle->{_cmd_type};
            $ftp_handle=$ftp_handle->{_cmd_handle};
            my $cygdrive=$ftp_handle->{_cygdrive};
            $hostlabel=$desthostlabel;
            ($ip,$hostname,$use,$ms_share,$ms_domain,
               $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
               $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
               $rcm_map,$uname,$ping,$freemem)
               =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
            my $sftploginid=($su_id)?$su_id:$login_id;
            if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
               $fttimeout=$Net::FullAuto::FA_lib::cltimeout;
            } elsif (!$fttimeout) {
               $fttimeout=$timeout if !$fttimeout;
            }
            $ftp_handle->timeout($fttimeout);
            $hostname||='';$ms_share||='';
            $host=($use eq 'ip') ? $ip : $hostname;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST3333=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            my $gotname=0;
            my $previous_method='';$stderr='';
            my $fm_cnt=-1;
            foreach my $connect_method (@connect_method) {
               $fm_cnt++;
               if ($stderr && $previous_method ne $connect_method) {
                  print "Warning, Preferred Connection ",
                        "$previous_method Failed\n";
               } else { $previous_method=$connect_method;$stderr='' }
               if (lc($connect_method) eq 'ftp') {
                  &Net::FullAuto::FA_lib::clean_filehandle($ftp_handle);
                  eval {
                     my $allines='';
                     $ftp_handle->print("${Net::FullAuto::FA_lib::ftppath}ftp $host");
                     ## Send Login ID.
                     ID: while (my $line=$ftp_handle->get) {
                        $allines.=$line;
                        if (!$allines && -1<index $line,'_funkyPrompt_') {
                           $line=~s/_funkyPrompt_//g;
                        }
                        my $tline=$line;
print "ftplogin() TLINE=$tline<==\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print $Net::FullAuto::FA_lib::MRLOG "ftplogin() TLINE=$tline<==\n"
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $tline=~s/Name.*$//s;
                        if (-1<index $allines,'ftp: connect:') {
                           $allines=~/^.*connect:\s*(.*?\n).*$/s;
                           if ((-1==index $allines,'Address already in use')
                                 && (-1==index $allines,'Connection timed out'
                                 )) {
                              &Net::FullAuto::FA_lib::handle_error("ftp: connect: $1",'-8');
                           } else {
                              $ftp_handle->close if defined fileno $ftp_handle;
                              sleep int $ftp_handle->timeout/3;
                              ($ftp_handle,$stderr)=
                                 &Rem_Command::new('Rem_Command',
                                 "__Master_${$}__",$new_master);
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                              my $ftp_pid=$ftp_handle->{_cmd_pid};
                              $cmd_type=$ftp_handle->{_cmd_type};
                              $ftp_handle=$ftp_handle->{_cmd_handle};
                              $ftp_handle->print(
                                 "${Net::FullAuto::FA_lib::ftppath}ftp $host");
                              FH1: foreach my $hlabel (
                                    keys %Net::FullAuto::FA_lib::Processes) {
                                 foreach my $sid (
                                       keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                                    foreach my $type (
                                          keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                                          {$sid}}) {
                                       if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                                             {$hlabel}{$sid}{$type}}[0]) {
                                          my $value=$Net::FullAuto::FA_lib::Processes
                                             {$hlabel}{$sid}{$type};
                                          delete
                                             $Net::FullAuto::FA_lib::Processes{$hlabel}
                                             {$sid}{$type};
                                          substr($type,0,3)='ftm';
                                          $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}
                                              {$type}=$value;
                                          last FH1;
                                       }
                                    }
                                 }
                              }
                              #$tline=$line;
                              #$tline=~s/Name.*$//s;
                           }
                        } elsif (-1<index $allines,'421 Service' ||
                              -1<index $allines,
                              'No address associated with name'
                              || (-1<index $allines,'Connection' &&
                              (-1<index $allines,'Connection closed' ||
                              -1<index $allines,
                              'ftp: connect: Connection timed out'))) {
                          $allines=~s/s*ftp> ?$//s;
                          die "$allines\n      $!";
                        } print $tline if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                        print $Net::FullAuto::FA_lib::MRLOG $tline
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        if (-1<index $allines,
                              'ftp: connect: Connection timed out') {
                           $allines=~s/s*ftp> ?\s*$//s;
                           die "$allines\n     $!";
                        } elsif ((-1<index $allines,'A remote host refused')
                               || (-1<index $allines,
                               'ftp: connect: Connection refused')) {
                           my $host=($use eq 'ip') ? $ip : $hostname;
                           $allines=~s/^(.*)?\n.*/$1/s;
                           $die=$allines;
                           if ($die) {
                              $die.="Destination Host - $host, HostLabel "
                                  ."- $hostlabel\n       refused an attempted "
                                  ."connect operation.\n       Check for a "
                                  ."running FTP daemon on $hostlabel";
                              &Net::FullAuto::FA_lib::handle_error($die);
                           }
                        }
                        if ($allines=~/Name.*[: ]+$/si) {
                           #$gotname=1;$ftr_cmd='ftp';last;
                           $gotname=1;last;
                        }
                     }
                  }; next if !$gotname;
                  if ($@) {
                     if ($@=~/read timed-out/) {
                        FLP: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                           foreach my $sid (
                                 keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                              foreach my $type (
                                    keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                                    {$sid}}) {
                                 if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                                       {$hlabel}{$sid}{$type}}[0]) {
                                    ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill(
                                       ${$Net::FullAuto::FA_lib::Processes
                                       {$hlabel}{$sid}{$type}}[2],9) if
                                       &Net::FullAuto::FA_lib::testpid(${$Net::FullAuto::FA_lib::Processes
                                       {$hlabel}{$sid}{$type}}[2]);
                                    ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill(
                                       ${$Net::FullAuto::FA_lib::Processes
                                       {$hlabel}{$sid}{$type}}[1],9) if
                                       &Net::FullAuto::FA_lib::testpid(${$Net::FullAuto::FA_lib::Processes
                                       {$hlabel}{$sid}{$type}}[1]);
                                    delete
                                       $Net::FullAuto::FA_lib::Processes{$hlabel}
                                       {$sid}{$type};
                                    last FLP;
                                 }
                              }
                           }
                        }
                        $ftp_handle->close;
                        my $die="&ftm_login() timed-out while\n       "
                               ."waiting for a login prompt from\n       "
                               ."Remote Host - $host,\n       HostLabel "
                               ."- $hostlabel\n\n       The Current Timeout"
                               ." Setting is $fttimeout Seconds.";
                        &Net::FullAuto::FA_lib::handle_error($die);
                     } else { die $@ }
                  }
                  if ($su_id) {
                     $ftp_handle->print($su_id);
                  } else {
                     $ftp_handle->print($login_id);
                  }
                  ## Wait for password prompt.
                  ($ignore,$stderr)=&wait_for_ftr_passwd_prompt(
                     { _cmd_handle=>$ftp_handle,
                       _hostlabel=>[ $hostlabel,'' ],
                       _cmd_type=>$cmd_type });
                  if ($stderr) {
                     if ($fm_cnt==$#{$ftr_cnct}) {
                        return '',$stderr;
                     } else { next }
                  }
                  $ftm_type='ftp';last;
               } elsif (lc($connect_method) eq 'sftp') {
                  $ftp_handle->print("${Net::FullAuto::FA_lib::sftppath}sftp ".
                     "$sftploginid\@$host");
                  $ftm_type='sftp';
               }
            }
            if ($su_id) {
               my $value=$Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"cmd_su_$Net::FullAuto::FA_lib::pcnt"};
               delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"cmd_su_$Net::FullAuto::FA_lib::pcnt"};
               $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"ftm_su_$Net::FullAuto::FA_lib::pcnt"}=$value;
            } else {
               my $value=$Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"cmd_id_$Net::FullAuto::FA_lib::pcnt"};
               delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"cmd_id_$Net::FullAuto::FA_lib::pcnt"};
               $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {"ftm_id_$Net::FullAuto::FA_lib::pcnt"}=$value;
            }
            if ($su_id) {
               $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                  $hostlabel,$su_id,$ms_share,
                  $ftm_errmsg,'__su__');
               if ($ftm_passwd ne 'DoNotSU!') {
                  $ftm_handle->print($su_id);
                  $su_login=1;
               } else { $su_id='' }
            }
            if (!$su_id) {
               $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                  $hostlabel,$login_id,
                  $ms_share,$ftm_errmsg);
               $ftp_handle->print($login_id);
            }
            my %ftp=(
               _ftp_handle => $ftp_handle,
               _cmd_type   => $cmd_type,
               _ftm_type   => $ftm_type,
               _hostname   => $hostname,
               _ip         => $ip,
               _uname      => $uname,
               _luname     => $Net::FullAuto::FA_lib::OS,
               _hostlabel  => [ $hostlabel,
                                $Net::FullAuto::FA_lib::localhost->{_hostlabel}->[0] ],
               _ftp_pid    => $ftp_pid
            );
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,$ftm_passwd);
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            $ftp_handle->prompt("/s*ftp> ?\$/");
            if ($su_id) {
               $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$su_id"}=\%ftp;
            } else {
               $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$login_id"}=\%ftp;
            }
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'binary')
               if $ftm_type ne 'sftp';
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            #$Net::FullAuto::FA_lib::pcnt++;
            if (defined $transfer_dir && $transfer_dir) {
print "FTRFIVE\n";
               $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                  $hostlabel,$ftp_handle,$ftm_type,$cygdrive,$_connect);
               ($output,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$ftp_handle,
                    _hostlabel=>[ $hostlabel,'' ]
                  },'cd '.${$work_dirs}{_tmp});
               if ($stderr) {
                  my $die="The FTP Service Cannot cd to "
                         ."TransferDir -> ".${$work_dirs}{_tmp}
                         ."\n\n       $stderr";
                  &Net::FullAuto::FA_lib::handle_error($die);
               } $Net::FullAuto::FA_lib::ftpcwd{$ftp_handle}{cd}=${$work_dirs}{_tmp};
            }
print "ARE WE HERE FOLKS????????\n";<STDIN>;
            my $ftmtype='';
            ($work_dirs,$ftr_cmd,$cmd_type,$ftmtype,$stderr)
               =ftr_cmd($hostlabel,$ftp_handle,
               $new_master,$_connect)
               if ($_connect ne 'connect_sftp' &&
               $connect ne 'connect_ftp');
            $ftm_type=$ftmtype if $ftmtype;
print "RETURNTWO and FTR_CMD=$ftr_cmd\n";<STDIN>;
            return $ftp_handle,$ftp_pid,$work_dirs,$ftr_cmd,
               $ftm_type,$cmd_type,$fpx_handle,$fpx_pid,$die;
         } else {
#print "WE ARE REALLY HERE AND HOSTLABEL=$hostlabel\n";sleep 2;
            foreach my $connect_method (@connect_method) {
               if (lc($connect_method) eq 'ftp') {
                  $ftm_type='ftp';last;
               } elsif (lc($connect_method) eq 'sftp') {
                  $ftm_type='sftp';last;
               }
            }
            if ($su_id) {
               $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd($hostlabel,
                  $su_id,'',$ftm_errmsg,'__su__',$ftm_type);
               if ($ftm_passwd ne 'DoNotSU!') {
                  $su_login=1;
               } else { $su_id='' }
            }
            if (!$su_id) {
               $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd($hostlabel,
                           $login_id,'',$ftm_errmsg,$ftm_type);
            }
         }
         ($ftp_handle,$stderr)=
              Rem_Command::new('Rem_Command',
              "__Master_${$}__",$new_master,$_connect);
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         $ftp_pid=$ftp_handle->{_cmd_pid};
         $shell_pid=$ftp_handle->{_sh_pid};
         $cmd_type=$ftp_handle->{_cmd_type};
         $ftp_handle=$ftp_handle->{_cmd_handle};
         $ftp_handle->timeout($fttimeout);
         my $previous_method='';$stderr='';
         my $fm_cnt=-1;
         CM: foreach my $connect_method (@connect_method) {
            $fm_cnt++;
            if ($stderr && $connect_method ne $previous_method) {
               print "Warning, Preferred Connection $previous_method Failed\n";
            } else { $previous_method=$connect_method;$stderr='' }
            if (lc($connect_method) eq 'ftp') {
               ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($ftp_handle);
               if ($stderr) {
                  if ($stderr eq 'Connection closed') {
                     ($ftp_handle,$stderr)
                        =&Rem_Command::login_retry(
                                $ftp_handle,$stderr);
                     &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                        if $stderr=~/Connection closed/s;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }
               }
               $ftp_handle->print("${Net::FullAuto::FA_lib::ftppath}ftp $host");
               FH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                  foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                     foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}}) {
                        if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}}[0]) {
                           my $value=$Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type};
                           delete
                              $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                           substr($type,0,3)='ftm';
                           $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                              $value;
                           last FH;
                        }
                     }
                  }
               }

               ## Send Login ID.
               my $showftp=
                  "\n\tLoggingB into $host via ftp  . . .\n\n";
               print $showftp if (!$Net::FullAuto::FA_lib::cron
                  || $Net::FullAuto::FA_lib::debug)
                  && !$Net::FullAuto::FA_lib::quiet;
               print $Net::FullAuto::FA_lib::MRLOG $showftp
                  if $Net::FullAuto::FA_lib::log
                  && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               $s_err=' ';
               my $gotname=0;
               my $allines='';
               while (1) {
                  eval {
                     ID: while (my $line=$ftp_handle->get) {
                        $line||='';
                        if (!$allines && -1<index $line,'_funkyPrompt_') {
                           $line=~s/_funkyPrompt_//g;
                        }
                        $allines.=$line;
                        my $tline=$line;
#print "ftplogin() TLINE=$tline<==\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print $Net::FullAuto::FA_lib::MRLOG "ftplogin() TLINE=$tline<==\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
  # if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $tline=~s/Name.*$//s;
                        if (-1<index $allines,'ftp: connect:') {
                           $allines=~/^.*connect:\s*(.*?\n).*$/s;
                           my $m=$1;$m||='';
                           if ((-1==index $allines,'Address already in use')
                                 && (-1==index $allines,'Connection timed out'
                                 )) {
                              $ftp_handle->cmd('bye');
                              die "ftp: connect: $m";
                              #&Net::FullAuto::FA_lib::handle_error("ftp: connect: $m",'-8',
                              #   '__cleanup__');
                           } elsif ($retrys++<2) {
                              ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9)
                                 if &Net::FullAuto::FA_lib::testpid($shell_pid)
                                 && $shell_pid ne $localhost->{_sh_pid};
                              ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($ftp_pid,9)
                                 if &Net::FullAuto::FA_lib::testpid($ftp_pid)
                                 && $ftp_pid ne $localhost{_cmd_pid};
                              $ftp_handle->close if defined fileno $ftp_handle;
                              sleep int $ftp_handle->timeout/3;
                              ($ftp_handle,$stderr)=
                                 &Rem_Command::new('Rem_Command',
                                 "__Master_${$}__",$new_master,$_connect);
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                              $ftp_handle=$ftp_handle->{_cmd_handle};
                              $ftp_handle->timeout($fttimeout);
                              my $sftploginid=($su_id)?$su_id:$login_id;
                              my $previous_method='';$stderr='';
                              my $fm_cnt=-1;
                              foreach $connect_method (@connect_method) {
                                 if (lc($connect_method) eq 'ftp') {
                                    $ftp_handle->print(
                                       "${Net::FullAuto::FA_lib::ftppath}ftp $host");
                                    last;
                                 } elsif (lc($connect_method) eq 'sftp') {
                                    $ftp_handle->print(
                                       "${Net::FullAuto::FA_lib::sftppath}sftp ".
                                       "$sftploginid\@$host");
                                    last;
                                 }
                              }
                              FH1: foreach my $hlabel (
                                    keys %Net::FullAuto::FA_lib::Processes) {
                                 foreach my $sid (
                                       keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                                    foreach my $type (
                                          keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                                          {$sid}}) {
                                       if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                                             {$hlabel}{$sid}{$type}}[0]) {
                                          my $value=$Net::FullAuto::FA_lib::Processes
                                             {$hlabel}{$sid}{$type};
                                          delete
                                             $Net::FullAuto::FA_lib::Processes{$hlabel}
                                             {$sid}{$type};
                                          substr($type,0,3)='ftm';
                                          $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}
                                              {$type}=$value;
                                          last FH1;
                                       }
                                    }
                                 }
                              }
                           } else {
                              ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9)
                                 if &Net::FullAuto::FA_lib::testpid($shell_pid)
                                 && $shell_pid ne $localhost->{_sh_pid};
print "FTP_PID=$ftp_pid\n";
                              ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($ftp_pid,9)
                                 if &Net::FullAuto::FA_lib::testpid($ftp_pid)
                                 && $ftp_pid ne $localhost{_cmd_pid};
                              &Net::FullAuto::FA_lib::handle_error("ftp: connect: $m\n       "
                                 ."$retrys Attempts Tried",'-8','__cleanup__');
                           }
                        } elsif (-1<index $allines,'421 Service' ||
                              -1<index $allines,
                              'No address associated with name'
                              || (-1<index $allines,'Connection' &&
                              (-1<index $allines,'Connection closed' ||
                              -1<index $allines,
                              'ftp: connect: Connection timed out'))) {
                          $allines=~s/s*ftp> ?$//s;
                          die "$allines\n      $!";
                        } print $tline if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                        print $Net::FullAuto::FA_lib::MRLOG $tline
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        if (-1<index $allines,
                              'ftp: connect: Connection timed out') {
                           $allines=~s/s*ftp> ?\s*$//s;
                           die "$allines\n     $!";
                        } elsif ((-1<index $allines,'A remote host refused')
                               || (-1<index $allines,
                               'ftp: connect: Connection refused')) {
                           my $host=($use eq 'ip') ? $ip : $hostname;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST4444=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           if ($ms_share && !$ftm_only) {
                              if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
                                 my $mswin_cwd='';
                                 ($mswin_cwd,$smb_type,$stderr)=
                                       &connect_share(
                                       $Net::FullAuto::FA_lib::localhost->{_cmd_handle},
                                       $hostlabel);
                                 $cmd_type='';
                                 $ftm_type='';
                                 $smb=1;
                                 if (!$stderr) {
                                    ${$work_dirs}{_tmp}=
                                       $Net::FullAuto::FA_lib::localhost->{_work_dirs}
                                       ->{_tmp};
                                    ${$work_dirs}{_tmp_mswin}=
                                       $Net::FullAuto::FA_lib::localhost->{_work_dirs}
                                       ->{_tmp_mswin};
                                    ${$work_dirs}{_pre_mswin}
                                       =${$work_dirs}{_cwd_mswin};
                                    my %cmd=(
                                       _cmd_handle => 
                                          $Net::FullAuto::FA_lib::localhost->{_cmd_handle},
                                       _cmd_type   => '',
                                       _work_dirs  => $work_dirs,
                                       _hostlabel  => [ $hostlabel,'' ],
                                       _hostname   => $hostname,
                                       _ip         => $ip,
                                       _uname      => $uname,
                                       _luname     => $Net::FullAuto::FA_lib::OS,
                                       _cmd_pid    =>
                                          $Net::FullAuto::FA_lib::localhost->{_cmd_pid},
                                       _smb        => 1
                                    );
                                    $ftr_cmd=bless \%cmd, 'Rem_Command';
print "RETURNTHREE and FTR_CMD=$ftr_cmd\n";<STDIN>;
                                    return '','',$work_dirs,$ftr_cmd,
                                       $ftm_type,$cmd_type,'','','';
                                 } elsif (unpack('a10',$stderr) eq 'System err'
                                       && $stderr=~/unknown user name/s) {
                                    &Net::FullAuto::FA_lib::handle_error($stderr);
                                 } else { $die=$stderr }
                              } elsif (exists $Net::FullAuto::FA_lib::Hosts{
                                         $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}) {
                                 $Net::FullAuto::FA_lib::Hosts{$hostname}{'RCM_Link'}
                                    ='';
                                 $Net::FullAuto::FA_lib::Hosts{$hostname}{'FTM_Link'}
                                    ='smb';
                                 $ms_host=$host;
                                 $ms_ms_share=$ms_share;
                                 $ms_hostlabel=$hostlabel;
                                 $ms_login_id=$login_id;
                                 $ms_su_id=$su_id;
                                 $hostlabel=$Net::FullAuto::FA_lib::DeploySMB_Proxy[0];
                                 ($ip,$hostname,$use,$ms_share,$ms_domain,
                                    $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
                                    $owner,$group,$fttimeout,$transfer_dir,
                                    $rcm_chain,$rcm_map,$uname,$ping,$freemem)
                                    =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
                                    $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]);
                                 if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
                                    $fttimeout=$Net::FullAuto::FA_lib::cltimeout;
                                 } elsif (!$fttimeout) {
                                    $fttimeout=$timeout if !$fttimeout;
                                 }
                                 $host=($use eq 'ip') ? $ip : $hostname;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST5555=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 $login_id=$Net::FullAuto::FA_lib::username if !$login_id;
                                 $login_id=$su_id if $su_id;
                                 if (exists $Net::FullAuto::FA_lib::Connections{
                                       ${Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}.
                                       "__%-$login_id"}) {
                                    $ftp_handle=$Net::FullAuto::FA_lib::Connections{
                                       ${Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}.
                                       "__%-$login_id"}->{_ftp_handle};
                                    $ftr_cmd=$Net::FullAuto::FA_lib::Connections{
                                       ${Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}.
                                       "__%-$login_id"};
                                    $cmd_type=$ftr_cmd->{_cmd_type};
                                    $ftm_type=$ftp_handle->{_ftm_type};
                                    $smb=1;
                                    $uname=$Net::FullAuto::FA_lib::Connections{
                                       ${Net::FullAuto::FA_lib::DeploySMB_Proxy[0]}.
                                       "__%-$login_id"}->{_uname};
                                    my $mswin_cwd='';
                                    ($work_dirs,$smb_type,$stderr)=
                                       &connect_share($ftr_cmd,$ms_hostlabel);
                                    if (defined $transfer_dir
                                          && $transfer_dir) {
                                       if (unpack('@1 a1',$transfer_dir)
                                             eq ':') {
                                          my ($drive,$path)=
                                             unpack('a1 x1 a*',$transfer_dir);
                                          ${$work_dirs}{_tmp_mswin}
                                             =$transfer_dir.'\\';
                                          $path=~tr/\\/\//;
                                          ${$work_dirs}{_tmp}
                                             =$ftr_cmd->{_cygdrive}
                                             .'/'.lc($drive).$path.'/';
                                       } elsif ($transfer_dir=~/^[\/|\\]/
                                             && $transfer_dir!~/
                                             $ftr_cmd->{_cygdrive_regex}/ &&
                                             $hostlabel eq "__Master_${$}__") {
                                          (${$work_dirs}{_tmp},
                                             ${$work_dirs}{_tmp_mswin})=
                                             &File_Transfer::get_drive(
                                             $transfer_dir,'Transfer',
                                             '',$hostlabel);
                                       }
                                    }
                                    if ($stderr) {
                                       $die="Could Not Map the Directory "
                                           ."Share\n       -> \"\\\\$host"
                                           ."\\$ms_share\"\n\n       $stderr";
                                       my $er=$!;
                                       if ($er=~s/is not /is not\n        /) {
                                          $er=" $er";
                                       } $die="$die\n       $er";
                                    }
print "RETURNFOUR and FTR_CMD=$ftr_cmd\n";<STDIN>;
                                    return '','',$work_dirs,$ftr_cmd,
                                           $ftm_type,$cmd_type,$smb,'','',$die;
                                 } else {
                                    $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                                       $Net::FullAuto::FA_lib::DeploySMB_Proxy[0],$login_id,
                                       $ms_share,$ftm_errmsg,'',$ftm_type);
                                    $ftp_handle->print('bye');
                                    $ftp_handle->get;
                                    $ftp_handle->timeout($fttimeout);
                                    my $sftploginid=($su_id)?$su_id:$login_id;
                                    foreach $connect_method (@{$ftr_cnct}) {
                                       if (lc($connect_method) eq 'ftp') {
                                          $ftp_handle->print(
                                             "${Net::FullAuto::FA_lib::ftppath}ftp $host");
                                          $ftm_type='ftp';
                                       } elsif (lc($connect_method) eq 'sftp') {
                                          $ftp_handle->print(
                                             "${Net::FullAuto::FA_lib::sftppath}sftp ".
                                             "$sftploginid\@$host");
                                          $ftm_type='sftp';
                                       }
                                    }
                                 } $smb=1;
                                 ## Send Login ID.
                                 while (my $line=$ftp_handle->get) {
                                    if ((20<length $line && unpack('a21',$line)
                                          eq 'A remote host refused')
                                          || (31<length $line && unpack(
                                          'a32',$line) eq
                                          'ftp: connect: Connection refused')) {
                                       $line=~s/^(.*)?\n.*/$1/s;
                                       $die=$line;last;
                                    }
                                    if ($line=~/Name.*[: ]*$/i) {
                                       $gotname=1;last ID;
                                    }
                                 }
                              } else {
                                 $allines=~s/^(.*)?\n.*/$1/s;
                                 $die=$allines;
                              }
                           } else {
                              $allines=~s/^(.*)?\n.*/$1/s;
                              $die=$allines;
                           }
print "NOWWWLINE=$line\n";
                           if ($die) {
                              $die.="Destination Host - $host, HostLabel "
                                  ."- $hostlabel\n       refused an attempted "
                                  ."connect operation.\n       Check for a "
                                  ."running FTP daemon on $hostlabel";
                              &Net::FullAuto::FA_lib::handle_error($die);
                           }
                        }
                        if ($allines=~/Name.*[: ]+$/si) {
                           #$gotname=1;$ftr_cmd='ftp';last;
                           $gotname=1;last;
                        } 
                     }
                  };
#print "WHAT IS THE FTP_EVAL_ERROR=$@\n";
                  if (!$gotname && $@!~/remote host did not respond/) {
                     if (1<=$#connect_method) {
                        $stderr=$@;
                        next CM;
                     }
                     $retrys++;next;
                  }
                  if ($@) {
                     if ($@=~/read timed-out/) {
                        my $die="&ftm_login() timed-out while\n       "
                               ."waiting for a login prompt from\n       "
                               ."Remote Host - $host,\n       HostLabel "
                               ."- $hostlabel\n\n       The Current Timeout"
                               ." Setting is $fttimeout Seconds.";
                        &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
                     } else {
print $Net::FullAuto::FA_lib::MRLOG "ftplogin() EVALERROR=$@<==\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        my $die="&ftm_login() encountered an error while\n       "
                               ."waiting for a login prompt from\n       "
                               ."Remote Host - $host,\n       HostLabel "
                               ."- $hostlabel\n\n       The Current Timeout"
                               ." Setting is $fttimeout Seconds.";
                        &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
                        #die $@;
                     }
                  } last
               }

               if ($su_id) {
                  $ftp_handle->print($su_id);
               } else {
                  $ftp_handle->print($login_id);
               }
               ## Wait for password prompt.
               ($ignore,$stderr)=&wait_for_ftr_passwd_prompt(
                  { _cmd_handle=>$ftp_handle,
                    _hostlabel=>[ $hostlabel,'' ],
                    _cmd_type=>$cmd_type });
               if ($stderr) {
                  if ($fm_cnt==$#{$ftr_cnct}) {
                     return '',$stderr;
                  } else { next }
               }
               $ftm_type='ftp';last;
            } elsif (lc($connect_method) eq 'sftp') {
               my $sftploginid=($su_id)?$su_id:$login_id;
               $ftp_handle->print("${Net::FullAuto::FA_lib::sftppath}sftp ".
                                  "$sftploginid\@$host");
               FH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                  foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                     foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}}) {
                        if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}}[0]) {
                           my $value=$Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type};
                           delete
                              $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                           substr($type,0,3)='ftm';
                           $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                              $value;
                           last FH;
                        }
                     }
                  }
               }
               my $showsftp=
                  "\n\tLoggingB into $host via sftp  . . .\n\n";
               print $showsftp if (!$Net::FullAuto::FA_lib::cron
                  || $Net::FullAuto::FA_lib::debug)
                  && !$Net::FullAuto::FA_lib::quiet;
               print $Net::FullAuto::FA_lib::MRLOG $showsftp
                  if $Net::FullAuto::FA_lib::log
                  && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ## Wait for password prompt.
               ($ignore,$stderr)=&wait_for_ftr_passwd_prompt(
                  { _cmd_handle=>$ftp_handle,
                    _hostlabel=>[ $hostlabel,'' ],
                    _cmd_type=>$cmd_type });
               if ($stderr) {
                  if ($fm_cnt==$#{$ftr_cnct}) {
                     return '',$stderr;
                  } else { next }
               }
               $ftm_type='sftp';last;
            }
         }

         ## Send password.
         $ftp_handle->print($ftm_passwd);

         $lin='';$asked=0;
         while (1) {
            while (my $line=$ftp_handle->get) {
#print "LOOKING FOR FTPPROMPTLINE11=$line<==\n";
print $Net::FullAuto::FA_lib::MRLOG "LOOKING FOR FTPPROMPTLINE11=$line<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               chomp($line=~tr/\0-\11\13-\37\177-\377//d);
               $lin.=$line;
               if ($lin=~/Perm/s) {
                  if ($lin=~/password[:\s]+$/si) {
                     if ($su_id && $su_id ne $login_id) {
                        if (!$asked++) {
                           my $error='';
                           ($error=$lin)=~s/^\s*(.*)\n.*$/$1/s;
                           my $banner="\n    The Host \"$hostlabel\" is "
                                  ."configured to attempt a su\n    with "
                                  ."the ID \'$su_id\'\; however, the first "
                                  ."attempt\n    resulted in the following "
                                  ."Error :\n\n           $error\n\n    It "
                                  ."may be that sftp is configured to "
                                  ."disallow logins\n    with \'$su_id\'\."
                                  ."\n\n    Please Pick an Operation :\n"
                                  ."\n    NOTE:    Choice will affect all "
                                  ."future logins!\n";
                           $choices[0]="Re-enter password and re-attempt with "
                                  ."\'$su_id\'";
                           $choices[1]=
                                  "Attempt login with base id \'$login_id\'";
                           my $choice=&Menus::pick(\@choices,$banner);
                           chomp $choice;
                           if ($choice ne ']quit[') {
                              if ($choice=~/$su_id/s) {
                                 my $show='';
                                 ($show=$lin)=~s/^.*?\n(.*)$/$1/s;
                                 while (1) {
                                    print $Net::FullAuto::FA_lib::blanklines;
                                    #print $Net::FullAuto::FA_lib::clear,"\n";
                                    print "\n$show ";
                                    my $newpass=<STDIN>;
                                    chomp $newpass;
                                    $ftp_handle->print($answer);
                                    print $Net::FullAuto::FA_lib::MRLOG $show
                                       if $Net::FullAuto::FA_lib::log &&
                                       -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                    $lin='';last;
                                 }
                              } else {
                                 &Net::FullAuto::FA_lib::su_scrub(
                                    $hostlabel,$su_id,$ftm_type);
                                 &Net::FullAuto::FA_lib::passwd_db_update(
                                    $hostlabel,$su_id,'DoNotSU!',
                                    $ftm_type);
print "EIGHT003\n";
                                 $ftp_handle->print("\003");
                                 $ftp_handle->print;
                                 while (my $line=$ftp_handle->get) {
print "TRYING TO USE NEW PASSWORDLINE=$line<==\n";
print $Net::FullAuto::FA_lib::MRLOG "LLINE44=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                    $line=~s/\s*$//s;
                                    last if $line=~/_funkyPrompt_$/s;
                                    last if $line=~/Killed by signal 2\.$/s;
                                 } $lin='';
                                 $ftp_handle->print(
                                    "${Net::FullAuto::FA_lib::sftppath}sftp $login_id\@$host");

                                 ## Wait for password prompt.
                                 ($ignore,$stderr)=
                                    &wait_for_ftr_passwd_prompt(
                                       { _cmd_handle=>$ftp_handle,
                                         _hostlabel=>[ $hostlabel,'' ],
                                         _cmd_type=>$cmd_type });
                                 if ($stderr) {
                                    if ($fm_cnt==$#{$ftr_cnct}) {
                                       return '',$stderr;
                                    } else { next }
                                 }

                                 ## Send password.
print "LIN=$lin<== and FTM_ERRMSG=$ftm_errmsg<==\n";
                                 my $ftm_passwd=
                                    &Net::FullAuto::FA_lib::getpasswd(
                                    $hostlabel,$login_id,
                                    $ms_share,$ftm_errmsg,'','sftp');
                                 $ftp_handle->print($ftm_passwd);

                                 my $showsftp="\n\tLoggingD into "
                                             ."$host via sftp  . . .\n\n";
                                 print $showsftp if
                                    (!$Net::FullAuto::FA_lib::cron
                                    || $Net::FullAuto::FA_lib::debug)
                                    && !Net::FullAuto::FA_lib::quiet;
                                 print $Net::FullAuto::FA_lib::MRLOG $showsftp
                                    if $Net::FullAuto::FA_lib::log &&
                                    -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 last;
                              }
                           } else { 
                              &Net::FullAuto::FA_lib::cleanup();
                           }
                        } elsif ($asked<4) {
print "YESSSSSSS WE HAVE DONE IT FOUR TIMES11\n";<STDIN>;
                        }
                     } else {

                        ## Send password.
print "LIN=$lin<== and FTM_ERRMSG=$ftm_errmsg<==\n";<STDIN>;
                        my $showerr='';
                        ($showerr=$lin)=~s/^.*?\n(.*)$/$1/s;
                        $showerr=~s/^(.*)?\n.*$/$1/s;
                        $retrys++;
                        if ($login_id eq 'root') {
                           $showerr="$showerr\n\n  HINT: sftp may not be "
                                   ."configured to allow \'root\' access."
                                   ."\n    If ssh connectivity & su root is "
                                   ."available, try setting\n    SU_ID =>"
                                   ." \'root\' in "
                                   ."$Net::FullAuto::FA_lib::fa_hosts\n";
                        }
                        my $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                           $hostlabel,$login_id,
                           $ms_share,$showerr,'','sftp','__force__');
print "PASSWORD=$ftm_passwd<== and LOGIN_ID=$login_id\n";
                        $ftp_handle->print($ftm_passwd);

                        my $showsftp=
                           "\n\tLoggingE into $host via sftp  . . .\n\n";
                        print $showsftp if (!$Net::FullAuto::FA_lib::cron
                                           || $Net::FullAuto::FA_lib::debug)
                                           && !Net::FullAuto::FA_lib::quiet;
                        print $Net::FullAuto::FA_lib::MRLOG $showsftp
                           if $Net::FullAuto::FA_lib::log
                           && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $lin='';next;
                     }
                  } elsif ($line=~/_funkyPrompt_$|Connection closed/s) {
                     $ftp_handle->print(
                        "${Net::FullAuto::FA_lib::sftppath}sftp $login_id\@$host");

                     ## Wait for password prompt.
                     ($ignore,$stderr)=
                        &wait_for_ftr_passwd_prompt(
                           { _cmd_handle=>$ftp_handle,
                             _hostlabel=>[ $hostlabel,'' ],
                             _cmd_type=>$cmd_type });
                     if ($stderr) {
                        if ($fm_cnt==$#{$ftr_cnct}) {
                           return '',$stderr;
                        } else { next }
                     }

                     ## Send password.
print "LIN=$lin<== and FTM_ERRMSG=$ftm_errmsg<==\n";<STDIN>;
                     my $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                        $hostlabel,$login_id,
                        $ms_share,$ftm_errmsg,'','sftp');
                     $ftp_handle->print($ftm_passwd);

                     my $showsftp="\n\tLoggingF into "
                                 ."$host via sftp  . . .\n\n";
                     print $showsftp if (!$Net::FullAuto::FA_lib::cron
                                        || $Net::FullAuto::FA_lib::debug)
                                        && !Net::FullAuto::FA_lib::quiet;
                     print $Net::FullAuto::FA_lib::MRLOG $showsftp
                        if $Net::FullAuto::FA_lib::log &&
                        -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     last;
                  }
               } elsif (!$authyes && (-1<index $lin,'The authen') &&
                     $lin=~/\?\s*$/s) {
print "AUTHENHERE!1111\n";
                  my $question=$lin;
                  $question=~s/^.*(The authen.*)$/$1/s;
                  $question=~s/\' can\'t/\'\ncan\'t/s;
                  while (1) {
                     print $Net::FullAuto::FA_lib::blanklines;
                     #print $Net::FullAuto::FA_lib::clear,"\n";
                     print "\n$question ";
                     my $answer=<STDIN>;
                     chomp $answer;
                     if (lc($answer) eq 'yes') {
                        $ftp_handle->print($answer);
                        print $Net::FullAuto::FA_lib::MRLOG $lin
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $authyes=1;$lin='';last;
                     } elsif (lc($answer) eq 'no') {
                        print $Net::FullAuto::FA_lib::MRLOG $lin
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        &Net::FullAuto::FA_lib::cleanup()
                     }
                  }
               } elsif ($lin=~/channel is being closed/s) {
                  $lin=~s/\s*//s;
                  $lin=~s/^(.*)?\n.*$/$1/s;
                  my $warning=$lin;
                  $warning=~tr/\015//d;
                  $warning=~s/^/       /gm;
                  $warning="WARNING! - sftp on Host $host is not configured\n"
                          ."              for user $login_id :\n\n$warning";
                  &Net::FullAuto::FA_lib::handle_error($warning,'__return__','__warn__');
                  die $lin;
               } elsif ($line=~/^530 /m) {
                  $line=~s/^.*(530.*)/$1/s;
                  $line=~s/\s*ftp\>\s*$//s;
                  $line=~s/\n/\n       /s;
                  die "$line\n";
               }
               if ($line=~/[\$\%\>\#\-\:]+ ?$/m) {
                  $lin='';last;
               } elsif ($line=~/[\$\%\>\#\-\:]+ ?$/s) {
                  $lin='';last;
               } elsif ($lin=~/Perm/s && $lin=~/password[: ]+$/si) { last }
            }
            if ($lin=~/Perm/s) {
               $lin=~s/\s*//s;
               $lin=~s/^(.*)?\n.*$/$1/s;
               die "$lin\n";
            } else { last }
         }
         my %ftp=(
            _ftp_handle => $ftp_handle,
            _ftm_type   => $ftm_type,
            _hostname   => $hostname,
            _ip         => $ip,
            _uname      => $uname,
            _luname     => $Net::FullAuto::FA_lib::OS,
            _hostlabel  => [ $hostlabel,
                             $Net::FullAuto::FA_lib::localhost->{_hostlabel}->[0] ],
            _ftp_pid    => $ftp_pid
         );

         # Make sure prompt won't match anything in send data.
         $ftp_handle->prompt("/s*ftp> ?\$/");

         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'binary')
            if $ftm_type ne 'sftp';
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;

         if ($_connect ne 'connect_sftp' && $_connect ne 'connect_ftp') {
            my $ftmtype='';
            if ($ms_hostlabel) {
               ($work_dirs,$ftr_cmd,$cmd_type,$ftmtype,$stderr)
                  =ftr_cmd($ms_hostlabel,$ftp_handle,
                           $new_master,$_connect);
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1','__cleanup__')
                  if $stderr;
               $ftm_type=$ftmtype if $ftmtype;
               if ($su_id) {
                  $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$su_id"}=$ftr_cmd;
               } else {
                  $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$login_id"}=$ftr_cmd;
               }
            } else {
               ($work_dirs,$ftr_cmd,$cmd_type,$ftmtype,$stderr)
                  =ftr_cmd($hostlabel,$ftp_handle,
                           $new_master,$_connect);
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               $ftm_type=$ftmtype if $ftmtype;
            }
         }
#$ftp_handle->print("quote stat");
#while ($line=$ftp_handle->get) {
#   print "FTPLINE2=$line\n";
#   last if $line=~/ftp>\s*/s;
#};<STDIN>;
         if (!$ftm_only && exists ${$work_dirs}{_tmp}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(
                { _ftp_handle=>$ftp_handle,
                  _hostlabel=>[ $hostlabel,'' ],
                  _uname=>$uname,
                  _luname=>$Net::FullAuto::FA_lib::OS,
                  _ftm_type=>$ftm_type },
                "cd \"${$work_dirs}{_tmp}\"");
            if ($stderr) {
               my $die="The FTP Service Cannot Change to "
                      ."the Transfer Directory"
                      ."\n\n       -> $stderr\n";
               &Net::FullAuto::FA_lib::handle_error($die);
            } $Net::FullAuto::FA_lib::ftpcwd{$ftp_handle}{cd}=${$work_dirs}{_tmp};
         }
         if ($Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(
                { _ftp_handle=>$ftp_handle,
                  _hostlabel=>[ $hostlabel,'' ],
                  _uname=>$uname,
                  _luname=>$Net::FullAuto::FA_lib::OS,
                  _ftm_type=>$ftm_type },
                "lcd \"$Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp}\"");
            if ($stderr) {
               my $die="The FTP Service Cannot Change to "
                      ."the Local Transfer Directory"
                      ."\n\n       -> $stderr\n";
               &Net::FullAuto::FA_lib::handle_error($die);
            }
            $Net::FullAuto::FA_lib::ftpcwd{$ftp_handle}{lcd}=
               $Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp};
         }
      };
#$ftp_handle->print("quote stat");
#while ($line=$ftp_handle->get) {
#   print "FTPLOGIN_EVAL=$line\n";
#   last if $line=~/ftp>\s*$/;
#};<STDIN>;
      if ($@) {
         $ftm_errmsg=$@;
print "FTM_LOGIN_ERRMSG=$ftm_errmsg and FTM_PID=$ftp_pid and SHELLPID=$shell_pid<===\n";sleep 2;
         print "sub ftm_login FTM_LOGIN_ERROR=$ftm_errmsg<==\n" if $debug;
         print $Net::FullAuto::FA_lib::MRLOG "sub ftm_login FTM_LOGIN_ERROR=$ftm_errmsg<==\n"
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if (unpack('a4',$ftm_errmsg) eq 'read' ||
               (-1<index $ftm_errmsg,'421 Service') ||
               (-1<index $ftm_errmsg,'Connection closed')) {
            my $host= $hostname ? $hostname : $ip;
print $Net::FullAuto::FA_lib::MRLOG "HOSTTEST6666=$host\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $ftm_errmsg="$@\n\n       While Attempting "
                ."Login to $host\n       -> HostLabel "
                ."\'$hostlabel\'\n\n";
            if (unpack('a4',$ftm_errmsg) eq 'read') {
                 $ftm_errmsg.="       Current Timeout "
                            ."Setting is ->  " . $ftp_handle->timeout
                            ." seconds.\n\n";
            }
            if ($retrys<2 && unpack('a4',$ftm_errmsg) eq 'read') {
               $retrys++;
               warn "$ftm_errmsg      $!";
               if (defined fileno $ftp_handle) {
                  $ftp_handle->print; # if defined fileno $ftp_handle;
                  while (my $line=$ftp_handle->get) {
print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::ftm_login() LOOKING FOR PROMPT=$line\n and ERROR=$@\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "File_Transfer::ftm_login() LOOKING FOR PROMPT=$line\n and ERROR=$@\n";
                     last if $line=~/logout|Connection.*closed/s;
                  }
               }
               FTH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                  foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                     foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}}) {
                        if ($ftp_handle eq ${$Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}}[0]) {
                           delete
                              $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                           last FTH;
                        }
                     }
                  }
               }
               $ftp_handle->close;
               if ($hostlabel eq $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]
                     && 1<$#FA_lib::DeploySMB_Proxy) {
                  shift @FA_lib::DeploySMB_Proxy;
    # DO MORE WORK ON SWITCHING DEPLOYPROXYS
    $ftm_errmsg.="COULD HAVE WORKED WITH NEW CODE SWITCHING DPRX.";
                  &Net::FullAuto::FA_lib::handle_error($ftm_errmsg);
               } elsif ($ftm_errmsg=~/421 Service/s ||
                     $ftm_errmsg=~/Connection closed/s) {
                  &Net::FullAuto::FA_lib::handle_error("$ftm_errmsg$s_err");
               }
               next;
            } else {
print $Net::FullAuto::FA_lib::MRLOG
   "File_Transfer::ftm_login() EXITING FROM TIMEOUT=$ftm_errmsg$s_err\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               &Net::FullAuto::FA_lib::handle_error("$ftm_errmsg$s_err");
            }
         }
         $die_login_id=($su_login)?$su_id:$login_id;
         if ($retrys<2) {
            if ($ftm_errmsg=~/530 |Perm|(channel is being closed)/) {
               my $shipht=$1;
               shift @connect_method if $shipht;
               if ($su_login) {
                  &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$su_id);
               } else {
                  &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$login_id);
               }
               $retrys++;
               $retrys=0 if $shipht;
print "NINE003\n";
               $ftp_handle->print("\003");
               $ftp_handle->get;
               $ftp_handle->print('bye');
               while (my $line=$ftp_handle->get) {
                  last if $line=~/_funkyPrompt_|221 Goodbye/s;
               }
               ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9)
                  if &Net::FullAuto::FA_lib::testpid($shell_pid)
                  && $shell_pid ne $localhost->{_sh_pid};
               ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($ftp_pid,9)
                  if &Net::FullAuto::FA_lib::testpid($ftp_pid)
                  && $ftp_pid ne $localhost{_cmd_pid};
               $ftp_handle->close;
               if (-1<$#connect_method && ($shipht || !$Net::FullAuto::FA_lib::cron)) {
                  next;
               }
            } elsif (unpack('a10',$ftm_errmsg) eq 'System err' &&
                 $ftm_errmsg=~/unknown user name/s) {
               if ($su_login) {
                  &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$su_id);
               } else {
                  &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$login_id);
               } $retrys++;next if !$Net::FullAuto::FA_lib::cron;
            }
         } else { shift @connect_method;next if $#connect_method }
         if (unpack('a10',$ftm_errmsg) eq 'The System') {
            $die="$ftm_errmsg$s_err";
         } else {
            my $f_t=$ftm_type;$f_t=~s/^(.)/uc($1)/e;
            $die="The Host $host Returned\n              the "
                ."Following Unrecoverable Error Condition\,\n"
                ."              Rejecting the $f_t Login Attempt"
                ." of the ID\n              -> $die_login_id "
                ."\n\n       at ".(caller(0))[1]." "
                ."line ".(caller(2))[2]." :\n\n       "
                ."$ftm_errmsg$s_err"
         } last;
      } else { last }
   } return $ftp_handle,$ftp_pid,$work_dirs,$ftr_cmd,
            $ftm_type,$cmd_type,$smb,'','',$die;

}

sub wait_for_ftr_passwd_prompt
{

   my @topcaller=caller;
   print "File_Transfer::wait_for_ftr_passwd_prompt() CALLER="
      ,(join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::wait_for_ftr_passwd_prompt() CALLER="
      ,(join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $filehandle=$_[0];
   ## Wait for password prompt.
   my $lin='';my $authyes=0;my $gotpass=0;my $warning='';
   my $eval_stdout='';my $eval_stderr='';$@='';
   my $connect_err=0;my $count=0;
   $filehandle->{_cmd_handle}->autoflush(1);
   eval {
      while (1) {
         PW: while (my $line=$filehandle->{_cmd_handle}->get(Timeout=>5)) {
            print "wait_for_ftr_passwd_prompt() OUTPUT_LINE=".
                  "$line<==\n" if $debug;
            print $Net::FullAuto::FA_lib::MRLOG "wait_for_ftr_passwd_prompt() ".
                  "OUTPUT_LINE=$line<==\n" if $Net::FullAuto::FA_lib::log &&
                  -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $lin.=$line;
            if (-1<index $line,'Permission denied') {
               die 'Permission denied';
            } elsif ($warning || (-1<index $line,'@@@@@@@@@@')) {
               $warning.=$line;
               $count++ if $line=~/^\s*$/s;
               if ($warning=~/Connection closed/s || $count==10) {
                  $warning=~s/^.*?(\@+.*)$/$1/s;
                  $warning=~s/_funkyPrompt_//s;
                  $warning=~s/^/       /gm;
                  $warning=~s/\s*$//s;
                  die "\n".$warning;
               } $filehandle->{_cmd_handle}->print;
               next;
            } elsif (-1<index $lin,'Address already in use') {
               die 'Connection closed';
            } elsif (7<length $line && unpack('a8',$line) eq 'Insecure') {
               $line=~s/^Insecure/INSECURE/s;
               $eval_stdout='';$eval_stderr=$line;
               die $line;
            } elsif (!$authyes && (-1<index $lin,'The authen') &&
                  $lin=~/\?\s*$/s) {
               my $question=$lin;
               $question=~s/^.*(The authen.*)$/$1/s;
               $question=~s/\' can\'t/\'\ncan\'t/s;
               while (1) {
                  print $Net::FullAuto::FA_lib::blanklines;
                  print "\n$question ";
                  my $answer=<STDIN>;
                  chomp $answer;
                  if (lc($answer) eq 'yes') {
                     $filehandle->{_cmd_handle}->print($answer);
                     print $Net::FullAuto::FA_lib::MRLOG $lin
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $authyes=1;$lin='';last;
                  } elsif (lc($answer) eq 'no') {
                     print $Net::FullAuto::FA_lib::MRLOG $lin
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     &Net::FullAuto::FA_lib::cleanup()
                  }
               }
            } elsif ($lin=~/password[: ]+$/si) {
print $Net::FullAuto::FA_lib::MRLOG "wait_for_ftr_passwd_prompt() GETGOTPASS!!=$lin<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               $gotpass=1;last PW;
            } elsif ((-1<index($lin,'530 '))
                  || (-1<index($lin,'421 '))
                  || (-1<index($lin,'Connection refused'))
                  || (-1<index($lin,'Connection closed'))) {
               chomp($lin=~tr/\0-\11\13-\31\33-\37\177-\377//d);
               $lin=~/(^530[ ].*$)|(^421[ ].*$)
                      |(^Connection[ ]closed.*$)
                      |(^Connection[ ]refused.*$)/xm;
               $lin=$1 if $1;$lin=$2 if $2;
               $lin=$3 if $3;$lin=$4 if $4;
               if ($lin eq 'Connection closed') {
                  die 'Connection closed';
               } else {
                  $eval_stdout='';$eval_stderr=$lin;
                  die $eval_stderr;
               }
            }
            if ($lin=~/Warning/s) {
               $lin=~s/^.*(Warning.*)$/$1/s;
               print "\n$lin";sleep 1;
               print $Net::FullAuto::FA_lib::MRLOG $lin
                  if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            }
         } last if $gotpass;
      }
   };
   if ($@) {
      if (wantarray) {
         my $error=$@;
         if ($@=~/Permission denied/) {
            return ('','read timed-out:do_slave')
         } elsif ($@!~/Connection closed/) {
            my $err=$@;
            eval {
               $filehandle->{_cmd_handle}->print;
               $filehandle->{_cmd_handle}->print("\004");
               my $cnt=0;
               while (my $line=$filehandle->{_cmd_handle}->get) {
                  last if $line=~/_funkyPrompt_/s;
                  $filehandle->{_cmd_handle}->print;
                  last if $cnt++==10;
               }
               if ($cnt==11 and (-1<index $err,'read timed-out')
                     && !$slave) {
                  $error='read timed-out:do_slave';
               }
            };
            if ($error eq 'read timed-out:do_slave') {
               return ('','read timed-out:do_slave')
            }
         } return '', $error."\n       Connection Closed";
      } else { &Net::FullAuto::FA_lib::handle_error($@) }
   } elsif (wantarray) {
      return $eval_stdout,$eval_stderr;
   } elsif ($eval_stderr) {
      &Net::FullAuto::FA_lib::handle_error($@);
   } else {
      return $eval_stdout;
   }
}

sub connect_share
{
   my @topcaller=caller;
   print "File_Transfer::connect_share() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::connect_share() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my (@outlines,@errlines)=();
   my $cmd_handle=$_[0];
   my $hostlabel=$_[1];
   my $_connect=$_[2]||'';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$cdtimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my $host=($use eq 'ip')?$ip:$hostname;    
   my $smb_type='';
#print "THISSS=net view \\\\\\\\$host | perl -pe 's/^/stdout: /' 2>&1";
   my @output=$cmd_handle->cmd(
      "net view \\\\\\\\$host | perl -pe 's/^/stdout: /' 2>&1");
#print "OUTPUT=@output and CMDHANDLE=$cmd_handle\n";
   for (@output) {
      push @{ s/stdout: // ? \@outlines : \@errlines }, $_;
   } my $stdout=join '', @outlines;
   my $stderr=join '',@errlines;@output=();
   if ($stdout) {
      if ($stdout=~/^Samba/m) {
         $smb_type='Samba';
      } else {
         $smb_type='cygwin';
      }
      my $ms_cnct='net use \\\\'.$host.'\\'.$ms_share;
      $login_id=$su_id if $su_id;
      my $dom='';
      if ($ms_domain) {
         $dom=$ms_domain.'\\';
      } else {
         if (($host=~tr/.//)==2) {
            $dom=substr($host,0,(index $host,'.')) . '\\';
         } else {
            $dom=$host.'//';
         }
      }
      if ($su_id) {
         $cnct_passwd=&Net::FullAuto::FA_lib::getpasswd(
             $hostlabel,$su_id,$ms_share,
             '','__su__');
      } else {
         $cnct_passwd=&Net::FullAuto::FA_lib::getpasswd(
             $hostlabel,$login_id,$ms_share,'');
      }
      while (1) {
         my $ms_cmd="$ms_cnct $cnct_passwd /USER:$dom"
                    .$login_id;
         ($output,$stderr)=Rem_Command::cmd(
            { _cmd_handle=>$cmd_handle,
              _hostlabel=>[ $hostlabel,'' ] },$ms_cmd);
         if (!$stderr ||
               (-1<index $stderr,'credentials supplied conflict')) {
            return "\\\\$host\\$ms_share\\",$smb_type,'';
         } elsif (-1<index $stderr,'Logon failure') {
            if ($su_id) {
               $cnct_passwd=&Net::FullAuto::FA_lib::getpasswd(
                   $hostlabel,$su_id,$ms_share,
                   $stderr,'__force__','__su__');
            } else {
               $cnct_passwd=&Net::FullAuto::FA_lib::getpasswd(
                   $hostlabel,$login_id,$ms_share,
                   $stderr,'__force__');
            }
         } else {
            $stderr="From Command :\n\n       $ms_cmd\n\n       "
                   ."$stderr\n       $!";
            return '','',$stderr;
         }
      }
   } else {
      $stderr=~s/^/       /mg;
      $stderr=~s/\s*//;
      $stderr="From Command :\n\n       "
             ."net view \\\\\\\\$host | perl -pe 's/^/stdout: /' 2>&1"
             ."\n\n$stderr\n       $!";
      return '','',$stderr;
   }

}

sub cwd
{
   my @topcaller=caller;
   print "File_Transfer::cwd() CALLER=",(join ' ',@topcaller),"\n";
      #if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "File_Transfer::cwd() CALLER=",
      (join ' ',@topcaller),"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my $target_dir=$_[1];
   $target_dir||='';
   $target_dir=~s/[\/\\]*$//
      if $target_dir ne '/' && $target_dir ne '\\';
   my $len_tdir=length $target_dir;
   my $output='';my $stderr='';
   if (unpack('a1',$target_dir) eq '.') {
      if ($target_dir eq '.') {
         if (wantarray) {
            return '\'.\' is Current Directory','';
         } else { return '\'.\' is Current Directory' }
      } elsif (1<$len_tdir &&
              (unpack('a2',$target_dir) eq './')
              || unpack('a2',$target_dir) eq '.\\') {
         $target_dir=unpack('x2,a*',$target_dir);
      } 
   }
#print "TARGET_DIR=$target_dir\n";
#print "SELFSTUFF=$self->{_work_dirs}->{_cwd}\n";
   my $hostlabel=$self->{_hostlabel}->[0]||$self->{_hostlabel}->[1];
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$cwtimeout,$transfer_dir,$ms_chain,
       $tn_chain,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$self->{_connect});
   my $host=($use eq 'ip')?$ip:$hostname;
   if (!$target_dir) {
      my @caller=caller;
      my $die="The First Argument to cwd is being "
             ."read by\n       $0 as a null or ''.  "
             ."Hint: (Perhaps a\n       variable being "
             ."used to pass the destination-\n       "
             ."directory-name is misspelled) in file\n"
             ."       -> $caller[1]  line $caller[2]\n\n";
      if (wantarray) {
        return '',$die;
      } else { &Net::FullAuto::FA_lib::handle_error($die) }
   }
   if ((exists $self->{_work_dirs}->{_cwd} &&
         $target_dir eq $self->{_work_dirs}->{_cwd}) ||
         ($self->{_work_dirs}->{_cwd_mswin} &&
         $target_dir eq $self->{_work_dirs}->{_cwd_mswin})) {
      if (wantarray) {
         return 'CWD command successful.','';
      } else { return 'CWD command successful.' }
   }
   eval {
      if (((exists $self->{_smb}) ||
             $self->{_uname} eq 'cygwin') &&
             ($target_dir=~/^\\\\|^([^~.\/\\][^:])/
             && (exists $self->{_work_dirs}->{_cwd_mswin} &&
             1<length $self->{_work_dirs}->{_cwd_mswin} &&
             unpack('a2',$self->{_work_dirs}->{_cwd_mswin})
             eq '\\\\') && !(exists $self->{_cygdrive} &&
             $target_dir=~/^$self->{_cygdrive}/))) {
         my $td=$1;
         if ($td) {
            if ($td=~/^[\/\\][^:]/) {
               if ($ms_share) {
                  if (($tar_dir=$target_dir)=~s/\//\\/g) {
                     $tar_dir=~s/\\/\\\\/g;
                  }
                  $tar_dir="\\\\$host\\$ms_share$tar_dir";
               } else {
                  my $die='Cannot Determine Root -or- Drive -or- Share'
                         ."\n       for Directory $target_dir";
                  if (wantarray) {
                     return '',$die;
                  } else { &Net::FullAuto::FA_lib::handle_error($die) }
               }
            } elsif (exists $self->{_work_dirs}->{_cwd_mswin} &&
                  1<length $self->{_work_dirs}->{_cwd_mswin} &&
                  unpack('a2',$self->{_work_dirs}->{_cwd_mswin})
                  eq '\\\\') {
               if (($tar_dir=$target_dir)=~s/\//\\/g) {
                  $tar_dir=~s/\\/\\\\/g;
               }
               $tar_dir=$self->{_work_dirs}->{_cwd_mswin}.$tar_dir;
            } else {
               my $die='Cannot Determine Root -or- Drive -or- Share'
                      ."\n       for Directory $target_dir";
               if (wantarray) {
                  return '',$die;
               } else { &Net::FullAuto::FA_lib::handle_error($die) }
            }
         } else {
            $tar_dir=$target_dir;
         }
         my @output=();my $cnt=0;
         while (1) {
            ($output,$stderr)=$self->{_cmd_handle}->
                  cmd("cmd /c dir /-C \'$tar_dir\'");
            if (!$stderr && substr($output,-12,-2) ne 'bytes free') {
               $output='';next unless $cnt++;
               my $die="Attempt to retrieve output from the command:\n"
                      ."\n       cmd /c dir /-C \'$tar_dir\'\n"
                      ."\n       run on the host $hostlabel FAILED";
               &Net::FullAuto::FA_lib::handle_error($die);
            } else { last }
         }
         my $outdir='';
         ($outdir=$output)=~s/^.*Directory of ([^\n]*).*$/$1/s;
         $outdir=~tr/\0-\37\177-\377//d; 
         if ($outdir eq $tar_dir) {
            $self->{_work_dirs}->{_pre_mswin}=
               $self->{_work_dirs}->{_cwd_mswin};
            $self->{_work_dirs}->{_cwd_mswin}=$target_dir.'\\';
            $output="CWD command successful";
         } else {
            $output=~s/^.*Directory of [^\n]*(.*)$/$1/s;
            my $leaf=substr($tar_dir,(rindex $tar_dir,"\\")+1);
            foreach my $line (split /\n/, $output) {
               $line=~tr/\0-\37\177-\377//d;
               if ($line=~/$leaf$/ and $line!~/\<DIR\>/) {
                  $die="Cannot cwd to the FILE:"
                      ."\n\n       --> $tar_dir\n\n"
                      ."       Because First cwd() Argument"
                      ."\n       Must be a Directory.\n";
                  if (wantarray) { return '',$die }
                  else { &Net::FullAuto::FA_lib::handle_error($die) }
               }
            }
            $die="Cannot cwd to the Directory:"
                . "\n\n       --> $tar_dir\n\n"
                . "       The Directory DOES NOT EXIST!\n";
            if (wantarray) { return '',$die }
            else { &Net::FullAuto::FA_lib::handle_error($die) }
         }
      } elsif ($target_dir=~/^([^~.\/\\][^:])/) {
         $target_dir=~s/\\/\//g;
         $target_dir=$self->{_work_dirs}->{_cwd}
                    .$target_dir.'/';
         ($output,$stderr)=$self->{_cmd_handle}->
               cmd("cd $target_dir");
         my $phost=$hostlabel;
         if ($self->{_cmd_type} eq 'ms_proxy') {
            $phost=$Net::FullAuto::FA_lib::DeployMS_Proxy[0];
         } elsif ($self->{_cmd_type} eq 'tn_proxy') {
            $phost=$Net::FullAuto::FA_lib::DeployTN_Proxy[0];
         }
         if ($stderr) {
            my $die="The Transfer Directory on Proxy Host "
                   ."- $phost :"
                   ."\n\n              --> $target_dir\n\n"
                   ."       DOES NOT EXIST!: $!";
            if (wantarray) { return '',$die }
            else { &Net::FullAuto::FA_lib::handle_error($die,'-12') }
         }
         $self->{_work_dirs}->{_pre_mswin}=
            $self->{_work_dirs}->{_cwd_mswin};
         $self->{_work_dirs}->{_cwd_mswin}=$target_dir.'\\';
      } elsif ($self->{_uname} eq 'cygwin' &&
            $target_dir=~/^[A-Za-z]:/) {
         my ($drive,$path)=unpack('a1 x1 a*',$target_dir);
         $path=~tr/\\/\//;
         my $tar_dir=$self->{_cygdrive}.'/'.lc($drive).$path;
         ($output,$stderr)=$self->cmd("cd $tar_dir");
         if ($stderr) {
            if (wantarray) {
               return $output,$stderr;
            } else {
               &Net::FullAuto::FA_lib::handle_error($stderr);
            }
         }
         $self->{_work_dirs}->{_pre}=$self->{_work_dirs}->{_cwd};
         $self->{_work_dirs}->{_pre_mswin}=
            $self->{_work_dirs}->{_cwd_mswin};
         $self->{_work_dirs}->{_cwd}=$tar_dir.'/';
         $self->{_work_dirs}->{_cwd_mswin}=$target_dir.'\\';
      } else {
         if (1<$len_tdir && unpack('a2',$target_dir) eq '..') {
            if ($self->{_ftm_type}=~/s*ftp/) {
               ($output,$stderr)=&ftpcmd(
                   { _ftp_handle=>$ftp_handle },
                   'cd \'..\'',$hostlabel);
               if ($stderr) {
                  if (wantarray) { return '',$stderr }
                  else { &Net::FullAuto::FA_lib::handle_error($stderr,'-3') }
               }
            }
print "ARGGGG=$arg\n";
            ($output,$stderr)=$self->cmd('cd \'..\'');
            if ($stderr) {
               if (wantarray) { return '',$stderr }
               else { &Net::FullAuto::FA_lib::handle_error($stderr,'-3') }
            }
         } elsif (unpack('a1',$target_dir) ne '/' &&
               unpack('a1',$target_dir) ne '\\' &&
               unpack('x1 a1',$target_dir) ne ':') {
eval{
print "WHAT IS REF=",ref $self->{_cmd_handle}," and $self->{_cmd_handle}\n";
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS REF=",ref $self->{_cmd_handle},"\n"
      if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "WHAT IS EXISTS=",exists $self->{_cmd_handle}->{_work_dirs},"\n";
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS EXISTS=",exists $self->{_cmd_handle}->{_work_dirs},"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "WHAT IS REFNOW=",ref $self->{_cmd_handle}->{_work_dirs},"\n";
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS REFNOW=",ref $self->{_cmd_handle}->{_work_dirs},"\n" if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
};
            if (exists $self->{_work_dirs}->{_cwd}) {
               $target_dir=$self->{_work_dirs}->{_cwd} 
                   ="$self->{_work_dirs}->{_cwd}/$target_dir/";
            } else {
               $target_dir=$self->{_work_dirs}->{_cwd_mswin}
                   ="$self->{_work_dirs}->{_cwd_mswin}\\$target_dir\\";
            }
         }
         if (exists $self->{_smb} && $ms_share &&
               $target_dir=~/^[\/\\][^\/\\]/ &&
               $target_dir!~/$self->{_cygdrive_regex}/) {
            my $tdir=$target_dir;
            $tdir=~s/^[\/|\\]+//;
            $tdir=~tr/\//\\/;
            $tdir="\\\\$host\\$ms_share\\$tdir";
            my $t_dir=$tdir;
            $t_dir=~s/\\/\\\\/g;
            if (&Net::FullAuto::FA_lib::test_dir($self->{_cmd_handle},$t_dir)) {
               if (exists $self->{_work_dirs}->{_pre_mswin}) {
                  $self->{_work_dirs}->{_pre_mswin}
                     =$self->{_work_dirs}->{_cwd_mswin};
                  $tdir=~s/[\\]*$//;
                  $self->{_work_dirs}->{_cwd_mswin}=$tdir.'\\';
               }
               $output='CWD command successful';
               return $output,'';
            } else {
               if (wantarray) {
                  return '',"Cannot locate $target_dir";
               } else {
                  &Net::FullAuto::FA_lib::handle_error(
                     "Cannot locate $target_dir");
               }
            }
         } elsif ((exists $self->{_ftm_type}) &&
               $self->{_ftm_type}=~/s*ftp/) {
my $pwd='';
($pwd,$stderr)=&Rem_Command::ftpcmd($self,'pwd');
&Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
(-1==index $stderr,'command success');
            ($output,$stderr)=
               &Rem_Command::ftpcmd($self,"cd \"$target_dir\"");
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-6') }
            } $Net::FullAuto::FA_lib::ftpcwd{$self->{_ftp_handle}}{cd}
                 =$target_dir;
         } 
         ($output,$stderr)=$self->cmd("cd \'$target_dir\'");
         if ($stderr) {
            if (wantarray) {
               return '',$stderr;
            } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
         } else {
            $self->{_work_dirs}->{_pre}=$self->{_work_dirs}->{_cwd};
            if (exists $self->{_work_dirs}->{_pre_mswin}) {
               $self->{_work_dirs}->{_pre_mswin}
                  =$self->{_work_dirs}->{_cwd_mswin};
               my $tdir='';
               ($tdir=$target_dir)=~s/$self->{_cygdrive_regex}//;
               $tdir=~s/^(.)/$1:/;
               $tdir=~tr/\//\\/;
               $tdir=~s/\\/\\\\/g;
               $self->{_work_dirs}->{_cwd_mswin}=$tdir.'\\';
            }
            $self->{_work_dirs}->{_cwd}=$target_dir.'/';
            $output='CWD command successful'
         }
      }
   };
   if ($@) {
      chomp($@);
      if (-1<index $@,"Transfer Directory") {
         if (wantarray) {
            return '', $@;
         } else { &Net::FullAuto::FA_lib::handle_error($@) }
      } else {
         my $die=$@;
         $die=~s/\.$//s;
         $die.=" on Host $hostlabel\n";
         my $cnt='';my $hnames='';
         foreach my $host (@{$self->{_hostlabel}}) {
            next if !$cnt++;
            next if !$host;
            $hnames.="\'$host\', ";
         } substr($hnames,-2)='';
         $die.="       (Host also has Labels - $hnames)\n"
            if $hnames;
         if (wantarray) {
            return '', "$die";
         } else { &Net::FullAuto::FA_lib::handle_error($die) }
      }
   } elsif (wantarray) {
      return $output,'';
   } else {
      return $output;
   } #elsif ($self->{_hostlabel}->[0] ne "__Master_${$}__") {
     # eval {
     #    $self->{_ftp_handle}->cmd("cd \"$arg\"");
     #    $Net::FullAuto::FA_lib::ftpcwd{$self->{_ftp_handle}}{cd}=$arg;
     # };
     # if ($@) {
     #    if (wantarray) { return '',$@ }
     #    else { &Net::FullAuto::FA_lib::handle_error($@) }
     # } else { return '\'.\' is Current Directory' }
   #} else {
   #   if ($@) {
   #      if (wantarray) { return '',$@ }
   #      else { &Net::FullAuto::FA_lib::handle_error($@) }
   #   } else { return '\'.\' is Current Directory' }
   #}

}

sub pwd
{
   my ($self) = @_;
   if ($self->{_work_dirs}->{_cwd}) {
      return $self->{_work_dirs}->{_cwd};
   } else {
      my $pwd=join '',$self->{"_$self->{_ftm_type}_handle"}->cmd('pwd');
      chomp $pwd;return $pwd;
   }

}

sub tmp
{
   my $self=$_[0];
   my $path=$_[1];
   $path||='';
   my $token=$_[2];
   $token||='';
   if ($token=~/[Ww_1]/ && $token!~/[UuXx]/) { $token=1 } else { $token=0 }
   if ($path) {
      if ($path=~/^[\/|\\]|[a-zA-Z]:/) {
         &Net::FullAuto::FA_lib::handle_error("Path: $path\n       Must NOT be Fully "
            ."Qualified\n       "
            ."(Hint: Must not begin with Drive Letter, or UNC, or '/')"
            ."\n       Example:  path/to/tmp  -Not-  b:\\path\\to\\tmp"
            ."\n                              or  \\\\computer\\share\\path"
            ."\n                              or  /path/to/tmp");
      }
      $path=~tr/\\/\//;
   }

   my $tdir='tmp'.$self->{_cmd_pid}.'_'
           .$Net::FullAuto::FA_lib::invoked[0].'_'.$Net::FullAuto::FA_lib::increment++;
   my $return_path='';
   if ($token) {
      $path=~tr/\\/\//;
      $path=~s/\//\\/g;
      $path=~s/\\/\\\\/g;
      $Net::FullAuto::FA_lib::tmp_files_dirs{$self->{_cmd_handle}}=[
         $self->{_work_dirs}->{_tmp},$tdir ];
      ($output,$stderr)=$self->cmd('mkdir -p '.
         $self->{_work_dirs}->{_tmp}.'/'.$tdir);
      &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
      $return_path=$self->{_work_dirs}->{_tmp_mswin}
                  .$tdir.'\\'.$path;
   } else {
      $path=~tr/\\/\//;
      $Net::FullAuto::FA_lib::tmp_files_dirs{$self->{_cmd_handle}}=[
         $self->{_work_dirs}->{_tmp},$tdir ];
      ($output,$stderr)=$self->cmd('mkdir -p '.
         $self->{_work_dirs}->{_tmp}.'/'.$tdir);
      &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
      $return_path=$self->{_work_dirs}->{_tmp}.$tdir.'/'.$path;
   } return $return_path;
}

sub mirror
{

   my ($baseFH, %args) = @_;
   my $dest_output='';my $base_output='';
   my $num_of_levels='';my $mirrormap='';my $trantar='';
   my $trandir='';my $chk_id='';my $local_transfer_dir='';
   my $output='';my $stderr='';
   my $destFH='';my $bprxFH='';my $dprxFH='';
   my $sub=(caller(1))[3];$sub=~s/\s*FA_lib::/&/;
   my $caller='';my $cline='';my $mirror_output='';
   my $debug_info='';$deploy_info='';
   my $mirror_debug='';
   ($caller,$cline)=(caller)[1,2];
   if (ref $args{DestHost} eq 'ARRAY') {
      @dhostlabels=@{$args{DestHost}};
   } elsif (4<length $args{DestHost} && unpack('a5',$args{DestHost})
         eq 'ARRAY') {
      &Net::FullAuto::FA_lib::handle_error(
         "quotes improperly surround $dest_hostlabel arg");
   } else { @dhostlabels=();push @dhostlabels, $args{DestHost} }
   foreach my $dest_hlabel (@dhostlabels) {
      unless (exists $Net::FullAuto::FA_lib::Hosts{"$dest_hlabel"}) {
         my $die="The \"DestHost =>\" Argument to &mirror()"
                ."\n              ->  \"$dest_hlabel\" Called"
                ." from the User Defined Subroutine\n        "
                ."      ->  $sub   is NOT\n              a Valid"
                ." Host Label in the \"subs\" Subroutine File"
                ."\n              ->  $caller line $cline.\n";
         if (wantarray) {
            return '',$die;
         } else { &Net::FullAuto::FA_lib::handle_error($die) }
      }
   }
   my $bhostlabel=$baseFH->{_hostlabel}->[0];
   my $dhostlabel=$dhostlabels[0];
   my $base_fdr=$args{BaseFileOrDir};
   $base_fdr||='';
   if (unpack('a1',$base_fdr) eq '~') {
      ($stdout,$stderr)=$baseFH->cmd('echo ~');
      $base_fdr=~s/~/$stdout/s;
   }
   my $dest_fdr=$args{DestDir};
   $dest_fdr||='';
   my ($bip,$bhostname,$buse,$bms_share,$bms_domain,
       $bcmd_cnct,$bftr_cnct,$blogin_id,$bsu_id,$bchmod,
       $bowner,$bgroup,$btimeout,$btransfer_dir,$brcm_chain,
       $brcm_map,$buname,$bping,$bfreemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($bhostlabel,
          $baseFH->{_connect});
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $btimeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (!$btimeout) {
      $btimeout=$timeout if !$btimeout;
   }
   my $bhost=($buse eq 'ip')?$bip:$bhostname;
   $bms_share||='';$btransfer_dir||='';
   my ($dip,$dhostname,$duse,$dms_share,$dms_domain,
       $dcmd_cnct,$dftr_cnct,$dlogin_id,$dsu_id,$dchmod,
       $downer,$dgroup,$dtimeout,$dtransfer_dir,$drcm_chain,
       $drcm_map,$duname,$dping,$dfreemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($dhostlabel,
          $destFH->{_connect});
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $dtimeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (!$dtimeout) {
      $dtimeout=$timeout if !$dtimeout;
   } my $do_dest_tmp_cwd=1;
   if ($baseFH->{_uname} ne 'cygwin' &&
         $baseFH->{_hostlabel}->[0] ne "__Master_${$}__") {
      ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,'lcd .');
      if ($stderr) {
         if (wantarray) {
            return '',$stderr;
         } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
      } 
      $local_transfer_dir=unpack('x20 a*',$output);
      $local_transfer_dir.='/';
      ($output,$stderr)=$baseFH->cwd($base_fdr) if $base_fdr;
      if ($stderr && (-1==index $stderr,'command success')) {
         if (wantarray) {
            return '',$stderr;
         } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
      } else { $stderr='' }
      $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{cd}=$base_fdr;
   }
   if ((exists $baseFH->{_smb})
         || $baseFH->{_uname} eq 'cygwin') {
      my $test_chr1='';my $test_chr2='';my $dir='';
      if ($base_fdr) {
         $test_chr1=unpack('a1',$base_fdr);
         if (1<length $base_fdr) {
            $test_chr2=unpack('a2',$base_fdr);
         }
         if ($test_chr2) {
            if (($test_chr1 eq '/' && $test_chr2 ne '//')
                  || ($test_chr1 eq '\\' &&
                  $test_chr2 ne '\\\\')) {
               $dir=$base_fdr;
               if ($base_fdr=~/$baseFH->{_cygdrive_regex}/) {
                  $dir=~s/$baseFH->{_cygdrive_regex}//;
                  $dir=~s/^(.)/$1:/;
                  $dir=~tr/\//\\/;
                  ($output,$stderr)=$baseFH->cwd($base_fdr);
                  if ($stderr && (-1==index $stderr,'command success')) {
                     if (wantarray) {
                        return '',$stderr;
                     } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
                  } else { $stderr='' }
                  $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{cd}=$base_fdr;
                  $do_dest_tmp_cwd=0;
               } elsif ($bms_share) {
                  $dir="\\\\$bhost\\$bms_share";
                  $base_fdr=~tr/\//\\/;
                  $dir.=$base_fdr;
               } else {
                  my $ignore='';
                  ($ignore,$dir)
                     =&File_Transfer::get_drive(
                     $base_fdr,'Base Folder',
                     $baseFH,$bhostlabel);
                  ($output,$stderr)=$baseFH->cwd($base_fdr);
                  if ($stderr && (-1==index $stderr,'command success')) {
                     if (wantarray) {
                        return '',$stderr;
                     } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
                  } else { $stderr='' }
                  $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{cd}=$base_fdr;
                  $do_dest_tmp_cwd=0;
               }
            } elsif ($test_chr2 eq '//' ||
                  $test_chr2 eq '\\\\') {
               $dir=$base_fdr;
            } elsif ($test_chr2=~/^[a-zA-Z]:$/) {
               $dir=$base_fdr;
               ($output,$stderr)=$baseFH->cwd($base_fdr);
               if ($stderr && (-1==index $stderr,'command success')) {
                  if (wantarray) {
                     return '',$stderr;
                  } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
               } else { $stderr='' }
               $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{cd}=$base_fdr;
               $do_dest_tmp_cwd=0;
            } elsif ($test_chr1!~/\W/) {
               $dir=$baseFH->{_work_dirs}->{_cwd}.$base_fdr;
               ($output,$stderr)=$baseFH->cwd($dir);
               if ($stderr && (-1==index $stderr,'command success')) {
                  if (wantarray) {
                     return '',$stderr;
                  } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-4') }
               } else { $stderr='' }
               $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{cd}=$dir;
               $do_dest_tmp_cwd=0;
            } elsif ($test_chr1 ne '~') {
               &Net::FullAuto::FA_lib::handle_error(
                  "Base Directory - $base_fdr CANNOT Be Located");
            }
         } elsif ($test_chr1 eq '/' || $test_chr1 eq '\\') {
            if ($baseFH->{_work_dirs}->{_cwd}=~
                  /$baseFH->{_cygdrive_regex}/) {
               ($dir=$baseFH->{_work_dirs}->{_cwd})=~
                  s/$baseFH->{_cygdrive_regex}//;
               $dir=s/^(.)/$1:/;
               $dir=~tr/\//\\/;
            } else {
               $dir=$baseFH->{_work_dirs}->{_cwd};
            }
         } elsif ($test_chr1=~/^[a-zA-Z]$/) {
            $dir=$test_chr1.':/';
         } elsif ($test_chr1 ne '~') {
            &Net::FullAuto::FA_lib::handle_error(
               "Base Directory - $base_fdr CANNOT Be Located");
         } my $cnt=0;
      } else {
         $dir=$baseFH->{_work_dirs}->{_cwd};
      } my $cnt=0;
      if (!exists $base_shortcut_info{$baseFH} ||
            $base_shortcut_info{$baseFH} ne $dir ||
            !(exists $args{ReUseAnalysis} && $args{ReUseAnalysis})) {
         while (1) {
            ($base_output,$stderr)=$baseFH->cmd(
               "cmd /c dir /s /-C /A- \'$dir\'");
               #,'','__debug__','__live__');
print $Net::FullAuto::FA_lib::MRLOG "WE ARE BACK ALREADY FROM DIR CMD and STDERR=$stderr\n";
            $base_shortcut_info{$baseFH}=$dir;
            if (exists $baseFH->{_unaltered_basehash} &&
                  $baseFH->{_unaltered_basehash}) { # line 7058
               foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
                  my $elems=$#{${$baseFH->{_unaltered_basehash}}{$key}}+1;
                  while (-1<--$elems) {
                     if (ref ${$baseFH->{_unaltered_basehash}}{$key}[$elems]
                           ne 'HASH') {
                        undef ${$baseFH->{_unaltered_basehash}}{$key}[$elems];
                     } else {
                        foreach my $key (
                              keys %{${$baseFH->{_unaltered_basehash}}
                              {$key}[$elems]}) {
                           if (${${$baseFH->{_unaltered_basehash}}
                                 {$key}[$elems]}{$key}) {
                              undef @{${${$baseFH->{_unaltered_basehash}}
                                    {$key}[$elems]}{$key}};
                           } delete ${${$baseFH->{_unaltered_basehash}}
                                    {$key}[$elems]}{$key};
                        } undef %{${$baseFH->{_unaltered_basehash}}
                                {$key}[$elems]};
                        undef ${$baseFH->{_unaltered_basehash}}
                              {$key}[$elems];
                     }
                  } undef ${$baseFH->{_unaltered_basehash}}{$key};
                  delete ${$baseFH->{_unaltered_basehash}}{$key};
               } undef %{$baseFH->{_unaltered_basehash}};
               $baseFH->{_unaltered_basehash}='';
            }
            if (!$stderr && $base_output!~/bytes free\s*/s) {
               delete $base_shortcut_info{$baseFH};
               $base_output='';next unless $cnt++;
               my $die="Attempt to retrieve output from the command:\n"
                      ."\n       cmd /c dir /-C \'$dir\'\n\n       run"
                      ." on the host $baseFH->{_hostlabel}->[0] FAILED\n";
               &Net::FullAuto::FA_lib::handle_error($die);
            } else { last }
         }
      } else {
         $baseFH->{_bhash}={};
         foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
            if (ref ${$baseFH->{_unaltered_basehash}}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$baseFH->{_unaltered_basehash}}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$baseFH->{_bhash}}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        $newelem{$key}=[@{${$elem}{$key}}];
                     }
                     push @{${$baseFH->{_bhash}}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$baseFH->{_bhash}}{$key}=
                  ${$baseFH->{_unaltered_basehash}}{$key};
            }
         }
      } &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
   } elsif ($base_fdr) {
      my $dir='';
      if (unpack('a1',$base_fdr) ne '/' && $base_fdr!~/^\W/) {
         $dir=$baseFH->{_work_dirs}-{_cwd}.$base_fdr;
      } elsif (unpack('a1',$base_fdr) eq '/') {
         $dir=$base_fdr;
      } else {
         &Net::FullAuto::FA_lib::handle_error(
            "Base Directory - $base_fdr CANNOT Be Located");
      }
      if (!exists $base_shortcut_info{$baseFH} ||
               $base_shortcut_info{$baseFH} ne $dir) {
         my $lspath='';
         if ($baseFH->{_hostlabel}->[0] eq "__Master_${$}__" &&
               exists $Hosts{"__Master_${$}__"}{'ls'}) {
            $lspath=$Hosts{"__Master_${$}__"}{'ls'};
            $lspath.='/' if $lspath!~/\/$/;
         }
         ($base_output,$stderr)=$baseFH->cmd("${lspath}ls -lRs \'$dir\'");
         $base_shortcut_info{$baseFH}=$dir;
         if ($baseFH->{_unaltered_basehash}) { # line 7112
            foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
               my $elems=$#{${$baseFH->{_unaltered_basehash}}{$key}}+1;
               while (-1<--$elems) {
                  if (ref ${$baseFH->{_unaltered_basehash}}{$key}[$elems]
                        ne 'HASH') {
                     undef ${$baseFH->{_unaltered_basehash}}{$key}[$elems];
                  } else {
                     foreach my $key (
                           keys %{${$baseFH->{_unaltered_basehash}}
                           {$key}[$elems]}) {
                        if (${${$baseFH->{_unaltered_basehash}}
                              {$key}[$elems]}{$key}) {
                           undef @{${${$baseFH->{_unaltered_basehash}}
                                 {$key}[$elems]}{$key}};
                        } delete ${${$baseFH->{_unaltered_basehash}}
                                 {$key}[$elems]}{$key};
                     } undef %{${$baseFH->{_unaltered_basehash}}{$key}[$elems]};
                     undef ${$baseFH->{_unaltered_basehash}}{$key}[$elems];
                  }
               } undef ${$baseFH->{_unaltered_basehash}}{$key}; 
               delete ${$baseFH->{_unaltered_basehash}}{$key};
            } undef %{$baseFH->{_unaltered_basehash}};
            $baseFH->{_unaltered_basehash}='';
         }
      }
   } elsif (!exists $base_shortcut_info{$baseFH} ||
         $base_shortcut_info{$baseFH} ne $dir) {
      my $dir=$baseFH->{_work_dirs}->{_cwd};
      $base_shortcut_info{$baseFH}=$dir;
      my $lspath='';
      if ($baseFH->{_hostlabel}->[0] eq "__Master_${$}__" &&
            exists $Hosts{"__Master_${$}__"}{'ls'}) {
         $lspath=$Hosts{"__Master_${$}__"}{'ls'};
         $lspath.='/' if $lspath!~/\/$/;
      }
      ($base_output,$stderr)=$baseFH->cmd("${lspath}ls -lRs \'$dir\'");
      if ($baseFH->{_unaltered_basehash}) { # line 7144
         foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
            my $elems=$#{${$baseFH->{_unaltered_basehash}}{$key}}+1;
            while (-1<--$elems) {
               if (ref ${$baseFH->{_unaltered_basehash}}{$key}[$elems]
                     ne 'HASH') {
                  undef ${$baseFH->{_unaltered_basehash}}{$key}[$elems];
               } else {
                  foreach my $key (
                        keys %{${$baseFH->{_unaltered_basehash}}
                        {$key}[$elems]}) {
                     if (${${$baseFH->{_unaltered_basehash}}
                           {$key}[$elems]}{$key}) {
                        undef @{${${$baseFH->{_unaltered_basehash}}
                              {$key}[$elems]}{$key}};
                     } delete ${${$baseFH->{_unaltered_basehash}}
                              {$key}[$elems]}{$key};
                  } undef %{${$baseFH->{_unaltered_basehash}}{$key}[$elems]};
                  undef ${$baseFH->{_unaltered_basehash}}{$key}[$elems];
               }
            } undef ${$baseFH->{_unaltered_basehash}}{$key};
            delete ${$baseFH->{_unaltered_basehash}}{$key};
         } undef %{$baseFH->{_unaltered_basehash}};
         $baseFH->{_unaltered_basehash}='';
      }
   } else {
      $baseFH->{_bhash}={};
      foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
         if (ref ${$baseFH->{_unaltered_basehash}}{$key} eq 'ARRAY') {
            foreach my $elem (@{${$baseFH->{_unaltered_basehash}}{$key}}) {
               if (ref $elem ne 'HASH') {
                  push @{${$baseFH->{_bhash}}{$key}}, $elem;
               } else {
                  my %newelem=();
                  foreach my $key (keys %{$elem}) {
                     $newelem{$key}=[@{${$elem}{$key}}];
                  }
                  push @{${$baseFH->{_bhash}}{$key}}, \%newelem;
               }
            }
         } else {
            ${$baseFH->{_bhash}}{$key}=${$baseFH->{_unaltered_basehash}}{$key};
         }
      }
   }
   if ($stderr) {
      if (unpack('a10',$stderr) eq 'The System') {
         if (wantarray) {
            return '',$stderr;
         } else { &Net::FullAuto::FA_lib::handle_error($stderr) }
      } else {
         my $die="The System $bhostlabel Returned\n       "
                ."       the Following Unrecoverable Error "
                ."Condition\n              at ".(caller(0))[1]
                ." line ".(caller(0))[2]." :\n\n       $stderr";
         print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log
            && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if (wantarray) {
            return '',$die;
         } else { &Net::FullAuto::FA_lib::handle_error($die) }
      }
   }

   my $mdh=0;
   my $timehash={};

   if (!$baseFH->{_bhash}) { 
      eval {
         ($ignore,$stderr)=&build_base_dest_hashes(
               $base_fdr,\$base_output,$args{Directives},
               $bhost,$bms_share,$bms_domain,
               $baseFH->{_uname},$baseFH,'BASE');
         if ($stderr) {
            if ($stderr eq 'redo ls') {
               while (1) {
                  my $err='';

                  my $lspath='';
                  if ($_[7]->{_hostlabel}->[0] eq "__Master_${$}__" &&
                        exists $Hosts{"__Master_${$}__"}{'ls'}) {
                     $lspath=$Hosts{"__Master_${$}__"}{'ls'};
                     $lspath.='/' if $lspath!~/\/$/;
                  }
                  ($base_output,$err)=$_[7]->cmd(
                     "${lspath}ls -lRs \'$_[0]\'");
                  &Net::FullAuto::FA_lib::handle_error($err,'-3') if $err;
                  ($ignore,$stderr)=&build_base_dest_hashes(
                     $base_fdr,\$base_output,$args{Directives},
                     $bhost,$bms_share,$bms_domain,
                     $baseFH->{_uname},$baseFH,'BASE');
                  next if $stderr eq 'redo ls';
                  last;
               }
            } else {
               $hostlabel=$bhostlabel;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-3');
            }
         }
      };
      if ($@) {
         if (unpack('a10',$@) eq 'The System') {
            return '','','',"$@";
         } else {
            my $die="The System $hostlabel Returned\n       "
                   ."       the Following Unrecoverable Error "
                   ."Condition\n              at ".(caller(0))[1]
                   ." line ".(caller(0))[2]." :\n\n       $@";
            print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log
               && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            return '','','',$die;
         }
      }

      ## CREATING UNALTERED BASE HIGH

      $baseFH->{_unaltered_basehash}={};
      foreach my $key (keys %{$baseFH->{_bhash}}) {
         if (ref ${$baseFH->{_bhash}}{$key} eq 'ARRAY') {
            foreach my $elem (@{${$baseFH->{_bhash}}{$key}}) {
               if (ref $elem ne 'HASH') {
                  push @{${$baseFH->{_unaltered_basehash}}{$key}}, $elem;
               } else {
                  my %newelem=();
                  foreach my $key (keys %{$elem}) {
                     $newelem{$key}=[@{${$elem}{$key}}];
                  }
                  push @{${$baseFH->{_unaltered_basehash}}{$key}}, \%newelem;
               }
            }
         } else {
            ${$baseFH->{_unaltered_basehash}}{$key}=${$baseFH->{_bhash}}{$key};
         }
      }

   }

   foreach my $dhostlabel (@dhostlabels) {

      my $activity=0;
      %Net::FullAuto::FA_lib::file_rename=();%Net::FullAuto::FA_lib::rename_file=();
      ($dip,$dhostname,$duse,$dms_share,$dms_domain,
         $dcmd_cnct,$dftr_cnct,$dlogin_id,$dsu_id,$dchmod,
         $downer,$dgroup,$dtimeout,$dtransfer_dir,$drcm_chain,
         $drcm_map,$duname,$dping,$freemem)
         =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($dhostlabel);
      if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
         $dtimeout=$Net::FullAuto::FA_lib::cltimeout;
      } elsif (!$dtimeout) {
         $dtimeout=$timeout if !$dtimeout;
      }

      ##=======================================
      ##  DOES DESTHOST CONNECTION EXIST?
      ##=======================================

      if (($dip eq $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'IP'}) ||
            ($dhostname eq $Net::FullAuto::FA_lib::Hosts{"__Master_${$}__"}{'HostName'})) {
         $dhostlabel="__Master_${$}__";
         $destFH=$Net::FullAuto::FA_lib::localhost;
         #($output,$stderr)=$destFH->cmd('pwd');
         #&Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         ($output,$stderr)=$destFH->cwd($destFH->{_work_dirs}->{_tmp});
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      } else {
         if ($dsu_id) { $chk_id=$dsu_id }
         elsif ($dlogin_id) { $chk_id=$dlogin_id }
         else { $chk_id=$Net::FullAuto::FA_lib::username }
         if (exists $Net::FullAuto::FA_lib::Connections{"${dhostlabel}__%-$chk_id"}) {
            $destFH=$Net::FullAuto::FA_lib::Connections{"${dhostlabel}__%-$chk_id"};
            if ($destFH->{_uname} ne $baseFH->{_uname} ||
                  $do_dest_tmp_cwd) {
if (defined $destFH->{_work_dirs}->{_tmp}) {
               ($output,$stderr)=$destFH->cwd(
                  $destFH->{_work_dirs}->{_tmp}||
                  $destFH->{_work_dirs}->{_tmp_mswin});
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
}
            }
print "WHAT IS PRENOW=$destFH->{_work_dirs}->{_pre}\n";
         } else {
            if (exists $args{DestTimeout}) {
               $dtimeout=$args{DestTimeout};
            }
            ($destFH,$stderr)=&Net::FullAuto::FA_lib::connect_host($dhostlabel,$dtimeout);
            if ($stderr) {
               if (wantarray) { return '',$stderr }
               else { &Net::FullAuto::FA_lib::handle_error($stderr,'-3') }
            }
            if ($destFH->{_work_dirs}->{_tmp}
                  && (exists $destFH->{_smb}) && ($destFH->{_uname}
                  ne $baseFH->{_uname})) {
               ($output,$stderr)=$destFH->cwd(
                  $destFH->{_work_dirs}->{_tmp});
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            }
         }
      }
      $dms_share||='';
      $dtransfer_dir||='';

      my $dest_dir='';my $dest_fld='';
      my $dhost=($duse eq 'ip')?$dip:$dhostname;
      my $die="The System $dhost Returned"
             ."\n              the Following Unrecoverable Error "
             ."Condition\n              at ".(caller(0))[1]." "
             ."line ".(caller(0))[2]." :\n\n       ";

      if ($destFH->{_uname} eq 'cygwin') {
print "HELLO CYGWIN\n";
         my ($test_chr1,$test_chr2)='';
         if ($dest_fdr) {
            $test_chr1=unpack('a1',$dest_fdr);
            if (1<length $dest_fdr) {
               $test_chr2=unpack('a2',$dest_fdr);
            }
            if ($test_chr2) {
               if (($test_chr1 eq '/' && $test_chr2 ne '//')
                     || ($test_chr1 eq '\\' &&
                     $test_chr2 ne '\\\\')) {
                  $dir=$dest_fdr;
                  if ($dest_fdr=~s/$destFH->{_cygdrive_regex}//) {
                     $dir=~s/^(.)/$1:/;
                     $dir=~tr/\//\\/;
print "PPPPPPPP\n";<STDIN>;
                  } else {
                     my $de_f=$dest_fdr;
                     $de_f=~s/^[\/\\]+//;
                     $de_f=~tr/\//\\/;
                     if (exists $destFH->{_smb}) {
                        $dir="\\\\$dhost\\$dms_share\\$de_f";
                     } else {
                        $dir=$destFH->{_work_dirs}->{_cwd_mswin}.=$de_f;
print "JDKKDK\n";<STDIN>;
                        $destFH->{_work_dirs}->{_cwd_mswin}.='\\';
                     }
                  }
               } elsif ($test_chr2 eq '//' ||
                    $test_chr2 eq '\\\\') {
                  $dir=$dest_fdr;
print "NAKED\n";<STDIN>;
               } elsif ($test_chr2=~/^[a-zA-Z]:$/) {
                  $dir=$dest_fdr;
print "NAKED\n";<STDIN>;
               } elsif ($test_chr1!~/\W/) {
                  my $de_f=$dest_fdr;
                  $de_f=~s/^[\/\\]+//;
                  $de_f=~tr/\//\\/;
                  $dir=$destFH->{_work_dirs}->{_cwd_mswin}.=$de_f;
                  $destFH->{_work_dirs}->{_cwd_mswin}.='\\';
print "DIRRRRRRR=$dir\n";<STDIN>;
               } else {
                  my $die="Destination Directory - $dest_fdr"
                         ." CANNOT Be Located";
                  &Net::FullAuto::FA_lib::handle_error($die);
              }
            } elsif ($test_chr1 eq '/' || $test_chr1 eq '\\') {
               if ($dest_fdr=~s/$destFH->{_cygdrive_regex}//) {
                  $dir=~s/^(.)/$1:/;
                  $dir=~tr/\//\\/;
print "OLSKDKF\n";
               } else {
                  my $de_f=$dest_fdr;
                  $de_f=~s/^[\/\\]+//;
                  $de_f=~tr/\//\\/;
                  $dir=$destFH->{_work_dirs}->{_cwd_mswin}.=$de_f;
                  $destFH->{_work_dirs}->{_cwd_mswin}.='\\';
print "WOOEEE\n";
               }
            } elsif ($test_chr1=~/^[a-zA-Z]$/) {
print "BLECKKK\n";
               $dir=$test_chr1 . ':\\';
            } else {
               my $die="Destination Directory - $dest_fdr"
                      ." CANNOT Be Located";
               &Net::FullAuto::FA_lib::handle_error($die);
            }
print "YEPDIR=$dir<==\n";
         } else {
            $dir=$destFH->{_work_dirs}->{_cwd_mswin};
print "HMMMM\n";
         } my $cnt=0;
         while (1) {
            ($dest_output,$stderr)=$destFH->cmd(
               "cmd /c dir /s /-C /A- \'$dir\'");
               #,'','__debug__','__live__');
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            if ($dest_output!~/bytes free\s*/s) {
               $dest_output='';next unless $cnt++;
               my $die="Attempt to retrieve output from the command:\n"
                      ."\n       cmd /c dir /-C \'$dir\'\n"
                      ."\n       run on the host "
                      ."$dest->{_hostlabel}->[0] FAILED";
               &Net::FullAuto::FA_lib::handle_error($die,'-1');
            } else { last }
         }
      } elsif ($dest_fdr) {
         my $test_char=unpack('a1',$dest_fdr);
         if ($test_char ne '/' && $test_char ne '.') {
            $dest_dir=$destFH->{_work_dirs}->{_cwd}
                     .$dest_fdr;
         } else {
            $dest_dir=$dest_fdr;
         }
         ($dest_output,$stderr)=$destFH->cmd(
            "ls -lRs \"$dest_dir\"");
         if ($stderr) {
            print $Net::FullAuto::FA_lib::MRLOG "$die$stderr"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if (wantarray) {
               return '', "$die$stderr";
            } elsif (unpack('a12',$stderr) eq 'No such file') {
               (); # Fixes Line Nums in AIX
               &Net::FullAuto::FA_lib::handle_error("$die$stderr",'-9');
            } elsif ($stderr) {
               (); # Fixes Line Nums in AIX
               &Net::FullAuto::FA_lib::handle_error("$die$stderr",'-12');
            }
         }
      } else {
         my $dest_dir=$destFH->{_work_dirs}->{_cwd}
         ($dest_output,$stderr)
            =$destFH->cmd("ls -lRs \'$dest_dir\'");
         if ($stderr) {
            print $Net::FullAuto::FA_lib::MRLOG "$die$stderr"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if (wantarray) {
               return '', "$die$stderr";
            } elsif (unpack('a12',$stderr) eq 'No such file') {
               &Net::FullAuto::FA_lib::handle_error("$die$stderr",'-8');
            } else {
               &Net::FullAuto::FA_lib::handle_error("$die$stderr",'-10');
            }
         }
      }
      ($output,$stderr)=$destFH->cwd($dest_dir)
         if $dest_fdr && (!exists $destFH->{_smb});
      if ($stderr) {
         if (wantarray) {
            return '',$stderr;
         } else { &Net::FullAuto::FA_lib::handle_error($stderr,'-7'); }
      }
      if (ref $dest_first_hash eq 'HASH') {
         foreach my $key (keys %{$destFH->{_dhash}}) {
            my $elems=$#{${$destFH->{_dhash}}{$key}}+1;
            while (-1<--$elems) {
               if (ref ${$destFH->{_dhash}}{$key}[$elems] ne 'HASH') {
                  undef ${$destFH->{_dhash}}{$key}[$elems];
               } else {
                  foreach my $key (
                        keys %{${$destFH->{_dhash}}{$key}[$elems]}) {
                     if (${${$destFH->{_dhash}}{$key}[$elems]}{$key}) {
                        undef @{${${$destFH->{_dhash}}{$key}[$elems]}{$key}};
                     } delete ${${$destFH->{_dhash}}{$key}[$elems]}{$key};
                  } undef %{${$destFH->{_dhash}}{$key}[$elems]};
                  undef ${$destFH->{_dhash}}{$key}[$elems];
               }
            } undef ${$destFH->{_dhash}}{$key};
            delete ${$destFH->{_dhash}}{$key};
         } undef %{$destFH->{_dhash}};
         foreach my $key (keys %{$baseFH->{_bhash}}) {
            my $elems=$#{${$baseFH->{_bhash}}{$key}}+1;
            while (-1<--$elems) {
               if (ref ${$baseFH->{_bhash}}{$key}[$elems] ne 'HASH') {
                  undef ${$baseFH->{_bhash}}{$key}[$elems];
               } else {
                  foreach my $key (
                        keys %{${$baseFH->{_bhash}}{$key}[$elems]}) {
                     if (${${$baseFH->{_bhash}}{$key}[$elems]}{$key}) {
                        undef @{${${$baseFH->{_bhash}}{$key}[$elems]}{$key}};
                     } delete ${${$baseFH->{_bhash}}{$key}[$elems]}{$key};
                  } undef %{${$baseFH->{_bhash}}{$key}[$elems]};
                  undef ${$baseFH->{_bhash}}{$key}[$elems];
               }
            } undef ${$baseFH->{_bhash}}{$key};
            delete ${$baseFH->{_bhash}}{$key};
         } undef %{$baseFH->{_bhash}};$baseFH->{_bhash}={};
         foreach my $key (keys %{$baseFH->{_unaltered_basehash}}) {
            if (ref ${$baseFH->{_unaltered_basehash}}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$baseFH->{_unaltered_basehash}}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$baseFH->{_bhash}}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        $newelem{$key}=[@{${$elem}{$key}}];
                     }
                     push @{${$baseFH->{_bhash}}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$baseFH->{_bhash}}{$key}=
                  ${$baseFH->{_unaltered_basehash}}{$key};
            }
         }
      }
      eval {
         ($ignore,$stderr)=&build_base_dest_hashes(
               $dest_fdr,\$dest_output,$args{Directives},
               $dhost,$dms_share,$dms_domain,
               $destFH->{_uname},$destFH,'DEST');
         if ($stderr) {
            if ($stderr eq 'redo ls' ||
                  $stderr=~/does not exist/s) {
               while (1) {
                  my $dest_output='';my $err='';
                  ($dest_output,$err)=$destFH->cmd(
                     "ls -lRs \'$dest_fdr\'");
                  &Net::FullAuto::FA_lib::handle_error($err,'-3') if $err;
                  ($ignore,$stderr)=&build_base_dest_hashes(
                     $dest_fdr,\$dest_output,$args{Directives},
                     $dhost,$dms_share,$dms_domain,
                     $destFH->{_uname},$destFH,'DEST');
                  next if $stderr eq 'redo ls';
                  last;
               }
            } else {
               $hostlabel=$dhostlabel;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-3');
            }
         }
      };
      if ($@) {
         if (unpack('a10',$@) eq 'The System') {
            return '','','',"$@";
         } else {
            my $die="The System $hostlabel Returned\n       "
                   ."       the Following Unrecoverable Error "
                   ."Condition\n              at ".(caller(0))[1]
                   ." line ".(caller(0))[2]." :\n\n       $@";
            print $Net::FullAuto::FA_lib::MRLOG $die
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            return '','','',$die;
         }
      }
      my $newborn_dest_first_hash_flag=0;
      if (ref $dest_first_hash ne 'HASH') {
      
               ## BUILDING FIRST DEST HASH

         $dest_first_hash={};$newborn_dest_first_hash_flag=1;
         foreach my $key (keys %{$destFH->{_dhash}}) {
            if (ref ${$destFH->{_dhash}}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$destFH->{_dhash}}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$dest_first_hash}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        if (${${$elem}{$key}}[0] ne 'EXCLUDE') {
                           $newelem{$key}=[@{${$elem}{$key}}];
                        }
                     }
                     push @{${$dest_first_hash}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$dest_first_hash}{$key}=${$destFH->{_dhash}}{$key};
            }
         }
      }

      my $shortcut=1;

      if (!$newborn_dest_first_hash_flag) {
         my $fdh=0;
         TK: foreach my $key (keys %{$destFH->{_dhash}}) {
            $fdh=1;
#print "SEARCHINGKEY=$key and VALUE=${$dest_first_hash}{$key}<==\n";
            if (exists ${$dest_first_hash}{$key}) {
               my %firstscalelems=();
               my %firsthashelems=();
#print "MAKING NEW FIRSTHASHELEMS and ALL=",@{${$dest_first_hash}{$key}},"\n";
               foreach my $felem (@{${$dest_first_hash}{$key}}) {
#print "ARE ALL FELEMS HASHES=$felem<==\n";
                  if ($felem eq 'EXCLUDE') {
                     delete ${$dest_first_hash}{$key};
                     next TK;
                  }
                  if (ref $felem ne 'HASH') {
                     #delete ${$dest_first_hash}{$key};
                     $firstscalelems{$felem}='-';
                     next;
                  }
#print "KEYSSSSBABYYYY=",keys %{${${$dest_first_hash}{$key}}[1]},"<==\n";
#<STDIN>;
                  foreach my $key (keys %{$felem}) {
#print "POPULATINGFIRST KEY=$key and VALUE=@{${$felem}{$key}}\n";
                     $firsthashelems{$key}=${$felem}{$key};
                  }
               } my $elemnum=-1;
               foreach my $elem (@{${$destFH->{_dhash}}{$key}}) {
                  if ($elem eq 'EXCLUDE') {
                     delete ${$dest_first_hash}{$key};
                     next TK;
                  }
                  if (ref $elem ne 'HASH') {
                     if (!exists $firstscalelems{$elem}) {
print "DEST SUBVALUE=$elem DOES NOT EXIST IN FIRST\n";
print "SETTING SHORTCUT TO ZERO 1\n";<STDIN>;
                        $shortcut=0;last;
                     }
                  } else {
#print "PARENTKEY=$key\n";
#print "ELEMSKEYSSSSSSSSSSSSSSSS=",keys %{$elem},"<==\n";
#print "FIRSTHASHSSSSSSSSSSSSSSSS=",keys %firsthashelems,"<==\n";
                     if (keys %{$elem}) {
                        if (keys %firsthashelems) {
                           foreach my $elm (keys %{$elem}) {
                              if (!exists $firsthashelems{$elm}) {
#print "0_DEST SUBHASHKEY=$elm DOES NOT EXIST IN FIRST and DIR=$key\n";
                                 my $return=0;my $returned_modif='';
                                 ($return,$returned_modif)=
                                    &$Net::FullAuto::FA_lib::f_sub($elm,$key)
                                    if $Net::FullAuto::FA_lib::f_sub;
                                 if ($return &&
                                    (-1<index $returned_modif,'e')) {
                                    delete
                                       ${${$destFH->{_dhash}}{$key}}[$elemnum];
                                    next TK;
                                 }
print "SETTING SHORTCUT TO ZERO 2\n";
                                 $shortcut=0;last;
                              } else {
                                 my $arr1=join '',@{${$elem}{$elm}};
                                 my $arr2=join '',@{$firsthashelems{$elm}};
                                 if ($arr1 ne $arr2) {
                                    my ($mn1,$dy1,$hr1,$mt1,$yr1,$sz1)=
                                       split ' ',$arr1;
                                    my ($mn2,$dy2,$hr2,$mt2,$yr2,$sz2)=
                                       split ' ',$arr2;
                                    if ($sz1==$sz2) {
                                       my $testnum='';
                                       if ($hr1<$hr2) {
                                          $testnum=$hr2-$hr1;
                                       } else { $testnum=$hr1-$hr2 }
                                       if ($testnum==1 || ($hr1==23
                                             && ($testnum==12 ||
                                             $testnum==11)) ||
                                             ("$mn1$dy1" eq "$mn2$dy2" 
                                             && (($hr1 eq '12' &&
                                             $mt1 eq '00') ||
                                             ($hr2 eq '12' &&
                                             $mt2 eq '00')))) {
                                          delete ${$dest_first_hash}{$key};
                                          next TK;
                                       }
                                    }
print "0_ELEM VALUE=",$arr1,"<== DOES NOT EXIST IN FIRST\n";
print "OKAY WHAT THE HECK IS THE ELEM VALUE=",$arr1,"<==\n";
print "OKAY WHAT THE HECK IS THE FVALUE=",$arr2,"<==\n";#<STDIN>;
print "SETTING SHORTCUT TO ZERO 3\n";sleep 3;
                                    $shortcut=0;last;
                                 }
                              }
                           } last if !$shortcut;
                        } else {
print "0_ELEM BUT NOT FIRST\n";
print "SETTING SHORTCUT TO ZERO 4\n";<STDIN>;
                           $shortcut=0;last;
                        }
                     } elsif (keys %firsthashelems) {
print "0_FIRSTHASHELEMS=",keys %firsthashelems,"\n";
print "SETTING SHORTCUT TO ZERO 5\n";<STDIN>;
                        $shortcut=0;last;
                     }
                  }
               } last if !$shortcut;
            } else {
               my $return=0;my $returned_modif='';
               ($return,$returned_modif)=
                  &$Net::FullAuto::FA_lib::d_sub($key)
                  if $Net::FullAuto::FA_lib::d_sub;
               if ($return &&
                     -1<index $returned_modif,'e') {
                  delete
                     ${$destFH->{_dhash}}{$key};
                  next TK;
               } else { $shortcut=0;
print "0_DEST KEY=$key DOES NOT EXIST IN FIRST\n";
print "SETTING SHORTCUT TO ZERO 6\n";sleep 6;
               }
            } last if !$shortcut;
         } $dest_first_hash={} if !$fdh;

      } else {

         ## BUILDING FIRST BASE HASH

         $baseFH->{_first_hash}={};
         foreach my $key (keys %{$baseFH->{_bhash}}) {
            if (ref ${$baseFH->{_bhash}}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$baseFH->{_bhash}}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$baseFH->{_first_hash}}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        $newelem{$key}=[@{${$elem}{$key}}];
                     }
                     push @{${$baseFH->{_first_hash}}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$baseFH->{_first_hash}}{$key}=${$baseFH->{_bhash}}{$key};
            }
         } %Net::FullAuto::FA_lib::renamefile=%Net::FullAuto::FA_lib::rename_file;
         $shortcut=0;
      }
print "WHAT IS SHORTCUT AFTER LOOKING AT FIRSTDESTHASH=$shortcut\n";sleep 1;

      if ($shortcut) {
         foreach my $key (keys %{$baseFH->{_bhash}}) {
            my $elems=$#{${$baseFH->{_bhash}}{$key}}+1;
            while (-1<--$elems) {
               if (ref ${$baseFH->{_bhash}}{$key}[$elems] ne 'HASH') {
                  undef ${$baseFH->{_bhash}}{$key}[$elems];
               } else {
                  foreach my $key (
                        keys %{${$baseFH->{_bhash}}{$key}[$elems]}) {
                     if (${${$baseFH->{_bhash}}{$key}[$elems]}{$key}) {
                        undef @{${${$baseFH->{_bhash}}{$key}[$elems]}{$key}};
                     } delete ${${$baseFH->{_bhash}}{$key}[$elems]}{$key};
                  } undef %{${$baseFH->{_bhash}}{$key}[$elems]};
                  undef ${$baseFH->{_bhash}}{$key}[$elems];
               }
            } undef ${$baseFH->{_bhash}}{$key};
            delete ${$baseFH->{_bhash}}{$key};
         } undef %{$baseFH->{_bhash}};$baseFH->{_bhash}={};
         foreach my $key (keys %{$baseFH->{_first_hash}}) {
            if (ref ${$baseFH->{_first_hash}}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$baseFH->{_first_hash}}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$baseFH->{_bhash}}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        $newelem{$key}=[@{${$elem}{$key}}];
                     }
                     push @{${$baseFH->{_bhash}}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$baseFH->{_bhash}}{$key}=${$baseFH->{_first_hash}}{$key};
            }
         }
         foreach my $key (keys %{$destFH->{_dhash}}) {
            my $elems=$#{${$destFH->{_dhash}}{$key}}+1;
            while (-1<--$elems) {
               if (ref ${$destFH->{_dhash}}{$key}[$elems] ne 'HASH') {
                  undef ${$destFH->{_dhash}}{$key}[$elems];
               } else {
                  foreach my $key (
                     keys %{${$destFH->{_dhash}}{$key}[$elems]}) {
                     if (${${$destFH->{_dhash}}{$key}[$elems]}{$key}) {
                        undef @{${${$destFH->{_dhash}}{$key}[$elems]}{$key}};
                     } delete ${${$destFH->{_dhash}}{$key}[$elems]}{$key};
                  } undef %{${$destFH->{_dhash}}{$key}[$elems]};
                  undef ${$destFH->{_dhash}}{$key}[$elems];
               }
            } undef ${$destFH->{_dhash}}{$key};
            delete ${$destFH->{_dhash}}{$key};
         } undef %{$destFH->{_dhash}};$destFH->{_dhash}={};
         foreach my $key (keys %{$dest_first_hash}) {
            if (ref ${$dest_first_hash}{$key} eq 'ARRAY') {
               foreach my $elem (@{${$dest_first_hash}{$key}}) {
                  if (ref $elem ne 'HASH') {
                     push @{${$destFH->{_dhash}}{$key}}, $elem;
                  } else {
                     my %newelem=();
                     foreach my $key (keys %{$elem}) {
                        $newelem{$key}=[@{${$elem}{$key}}];
                     }
                     push @{${$destFH->{_dhash}}{$key}}, \%newelem;
                  }
               }
            } else {
               ${$destFH->{_dhash}}{$key}=${$dest_first_hash}{$key};
            }
         }
      }

      $dest_output='';$deploy_info='';
      ($baseFH,$destFH,$timehash,$deploy_info,
            $debug_info)
            =&build_mirror_hashes($baseFH,$destFH,$bhostlabel,$dhostlabel);

      $mirror_output.="\n\n### mirror() output for Base Host:"
                    ." $bhostlabel and Destination Host $dhostlabel"
                    ." :\n\n$deploy_info";

      $mirror_debug.="\n\n### mirror() debug for Base Host:"
                   ." $bhostlabel and Destination Host $dhostlabel"
                   ." :\n\n$debug_info";

#print "KEYSBASEHASH=",keys %{$baseFH->{_bhash}},"\n";
#print "KEYSDESTHASH=",keys %{$destFH->{_dhash}},"\n";
#print "KEYSTIMEHASH=",keys %{$timehash},"\n";

      if (keys %{$baseFH->{_bhash}}) {
         if ($baseFH->{_uname} ne 'cygwin' ||
               $base_fdr!~/^[\/|\\][\/|\\]/ ||
               !$bms_share || !$#{$baseFH->{_hostlabel}}) {
            my $base__dir=$baseFH->{_work_dirs}->{_cwd};
            my $bcurdir=$baseFH->{_work_dirs}->{_tmp};
            my $aix_tar_input_variable_flag=0;
            my $aix_tar_input_variable1='';
            my $aix_tar_input_variable2='';
            my $gnu_tar_input_file_flag=0;
            my $gnu_tar_input_file1='';
            my $gnu_tar_input_file2='';
            my $gnu_tar_input_list1='';
            my $gnu_tar_input_list2='';
            my @dirt=();my $tmp_dir='';
            if ($baseFH->{_uname} eq 'cygwin' && 
                  $destFH->{_uname} eq 'cygwin' &&
                  $dest_fdr=~/^[\/|\\][\/|\\]*/ &&
                  $dms_share && $#{$destFH->{_hostlabel}}) {
               my $de_f=$dest_fdr;
               $de_f=~s/^[\/\\]+//;
               $de_f=~tr/\//\\/;my $ps='/';
               if (exists $destFH->{_smb}) {
                  $dir="\\\\$dhost\\$dms_share\\$de_f";
                  $ps='\\';
               } else {
                  $dir=$destFH->{_work_dirs}->{_cwd_mswin}.=$de_f;
                  $destFH->{_work_dirs}->{_cwd_mswin}.='\\';
               }
               my @basekeys=sort keys %{$baseFH->{_bhash}};
               while (my $key=shift @basekeys) {
                  my @files=();
                  foreach my $file
                        (keys %{${$baseFH->{_bhash}}{$key}[1]}) {
                     if (${$baseFH->{_bhash}}{$key}[1]
                           {$file}[0] ne 'EXCLUDE'
                           && unpack('a4',
                           ${$baseFH->{_bhash}}{$key}[1]
                           {$file}[0]) ne 'SAME') {
                        push @files, $file;
                     }
                  } my $tar_cmd='';my $save_dir='';
                  my $filearg='';my $farg='';
                  my $tdir='';my $filecount=0;
                  foreach my $fil (@files) {
                     $filecount++;
                     $fil=~s/%/\\%/g;
                     if ($key eq '/') {
                        $farg.="\'$base__dir$fil\' ";
                        $tdir=$dir;
                     } else {
                        $farg.="\'$base__dir$key/$fil\' ";
                        my $tkey=$key;
                        $tkey=~tr/\//\\/ if ($ps ne '/');
                        $tdir="$dir$ps$tkey"
                     }
                     if (1500 < length "cp -fpv $farg\'$tdir\'") {
print "HERE IS THE COMMANDXXX==>","cp -fpv $filearg\'$tdir\'","<==\n";
                        ($output,$stderr)=$destFH->cmd(
                           "cp -fpv $filearg\'$tdir\'",__display__,__notrap__);
print "CMDXXXOUTPUT=$output<== and STDERR=$stderr<==\n";
                        if ($stderr) {
                           &clean_process_files($destFH);
                           if (-1<index $stderr,': Permission denied') {
                              ($output,$stderr)=$destFH->cmd(
                                 "chmod -v 777 \"$tdir$ps$file\"");
                           } elsif (-1==index $stderr,'already exists') {
                              &move_MSWin_stderr($stderr,$filearg,
                                 $tdir,$destFH,'')
                           }
                        }
                     } $filearg=$farg;
                  }
                  if ($filearg) {
                     if ($filecount==1) {
                        my $testd=&Net::FullAuto::FA_lib::test_dir($destFH->{_cmd_handle},
                           $tdir);
                        if ($testd) {
                           if ($testd eq 'READ') {
                              ($output,$stderr)=$destFH->cmd(
                                 "chmod -v 777 \"$tdir\"");
                              if ($stderr) {
                                 my $die="Destination Directory $tdir\n"
                                        .'       is NOT Writable!';
                                 if (wantarray) {
                                    return '',$die;
                                 } else {
                                    &Net::FullAuto::FA_lib::handle_error($die);
                                 }
                              } else {
print "BE SURE TO ADD NEW CODE TO CHANGE BACK TO ",
      "MORE RESTRICTIVE PERMISSIONS\n";
                              }
                           } else {
                              ($output,$stderr)=$destFH->cmd(
                                 "cp -fpv $filearg\'$tdir\'",
                                 '__display__','__notrap__');
                              if ($stderr) {
                                 &clean_process_files($destFH);
                                 if (-1<index $stderr,': Permission denied') {
                                    ($output,$stderr)=$destFH->cmd(
                                       "chmod -v 777 \"$tdir$ps$file\"");
                                 } elsif (-1==index $stderr,'already exists') {
                                    &move_MSWin_stderr($stderr,$filearg,
                                       $tdir,$destFH,'')
                                 }
                              }
                           }
                        } else {
                           ($output,$stderr)=$destFH->cmd(
                              "cmd /c mkdir \"$tdir\"",'__live__');
                              #'__display__','__notrap__');
                           &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
print "FILEARGGGGGG=$filearg<==\n";
                           ($output,$stderr)=$destFH->cmd(
                              "cp -fpv $filearg\'$tdir\'",
                              '__display__','__notrap__');
                           &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                        }
                     } else {
                        ($output,$stderr)=$destFH->cmd(
                           "cp -fpv $filearg\'$tdir\'",
                           '__display__','__notrap__');
                        if ($stderr) {
                           &clean_process_files($destFH);
                           if (-1<index $stderr,': Permission denied') {
                              ($output,$stderr)=$destFH->cmd(
                                 "chmod -v 777 \"$tdir/$file\"");
                           } elsif (-1==index $stderr,'already exists') {
                              &move_MSWin_stderr($stderr,$filearg,
                                 $tdir,$destFH,'')
                           }
                        }
                     }
                  }
               }
            } else {
               if (!$shortcut) {
                  if (0<$#dhostlabels && !$newborn_dest_first_hash_flag
                        && !$Net::FullAuto::FA_lib::tranback && $activity) {
                     ($output,$stderr)=$baseFH->cmd(
                        "cp $bcurdir/transfer$Net::FullAuto::FA_lib::tran[3].tar ".
                        "$bcurdir/transfer$Net::FullAuto::FA_lib::tran[3]_1.tar");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                     $Net::FullAuto::FA_lib::tranback=2;
                  } $activity=0;
                  my @basekeys=sort keys %{$baseFH->{_bhash}};
                  my $f_cnt=0;
                  ($output,$stderr)=$baseFH->cmd("${tarpath}tar --help");
                  if ($stderr) {
                     if (-1<index $stderr,'-LInputList') {
                        $aix_tar_input_variable_flag=1;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                     }
                  } elsif ($output) {
                     if (-1<index $output,'-T, --files-from=NAME') {
                        $gnu_tar_input_file_flag=1; 
                     }
                  }
                  while (my $key=shift @basekeys) {
                     foreach my $file
                           (keys %{${$baseFH->{_bhash}}{$key}[1]}) {
                        if (${$baseFH->{_bhash}}{$key}[1]
                               {$file}[0] ne 'EXCLUDE'
                               && unpack('a4',
                               ${$baseFH->{_bhash}}{$key}[1]
                               {$file}[0]) ne 'SAME') {
                           push @files, $file;
                        }
                     } my $tar_cmd='';my $save_dir='';
                     foreach my $file (@files) {
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY2" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $activity=1;
                        my $base___dir='';
                        my $dir= ($key eq '/') ? '' : "$key/";
                        my $dirt='';
                        if (exists $Net::FullAuto::FA_lib::file_rename{"$dir$file"}) {
                           $cmd="cp -Rpv \"$base__dir$dir$file\" "
                               ."\"$bcurdir/"
                               .$Net::FullAuto::FA_lib::file_rename{"$dir$file"}."\"";
                           $file=$Net::FullAuto::FA_lib::file_rename{"$dir$file"};
                           $base___dir=$bcurdir;
                           ($output,$stderr)
                              =$baseFH->cmd($cmd,'__debug__');
                           $Net::FullAuto::FA_lib::savetran=1 if $stderr;
                           &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                           $dirt=substr($dir,0,(index $dir,'/'));
                           $dir='';
                           if ($gnu_tar_input_file_flag) {
                              $gnu_tar_input_file2=
                                 $baseFH->tmp('tarlist2.txt')
                                 if !$gnu_tar_input_file2;
                              $gnu_tar_input_list2.="$file\n";
                              $tmp_dir=$bcurdir;
                              push @dirt, $file;
                           } elsif ($aix_tar_input_variable_flag) {
                              $aix_tar_input_variable2.="$bcurdir/$file\n";
                              push @dirt, $file;
                              $tmp_dir=$bcurdir;
                           } next
                        } else { $base___dir=$base__dir }
                        if ($gnu_tar_input_file_flag) {
                           $gnu_tar_input_file1=
                              $baseFH->tmp('tarlist1.txt')
                              if !$gnu_tar_input_file1;
                           $gnu_tar_input_list1.="$dir$file\n";
                        } elsif ($aix_tar_input_variable1) {
                            $aix_tar_input_variable1.="$dir$file\n";
                        } else {
                            if (!$f_cnt) {
                               $f_cnt++;
                               $tar_cmd=
                                  "tar cvf $bcurdir/transfer".
                                  "$Net::FullAuto::FA_lib::tran[3].tar ";
                           } else {
                              $tar_cmd=
                                 "tar rvf $bcurdir/transfer".
                                 "$Net::FullAuto::FA_lib::tran[3].tar ";
                           }
                           $tar_cmd.="-C \"$base___dir\" \"$dir$file\"";
                           ($output,$stderr)=$baseFH->cmd($tar_cmd);
                           &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                              if $stderr;
                           if ($dirt) {
                              $cmd="rm -rf \"$base___dir/$dirt\"";
                              ($output,$stderr)
                                 =$baseFH->cmd($cmd,'__debug__');
                              $Net::FullAuto::FA_lib::savetran=1 if $stderr;
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-2')
                                 if $stderr;
                           }
                        }
                     } @files=();
                  }
               } elsif ($Net::FullAuto::FA_lib::tranback==2 && $activity) {
                  ($output,$stderr)=$baseFH->cmd(
                     "cp $bcurdir/transfer$Net::FullAuto::FA_lib::tran[3]_1.tar ".
                     "$bcurdir/transfer$Net::FullAuto::FA_lib::tran[3].tar");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  $Net::FullAuto::FA_lib::tranback=1;$activity=0;
               } else { $activity=0 }
            }
            if ($activity) {
               if ($gnu_tar_input_list1) {
                  chomp $gnu_tar_input_list1;
                  my @files=split /^/, $gnu_tar_input_list1;
                  my $filearg='';my $farg='';
                  foreach my $fil (@files) {
                     $fil=~s/%/\\%/g;
                     $farg.=$fil;
                     if (1601 <
                           length "echo \"$farg\" >> \$gnu_tar_input_file1") {
                        chomp $filearg;
                        ($output,$stderr)=$baseFH->cmd(
                           "echo \"$filearg\" >> $gnu_tar_input_file1");
                        &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                        $farg=$fil;
                     } $filearg=$farg;
                  }
                  if ($filearg) {
                     chomp $filearg;
                     ($output,$stderr)=$baseFH->cmd(
                        "echo \"$filearg\" >> $gnu_tar_input_file1");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
                  $tar_cmd=
                     "tar cvf $bcurdir/transfer".
                     "$Net::FullAuto::FA_lib::tran[3].tar ";
                  $tar_cmd.="-C \"$base__dir\" -T \"$gnu_tar_input_file1\"";
                  ($output,$stderr)=$baseFH->cmd($tar_cmd,__display__);
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               }
               if ($gnu_tar_input_list2) {
                  chomp $gnu_tar_input_list2;
                  my @files=split /^/, $gnu_tar_input_list2;
                  my $filearg='';my $farg='';
                  foreach my $fil (@files) {
                     $fil=~s/%/\\%/g;
                     $farg.=$fil;
                     if (1601 <
                           length "echo \"$farg\" >> \$gnu_tar_input_file2") {
                        chomp $filearg;
                        ($output,$stderr)=$baseFH->cmd(
                           "echo \"$filearg\" >> $gnu_tar_input_file2");
                        &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                        $farg=$fil;
                     } $filearg=$farg;
                  }
                  if ($filearg) {
                     chomp $filearg;
                     ($output,$stderr)=$baseFH->cmd(
                        "echo \"$filearg\" >> $gnu_tar_input_file2");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
                  $tar_cmd=
                     "tar rvf $bcurdir/transfer".
                     "$Net::FullAuto::FA_lib::tran[3].tar ";
                  $tar_cmd.="-C \"$tmp_dir\" -T \"$gnu_tar_input_file2\"";
                  ($output,$stderr)=$baseFH->cmd($tar_cmd);
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  foreach my $dirt (@dirt) {
                     $cmd="rm -rf \"$tmp_dir/$dirt\"";
                     ($output,$stderr)
                        =$baseFH->cmd($cmd,'__debug__');
                     $Net::FullAuto::FA_lib::savetran=1 if $stderr;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                  }
               } elsif ($aix_tar_input_variable1) {

               }
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY3" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               if (!$shortcut) {
                  ($output,$stderr)=$baseFH->cmd(
                     "chmod 777 $bcurdir/transfer$Net::FullAuto::FA_lib::tran[3].tar");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
               }
               &move_tarfile($baseFH,$btransfer_dir,$destFH,$shortcut);
#print "BASEFH=$baseFH\n";
#print "DESTFH=$destFH\n";
#print "BMS_SHARE=$bms_share\n";
#print "DMS_SHARE=$dms_share\n";
#print "LOCALTRANSFERDIR=$local_transfer_dir\n";
#print "TRANTAR=$trantar\n";
#print "BHOSTLABEL=$bhostlabel\n";
#print "DHOSTLABEL=$dhostlabel\n";
               if ($destFH->{_uname} eq 'cygwin' && 
                     $dest_fdr=~/^[\/|\\][\/|\\]/ &&
                     $dms_share && $#{$destFH->{_hostlabel}}) {
                  $trantar=move_files($baseFH,'/','',
                           $dest_fdr,
                           $destFH,$bms_share,
                           $dms_share,'DEPLOY_ALL',
                           $local_transfer_dir,'',
                           $bhostlabel,$dhostlabel,
                           '',$shortcut);
               }
            }
            foreach my $key (keys %{$destFH->{_dhash}}) {
               if ($Net::FullAuto::FA_lib::d_sub) {
                  my $return=0;my $returned_modif='';
                  ($return,$returned_modif)=&$Net::FullAuto::FA_lib::d_sub($key);
                  next if $return && -1<index $returned_modif,'e';
               } $excluded=0;
               if (exists ${$baseFH->{_bhash}}{$key}) {
                  foreach my $file (keys %{${$destFH->{_dhash}}{$key}[1]}) {
                     my $return=0;my $returned_modif='';
                     ($return,$returned_modif)=
                        &$Net::FullAuto::FA_lib::f_sub($file,$key)
                        if $Net::FullAuto::FA_lib::f_sub;
                     next if $return && -1<index $returned_modif,'e';
                     if ((exists $args{DeleteOnDest} &&
                           $args{DeleteOnDest}) && (!exists
                           ${$baseFH->{_unaltered_basehash}}
                           {$key}[1]{$file})) {
${$baseFH->{_unaltered_basehash}}{$key}[1]{$file}||='';
print "SHORTCUT=$shortcut and THISSS=",
   ${$baseFH->{_unaltered_basehash}}{$key}[1]{$file},"<== and KEY=$key and FILE=$file\n";#<STDIN>;
                        if ($key eq '/') {
                           $activity=1;
                           $mirror_output.="DELETEDa File ==> $file\n";
                           $mirror_debug.="DELETED File ==> $file\n";
                           print "DELETINGa File ==> $file\n"
                              if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                           if (!$destFH->{_work_dirs}->{_cwd} &&
                                 $destFH->{_work_dirs}->{_cwd_mswin}) {
                              my $fil=$file;
                              $fil=$destFH->{_work_dirs}->{_cwd_mswin}
                                  .$fil;
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$fil\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           } else {
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$file\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           }
                        } else {
print $Net::FullAuto::FA_lib::MRLOG "DELETEFILE1b=$file\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           $activity=1;
                           $mirror_output.="DELETEDb File ==> $key/$file\n";
                           $mirror_debug.="DELETED File ==> $key/$file\n";
                           print "DELETINGb File ==> $key/$file\n";
                           if (!$destFH->{_work_dirs}->{_cwd} &&
                                 $destFH->{_work_dirs}->{_cwd_mswin}) {
                              my $fil="$key/$file";
                              $fil=~s/\//\\/g;
                              $fil=$destFH->{_work_dirs}->{_cwd_mswin}
                                   .$fil;
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$fil\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           } else {
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$key/$file\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           }
                        }
                     }
                  }
               } elsif ((exists $args{DeleteOnDest} &&
                     $args{DeleteOnDest}) &&
                     (!$shortcut || !exists
                     ${$baseFH->{_unaltered_basehash}}{$key})) {
                  $activity=1;
                  $key="$dest_fdr/." if $key eq '/';
                  $mirror_output.="DELETEDc Directory ==> $key\n";
                  $mirror_debug.="DELETED Directory ==> $key\n";
                  print "DELETINGc Directory ==> $key\n"
                     if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                  if (!$destFH->{_work_dirs}->{_cwd} &&
                        $destFH->{_work_dirs}->{_cwd_mswin}) {
                     my $dir=$key;
                     $dir=~s/\//\\/g;
                     $dir=$destFH->{_work_dirs}->{_cwd_mswin}
                          .$dir;
                     my ($output,$stderr)=
                        $destFH->cmd("rm -rf \"$dir\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                        if $stderr;
                  } else {
                     my ($output,$stderr)=
                        $destFH->cmd("rm -rf \"$key\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                        if $stderr;
                  }
               }
            }
            foreach my $key (keys %{$baseFH->{_bhash}}) {
               if (defined ${$baseFH->{_bhash}}{$key}[3]
                     && ${$baseFH->{_bhash}}{$key}[3] eq 'NOT_ON_DEST') {
                  if (exists $destFH->{_smb}) {
                     my $tdir=$key;
                     $tdir=~tr/\//\\/;
                     $tdir="\\\\$dhost\\$dms_share\\$tdir";
                     ($output,$stderr)=$destFH->cmd("cmd /c mkdir $tdir",
                        '__live__');
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  } else {
                     ($output,$stderr)=$destFH->cmd("mkdir -p $key");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
                  $activity=1;
               }
            }
            my $nodif="\n       THERE ARE NO DIFFERENCES "
                     ."BETWEEN THE BASE AND TARGET\n\n";
            print $nodif if !$activity &&
               !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
            print $Net::FullAuto::FA_lib::MRLOG $nodif
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*'
               && !$activity;
            $mirror_output.=$nodif if !$activity;
            $mirror_debug.=$nodif if !$activity;
push @main::test_tar_output, $mirror_output;
         } else {
            $activity=0;
            if (${$baseFH->{_bhash}}{'/'}[0] eq 'ALL') {
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY7" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               $activity=1;
               $trantar=move_files($baseFH,'/','',
                             $dest_fdr,
                             $destFH,$bms_share,
                             $dms_share,'DEPLOY_ALL',
                             $local_transfer_dir,'',
                             $bhostlabel,$dhostlabel,
                             '',$shortcut);
                             #'',$shortcut,\%desthash);
            #if (exists $baseFH->{_smb}) {

            #}
            } else {
#print "HERE WE ARE FFFFTOP and $#{[keys %{$baseFH->{_bhash}}]}\n";
#print $Net::FullAuto::FA_lib::MRLOG "WE ARE HERE FFFFTOP and ",
#"$#{[keys %{$baseFH->{_bhash}}]}\n"
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               my @basekeys=sort keys %{$baseFH->{_bhash}};
               while (my $key=shift @basekeys) {
#print "BASEKEYYYYYY=$key and ==>",${$baseFH->{_bhash}}{$key}[0],"<==\n";
                  if (${$baseFH->{_bhash}}{$key}[0] eq 'ALL' ||
                        ${$baseFH->{_bhash}}{$key}[0] eq 'NOT_ON_DEST'
                        || ${$baseFH->{_bhash}}{$key}[0] eq
                        'ALL_DIR_ON_DEST') {
#print "BASEFH=$baseFH\n";
#print "KEY=$key\n";
#print "DEST_FDR=$dest_fdr\n";
#print "DESTFH=$destFH\n";
#print "BMS_SHARE=$bms_share\n";
#print "DMS_SHARE=$dms_share\n";
#print "LOCAL=$local_transfer_dir\n";
#print "TRANTAR=$trantar\n";
#print "BHOSTLABEL=$bhostlabel\n";
#print "KEYYYYY=$key and DIREC=",${$baseFH->{_bhash}}{$key}[0],"\n";<STDIN>;
                     my $parentkey='';
                     if ($key ne '/') {
                        if (-1<index $key,'/') {
                           $parentkey=$key;
                           substr($parentkey,(rindex $parentkey,'/'))='';
                           next if exists ${$baseFH->{_bhash}}{$parentkey}[0]
                              && ${$baseFH->{_bhash}}{$parentkey}[0] eq 'ALL';
                           $parentkey="\\$parentkey";
                        }
                     }
                     $trantar=move_files($baseFH,$key,'',
                        $dest_fdr,
                        $destFH,$bms_share,$dms_share,
                        '',$local_transfer_dir,$trantar,
                        $bhostlabel,$dhostlabel,
                        $parentkey,$shortcut);
                     if ($basekeys[0] && (-1<index $basekeys[0],'/')) {
                        my $lkey=0;my $lbky=0;
                        $lkey=length $key;
                        $lbky=length $basekeys[0];
                        while ($lkey<=$lbky &&
                                  unpack("a$lkey",$basekeys[0])
                                  eq $key &&
                                  (-1<index $basekeys[0],'/')) {
                           shift @basekeys;
                        }
                     } $activity=1;
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY8" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     next;
                  } elsif (${$baseFH->{_bhash}}{$key}[0] ne 'EXCLUDE'
                        && ${$baseFH->{_bhash}}{$key}[2] ne
                        'DEPLOY_NOFILES_OF_CURDIR') {
                     my @files=();
                     foreach my $file
                        (keys %{${$baseFH->{_bhash}}{$key}[1]}) {
                        if (${$baseFH->{_bhash}}{$key}[1]
                               {$file}[0] ne 'EXCLUDE'
                               && unpack('a4',
                               ${$baseFH->{_bhash}}{$key}[1]
                               {$file}[0]) ne 'SAME') {
                           push @files, $file;
                        }
                     }
                     $trantar=move_files($baseFH,$key,
                        \@files,$dest_fdr,
                        $destFH,$bms_share,$dms_share,
                        '',$local_transfer_dir,$trantar,
                        $bhostlabel,$dhostlabel,
                        '',$shortcut);
                     $activity=1;
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY9" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  } elsif (${$baseFH->{_bhash}}{$key}[0] ne 'EXCLUDE') {
                     $trantar=move_files($baseFH,$key,
                        \@files,$dest_fdr,
                        $destFH,$bms_share,$dms_share,
                        '',$local_transfer_dir,$trantar,
                        $bhostlabel,$dhostlabel,
                        ')DIRONLY',$shortcut);
print $Net::FullAuto::FA_lib::MRLOG "ACTIVITY10" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $activity=1;
                  }
               }
            }
            if ($activity && $trantar) { #&& (exists $baseFH->{_smb})
                     #&& !$dms_share) {
               if (!$shortcut) {
                  foreach my $file (keys %Net::FullAuto::FA_lib::file_rename) {
                     my $cmd="mv \"transfer$Net::FullAuto::FA_lib::tran[3]/$file\" "
                            ."\"transfer$Net::FullAuto::FA_lib::tran[3]/"
                            ."$Net::FullAuto::FA_lib::file_rename{$file}\"";
                     my ($output,$stderr)=$baseFH->cmd("$cmd",'__debug__');
                     $Net::FullAuto::FA_lib::savetran=1 if $stderr;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                  }
                  my $cmd="cmd /c tar -C \'transfer$Net::FullAuto::FA_lib::tran[3]\'"
                         ." -cvf \'transfer$Net::FullAuto::FA_lib::tran[3].tar\' .";
                  $cmd=~tr/\\/\//;
($output,$stderr)=$baseFH->cmd('pwd');
   &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
print $Net::FullAuto::FA_lib::MRLOG "TARRRPWDDDDD=$output\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  my ($output,$stderr)=$baseFH->cmd($cmd);
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  ($output,$stderr)=$baseFH->cmd(
                     "cmd /c rmdir /s /q transfer$Net::FullAuto::FA_lib::tran[3]");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  if (&Net::FullAuto::FA_lib::test_dir(
                        #$baseFH->{_cmd_handle}->{_cmd_handle},
                        $baseFH->{_cmd_handle},
                        "transfer$Net::FullAuto::FA_lib::tran[3]")) {
                     ($output,$stderr)=$baseFH->cmd(
                        "chmod -R 777 transfer$Net::FullAuto::FA_lib::tran[3]");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                     ($output,$stderr)=$baseFH->cmd(
                        "cmd /c rmdir /s /q transfer$Net::FullAuto::FA_lib::tran[3]");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
               }
print "DO MOVETARFILE\n";
               &move_tarfile($baseFH,$btransfer_dir,$destFH,$shortcut);
               if (keys %{$timehash}) {
my $logreset=1;
if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
else { $Net::FullAuto::FA_lib::log=1 }

                  ($output,$stderr)=$destFH->cmd("touch --version");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
                     (-1==index $stderr,'Not a recog') &&
                     (-1==index $stderr,'illegal opt');
print "TOUCHOUT=$output and STDERR=$stderr\n";
print $Net::FullAuto::FA_lib::MRLOG "TOUCHOUT=$output and STDERR=$stderr and EVAL=$@\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  my $touch='';
                  $touch='GNU' if -1<index $output,'GNU';
                  foreach my $file (keys %{$timehash}) {
                     my $time='';
                     $time=${${$timehash}{$file}}[1];
                     $time=~tr/ //d;
                     if ($touch eq 'GNU') {
                        $time="$time${${$timehash}{$file}}[0]";
                     } else {
                        $time="${${$timehash}{$file}}[0]$time";
                     }
print "GOING TO TOUCH TIME=$time and FILE=$file\n";
print $Net::FullAuto::FA_lib::MRLOG "GOING TO TOUCH TIME=$time and FILE=$file\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     my ($output,$stderr)=
                        $destFH->cmd('touch -t'." $time \"$file\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
$Net::FullAuto::FA_lib::log=0 if $logreset;
                  foreach my $key (keys %{$destFH->{_dhash}}) {
                     if ($Net::FullAuto::FA_lib::d_sub) {
                        my $return=0;my $returned_modif='';
                        ($return,$returned_modif)=&$Net::FullAuto::FA_lib::d_sub($key);
                        next if $return && -1<index $returned_modif,'e';
                     } $excluded=0;
                     if (!$shortcut && exists ${$baseFH->{_bhash}}{$key}) {
                        foreach my $file (
                              keys %{${$destFH->{_dhash}}{$key}[1]}) {
                           my $return=0;my $returned_modif='';
                           ($return,$returned_modif)=
                              &$Net::FullAuto::FA_lib::f_sub($file,$key)
                              if $Net::FullAuto::FA_lib::f_sub;
                           next if $return && -1<index $returned_modif,'e';
                           if ((exists $args{DeleteOnDest}
                                 && $args{DeleteOnDest}) &&
                                 (!$shortcut || !exists
                                 ${$baseFH->{_unaltered_basehash}}
                                 {$key}[1]{$file})) {
                              if ($key eq '/') {
                                 $mirror_output.="DELETEDd File ==> $file\n";
                                 $mirror_debug.="DELETED File ==> $file\n";
                                 print "DELETINGd File ==> $file\n"
                                    if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                                 if (!$destFH->{_work_dirs}->{_cwd} &&
                                       $destFH->{_work_dirs}->{_cwd_mswin}) {
                                    my $fil=$file;
                                    $fil=$destFH->{_work_dirs}->{_cwd_mswin}
                                        .$fil;
                                    my ($output,$stderr)=
                                       $destFH->cmd("rm -f \"$fil\"");
                                    &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                       if $stderr;
                                 } else {
                                    my ($output,$stderr)=
                                       $destFH->cmd("rm -f \"$file\"");
                                    &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                       if $stderr;
                                 }
                              } else {
                                 $mirror_output.=
                                    "DELETEDe File ==> $key/$file\n";
                                 $mirror_debug.=
                                    "DELETED File ==> $key/$file\n";
                                 print "DELETINGe File ==> $key/$file\n"
                                    if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                                 if (!$destFH->{_work_dirs}->{_cwd} &&
                                       $destFH->{_work_dirs}->{_cwd_mswin}) {
                                    my $fil="$key/$file";
                                    $fil=~s/\//\\/g;
                                    $fil=$destFH->{_work_dirs}->{_cwd_mswin}
                                        .$fil;
                                    my ($output,$stderr)=
                                       $destFH->cmd("rm -f \"$fil\"");
                                    &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                       if $stderr;
                                 } else {
                                    my ($output,$stderr)=
                                       $destFH->cmd("rm -f \"$key/$file\"");
                                    &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                       if $stderr;
                                 }
                              }
                           }
                        }
                     } elsif ((exists $args{DeleteOnDest} &&
                           $args{DeleteOnDest}) &&
                           (!$shortcut || !exists
                           ${$baseFH->{_unaltered_basehash}}{$key})) {
                        $key="$dest_fdr/." if $key eq '/';
                        $mirror_output.="DELETEDf Directory ==> $key\n";
                        $mirror_debug.="DELETED Directory ==> $key\n";
                        print "DELETINGf Directory ==> $key\n"
                           if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                        if (!$destFH->{_work_dirs}->{_cwd} &&
                              $destFH->{_work_dirs}->{_cwd_mswin}) {
                           my $dir=$key;
                           $dir=~s/\//\\/g;
                           $dir=$destFH->{_work_dirs}->{_cwd_mswin}
                               .$dir;
                           my ($output,$stderr)=
                              $destFH->cmd("rm -rf \"$dir\"");
                           &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                              if $stderr;
                        } else {
                           my ($output,$stderr)=
                              $destFH->cmd("rm -rf \"$key\"");
                           &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                              if $stderr;
                        }
                     }
                  }
               }
            } elsif (!$activity) {
               my $nodif='';my $excluded=0;
               foreach my $key (keys %{$destFH->{_dhash}}) {
                  if ($Net::FullAuto::FA_lib::d_sub) {
                     my $return=0;my $returned_modif='';
                     ($return,$returned_modif)=&$Net::FullAuto::FA_lib::d_sub($key);
                     next if $return && -1<index $returned_modif,'e';
                  } $excluded=0;
                  if (exists ${$baseFH->{_bhash}}{$key}) {
                     foreach my $file (keys %{${$destFH->{_dhash}}{$key}[1]}) {
                        my $return=0;my $returned_modif='';
                        ($return,$returned_modif)=
                           &$Net::FullAuto::FA_lib::f_sub($file,$key)
                           if $Net::FullAuto::FA_lib::f_sub;
                        next if $return && -1<index $returned_modif,'e';
                        if ((exists $args{DeleteOnDest} &&
                              $args{DeleteOnDest}) &&
                              (!$shortcut || !exists
                              ${$baseFH->{_unaltered_basehash}}
                              {$key}[1]{$file})) {
                           if ($key eq '/') {
                              $mirror_output.="DELETEDg File ==> $file\n";
                              $mirror_debug.="DELETED File ==> $file\n";
                              print "DELETINGg File ==> $file\n"
                                 if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$file\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           } else {
                              $mirror_output.=
                                 "DELETEDh File ==> $key/$file\n";
                              $mirror_debug.=
                                 "DELETED File ==> $key/$file\n";
                              print "DELETINGh File ==> $key/$file\n"
                                 if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                              my ($output,$stderr)=
                                 $destFH->cmd("rm -f \"$key/$file\"");
                              &Net::FullAuto::FA_lib::handle_error($stderr,'-1')
                                 if $stderr;
                           }
                        }
                     }
                  } elsif ((exists $args{DeleteOnDest} &&
                        $args{DeleteOnDest}) &&
                        (!$shortcut || !exists
                        ${$baseFH->{_unaltered_basehash}}{$key})) {
                     $key="$dest_fdr/." if $key eq '/';
                     $mirror_output.="DELETEDi Directory ==> $key\n";
                     $mirror_debug.="DELETED Directory ==> $key\n";
                     print "DELETINGi DIRECTORY ==> $key\n"
                        if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                     my ($output,$stderr)=
                        $destFH->cmd("rm -rf $key");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
               }
               $nodif="\n       THERE ARE NO DIFFERENCES "
                     ."BETWEEN THE BASE AND TARGET\n\n";
               print $nodif if !$activity &&
                  !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
               print $Net::FullAuto::FA_lib::MRLOG $nodif
                  if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*'
                  && !$activity;
               $mirror_output.=$nodif if !$activity;
               $mirror_debug.=$nodif if !$activity;
push @main::test_tar_output, $mirror_output;
            }
         }
      }
   }
   %base_shortcut_info=();
   if (exists $destFH->{_work_dirs}->{_pre} && $destFH->{_work_dirs}->{_pre}
         && $destFH->{_work_dirs}->{_pre} ne $destFH->{_work_dirs}->{_cwd}
         && $destFH->{_work_dirs}->{_pre} ne $destFH->{_work_dirs}->{_tmp}) {
      ($output,$stderr)=$destFH->cwd($destFH->{_work_dirs}->{_pre});
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
   }
   if (wantarray) {
      return $mirror_output,$mirror_debug;
   } else { return $mirror_output }

}

sub get_drive
{
   my @topcaller=caller;
   print "get_drive() CALLER=",(join ' ',@topcaller),"\n";
   #   if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "get_drive() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($folder,$base_or_dest,$cmd_handle,$hostlabel)=@_;
   $cmd_handle||='';
   my @drvs=();
   if (unpack('a1',$folder) eq '/' ||
         unpack('a1',$folder) eq '\\') {
      $dir=unpack('a1',$folder);
   } else { $dir=$folder }
   $dir=~tr/\\/\//;
   my $ms_dir=$dir;
   $ms_dir=~tr/\//\\/;
   $ms_dir=~tr/\\/\\\\/;
   if (exists $Net::FullAuto::FA_lib::drives{$hostlabel}) {
      $drvs=$Net::FullAuto::FA_lib::drives{$hostlabel};
   } else {
      my $sav_curdir='';
      if ($cmd_handle) {
         bless $cmd_handle, 'File_Transfer';
         $sav_curdir=&Net::FullAuto::FA_lib::push_cmd($cmd_handle,
                     'cmd /c chdir',$hostlabel);
         #my $cou=2;
         #while ($cou--) {
         #   ($sav_curdir,$stderr)=$cmd_handle->cmd('cmd /c chdir',__live__);
         #   &Net::FullAuto::FA_lib::handle_error($stderr,'-1','__cleanup__') if $stderr;
         #   if (!$sav_curdir) {
         #      ($output,$stderr)=
         #         &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
         #      &Net::FullAuto::FA_lib::handle_error($stderr,'__cleanup__') if $stderr;
         #   } else { last }
         #}
         ($output,$stderr)=$cmd_handle->cwd($cmd_handle->{_cygdrive});
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         ($drvs,$stderr)=$cmd_handle->cmd('ls');
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      } elsif ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
         $sav_curdir=Cwd::getcwd();
         chdir $Net::FullAuto::FA_lib::localhost->{_cygdrive};
         $drvs=`ls`;
      }
      if ($cmd_handle) {
         ($output,$stderr)=$cmd_handle->cwd($sav_curdir);
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      } else { chdir $sav_curdir }
      $Net::FullAuto::FA_lib::drives{$hostlabel}=$drvs;
   }
print "ARE WE HERE and what are DRVS=$drvs\n";
   foreach my $drv (split /\n/, $drvs) {
      last unless $drv;
      if ($cmd_handle) {
         my $result=&Net::FullAuto::FA_lib::test_dir($cmd_handle->{_cmd_handle},
            $cmd_handle->{_cygdrive}."/$drv/$dir/");
         if ($result ne 'NODIR') { 
            push @drvs, "$drv:\\$ms_dir\\";
         }
      } elsif (-d "$drv:\\$ms_dir") {
         push @drvs, "$drv:\\$ms_dir\\";
      }
   }
   if (-1<$#drvs) {
      if ($#drvs==0) {
         $dir=$drvs[0];
      } else {
         my $banner="\n   Please Pick a $base_or_dest Directory\n"
                   ."   on the Local Host "
                   ."$Net::FullAuto::FA_lib::Local_HostName :";
         $dir=&Term::Menus::pick(\@drvs,$banner);
      }
      my ($drive,$path)=unpack('a1 x1 a*',$dir);
      $path=~tr/\\/\//;
      if ($cmd_handle) {
         $folder=$cmd_handle->{_cygdrive}.'/'.lc($drive).$path.'/';
      } else {
         $folder=$Net::FullAuto::FA_lib::localhost->{_cygdrive}.'/'.
                 lc($drive).$path.'/';
      }
   } else {
      my $die="Cannot Locate Directory $folder\n"
             ."       Anywhere on Local $base_or_dest Host "
             ."$Net::FullAuto::FA_lib::Local_HostName\n";
      &Net::FullAuto::FA_lib::handle_error($die);
   }
   if (wantarray) {
      return $folder,$dir
   } else { return $folder }

}

sub move_tarfile
{
print "MOVE_TARFILECALLER=",caller,"\n";
   my ($baseFH,$btransfer_dir,$destFH,$shortcut)=@_;
   my $dest_fdr=$destFH->{_work_dirs}->{_cwd};
   my $output='';my $stderr='';my $bprxFH='';
   my $dprxFH='';my $d_fdr='';my $trandir_parent='';
   my $phost= $baseFH->{_hostlabel}->[1]?
              $baseFH->{_hostlabel}->[1]:
              $baseFH->{_hostlabel}->[0];
   if ($destFH->{_hostlabel}->[0] eq "__Master_${$}__") {
      if ($destFH->{_work_dirs}->{_tmp}) {  # DEST-Master has trandir
         ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,
            "lcd \"$destFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         $d_fdr=$Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{lcd}=
            $destFH->{_work_dirs}->{_tmp};
      } else {
         ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,"lcd \"$dest_fdr\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
         $d_fdr=$Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{lcd}=$dest_fdr;
      }
      if ($baseFH->{_work_dirs}->{_tmp}) { # If BASE has remote trandir
                                           # cd ftp handle to it
         ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,
            "cd $baseFH->{_work_dirs}->{_tmp}");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      } else {
         ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,
            "cd $baseFH->{_work_dirs}->{_cwd}");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      }
      ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,
         "get transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
   } elsif ($baseFH->{_hostlabel}->[0] eq "__Master_${$}__" ||
         ($Net::FullAuto::FA_lib::DeploySMB_Proxy[0] eq "__Master_${$}__"
         && (exists $baseFH->{_smb}))) {
      if ($baseFH->{_work_dirs}->{_tmp} &&
            exists $baseFH->{_ftp_handle}) {
         ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
               "lcd \"$baseFH->{_work_dirs}->{_tmp}\"");
         $Net::FullAuto::FA_lib::ftpcwd{$baseFH->{_ftp_handle}}{lcd}=
            $baseFH->{_work_dirs}->{_tmp};
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
      }
      if ($destFH->{_work_dirs}->{_tmp}) {               # If DEST has trandir
         ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
            "cd \"$destFH->{_work_dirs}->{_tmp}\""); # cd ftp handle to trandir
         $d_fdr="$destFH->{_work_dirs}->{_tmp}/";
         if (exists $destFH->{_smb}) { # If DEST needs SMB
            ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
               "mkdir \"transfer$Net::FullAuto::FA_lib::tran[3]\""); # Add tmp 'transfer' dir
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
            $Net::FullAuto::FA_lib::tran[4]=1;
            ($output,$stderr)=
               &Rem_Command::ftpcmd($destFH, # cd ftp handle to 'transfer'
               "cd \"transfer$Net::FullAuto::FA_lib::tran[3]\"");
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
            $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{cd}
                                      ="transfer$Net::FullAuto::FA_lib::tran[3]";
            $d_fdr.="transfer$Net::FullAuto::FA_lib::tran[3]";
         }
      } else {                                   # No trandir on DEST,
         ($output,$stderr)=&Rem_Command::ftpcmd( # use $dest_fdr for transfer
            $destFH,"cd \"$dest_fdr\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{cd}
            =$d_fdr=$dest_fdr;
      }
      ($output,$stderr)=&Rem_Command::ftpcmd( # Transfer the tar file
         $destFH,"!id");                      # 'put' because DEST is remote
print $Net::FullAuto::FA_lib::MRLOG "TRYING TO DO PUT TWO\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "TRYING TO DO PUT TWO\n";
      ($output,$stderr)=&Rem_Command::ftpcmd( # Transfer the tar file
         $destFH,                             # 'put' because DEST is remote
         "put transfer$Net::FullAuto::FA_lib::tran[3].tar");
      if (-1<index "$output","permissions do not") {
         &Net::FullAuto::FA_lib::handle_error($output,'-1');
         die "$output       $!"
      }
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      if ($baseFH->{_work_dirs}->{_tmp}) {
         ($output,$stderr)=&Rem_Command::ftpcmd(
            $destFH,                           # lcd ftp handle back to parent
            "lcd \"$baseFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
print "WE ARE PUTTING LCD OF DEST3=$baseFH->{_work_dirs}->{_tmp}\n";
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{lcd}
            =$baseFH->{_work_dirs}->{_tmp};
      }
   } elsif (&ftm_connect($destFH,$phost)) {
print "WHAT THE FLIP ARE WE DOING HERE!!!!!!!!!!!!!\n";<STDIN>;
      my %ftp=(
         _ftp_handle => $destFH->{_cmd_handle},
         _ftm_type   => $destFH->{_ftm_type},
         _hostname   => $destFH->{_hostname},
         _ip         => $destFH->{_ip},
         _uname      => $destFH->{_uname},
         _luname     => $baseFH->{_uname},
         _hostlabel  => [ $destFH->{_hostlabel}->[0],$phost ],
         _ftp_pid    => $destFH->{_ftp_pid}
      );
      if ($destFH->{_uname} ne 'cygwin' ||
            $dest_fdr!~/^[\/|\\][\/|\\]/ ||
            !$destFH_>{_ms_share} || !$#{$destFH->{_hostlabel}}) {
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,"lcd \"$dest_fdr\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
print "SAVING LCD PATH OF DEST2=transfer$Net::FullAuto::FA_lib::tran[3]\n";
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{lcd}
            =$d_fdr=$dest_fdr;
      } else {

      #if (exists $destFH->{_smb}) {
#print "XXXXXAAAAA\n";
         if ($destFH->{_work_dirs}->{_tmp}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
               "lcd \"$destFH->{_work_dirs}->{_tmp}\"");
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
            $d_fdr="$destFH->{_work_dirs}->{_tmp}/";
         }
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
            "!mkdir transfer$Net::FullAuto::FA_lib::tran[3]");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         $Net::FullAuto::FA_lib::tran[4]=1;
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
            "lcd transfer$Net::FullAuto::FA_lib::tran[3]");
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{lcd}
            ="transfer$Net::FullAuto::FA_lib::tran[3]";
         $d_fdr.="transfer$Net::FullAuto::FA_lib::tran[3]";
      } #else {
#print "XXXXXBBBBB\n";
#         ($output,$stderr)=&ftp(\%ftp,'',"lcd \"$dest_fdr\"");
#         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
#               (-1==index $stderr,'command success');
#print "SAVING LCD PATH OF DEST2=transfer$Net::FullAuto::FA_lib::tran[3]\n";
#         #$Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}->{_cmd_handle}}{lcd}
#         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{lcd}
#                                      =$d_fdr=$dest_fdr;
#      }
      if ($baseFH->{_work_dirs}->{_tmp}) {
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
            "cd \"$baseFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         my ($output,$stderr)=$baseFH->cwd(
            $baseFH->{_work_dirs}->{_tmp});
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{cd}
                                       =$baseFH->{_work_dirs}->{_tmp};
      } else {
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
            "cd \"$baseFH->{_work_dirs}->{_cwd}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{cd}
                ="$baseFH->{_work_dirs}->{_cwd}";
      }
print "GOING TO GET THE TAR AND BRING IT TO DESTTTTTTTTTTTTTTTTT\n";
      ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
            "get transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      my $prompt = '_funkyPrompt_';
      $destFH->{_cmd_handle}->prompt("/$prompt\$/");
      $destFH->{_cmd_handle}->print('bye');
      while (my $line=$destFH->{_cmd_handle}->get) {
print "GETTING BACK THE CMD FROM FTP LINE=$line\n";
         last if $line=~/_funkyPrompt_/s;
      }
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      DH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                    {$sid}}) {
               if ($destFH->{_cmd_handle}
                     eq ${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[0]) {
                  my $value=$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type};
                  delete
                     $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                  substr($type,0,3)='cmd';
                  $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                      $value;
                  last DH;
               }
            }
         }
      }
   } elsif ($Net::FullAuto::FA_lib::DeployFTM_Proxy[0] eq "__Master_${$}__" ||
         exists $Net::FullAuto::FA_lib::same_host_as_Master{
         $Net::FullAuto::FA_lib::DeployFTM_Proxy[0]}) {
      if ($baseFH->{_work_dirs}->{_tmp}) {
         #($output,$stderr)=&Rem_Command::ftpcmd(\%bftp,
         ($output,$stderr)=&Rem_Command::ftpcmd($baseFH,
            "cd \"$baseFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         ($stdout,$stderr)=$baseFH->cmd(
            "cd \"$baseFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_cmd_handle}}{cd}
            =$baseFH->{_work_dirs}->{_tmp};
      }
      ($output,$stderr)=&Rem_Command::ftpcmd(
         $baseFH,"get transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      if (exists $destFH->{_smb}) {
         if ($destFH->{_work_dirs}->{_tmp}) {
            #($output,$stderr)=&ftp(\%dftp,'',
            ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
               "cd \"$destFH->{_work_dirs}->{_tmp}\"");
            &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
            $d_fdr="$destFH->{_work_dirs}->{_tmp}/";
         }
         ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
            "mkdir transfer$Net::FullAuto::FA_lib::tran[3]");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         $Net::FullAuto::FA_lib::tran[4]=1;
         $d_fdr.=transfer$Net::FullAuto::FA_lib::tran[3];
      } else {
         $d_fdr=$destFH->{_work_dirs}->{_cwd};
      }
      #($output,$stderr)=&ftp(\%dftp,'',"cd $d_fdr");
      ($output,$stderr)=&Rem_Command::ftpcmd($destFH,"cd $d_fdr");
      if ($stderr && -1==index $stderr,'command success') {
         my $die="The System $destFH->{_hostlabel}->[0]"
                ." Returned\n              the Following "
                ."Unrecoverable Error "
                ."Condition :\n\n       $stderr";
         &Net::FullAuto::FA_lib::handle_error($die);
      } $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{cd}=$d_fdr;
      my $putoutput='';
      ($putoutput,$stderr)=&Rem_Command::ftpcmd($destFH,
         "put transfer$Net::FullAuto::FA_lib::tran[3].tar");
         #&ftp($destFH,'',"put transfer$Net::FullAuto::FA_lib::tran[3].tar");
      if (-1<index $putoutput,"Couldn't get handle: Permission denied") {
         my $die="The System $destFH->{_hostlabel}->[0]"
                ." Returned\n              the Following "
                ."Unrecoverable Error "
                ."Condition :\n\n       "
                ."Couldn't get handle: Permission denied";
         ($output,$stderr)=$destFH->cwd('/tmp');
         &Net::FullAuto::FA_lib::handle_error("$die\n\n       $stderr",'-1') if $stderr;
         ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
            "put transfer$Net::FullAuto::FA_lib::tran[3].tar"); 
            #&ftp($destFH,'',"put transfer$Net::FullAuto::FA_lib::tran[3].tar");
         &Net::FullAuto::FA_lib::handle_error("$die\n\n       $stderr",'-1') if $stderr &&
               (-1==index $stderr,'command success');
         ($output,$stderr)=$destFH->cmd(
            "mv transfer$Net::FullAuto::FA_lib::tran[3].tar $d_fdr");
         &Net::FullAuto::FA_lib::handle_error("$die\n\n       $stderr",'-1') if $stderr;
         ($output,$stderr)=$destFH->cwd($d_fdr);
         &Net::FullAuto::FA_lib::handle_error("$die\n\n       $stderr",'-1') if $stderr;
      } elsif ($stderr && -1==index $stderr,'command success') {
         my $die="The System $destFH->{_hostlabel}->[0]"
                ." Returned\n              the Following "
                ."Unrecoverable Error "
                ."Condition :\n\n       $stderr";
         &Net::FullAuto::FA_lib::handle_error($die);
      }
   } elsif ($Net::FullAuto::FA_lib::DeployFTM_Proxy[0]) {
print "IM HERE THIS\n";
      ($bprxFH,$stderr)=
           Rem_Command::new('Rem_Command',
           $Net::FullAuto::FA_lib::DeployFTM_Proxy[0],$_connect);
      &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
      my %bprx=(
         _cmd_handle => $bprxFH,
      );
      &ftm_connect(\%bprx,$phost);
      my %bftp=(
         _ftp_handle => $bprx->{_cmd_handle},
         _ftm_type   => $bprx->{_ftm_type},
         _hostname   => $bprx->{_hostname},
         _ip         => $bprx->{_ip},
         _uname      => $bprx->{_uname},
         _luname     => $baseFH->{_uname},
         _hostlabel  => [ $Net::FullAuto::FA_lib::DeployFTM_Proxy[0],'' ],
         _ftp_pid    => $bprx->{_cmd_pid}
      );my $btrandir='';
      if ($btransfer_dir) {
         if (unpack('@1 a1',"$btransfer_dir") eq ':') {
            my ($drive,$path)=unpack('a1 x1 a*',$btransfer_dir);
            $path=~tr/\\/\//;
            $btrandir=$baseFH->{_cygdrive}.'/'.lc($drive).$path.'/';
         } elsif (substr($btransfer_dir,-1) ne '/') {
            $btrandir.='/';
         }
         ($output,$stderr)=&Rem_Command::ftpcmd(
         #($output,$stderr)=&ftp(\%bftp,'',
            \%bftp,"cd \"$btrandir\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         $Net::FullAuto::FA_lib::ftpcwd{$bprx{_cmd_handle}}{cd}=$btrandir;
      } elsif ($baseFH->{_work_dirs}->{_tmp}) {
         #($output,$stderr)=&ftp(\%bftp,'',"cd $baseFH->{_work_dirs}->{_tmp}");
         ($output,$stderr)=&Rem_Command::ftpcmd(
            \%bftp,"cd $baseFH->{_work_dirs}->{_tmp}");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
               (-1==index $stderr,'command success');
         $Net::FullAuto::FA_lib::ftpcwd{$bprx{_cmd_handle}}{cd}=
            $baseFH->{_work_dirs}->{_tmp};
      } else {
         #($output,$stderr)=&ftp(\%bftp,'',
         ($output,$stderr)=&Rem_Command::ftpcmd(\%bftp,
            "cd \"$baseFH->{_work_dirs}->{_cwd}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
         $Net::FullAuto::FA_lib::ftpcwd{$bprx->{_cmd_handle}}{cd}=
            $baseFH->{_work_dirs}->{_cwd};
      } 
      #($output,$stderr)=&ftp(\%bftp,'',"get transfer$Net::FullAuto::FA_lib::tran[3].tar");
      ($output,$stderr)=&Rem_Command::ftpcmd(\%bftp,
         "get transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      my $prompt = '_funkyPrompt_';
      $bprx{_cmd_handle}->prompt("/$prompt\$/");
      $bprx{_cmd_handle}->cmd('bye');
      BPH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                    {$sid}}) {
               if ($bprx{_cmd_handle}
                     eq ${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[0]) {
                  my $value=$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type};
                  delete
                     $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                  substr($type,0,3)='cmd';
                  $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                      $value;
                  last BPH;
               }
            }
         }
      }
      ($dprxFH,$stderr)=
            Rem_Command::new('Rem_Command',
            $Net::FullAuto::FA_lib::DeployFTM_Proxy[0],$_connect);
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      my %dprx=(
         _cmd_handle => $dprxFH,
      );
      &ftm_connect(\%dprx,$destFH->{_hostlabel}->[0]);
      my %dftp=(
         _ftp_handle => $dprx->{_cmd_handle},
         _ftm_type   => $dprx->{_ftm_type},
         _hostname   => $dprx->{_hostname},
         _ip         => $dprx->{_ip},
         _uname      => $dprx->{_uname},
         _luname     => $destFH->{_uname},
         _hostlabel  => [ $Net::FullAuto::FA_lib::DeployFTM_Proxy[0],'' ],
         _ftp_pid    => $dprx->{_cmd_pid}
      );
      #($output,$stderr)=&ftp(\%dftp,'',
      ($output,$stderr)=&Rem_Command::ftpcmd(
         \%dftp,"cd \"$dest_fdr\"");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
         (-1==index $stderr,'command success');
      $Net::FullAuto::FA_lib::ftpcwd{$dprx{_cmd_handle}}{cd}
         =$d_fdr=$dest_fdr;
print $Net::FullAuto::FA_lib::MRLOG "TRYING TO DO PUT ONE\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "TRYING TO DO PUT ONE\n";
      #($output,$stderr)=&ftp(\%dftp,'',"put transfer$Net::FullAuto::FA_lib::tran[3].tar");
      ($output,$stderr)=&Rem_Command::ftpcmd(
         \%dftp,"put transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr &&
            (-1==index $stderr,'command success');
      $dprx{_cmd_handle}->prompt("/$prompt\$/");
      $dprx{_cmd_handle}->cmd('bye');
      DPH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                    {$sid}}) {
               if ($dprx{_cmd_handle}
                     eq ${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[0]) {
                  my $value=$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type};
                  delete
                     $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                  substr($type,0,3)='cmd';
                  $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                     $value;
                  last DPH;
               }
            }
         }
      }
   } else {
      &Net::FullAuto::FA_lib::handle_error("NO FTP PROXY DEFINED");
   }
my $shownow="NOW HERE SO THERE and FTPProxy=$Net::FullAuto::FA_lib::DeployFTM_Proxy[0] and "
      .(exists $Net::FullAuto::FA_lib::same_host_as_Master{"$Net::FullAuto::FA_lib::DeployFTM_Proxy[0]"})."\n";
#print "SHOWWWWWWWWWWWWWWWWW=$shownow\n";
#print $Net::FullAuto::FA_lib::MRLOG $shownow if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "HOSTNAME FOR DEST=",$destFH->cmd('hostname'),"\n";
#print "THISHOSTNAME FOR DEST=",$destFH->cmd('hostname'),"\n";
#print "D_FDR=$d_fdr<== and DEST_FDR=$dest_fdr<==\n";<STDIN>;
   if ($d_fdr eq $dest_fdr) {
      ($output,$stderr)=$destFH->cwd(  # cd cmd handle to folder
          $d_fdr);                     # that now has tar file
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      my $tdr='';
      my $testf=&Net::FullAuto::FA_lib::test_file($destFH->{_cmd_handle},
         "transfer$Net::FullAuto::FA_lib::tran[3].tar");
      if ($testf ne 'WRITE' && $testf ne 'READ') {
         $tdr=$destFH->{_work_dirs}->{_tmp}
            if $destFH->{_work_dirs}->{_tmp};
      }
      ($output,$stderr)=
         $destFH->cmd(
         "chmod 755 ${tdr}transfer$Net::FullAuto::FA_lib::tran[3].tar", # chmod it
            '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      ($output,$stderr)=
         $destFH->cmd(
         "tar xovf ${tdr}transfer$Net::FullAuto::FA_lib::tran[3].tar", # un-tar it
            '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
print "WHAT IS THE SHORTCUT HERE=$shortcut\n";sleep 6;
      if (!$shortcut) {
         foreach my $file (keys %Net::FullAuto::FA_lib::rename_file) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::rename_file{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      } else {
         foreach my $file (keys %Net::FullAuto::FA_lib::renamefile) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::renamefile{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      }
      ($output,$stderr)=
         $destFH->cmd(
         "rm ${tdr}transfer$Net::FullAuto::FA_lib::tran[3].tar"); # delete tar file
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
   } elsif (exists $destFH->{_smb}) {
      ($output,$stderr)=$destFH->cwd(  # cd cmd handle to folder
          $d_fdr);                     # that is the un-tar target
      $Net::FullAuto::FA_lib::tran[2]=1 if $Net::FullAuto::FA_lib::tran[4];
      &Net::FullAuto::FA_lib::handle_error($stderr,'-3') if $stderr;
      my $tdr='';
      my $testf=&Net::FullAuto::FA_lib::test_file($destFH->{_cmd_handle},
         "transfer$Net::FullAuto::FA_lib::tran[3].tar");
      if ($testf ne 'WRITE' && $testf ne 'READ') {
         $tdr="$destFH->{_work_dirs}->{_tmp}/"
            if $destFH->{_work_dirs}->{_tmp};
      }
      my $dtr=($destFH->{_hostlabel}->[0] ne "__Master_${$}__") ? $d_fdr
          : $destFH->{_work_dirs}->{_tmp};
      ($output,$stderr)=
         $destFH->cmd(
         "chmod 755 ${tdr}transfer$Net::FullAuto::FA_lib::tran[3].tar", # chmod it
            '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      ($output,$stderr)=
          $destFH->cmd(
             "tar xovf $dtr/transfer$Net::FullAuto::FA_lib::tran[3].tar",     # un-tar it
                '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-3') if $stderr;
      if (!$shortcut) {
         foreach my $file (keys %Net::FullAuto::FA_lib::rename_file) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::rename_file{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      } else {
         foreach my $file (keys %Net::FullAuto::FA_lib::renamefile) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::renamefile{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      }
      if ($Net::FullAuto::FA_lib::tran[4]) {
         ($output,$stderr)=&Rem_Command::ftpcmd($destFH,
            "cd \"$destFH->{_work_dirs}->{_tmp}\"");
         &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         $Net::FullAuto::FA_lib::ftpcwd{$destFH->{_ftp_handle}}{cd}
            =$destFH->{_work_dirs}->{_tmp};
         ($output,$stderr)=
            $destFH->cwd($destFH->{_work_dirs}->{_tmp});
         &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         $Net::FullAuto::FA_lib::tran[2]=0;
      }
      ($output,$stderr)=
         $destFH->cmd("rm $dtr/transfer$Net::FullAuto::FA_lib::tran[3].tar"); # delete
                                                               # tar file
      &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
   } else {
      ($output,$stderr)=$destFH->cwd(  # cd cmd handle to dest folder
          $dest_fdr);
      &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
      my $tdr='';
      my $testf=&Net::FullAuto::FA_lib::test_file($destFH->{_cmd_handle},
         "transfer$Net::FullAuto::FA_lib::tran[3].tar");
print "TESTF=$testf<===\n";#<STDIN>;
      if ($testf ne 'WRITE' && $testf ne 'READ') {
         $tdr="$destFH->{_work_dirs}->{_tmp}/"
            if $destFH->{_work_dirs}->{_tmp};
      }
      ($output,$stderr)=
         $destFH->cmd(
         "chmod 777 ${tdr}transfer$Net::FullAuto::FA_lib::tran[3].tar", # chmod it
            '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      ($output,$stderr)=                        # un-tar it
          $destFH->cmd("tar xovf $d_fdr/transfer$Net::FullAuto::FA_lib::tran[3].tar",
                       '__debug__');
      &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
      if (!$shortcut) {
         foreach my $file (keys %Net::FullAuto::FA_lib::rename_file) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::rename_file{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      } else {
         foreach my $file (keys %Net::FullAuto::FA_lib::renamefile) {
            my $cmd="mv \"$file\" \"$Net::FullAuto::FA_lib::renamefile{$file}\"";
            my ($output,$stderr)=$destFH->cmd($cmd);
            $Net::FullAuto::FA_lib::savetran=1 if $stderr;
            &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
         }
      }
      ($output,$stderr)=$destFH->cmd(  # delete tar file
                            "rm $d_fdr/transfer$Net::FullAuto::FA_lib::tran[3].tar");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
   }
print "ANYTHING FALLING THRROUGH BOTTOM and $destFH->{_work_dirs}->{_cwd}\n";
}

sub ftm_connect
{
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }
   my @topcaller=caller;
   print "ftm_connect() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "ftm_connect() CALLER=",
      (join ' ',@topcaller)," and HOSTLABEL=$_[1]\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $ftpFH=$_[0];my $hostlabel=$_[1];$_connect=$_[2]||'';
   my $ftm_type='';my $ftm_passwd='';
   my $output='';my $stderr='';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
      $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
      $owner,$group,$fctimeout,$transfer_dir,$rcm_chain,
      $rcm_map,$uname,$ping,$freemem)
      =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my @connect_method=@{$ftr_cnct};
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $fctimeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (!$fctimeout) {
      $fctimeout=$timeout if !$fctimeout;
   }
   my @hosts=();
   if ($use eq 'ip') {
      @hosts=($hostname,$ip);
   } else {
      @hosts=($ip,$hostname);
   } my $host='';
   if ($ping) {
      while (1) {
         my $error=0;
         eval {
            while ($host=pop @hosts) {
               $ftpFH->{_cmd_handle}->print("${pingpath}ping $host");
               while (my $line=
                     $ftpFH->{_cmd_handle}->get(
                     Timeout=>5)) {
                  if ($line=~/ from /s) {
print "TEN003\n";
                     $ftpFH->{_cmd_handle}->print("\003");
                     while (my $ln=$ftpFH->{_cmd_handle}->get) {
                        last if $ln=~/_funkyPrompt_$/s;
                     } return;
                  } elsif (-1<index $line,'NOT FOUND'
                        || -1<index $line,'Bad IP') {
                     if ($line=~/_funkyPrompt_$/s) {
                        $error=1;return;
                     }
                  }
               }
            }
         };
         if ($@) {
            next if $error;
            if (-1<index $@,'read timed-out') {
print "ELEVEN003\n";
               $ftpFH->{_cmd_handle}->print("\003");
               while (my $ln=$ftpFH->{_cmd_handle}->get) {
                  last if $ln=~/_funkyPrompt_$/s;
               } return 0;
            } elsif ((-1<index $@,'read error') ||
                     (-1<index $@,'filehandle isn')) {
print $Net::FullAuto::FA_lib::MRLOG "ftm_connect::cmd() HAD TO DO LOGIN_RETRY".
   " for $ftpFH->{_cmd_handle} and HOSTLABEL=$ftpFH->{_hostlabel}->[0] and $ftpFH->{_hostlabel}->[1]\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ($ftpFH->{_cmd_handle}->{_cmd_handle},$stderr)=
                  &Rem_Command::login_retry(
                  $ftpFH->{_cmd_handle},$@);
               if ($stderr) {
                  $stderr="$@\n       $stderr";
                  return 0;
               } elsif (!$ftpFH->{_cmd_handle}) {
                  return 0;
               }
               ($output,$stderr)=$ftpFH->{_cmd_handle}->cmd(
                  "cd $ftpFH->{_work_dirs}->{_cwd}");
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            } else { &Net::FullAuto::FA_lib::handle_error($@) }
         } elsif ($error) {
            $error=0;next;
         } last;
      }
   } elsif ($use eq 'ip') {
      $host=$ip
   } else { $host=$hostname }
   if ($su_id) {
      $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
         $hostlabel,$su_id,$ms_share,
         $ftm_errmsg,'__su__');
print $Net::FullAuto::FA_lib::MRLOG "ftm_connect::cmd() BACK FROM PASSWD=$ftm_passwd<==\n";
#.
#   " for $ftpFH->{_cmd_handle} and HOSTLABEL=$ftpFH->{_hostlabel}->[0] and $ftpFH->{_hostlabel}->[1]\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      if ($ftm_passwd ne 'DoNotSU!') {
         $su_login=1;
      } else { $su_id='' }
   }
   if (!$su_id) {
      $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
         $hostlabel,$login_id,
         $ms_share,$ftm_errmsg);
   }
   $ftpFH->{_cmd_handle}->timeout($fctimeout);
   WE: while (1) {
      my $fm_cnt=-1;
      foreach my $connect_method (@connect_method) {
         $fm_cnt++;
         if (lc($connect_method) eq 'ftp') {
            $ftm_type='ftp';
            my ($ignore,$stderr)
               =&Net::FullAuto::FA_lib::clean_filehandle($ftpFH->{_cmd_handle});
            if ($stderr && $stderr=~/Connection closed/) {
print $Net::FullAuto::FA_lib::MRLOG "ftm_connect::cmd() HAD TO DO FTP LOGIN_RETRY".
   " for $ftpFH->{_cmd_handle} and HOSTLABEL=$ftpFH->{_hostlabel}->[0] and $ftpF
H->{_hostlabel}->[1]\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ($ftpFH->{_cmd_handle},$stderr)
                  =&Rem_Command::login_retry(
                  $ftpFH->{_cmd_handle},$stderr);
               &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               @connect_method=();
               @connect_method=@{$ftr_cnct};
               next WE;
            }
            my $showftp=
               "\n\tLoggingG into $host via ftp  . . .\n\n";
            print $showftp if (!$Net::FullAuto::FA_lib::cron
               || $Net::FullAuto::FA_lib::debug)
               && !$Net::FullAuto::FA_lib::quiet;
            print $Net::FullAuto::FA_lib::MRLOG $showftp
               if $Net::FullAuto::FA_lib::log
               && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $ftpFH->{_cmd_handle}->print(
               "${Net::FullAuto::FA_lib::ftppath}ftp $host");
            FP: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
               foreach my $sid (
                     keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                  foreach my $type (
                        keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                        {$sid}}) {
                     if ($ftpFH->{_cmd_handle}
                           eq ${$Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}{$type}}[0]) {
                        my $value=$Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type};
                        delete $Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}{$type};
                        substr($type,0,3)='ftm';
                        $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}
                           =$value;
                        last FP;
                     }
                  }
               }
            }
            my $lin='';$stderr='';
            eval {
               while (my $line=$ftpFH->{_cmd_handle}->get) {
                  my $tline=$line;
                  $tline=~s/Name.*$//s;
                  $lin.=$line; 
                  print $tline if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                  print $Net::FullAuto::FA_lib::MRLOG $tline
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($lin=~/Name.*[: ]+$/si) {
                     $ftr_cmd='ftp';last;
                  }
                  $stderr.=$line;
                  if ($lin=~/s*ftp> ?$/s) {
                     $stderr=~s/^(.*?)(\012|\013)+//s;
                     $stderr=~s/s*ftp> ?$//s;
                     last;
                  }
               }
            };
            if ($@) {
               $ftpFH->{_cmd_handle}->print('bye');
               &Net::FullAuto::FA_lib::clean_filehandle($ftpFH->{_cmd_handle}); 
               return 0;
            }

            if ($su_id) {
               $ftpFH->{_cmd_handle}->print($su_id);
            } else {
               $ftpFH->{_cmd_handle}->print($login_id);
            }

            ## Wait for password prompt.
            ($ignore,$stderr)=&wait_for_ftr_passwd_prompt(
               $ftpFH);
            if ($stderr) {
print "WE GOT FTPPPPPPSTDERRRRR=$stderr<==\n";
               $ftpFH->{_cmd_handle}->print;
               $ftpFH->{_cmd_handle}->print('bye');
while (my $line=$ftpFH->{_cmd_handle}->get) {
print "STDERRRRLINE=$line<==\n";
   last if $line=~/_funkyPrompt_/s;
}
print "YES WE GOT OUT AND ARE NOT GOING TO CLEAN<==\n";
               &Net::FullAuto::FA_lib::clean_filehandle($ftpFH->{_cmd_handle});
print "GOOD _ DONE WITH CLEANING\n";
               if ((-1<index $stderr,'read timed-out') ||
                     (-1<index $stderr,'Connection closed')) {
print "YEA WE GOT HERE!!!!!!!!!!!!!!!!!!!!!!\n";
                  return 0;
               } elsif ($fm_cnt==$#{$ftr_cnct}) {
print "WE ARE RETURNING THE FOLLOWING ERROR=$stderr<==\n";
                  return 0;
               } else { next }
            }
            $ftm_type='ftp';last;

         } elsif (lc($connect_method) eq 'sftp') {
            my ($ignore,$stderr)
               =&Net::FullAuto::FA_lib::clean_filehandle($ftpFH->{_cmd_handle});
################# CESSNA
         #if (1) {
            if ($stderr && $stderr=~/Connection closed/) {
print "YEP GOT TO LOGIN_RETRY<==\n";
print $Net::FullAuto::FA_lib::MRLOG "ftm_connect::cmd() HAD TO DO SFTP LOGIN_RETRY".
   " for $ftpFH->{_cmd_handle} and HOSTLABEL=$ftpFH->{_hostlabel}->[0] and $ftpFH->{_hostlabel}->[1]\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ($ftpFH->{_cmd_handle},$stderr)
                  =&Rem_Command::login_retry(
                  $ftpFH->{_cmd_handle},$stderr);
               &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               @connect_method=();
               @connect_method=@{$ftr_cnct};
               next WE;
            }
            $ftm_type='sftp';
            my $showsftp=
               "\n\tLoggingH into $host via sftp  . . .\n\n";
            print $showsftp if (!$Net::FullAuto::FA_lib::cron
               || $Net::FullAuto::FA_lib::debug)
               && !$Net::FullAuto::FA_lib::quiet;
            print $Net::FullAuto::FA_lib::MRLOG $showsftp
               if $Net::FullAuto::FA_lib::log
               && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "SU_IDDDDDDDDDDDDDDD=$su_id and FTHH=$ftpFH and CH=$ftpFH->{_cmd_handle}<==\n";
            if ($su_id) {
               $ftpFH->{_cmd_handle}->print( 
                  "${Net::FullAuto::FA_lib::sftppath}sftp $su_id\@$host");
            } else {
               $ftpFH->{_cmd_handle}->print(
                  "${Net::FullAuto::FA_lib::sftppath}sftp $login_id\@$host");
            }

            ## Wait for password prompt.
            ($ignore,$stderr)=&wait_for_ftr_passwd_prompt(
               $ftpFH);
print "FTM_CONNECT_ERRORRRRRRRR======$stderr<==\n";
            if ($stderr) {
            #$ftpFH->{_cmd_handle}->print("\004");
               &Net::FullAuto::FA_lib::clean_filehandle($ftpFH->{_cmd_handle});             
               if ((-1<index $stderr,'read timed-out') ||
                     (-1<index $stderr,'Connection closed')) {
print "YEA WE GOT HERE!!!!!!!!!!!!!!!!!!!!!!\n";
                  return 0;
               } elsif ($fm_cnt==$#{$ftr_cnct}) {
                  return 0;
               } else { next }
            }

            SP: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
               foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                  foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                          {$sid}}) {
                     if ($ftpFH->{_cmd_handle}
                           eq ${$Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}}[0]) {
                        my $value=$Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type};
                        delete $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                        substr($type,0,3)='ftm';
                        $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                           $value;
                        last SP;
                     }
                  }
               }
            }

            $ftm_type='sftp';last;

         }
      } last;
   }
print "OUT OF WAITING FOR PASSWORD\n";
   my $die='';my $die_login_id='';my $ftm_errmsg='';
   my $su_login='';my $retrys=0;
   my %ftp=();
   while (1) {
      eval {
         %ftp=(
            _ftp_handle => $ftpFH->{_cmd_handle},
            _ftm_type   => $ftm_type,
            _hostname   => $hostname,
            _ip         => $ip,
            _hostlabel  => [ $hostlabel, $ftpFH->{_hostlabel}->[0] ],
            _uname      => $uname,
            _luname     => $ftpFH->{_uname},
            _ftp_pid    => $ftpFH->{_ftp_pid}
         );
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,$ftm_passwd);
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
print "I AM GOING TO TRY AND DO THE PROMPT\n";
eval {
         $ftpFH->{_cmd_handle}->prompt("/s*ftp> ?\$/");
};
print "GOT PAST THE PROMPT and EVALERR=$@\n";

################## MAKE NEW SUBROUTINE START HERE
         $lin='';$asked=0;
         while (1) {
            $ftpFH->{_cmd_handle}->print;
            while (my $line=$ftpFH->{_cmd_handle}->get) {
print "LOOKING FOR FTPPROMPTLINE12=$line<==\n";
#print $Net::FullAuto::FA_lib::MRLOG "LOOKING FOR FTPPROMPTLINE12=$line<==\n"
      #if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               chomp($line=~tr/\0-\11\13-\37\177-\377//d);
               $lin.=$line;
               if ($lin=~/Perm/s && $lin=~/password[: ]+$/si) {
                  if ($su_id) {
                     if (!$asked++) {
                        my $error='';
                        ($error=$lin)=~s/^\s*(.*)\n.*$/$1/s;
                        my $banner="\n    The Host \"$hostlabel\" is "
                                  ."configured to attempt a su\n    with "
                                  ."the ID \'$su_id\'\; however, the first "
                                  ."attempt\n    resulted in the following "
                                  ."Error :\n\n           $error\n\n    It "
                                  ."may be that sftp is configured to "
                                  ."disallow logins\n    with \'$su_id\'\."
                                  ."\n\n    Please Pick an Operation :\n"
                                  ."\n    NOTE:    Choice will affect all "
                                  ."future logins!\n";
                        $choices[0]="Re-enter password and re-attempt with "
                                   ."\'$su_id\'";
                        $choices[1]="Attempt login with base id \'$login_id\'";
                        my $choice=&Menus::pick(\@choices,$banner);
                        chomp $choice;
                        if ($choice ne ']quit[') {
                           if ($choice=~/$su_id/s) {
                              my $show='';
                              ($show=$lin)=~s/^.*?\n(.*)$/$1/s;
                              while (1) {
                                 print $Net::FullAuto::FA_lib::blanklines;
                                 #print $Net::FullAuto::FA_lib::clear,"\n";
                                 print "\n$show ";
                                 my $newpass=<STDIN>;
                                 chomp $newpass;
                                 $ftpFH->{_cmd_handle}->print($answer);
                                 print $Net::FullAuto::FA_lib::MRLOG $show
                                    if $Net::FullAuto::FA_lib::log &&
                                    -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 $lin='';last;
                              }
                           } else {
                              &Net::FullAuto::FA_lib::su_scrub($hostlabel,$su_id,$cmd_type);
                              &Net::FullAuto::FA_lib::passwd_db_update(
                                 $hostlabel,$su_id,'DoNotSU!',
                                 $cmd_type);
print "TWELVE003\n";
                              $ftpFH->{_cmd_handle}->print("\003");
                              while (my $line=$ftpFH->{_cmd_handle}->get) {
print $Net::FullAuto::FA_lib::MRLOG "LLINE44=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 $line=~s/\s*$//s;
                                 last if $line=~/_funkyPrompt_$/s;
                                 last if $line=~/Killed by signal 2\.$/s;
                              }
                              $ftpFH->{_cmd_handle}->print(
                                 "${Net::FullAuto::FA_lib::sftppath}sftp $login_id\@$host");

                              ## Wait for password prompt.
                              ($ignore,$stderr)=
                                 &wait_for_ftr_passwd_prompt(
                                 $ftpFH);
                              if ($stderr) {
                                 if ($fm_cnt==$#{$ftr_cnct}) {
                                    return '',$stderr;
                                 } else { next }
                              }

                              ## Send password.
print "LIN=$lin<== and FTM_ERRMSG=$ftm_errmsg<==\n";
                              my $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                                 $hostlabel,$login_id,
                                 $ms_share,$ftm_errmsg,'','sftp');
                              $ftpFH->{_cmd_handle}->print($ftm_passwd);
                              my $showsftp=
                                 "\n\tLoggingI into $host via sftp  . . .\n\n";
                              print $showsftp if (!$Net::FullAuto::FA_lib::cron
                                 || $Net::FullAuto::FA_lib::debug)
                                 && !$Net::FullAuto::FA_lib::quiet;
                              print $Net::FullAuto::FA_lib::MRLOG $showsftp
                                 if $Net::FullAuto::FA_lib::log
                                 && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              last;
                           }
                        } else { 
                           &Net::FullAuto::FA_lib::cleanup();
                        }
                     } elsif ($asked<4) {
print "YESSSSSSS WE HAVE DONE IT FOUR TIMES22\n";<STDIN>;
                     }
                  } else {

                     ## Send password.
print "LIN=$lin<== and FTM_ERRMSG=$ftm_errmsg<==\n";<STDIN>;
                     my $showerr='';
                     ($showerr=$lin)=~s/^.*?\n(.*)$/$1/s;
                     $showerr=~s/^(.*)?\n.*$/$1/s;
                     $retrys++;
                     my $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
                        $hostlabel,$login_id,
                        $ms_share,$showerr,'','sftp','__force__');
print "PASSWORD=$ftm_passwd<== and LOGIN_ID=$login_id\n";
                     $ftpFH->{_cmd_handle}->print($ftm_passwd);
                     my $showsftp=
                        "\n\tLoggingJ into $host via sftp  . . .\n\n";
                     print $showsftp if (!$Net::FullAuto::FA_lib::cron
                        || $Net::FullAuto::FA_lib::debug)
                        && !$Net::FullAuto::FA_lib::quiet;
                     print $Net::FullAuto::FA_lib::MRLOG $showsftp
                        if $Net::FullAuto::FA_lib::log
                        && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $lin='';next;
                  }
               } elsif (!$authyes && (-1<index $lin,'The authen') &&
                     $lin=~/\?\s*$/s) {
                  my $question=$lin;
                  $question=~s/^.*(The authen.*)$/$1/s;
                  $question=~s/\' can\'t/\'\ncan\'t/s;
                  while (1) {
                     print $Net::FullAuto::FA_lib::blanklines;
                     #print $Net::FullAuto::FA_lib::clear,"\n";
                     print "\n$question ";
                     my $answer=<STDIN>;
                     chomp $answer;
                     if (lc($answer) eq 'yes') {
                        $ftpFH->{_cmd_handle}->print($answer);
                        print $Net::FullAuto::FA_lib::MRLOG $lin
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $authyes=1;$lin='';last;
                     } elsif (lc($answer) eq 'no') {
                        print $Net::FullAuto::FA_lib::MRLOG $lin
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        &Net::FullAuto::FA_lib::cleanup()
                     }
                  }
               }
               if ($line=~/[\$\%\>\#\-\:]+ ?$/m) {
                  $lin='';last;
               } elsif ($line=~/[\$\%\>\#\-\:]+ ?$/s) {
                  $lin='';last;
               } elsif ($lin=~/Perm/s) { last }
            }
            if ($lin=~/Perm/s) {
               $lin=~s/\s*//s;
               $lin=~s/^(.*)?\n.*$/$1/s;
               while (1) {
                  last if $previous_method eq $connect_method[0];
                  shift @connect_method;
               }
               die $lin;
            } else { last }
         }
################## MAKE NEW SUBROUTINE END HERE
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'binary')
            if $ftm_type ne 'sftp';
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      };
      if ($@=~/ogin incor/ && $retrys<2) {
         $retrys++;
	 if ($su_login) {
	    &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$su_id);
	    $die_login_id=$su_id;
	 } else {
	    &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$login_id);
	    $die_login_id=$login_id;
	 }
         $ftpFH->{_cmd_handle}->print('bye');
         while (my $line=$ftpFH->{_cmd_handle}->get) { 
	    last if $line=~/_funkyPrompt_$/s;
	 }
         $ftpFH->{_cmd_handle}->timeout($fctimeout);
         if ($cmd_type eq 'ftp') {
            $ftpFH->{_cmd_handle}->print("${Net::FullAuto::FA_lib::ftppath}ftp $host");
         } elsif ($ftm_type eq 'sftp') {
            if ($su_id) {
               $ftpFH->{_cmd_handle}->print(
                  "${Net::FullAuto::FA_lib::sftppath}sftp $su_id\@$host");
            } else {
               $ftpFH->{_cmd_handle}->print(
                  "${Net::FullAuto::FA_lib::sftppath}sftp $su_id\@$host");
            }
         }
         $ftpFH->{_cmd_handle}->
	       waitfor(-match => '/Name.*[: ]+$/i');
	 $@='';next;
      } elsif ($@) {
         my $f_t=$ftm_type;$f_t=~s/^(.)/uc($1)/e;
         $die="The System $host Returned\n              the "
             ."Following Unrecoverable Error Condition\,\n"
             ."              Rejecting the $f_t Login Attempt"
             ." of the ID\n              -> $die_login_id "
             ."at ".(caller(0))[1]." "
             ."line ".(caller(2))[2]." :\n\n       $@";
      } else { last }
   }
   if (defined $transfer_dir && $transfer_dir) {
      if (unpack('@1 a1',$transfer_dir) eq ':') {
         my ($drive,$path)=unpack('a1 @2 a*',$transfer_dir);
         $path=~tr/\\/\//;
         $transfer_dir="/cygdrive/$drive$path/";
      }
      my ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,"cd \"$transfer_dir\"");
      foreach my $line (split /^/, $output) {
         print $line if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
         print $Net::FullAuto::FA_lib::MRLOG $line
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         next if $line!~/^\d/;
         if (unpack('a3',$line)!=250) {
            my $warn="The FTP Service Cannot Change to "
                    ."the Transfer Directory"
                    ."\n\n       -> $line\n";
            warn "$warn       $!";return 0;
         }
      } $Net::FullAuto::FA_lib::ftpcwd{$ftpFH->{_cmd_handle}}{cd}=$transfer_dir;
   } return 1;

}

sub dup_Processes
{
   my $cmd_handle=$_[0];
   foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
      foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
         foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                 {$sid}}) {
            if ($cmd_handle
                  eq $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}) {
               return 1;
            }
         }
      }
   } return 0;
}

sub map_mirror
{
   my $mirrormap=$_[0];
   my $map='mirrormap';
   my @keys=split '/',"$_[1]";
   my $file="$_[3]";
   my $reason="$_[4]";
   my $num_of_levels=$#keys;
#print "REASON=$reason\n";
#print "KEYS=@keys\n";
#print "NUM_OF_LEVELS=$num_of_levels\n";
   if ($_[1] eq '/') {
      eval "\@{\${\$$map}[0]}[0,1,2]=(\'all\',\'/\',\'\')";
   } elsif ($file ne '') {
      if ("$_[2]" eq 'EXCLUDE') {
         eval "push \@{\${\${\$$map}[0]}[4]}, [ \"\$file\",\"\$reason\" ]";
      } else {
         eval "push \@{\${\${\$$map}[0]}[3]}, [ \"\$file\",\"\$reason\" ]";
      }
   } else {
      my $num_decrement=$num_of_levels;
      my ($exclude,$num,$num_of_elem)='';
      while (-1<$num_decrement--) {
         $num_of_elem=eval "\$\#{$map}";
         $num_of_elem=0 if $num_of_elem==-1;
         $map.="\}\[$num_of_elem\]";
         $map="\$\{$map";
         $num++;
print "NUM=$num and KEYS=$#keys\n";
         if ("$_[2]" eq 'EXCLUDE') {
print "MAPP1=$map and $keys[$num]\n";
            eval "\@{\${\$$map}[0]}[0]=\'some\'";
print "MIRRORMAP=$mirrormap and THIS=${${${$mirrormap}[0]}[0]}[0]\n";<STDIN>;
            print "GOT THE GOODS=",eval "\@{\${\$$map}[0]}[2]","\n";
            if (eval "\${\${\$$map}[0]}[2]" eq 'EXCLUDE') {
               $exclude='EXCLUDE';
            }
         } elsif ($#keys==$num) {
            eval "\@{\${\$$map}[0]}[0,1,2]=(\'all\',\'$keys[$num]\',\'\')";
print "MIRRORMAP=$mirrormap and THIS=${${${$mirrormap}[0]}[0]}[0]\n";<STDIN>;
         }
      }
   }
   return $mirrormap;
}
#print "BFH=$baseFH and KEY=$key and FILE=\@files and DESTDR=$dest_fdr and LCD=$local_transfer_dir and TRANTAR=$trantar and BHOIS=$bhostlabel and DHOST=$dhostlabel\n";<STDIN>;
#               $trantar=move_files($baseFH,"$key",
#                  \@files,$dest_fdr,
#                  $destFH,$bms_share,$dms_share,
#                  '',$local_transfer_dir,$trantar,
#                  $bhostlabel,$dhostlabel,'',
#                  $shortcut,\%desthash);
   
sub move_files
{
print "MOVE_FILESCALLER=",caller,"\n";<STDIN>;
   my ($baseFH,$key,$file,$dest_fdr,
       $destFH,$bms_share,$dms_share,$nosubs,
       $local_transfer_dir,$trantar,$bhostlabel,
       $dhostlabel,$parentkey,$shortcut) = @_;
print "BASEFH=$baseFH\n";
print "KEY=$key\n";
print "FILE=$file\n";
print "DEST_FDR=$dest_fdr\n";
print "DESTFH=$destFH\n";
print "BMS_SHARE=$bms_share\n";
print "DMS_SHARE=$dms_share\n";
print "NOSUBS=$nosubs\n";
print "LOCALTRANSFERDIR=$local_transfer_dir\n";
print "TRANTAR=$trantar\n";
print "BHOSTLABEL=$bhostlabel\n";
print "DHOSTLABEL=$dhostlabel\n";<STDIN>;
   my $basefile='';my $basedir='';my $destdir='';my $msprxFH='';
   my $w32copy='';my $output='';my $stderr='';my $destd='';my $baseprx='';
   if ($bms_share || $baseFH->{_uname} eq 'cygwin') {
      if ($key eq '/') {
         $basedir=$baseFH->{_work_dirs}->{_cwd};
      } else {
         $basedir="$baseFH->{_work_dirs}->{_cwd}$key";
      } $basedir.='/' if $file;
      if ($dms_share || $destFH->{_uname} eq 'cygwin') {
         if ((exists $destFH->{_smb})
               && (exists $baseFH->{_smb})) {
print "HEREEEEEEEEE1\n";
            $msprxFH=$destFH;
         } elsif (exists $baseFH->{_smb}) {
            $msprxFH=$baseFH;
         } elsif ($dhostlabel ne "__Master_${$}__") {
            &Net::FullAuto::FA_lib::handle_error('NO Microsoft OS Proxy Host Defined');
         }
         if ($dhostlabel ne "__Master_${$}__") {
            if ($key eq '/') {
               $destdir=$dest->{_work_dirs}->{_cwd};
            } else {
               $destdir="$destFH->{_work_dirs}->{_cwd}$key";
            } $destdir.='/' if $file;
         } elsif (unpack('a1',$dest_fdr) eq '/') {
            my $testd=&test_dir($destFH->{_cmd_handle},$dest_fdr);
            if ($destFH->{_uname} eq 'cygwin') {
               my $testd=&test_dir($destFH->{_cmd_handle},$dest_fdr);
               if ($testd ne 'WRITE') {
                  if ($testd eq 'NODIR') {
                     my $destdir_mswin='';
                     ($destdir,$destdir_mswin)
                        =&File_Transfer::get_drive($dest_fdr,'Destination',
                        '',$dhostlabel);
                     ($output,$stderr)=$destFH->cwd($destdir);
                     my $die="Destination Directory $dest_fdr\n"
                            .'       Does NOT Exist!:\n\n        '
                            .$stderr;
                     if ($stderr) {
                        if (wantarray) {
                           return '',$die;
                        } else {
                           &Net::FullAuto::FA_lib::handle_error($die);
                        }
                     }
                  } else {
                     my $die="Destination Directory $dest_fdr\n"
                            .'       is NOT Writable!';
                     if (wantarray) {
                        return '',$die;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($die);
                     }
                  }
               }
               $dest_fdr=&Net::FullAuto::FA_lib::push_cmd($destFH,
                         'cmd /c chdir',$dhostlabel);
               #my $cou=2;
               #while ($cou--) {
               #   ($dest_fdr,$stderr)=$destFH->cmd(
               #      "cmd /c chdir $dest_fdr",__live__);
               #   &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               #   if (!$dest_fdr) {
               #      ($output,$stderr)=
               #         &Net::FullAuto::FA_lib::clean_filehandle($destFH);
               #      &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               #   } else { last }
               #}
               $dest_fdr=unpack('a2',$dest_fdr);
               $dest_fdr=~tr/\\/\//;
            } elsif ($testd ne 'WRITE') {
               if ($testd eq 'NODIR') {
                  my $die="Destination Directory $dest_fdr\n"
                          .'       Does NOT Exist!';
                  if (wantarray) {
                     return '',$die;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($die);
                  }
               } else {
                  my $die="Destination Directory $dest_fdr\n"
                         .'       is NOT Writable!';
                  if (wantarray) {
                     return '',$die;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($die);
                  }
               }
            }
            if ($key eq '/') {
               $destdir=$destFH->{_work_dirs}->{_cwd};
            } else {
               $destdir="$destFH->{_work_dirs}->{_cwd}$destdir/$key";
            } $destdir.='/' if $file;
         } elsif (unpack('x1 a1',$dest_fdr) eq ':') {
            $destFH->{_work_dirs}->{_pre}=
               $destFH->{_work_dirs}->{_cwd};
            $destFH->{_work_dirs}->{_pre_mswin}=
               $destFH->{_work_dirs}->{_cwd_mswin};
            my ($drive,$path)=unpack('a1 x1 a*',$dest_fdr);
            $path=~tr/\\/\//;
            $destFH->{_work_dirs}->{_cwd_mswin}=$dest_fdr;
            $destFH->{_work_dirs}->{_cwd}=$destFH->{_cygdrive}
               .'/'.lc($drive).$path.'/';
            if ($key eq '/') {
               $destdir=$destFH->{_work_dirs}->{_cwd};
            } else {
               $destdir="$destFH->{_work_dirs}->{_cwd}$key";
            } $destdir.='/' if $file;
         } else {
            if ($key eq '/') {
               $destdir=$destFH->cmd('pwd');
            } else {
               $destdir=$destFH->cmd('pwd')."/$key";
            } $destdir.='/' if $file;
            $destdir=~tr/\\/\//;
         }
      } else {
         if ((exists $baseFH->{_smb}) ||
               $baseFH->{_uname} eq 'cygwin') {
            $msprxFH=$baseFH;
         } elsif ($bhostlabel ne "__Master_${$}__") {
            &Net::FullAuto::FA_lib::handle_error('NO Microsoft OS Proxy Host Defined');
         }
         if ($destFH->{_work_dirs}->{_tmp}) {
            if ($key eq '/') {
               $destdir=$destFH->{_work_dirs}->{_cwd_mswin};
            } else {
               $destdir="$destFH->{_work_dirs}->{_cwd_mswin}$key";
            } $destdir.='/' if $file;
         } elsif ($key ne '/') {
            $destdir=$key;
         }
         $trantar=1;
      }
   } elsif ($dms_share) {
      if ($key eq '/') {
         $basedir=$baseFH->{_work_dirs}->{_cwd_mswin};
         $destdir=$destFH->{_work_dirs}->{_cwd_mswin};
      } else {
         $basedir="$baseFH->{_work_dirs}->{_cwd_mswin}$key";
         $destdir="$destFH->{_work_dirs}->{_cwd_mswin}$key";
      } $basedir.='/' if $file;
      $destdir.='/' if $file;
      $destdir=~tr/\//\\/;
      $destdir=~tr/\\/\\\\/;
      if (exists $destFH->{_smb}) {
         $msprxFH=$destFH;
      } elsif ($dhostlabel ne "__Master_${$}__") {
         &Net::FullAuto::FA_lib::handle_error('NO Microsoft OS Proxy Host Defined');
      }
   } else {
      if ($key eq '/') {
         $basedir=$baseFH->{_work_dirs}->{_cwd_mswin};
      } else {
         $basedir="$baseFH->{_work_dirs}->{_cwd_mswin}$key";
      } $basedir.='/' if $file;
      $destdir=$key;$trantar=1;
   }

   my $b_OS='';my $m_OS='';my $d_OS='';my $FH='';
   if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
      if ($bms_share || ($baseFH->{_uname} eq 'cygwin' &&
            $bhostlabel eq "__Master_${$}__")) {
         if ($dms_share || $destFH->{_uname} eq 'cygwin') {
            $b_OS=$m_OS=$d_OS='cygwin';
         } else {
            $b_OS=$m_OS='cygwin';
            $d_OS='Unix';
         } $msprxFH=$Net::FullAuto::FA_lib::localhost;
      } elsif ($dms_share) {
         $m_OS=$d_OS='cygwin';
         $b_OS='Unix';
print "HEREEEEEEEEE7\n";
         $msprxFH=$Net::FullAuto::FA_lib::localhost;
         $Net::FullAuto::FA_lib::tran[1]="__Master_${$}__";
         if ($msprxFH->{_work_dirs}->{_tmp}) {
            my ($output,$stderr)=$msprxFH->cwd(
               $msprxFH->{_work_dirs}->{_tmp});
            if ($stderr) {
               @FA_lib::tran=();
               my $die="Cannot cd to TransferDir -> "
                      ."$msprxFH->{_work_dirs}->{_tmp}\n        $stderr";
               &Net::FullAuto::FA_lib::handle_error($die,'-6');
            } $Net::FullAuto::FA_lib::tran[0]=$msprxFH->{_work_dirs}->{_tmp};
         } else {
            $Net::FullAuto::FA_lib::tran[0]=$msprxFH->cmd('pwd');
         }
      } else {
         $m_OS='cygwin';
         $b_OS=$d_OS='Unix';
      }
   } else {
      if ($bms_share || $baseFH->{_uname} eq 'cygwin') {
         if ($dms_share || $destFH->{_uname} eq 'cygwin') {
            $b_OS=$d_OS='cygwin';
            $m_OS='UNIX';
print "HEREEEEEEEEE8\n";
            $msprxFH=$baseFH;
         } else {
            $b_OS='cygwin';
            $m_OS=$d_OS='Unix';
         }
      } elsif ($dms_share) {
         $d_OS='cygwin';
         $b_OS=$m_OS='Unix';
print "HEREEEEEEEEE9\n";
         $destdir=$destFH->{_work_dirs}->{_cwd_mswin};
      } else {
         $b_OS=$m_OS=$d_OS='Unix';
      }
   }
   #if ($msprxFH) {
   #   ($output,$stderr)=$msprxFH->cmd('cp','__notrap__');
   #   if (unpack('a11',$stderr) ne 'cp: missing') {
   #      $w32copy=1;
   #   }
   #}
   &move_file_list($file,$basedir,
      $destdir,$msprxFH,$baseFH,
      $destFH,$key,$w32copy,
      $local_transfer_dir,
      $b_OS,$m_OS,$d_OS,
      $parentkey)
      if !$shortcut || !$msprxFH || $b_OS ne 'cygwin';

   return $trantar;

}

sub move_file_list
{
my @topcaller=caller;
print "MOVEFILELISTCALLER=",(join ' ',@topcaller),"\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
   my ($file,$basedir,$destdir,$msprxFH,$baseFH,
          $destFH,$key,$w32copy,$local_transfer_dir,
          $b_OS,$m_OS,$d_OS,$parentkey,$shortcut)=@_;
print "BASEDIR=$basedir<===\n";#<STDIN>;
   my $farg='';my $filearg='';my $proxydir='';
   my $output='';my $stderr='';
   if ($msprxFH) {                      ### if MS Proxy Needed
      if ($b_OS eq 'cygwin') {           ### if Base Needs Proxy
         if ($d_OS eq 'cygwin') {        ### Dest Does Not Need Proxy
            foreach my $fil (@{$file}) {
               $fil=~s/%/\\%/g;
               $farg.="\'$baseFH->{_work_dirs}->{_cwd}$basedir$fil\' ";
               if (1500<length "$farg$destdir") {
                  $filearg=~tr/\\/\//;
                  $destdir.=$key if $key;
                  $destdir=~tr/\\/\//;
                  chop $filearg;
                  my $td="--target-directory=$destdir";
                  ($output,$stderr)=$msprxFH->cmd(
                      "cmd /c cp -fpv $filearg $td",'__notrap_');
                  if ($stderr) {
                     &clean_process_files($msprxFH);
                     if (-1==index $stderr,'already exists') {
                        &move_MSWin_stderr($stderr,$filearg,
                           '',$msprxFH,'')
                     }
                  }
                  $farg="\'$baseFH->{_work_dirs}->{_cwd}$basedir$fil\' ";
               } $filearg=$farg;
            }
            if ($filearg) {
               $filearg=~tr/\\/\//;
               $destdir=~tr/\\/\//;
               chop $filearg;
               my $td="--target-directory=$destdir";
               ($output,$stderr)=$msprxFH->cmd(
                  "cmd /c cp -fpv $filearg $td",'__notrap__');
               if ($stderr) {
                  &clean_process_files($msprxFH);
                  if (-1==index $stderr,'already exists') {
                     &move_MSWin_stderr($stderr,$filearg,
                        $destdir,$msprxFH,'')
                  }
               }
            } #else {
              # &move_MSWin_stderr('','',$destdir,$msprxFH,'')
            #}
         } else {                       ### Dest Needs Proxy
            if ($key && $key ne '/' && ($file
                  || $parentkey eq ')DIRONLY')) {
               $proxydir="\".\\transfer$Net::FullAuto::FA_lib::tran[3]\\$key\"";
            } else {
               $proxydir="\".\\transfer$Net::FullAuto::FA_lib::tran[3]$parentkey\"";
            }
            $proxydir=~tr/\\/\//;
            my $td="--target-directory=$proxydir";
            if ($file) {
               foreach my $fil (@{$file}) {
                  $fil=~s/%/\\%/g;
                  $farg.="\'$baseFH->{_work_dirs}->{_cwd}$basedir$fil\' ";
                  if (1500<length "$farg$proxydir") {
                     $filearg=~tr/\\/\//;
                     chop $filearg;
                     ($output,$stderr)=$msprxFH->cmd(
                         "cmd /c cp -fpv $filearg $td",'__notrap__');
                     if ($stderr) {
                        &clean_process_files($msprxFH);
                        if (-1==index $stderr,'already exists') {
                           &move_MSWin_stderr($stderr,$filearg,
                              $proxydir,$msprxFH,'')
                        }
                     }
                     $farg="\'$baseFH->{_work_dirs}->{_cwd}$basedir$fil\' ";
                  } $filearg=$farg;
               }
               if ($filearg) {
                  $filearg=~tr/\\/\//;
                  chop $filearg;
                  ($output,$stderr)=$msprxFH->cmd(
                     "cmd /c cp -fpv $filearg $td",'__notrap__');
                  if ($stderr) {
                     &clean_process_files($msprxFH);
                     if (-1==index $stderr,'already exists') {
                        &move_MSWin_stderr($stderr,$filearg,
                           $proxydir,$msprxFH,'')
                     }
                  }
               } #else {
                 # &move_MSWin_stderr('','',$proxydir,$msprxFH,'')
               #}
            } elsif ($parentkey ne ')DIRONLY') {
               my $fdot='';
               $fdot='/.' if $key eq '/';
               #$filearg.="\'$baseFH->{_work_dirs}->[0]$basedir$fdot\'";
               $filearg.="\'$baseFH->{_work_dirs}->{_cwd}$fdot\'";
               $filearg=~tr/\\/\//;
               ($output,$stderr)=$msprxFH->cmd(
                  "cmd /c cp -Rfpv $filearg $td",'__notrap__');
               if ($stderr) {
                  &clean_process_files($msprxFH);
                  if (-1==index $stderr,'already exists') {
                     &move_MSWin_stderr($stderr,$filearg,
                        $proxydir,$msprxFH,'R')
                  }
               }
            } else {
               &move_MSWin_stderr('','',$proxydir,$msprxFH,'')
            }
         }
      } else {                          ### Dest Needs Proxy
         $destdir=~tr/\\/\//;
         $td.=$destdir;
         $td="--target-directory=$td";
         &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
         ($output,$stderr)=$msprxFH->cmd(
             "cmd /c cp -Rfpv ./transfer$Net::FullAuto::FA_lib::tran[3]/* \"$td\"");
         if ($stderr) {
            my $die="Could not Execute the Command :"
                   ."\n\n       cmd /c cp -Rfpv ./transfer"
                   ."$Net::FullAuto::FA_lib::tran[3]/* \"$td\"\n\n       "
                   . $stderr;
            &Net::FullAuto::FA_lib::handle_error($die,'-7');
         }
      }
   }
}

sub clean_process_files
{
my @topcaller=caller;
print "CLEAN_PROCESS_FILES-CALLER=",(join ' ',@topcaller),"\n"
if !$Net::FullAuto::FA_lib::cron && $debug;
   my $self=$_[0];
   my $pid_ts=pop @FA_lib::pid_ts;
   $pid_ts||='';return '','' if !$pid_ts;
   my $str="echo \"del rm${pid_ts}.bat\"";
   my $output='';my $stderr='';
   $str.=" >> rm${pid_ts}.bat";
   ($output,$stderr)=$self->cmd($str);
   if ($stderr) {
      push @FA_lib::pid_ts, $pid_ts;
      $die= "$stderr\n\n       From Command -> " . "\"$str\"";
      &Net::FullAuto::FA_lib::handle_error($die);
   }
   if ($self->{_uname} eq 'cygwin') {
      $output=join '',$self->{_cmd_handle}->cmd(
         "cmd /c rm${pid_ts}.bat");
   } else {
      $output=join '',$self->{_cmd_handle}->{_cmd_handle}->cmd(
         "cmd /c rm${pid_ts}.bat");
   }
   if ($stderr) {
      push @FA_lib::pid_ts, $pid_ts;
      $die="$stderr\n\n       From Command -> "
          ."\"cmd /c rm${pid_ts}.bat\"";
      &Net::FullAuto::FA_lib::handle_error($die);
   }
   #($output,$stderr)=$localhost->cmd(
   #                   "rm ${trandir}out${pid_ts}.txt");
   if (0 && $Net::FullAuto::FA_lib::OS ne 'cygwin') {
print "WHAT THE HECK IS LOCALDIR=",$localhost->cmd("pwd"),"\n";
      ($output,$stderr)=$localhost->cmd(
         "rm out${pid_ts}.txt"); 
      if ($stderr) {
         push @FA_lib::pid_ts, $pid_ts;
         $die="$stderr\n\n       From Command -> "
             ."\"rm out${pid_ts}.txt\"";
         &Net::FullAuto::FA_lib::handle_error($die);
      }
   #($output,$stderr)=$localhost->cmd(
   #                   "rm ${trandir}err${pid_ts}.txt");
      ($output,$stderr)=$localhost->cmd(
         "rm err${pid_ts}.txt");
      if ($stderr) {
         push @FA_lib::pid_ts, $pid_ts;
         $die="$stderr\n\n       From Command -> "
             ."\"rm err${pid_ts}.txt\"";
         &Net::FullAuto::FA_lib::handle_error($die);
      }
   }

}

sub move_MSWin_stderr
{
#print "MSWin_stderrCALLER=",caller,"\n";
   my ($stderr,$filearg,$destdir,$FH,$option)=@_;
   my $output='';
   if (!$stderr || (-1<index $stderr,"No such file")
         || (-1<index $stderr,"not a directory")) {
      my $destd='';
      if (unpack('a10',$destdir) eq '/cygdrive/') {
         $destd=unpack('x10 a*',$destdir);
         $destd=~s/^(.)/$1:/;
      } else { $destd=$destdir }
      $destd=~tr/\//\\/;
      $stderr='';
      ($output,$stderr)=$FH->cmd(
         "cmd /c mkdir \"$destd\"");
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr
         && (-1==index $stderr,'already exists');
      if (!$Net::FullAuto::FA_lib::tran[4] &&
            17<length $destd &&
            -1<index $destd,"transfer$Net::FullAuto::FA_lib::tran[3]") {
         $Net::FullAuto::FA_lib::tran[0]="transfer$Net::FullAuto::FA_lib::tran[3]";
         $Net::FullAuto::FA_lib::tran[1]= ($FH->{_hostlabel}->[1]) ?
            $FH->{_hostlabel}->[1] : $FH->{_hostlabel}->[0];
         $Net::FullAuto::FA_lib::tran[4]=1;
      } return if !$filearg;
      $stderr='';
      my $td="--target-directory=$destdir";
      my $e_cnt=0;
      ($output,$stderr)=$FH->cmd(
         "cmd /c cp -${option}fpv $filearg $td");
      if ($stderr) {
         my $subwarn="WARNING! COPY ERROR";
         my %mail=(
            'Body'    => "$stderr",
            'Subject' => "$subwarn AND \$filearg=$filearg"
         );
         &Net::FullAuto::FA_lib::send_email(\%mail);
         #if ($e_cnt++==4) {
         #my $cperr="$stderr\n\n\n*****************************"
         #         ."************************************\n\n\n"
         #         ."$Net::FullAuto::FA_lib::fa_debug";
         #&Net::FullAuto::FA_lib::handle_error($cperr,'-11') if $stderr
         print $Net::FullAuto::FA_lib::MRLOG $stderr
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         &Net::FullAuto::FA_lib::handle_error($stderr,'-12') if $stderr
            && (-1==index $stderr,'already exists');
      }
   } else {
      print $Net::FullAuto::FA_lib::MRLOG $stderr 
         if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      &Net::FullAuto::FA_lib::handle_error($stderr,'-1');
   }

}

sub build_mirror_hashes
{
   my $hostlabel='';
   my $timehash={};my $num_of_files=0;$num_of_basefiles=0;
   my $timekey='';$deploy_needed=0;my $output='';
   my $baseFH=$_[0];my $destFH=$_[1];
   my $bhostlabel=$_[2];my $dhostlabel=$_[3];my $stderr='';
   my $deploy_empty_dir=0;
   eval {
      $num_of_files=${$baseFH->{_bhash}}{"___%EXCluD%E--NUMOFFILES"};
      delete ${$baseFH->{_bhash}}{"___%EXCluD%E--NUMOFFILES"};
      $num_of_basefiles=
             ${$baseFH->{_bhash}}{"___%EXCluD%E--NUMOFBASEFILES"};
      delete ${$baseFH->{_bhash}}{"___%EXCluD%E--NUMOFBASEFILES"};
      delete ${$destFH->{_dhash}}{"___%EXCluD%E--NUMOFFILES"};
      delete ${$destFH->{_dhash}}{"___%EXCluD%E--NUMOFBASEFILES"};
#print "NUM_OF_FILES=$num_of_files\n";
#print "NUM_OF_BASEFILES=$num_of_basefiles\n";<STDIN>;
      foreach my $key (sort keys %{$baseFH->{_bhash}}) {
         next if ${$baseFH->{_bhash}}{$key}[0] eq 'EXCLUDE';
         my @keys=();
         if (${$baseFH->{_bhash}}{$key}[2] eq 'DEPLOY_NOFILES_OF_CURDIR') {
            ${$baseFH->{_bhash}}{$key}[0]='SOME';
            if (-1<index $key,'/') {
               my $chkkey=$key;
               while ($chkkey=substr($chkkey,0,
                              (rindex $chkkey,'/'))) {
                  unshift @keys, $chkkey;
                  last if -1==index $chkkey,'/';
               }
            } unshift @keys, '/';
            foreach my $key (@keys) {
               ${$baseFH->{_bhash}}{$key}[0]='SOME';
            } next
         }
         my $dest_dir_status='';
         if ($key ne '/') {
            if (-1==$#keys) {
               if (-1<index $key,'/') {
                  my $chkkey=$key;
                  while ($chkkey=substr($chkkey,0,
                                 (rindex $chkkey,'/'))) {
                     unshift @keys, $chkkey;
                     last if -1==index $chkkey,'/';
                  }
               } unshift @keys, '/';
            }
#if ($key=~/172/) {
#print "ALLDESTKEYS1=",keys %{$destFH->{_dhash}},"GOT172!!!\n";
#foreach my $key (keys %{$destFH->{_dhash}}) {
#   print "KEYYYYYY=$key\n"; }
#<STDIN>;
#}
            if (!exists ${$destFH->{_dhash}}{$key}) {
#foreach my $key (keys %{$destFH->{_dhash}}) {
#   print "DESTKEYYYYYY=$key\n";
#}
#print "WHAT IS THE BAD KEY==>$key<==\n";<STDIN>;
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS THE BAD KEY==>$key<==\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ${$baseFH->{_bhash}}{$key}[3]='NOT_ON_DEST';
               $dest_dir_status='DIR_NOT_ON_DEST';
               $deploy_info.="DEPLOY EMPTY DIR $key - DIR_NOT_ON_DEST\n";
               $debug_info.="DEPLOY EMPTY DIR $key - DIR_NOT_ON_DEST\n";
               $deploy_empty_dir=$deploy_needed=1;
            } else {
               ${$baseFH->{_bhash}}{$key}[3]='DIR_ON_DEST';
               $dest_dir_status='DIR_ON_DEST';
            }
         }
         my $skip=0;my $deploy=0;
         foreach my $file (keys %{${$baseFH->{_bhash}}{$key}[1]}) {
#if ($key=~/quebecor|32bj|about/) {
#print "DEST_DIR_STATUS=$dest_dir_status and KEY=$key\n";
#print "FILE=$file and BASEHASH=",@{${$baseFH->{_bhash}}{$key}[1]{$file}},"\n";
#print "DESTHASH=",${$destFH->{_dhash}}{$key}[1]{$file},"\n" if exists
#      ${$destFH->{_dhash}}{$key}[1]{$file};
#}
            if (${$baseFH->{_bhash}}{$key}[1]{$file}[0] eq 'EXCLUDE') {
print "SKIP1=> KEY=$key and FILE=$file\n"
   if !$Net::FullAuto::FA_lib::cron && $Net::FullAuto::FA_lib::debug;
print $Net::FullAuto::FA_lib::MRLOG "SKIP1=> KEY=$key and FILE=$file\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               if ($key eq '/') {
                  $debug_info.="SKIP FILE $file - EXCLUDED_BY_FILTER\n";
               } else {
                  $debug_info.="SKIP FILE $key/$file - EXCLUDED_BY_FILTER\n";
               }
               $skip=1;next;
            } my $dchmod='';my $dtime='';my $dyear='';my $dsize='';
            my $dtime1='';my $dtime2='';my $dtime3='';
            if (exists ${$destFH->{_dhash}}{$key}[1]{$file}) {
#if ($key=~/\//) {
print $Net::FullAuto::FA_lib::MRLOG "KEY=$key DEST TIMELINE ENTRY=",
      ${${$destFH->{_dhash}}{$key}[1]{$file}}[1],"\n"
      ." and FILE=$file\n" if $Net::FullAuto::FA_lib::debug;
#}
               ${${$destFH->{_dhash}}{$key}[1]{$file}}[1]=~
                  /^(\d+\s+)(\d+)(\s+\d+\s+\d+)\s+(\d\d\d\d)\s+(\d+)$/;
               $dtime1=$1;$dtime2=$2;$dtime3=$3;
               $dyear=$4;$dsize=$5;$dchmod=$6;
               $dtime2="0$dtime2" if length $dtime2==1;
               $dtime=$dtime1.$dtime2.$dtime3;
               $dchmod||='';
            }
            ${${$baseFH->{_bhash}}{$key}[1]{$file}}[1]=~
               /^(\d+\s+)(\d+)(\s+\d+\s+\d+)\s+(\d\d\d\d)\s+(\d+)$/;
            my $btime1=$1;my $btime2=$2;my $btime3=$3;
            my $byear=$4;my $bsize=$5;my $bchmod=$6;
            $btime2="0$btime2" if length $btime2==1;
            my $btime=$btime1.$btime2.$btime3;
            $bchmod||='';
#if ($file=~/index.html/) {
#print "BASE TIMELINE ENTRY=",${$baseFH->{_bhash}}{$key}[1]{$file}[1],"\n"
#                 ." and FILE=$file and DEST_DIR_STATUS=$dest_dir_status"
#                 ."\n*****************************************\n";
#}
            if ($dest_dir_status eq 'DIR_NOT_ON_DEST') {
               if ($key eq '/') {
                  $deploy_info.="DEPLOY FILE $file - DIR_NOT_ON_DEST\n";
                  $debug_info.="DEPLOY FILE $file - DIR_NOT_ON_DEST\n";
                  if (99<length "$key/$file") {
                     my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                     $Net::FullAuto::FA_lib::file_rename{$file}=$tmp_file_name;
                     $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=$file;
                  }
               } else {
                  $deploy_info.="DEPLOY FILE $key/$file - DIR_NOT_ON_DEST\n";
                  $debug_info.="DEPLOY FILE $key/$file - DIR_NOT_ON_DEST\n";
                  if (99<length "$key/$file") {
                     my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                     $Net::FullAuto::FA_lib::file_rename{"$key/$file"}=$tmp_file_name;
                     $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}="$key/$file";
                  }
               }
               ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                  ="NOT_ON_DEST $bsize $dsize";
               ${$baseFH->{_bhash}}{$key}[1]{$file}[2]=$bchmod;
print "DEPLOY NEEDED for KEY=$key and FILE=$file because DIR_NOT_ON_DEST\n";
print $Net::FullAuto::FA_lib::MRLOG "DEPLOY NEEDED for KEY=$key and ",
                     "FILE=$file because DIR_NOT_ON_DEST\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               $deploy_needed=$deploy=1;
               $btime=~tr/ //;
               if ($key ne '/') {
                  $timekey="$key/$file";
               } else { $timekey=$file }
print $Net::FullAuto::FA_lib::MRLOG "UPDATEING TIMEHASH1=> TIMEKEY(FILE)=$timekey ",
                     "and BYEAR=$byear and BTIME=$btime\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ${$timehash}{$timekey}=[$byear,$btime];
               next;
            }
#if ($key=~/about/) {
#print $Net::FullAuto::FA_lib::MRLOG "BEFORE DEST HASH=$file and THISSSSEXISTS="
#                  .(exists ${$destFH->{_dhash}}{$key}[1]{$file})
#                  ." and KEYS="
#                  .join ' ',@{[keys %{${$destFH->{_dhash}}{$key}[1]}]}
#                  ." and KEYYYYY=$key\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#}
            if (exists ${$destFH->{_dhash}}{$key}[1]{$file}) {
#if ($file=~/index.html/) {
#print "KEY=$key and FILE=$file\n";
#print $Net::FullAuto::FA_lib::MRLOG
#print 
#   "BSIZE=$bsize and DSIZE=$dsize and BTIME=$btime and DTIME=$dtime\n";
#   #if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#<STDIN>;
#}
               if ($bsize ne $dsize) {
                  ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                      ="DIFF_SIZE $bsize $dsize";
                  if ($key eq '/') {
                     $deploy_info.="DEPLOYa $file - DIFF_SIZE\n";
                     $debug_info.="DEPLOY $file - DIFF_SIZE\n";
                     if (99<length "$key/$file") {
                        my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                        $Net::FullAuto::FA_lib::file_rename{$file}=$tmp_file_name;
                        $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=$file;
                     }
                  } else {
                     $deploy_info.="DEPLOYb $key/$file - DIFF_SIZE\n";
                     $debug_info.="DEPLOY $key/$file - DIFF_SIZE\n";
                     if (99<length "$key/$file") {
                        my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                        $Net::FullAuto::FA_lib::file_rename{"$key/$file"}=
                           $tmp_file_name;
                        $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=
                           "$key/$file";
                     }
                  }
print "DEPLOY NEEDED for KEY=$key and FILE=$file because DIFF SIZE BSIZE=$bsize and DSIZE=$dsize\n";
print $Net::FullAuto::FA_lib::MRLOG "DEPLOY NEEDED for KEY=$key and FILE=$file ",
                     "because DIFF SIZE BSIZE=$bsize and DSIZE=$dsize\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  $deploy_needed=$deploy=1;
                  delete ${$destFH->{_dhash}}{$key}[1]{$file}
                     if $dest_dir_status ne 'DIR_NOT_ON_DEST';
                  $btime=~tr/ //;
                  if ($key ne '/') {
                     $timekey="$key/$file";
                  } else { $timekey=$file }
print $Net::FullAuto::FA_lib::MRLOG "UPDATEING TIMEHASH2=> TIMEKEY(FILE)=$timekey ",
                     "and BYEAR=$byear and BTIME=$btime\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  ${$timehash}{$timekey}=[$byear,$btime];
                  next;
               }
               my ($bmndy,$bhr,$bmt)
                  =unpack('a5 x1 a2 x1 a2',$btime);
               my ($dmndy,$dhr,$dmt)
                  =unpack('a5 x1 a2 x1 a2',$dtime);
#print "BTIME=$btime and DTIME=$dtime\n" if $file=~/index.html/;
#<STDIN> if $file=~/index.html/;
               if ($btime ne $dtime) {
                  my $btim=unpack('x6 a2',$btime);
                  my $dtim=unpack('x6 a2',$dtime);
#print "BTIM=$btim and BTIME=$btime and DTIME=$dtime\n";
#print "DTIM=$dtim and FILE=$key/$file\n";
#<STDIN> if $file=~/index.html/;
                  my $btme=$btime;
                  my $dtme=$dtime;
                  substr($btme,6,2)='';
                  substr($dtme,6,2)='';
                  my $testnum='';
                  if ($dtim<$btim) {
                     $testnum=$btim-$dtim;
                  } else { $testnum=$dtim-$btim }
                  ${$baseFH->{_bhash}}{$key}[1]{$file}[2]=$bchmod;
                  if ($btme eq $dtme && ($testnum==1 ||
                        ($btim==23 && ($testnum==12 ||
                         $testnum==11))) || ($bmndy eq $dmndy
                         && (($dhr eq '12' && $dmt eq '00')
                         || ($bhr eq '12' && $bmt eq '00')))) {
                     delete ${$destFH->{_dhash}}{$key}[1]{$file}
                        if $dest_dir_status ne 'DIR_NOT_ON_DEST';
                     $skip=1;
                     if ($key eq '/') {
                        $debug_info.=
                           "SKIP FILE $file - SAME_SIZE_TIME_STAMP1\n";
                     } else {
                        $debug_info.=
                           "SKIP FILE $key/$file - SAME_SIZE_TIME_STAMP1\n";
                     }
                     ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                         ="SAME $btime $bsize";
                     next;
                  } elsif ($dtim<$btim &&
                         exists $Net::FullAuto::FA_lib::Hosts{$dhostlabel}{'TimeStamp'}
                         && lc($Net::FullAuto::FA_lib::Hosts{$dhostlabel}
                         {'TimeStamp'}) eq 'newer') {
                     ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                         ="NEWR_TIME $btime $dtime";
                     if ($key eq '/') {
                        $deploy_info.="DEPLOYc $file - NEWR_TIME\n";
                        $debug_info.="DEPLOY $file - NEWR_TIME\n";
                        if (99<length "$key/$file") {
                           my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                           $Net::FullAuto::FA_lib::file_rename{$file}=$tmp_file_name;
                           $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=$file;
                        }
                     } else {
                        $deploy_info.="DEPLOYd $key/$file - NEWR_TIME\n";
                        $debug_info.="DEPLOY $key/$file - NEWR_TIME\n";
                        if (99<length "$key/$file") {
                           my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                           $Net::FullAuto::FA_lib::file_rename{"$key/$file"}=
                              $tmp_file_name;
                           $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=
                              "$key/$file";
                        }
                     }
                     $deploy_needed=$deploy=1;
                     delete ${$destFH->{_dhash}}{$key}[1]{$file}
                        if $dest_dir_status ne 'DIR_NOT_ON_DEST';
                  } else {
#print "DIFFTIME=$file<== and BTIME=$btime and DTIME=$dtime\n";#<STDIN>;
                     ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                        ="DIFF_TIME $btime $dtime";
                     if ($key eq '/') {
                        $deploy_info.="DEPLOYe $file - DIFF_TIME\n";
                        $debug_info.="DEPLOY $file - DIFF_TIME\n";
                        if (99<length "$key/$file") {
                           my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                           $Net::FullAuto::FA_lib::file_rename{$file}=$tmp_file_name;
                           $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=$file;
                        }
                     } else {
                        $deploy_info.="DEPLOYf $key/$file - DIFF_TIME\n";
                        $debug_info.="DEPLOY $key/$file - DIFF_TIME\n";
                        if (99<length "$key/$file") {
                           my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                           $Net::FullAuto::FA_lib::file_rename{"$key/$file"}=
                              $tmp_file_name;
                           $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=
                              "$key/$file";
                        }
                     }
                     $deploy_needed=$deploy=1;
                     delete ${$destFH->{_dhash}}{$key}[1]{$file}
                        if $dest_dir_status ne 'DIR_NOT_ON_DEST';
                  }
               } else {
                  delete ${$destFH->{_dhash}}{$key}[1]{$file}
                     if $dest_dir_status ne 'DIR_NOT_ON_DEST';
                  ${$baseFH->{_bhash}}{$key}[1]{$file}[0]
                     ="SAME $btime $bsize";
                  if ($key eq '/') {
                     $debug_info.=
                        "SKIP FILE $file - SAME_SIZE_TIME_STAMP2\n";
                  } else {
                     $debug_info.=
                        "SKIP FILE $key/$file - SAME_SIZE_TIME_STAMP2\n";
                  }
                  ${$baseFH->{_bhash}}{$key}[1]{$file}[2]=$bchmod;
                  $skip=1;next;
               }
            } else {
               ${$baseFH->{_bhash}}{$key}[1]{$file}[0]='NOT_ON_DEST';
               ${$baseFH->{_bhash}}{$key}[1]{$file}[2]=$bchmod;
               if ($key eq '/') {
                  $deploy_info.="DEPLOYg $file - NOT_ON_DEST\n";
                  $debug_info.="DEPLOY $file - NOT_ON_DEST\n";
                  if (99<length "$key/$file") {
                     my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                     $Net::FullAuto::FA_lib::file_rename{$file}=$tmp_file_name;
                     $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}=$file;
                  }
               } else {
                  $deploy_info.="DEPLOYh $key/$file - NOT_ON_DEST\n";
                  $debug_info.="DEPLOY $key/$file - NOT_ON_DEST\n";
                  if (99<length "$key/$file") {
                     my $tmp_file_name="X_".time."_"
                                       .$Net::FullAuto::FA_lib::increment++
                                       ."_X.mvx";
                     $Net::FullAuto::FA_lib::file_rename{"$key/$file"}=$tmp_file_name;
                     $Net::FullAuto::FA_lib::rename_file{$tmp_file_name}="$key/$file";
                  }
               }
               $deploy_needed=$deploy=1;
            }
            $btime=~tr/ //;
            if ($key ne '/') {
               $timekey="$key/$file";
            } else { $timekey=$file }
            ${$timehash}{$timekey}=[$byear,$btime];
print $Net::FullAuto::FA_lib::MRLOG "UPDATEING TIMEHASH3=> TIMEKEY(FILE)=$timekey ",
                     "and BYEAR=$byear and BTIME=$btime\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         }
         if ($skip) {
            if ($deploy) {
               ${$baseFH->{_bhash}}{$key}[2]='DEPLOY_SOMEFILES_OF_CURDIR';
#print "HERE I AMMM333 AND KEY=$key\n";<STDIN>;
               ${$baseFH->{_bhash}}{$key}[0]='SOME';
               foreach my $key (@keys) {
#print "SETTING BASEHASH TO \'SOME\' for KEY=$key and SKIP=$skip and DEPLOY=$deploy\n";
#print $Net::FullAuto::FA_lib::MRLOG "SETTING BASEHASH TO \'SOME\' for KEY=$key and ",
#                     "SKIP=$skip and DEPLOY=$deploy\n"
#                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "HERE I AMMM444 AND KEY=$key\n";<STDIN>;
                  ${$baseFH->{_bhash}}{$key}[0]='SOME';
               }
            } else {
               delete ${$destFH->{_dhash}}{$key}
                  if !keys %{${$destFH->{_dhash}}{$key}[1]};
               ${$baseFH->{_bhash}}{$key}[2]='DEPLOY_NOFILES_OF_CURDIR';
               ${$baseFH->{_bhash}}{$key}[0]='EXCLUDE'
                  if ${$baseFH->{_bhash}}{$key}[0] ne 'SOME'
                  && ${$baseFH->{_bhash}}{$key}[0] ne 'NOT_ON_DEST';
            }
         } elsif ($deploy) {
            ${$baseFH->{_bhash}}{$key}[2]='DEPLOY_SOMEFILES_OF_CURDIR';
         } else {
            delete ${$destFH->{_dhash}}{$key}
               if !keys %{${$destFH->{_dhash}}{$key}[1]};
            ${$baseFH->{_bhash}}{$key}[2]='DEPLOY_NOFILES_OF_CURDIR';
#if ($key=~/pdf/) {
#print "SETTING1 $key to EXCLUDE\n";
#}
            ${$baseFH->{_bhash}}{$key}[0]='EXCLUDE'
               if ${$baseFH->{_bhash}}{$key}[0] ne 'SOME'
               && ${$baseFH->{_bhash}}{$key}[0] ne 'NOT_ON_DEST' 
               && !$deploy_empty_dir;
         } $deploy_empty_dir=0;
      } ${$baseFH->{_bhash}}{'/'}[0]='EXCLUDE' if !$deploy_needed;
   };
   if ($@) {
      if (unpack('a10',$@) eq 'The System') {
         return '','','','',$@;
      } else {
         my $die="The System $hostlabel Returned"
                ."\n              the Following Unrecoverable Error "
                ."Condition\n              at ".(caller(0))[1]." "
                ."line ".(caller(0))[2]." :\n\n       $@";
         print $Net::FullAuto::FA_lib::MRLOG $die 
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         return '','','','',$die;
      }
   }
print $Net::FullAuto::FA_lib::MRLOG "KEYSBASEHASHTEST=",keys %{$baseFH->{_bhash}},"\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
 return $baseFH, $destFH, $timehash, $deploy_info, $debug_info;

}

sub build_base_dest_hashes
{

   my $modifiers='';my $mod_dirs_flag='';
   my $mod_files_flag='';$s='';my $hostname='';
   my $num_of_included=0;$num_of_excluded=0;
   my @modifiers=();
   my $base_or_dest_folder=$_[0];
   my $ms_share=$_[4];$ms_share||='';
   my $ms_domain=$_[5];$ms_domain||='';
   my $cygwin = (-1<index lc($_[6]),'cygwin') ? 1 : 0;
   my $cmd_handle=$_[7];$cmd_handle||='';
   my $base_dest=$_[8];my $bd='';
   $bd=($base_dest eq 'BASE')?'b':'d';
   if (0) {
   #if (keys %outhash) {
      foreach my $key (keys %outhash) {
         my $elems=$#{$outhash{$key}}+1;
         while (-1<--$elems) {
            if (ref $outhash{$key}[$elems] ne 'HASH') {
               undef $outhash{$key}[$elems];
            } else {
               foreach my $key (
                     keys %{$outhash{$key}[$elems]}) {
                  if (${$outhash
                        {$key}[$elems]}{$key}) {
                     undef @{${$outhash
                           {$key}[$elems]}{$key}};
                  } delete ${$outhash
                           {$key}[$elems]}{$key};
               } undef %{$outhash{$key}[$elems]};
               undef $outhash{$key}[$elems];
            }
         } undef $outhash{$key};
         delete $outhash{$key};
      } undef %outhash;$outhash='';
   }
   my %navhash=();
   eval {
      if ($_[2]) {
         my @directives=@{$_[2]};my @delim=();
         foreach my $directive (@directives) {
            $s=0;$s=1 if $directive=~/^s/;
            if ($s==1 || substr($directive,0,1) eq 'm') {
               $delim[0]=substr($directive,1,1);
            } else { $delim[0]=substr($directive,0,1); }
            if ($delim[0] eq '(') { $delim[1]=')' }
            elsif ($delim[0] eq '[') { $delim[1]=']' }
            elsif ($delim[0] eq '{') { $delim[1]='}' }
            else { $delim[1]=$delim[0] }
            my $rindex=rindex $directive,$delim[1];
            my $modifiers=lc(substr($directive,$rindex+1));
            my $regex=substr($directive,(index $directive,$delim[0])+1,
                             $rindex-1);
            my $perl_mods='';
            my $mods='';
            if ($directive=~/^s/) {
               $s=1;
               $perl_mods.='g' if -1<index $modifiers,'g';
               $perl_mods.='e' if -1<index $modifiers,'e';
            } elsif (-1<index $modifiers,'e') { $mods.='e' }
            $perl_mods.='i' if -1<index $modifiers,'i';
            if (-1<index $modifiers,'d') {
               if ($s) {
                  push @modifiers, [ qr/$regex/,$perl_mods,"s$mods",'d' ];
               } elsif (-1<index $modifiers,'e') {
                  push @modifiers, [ qr/$regex/,$perl_mods,$mods,'d' ];
               } else {
                  push @modifiers, [ qr/$regex/,$perl_mods,"${mods}i",'d' ];
               } $mod_dirs_flag=1;
            } else {
               if ($s) {
                  push @modifiers, [ qr/$regex/,$perl_mods,"s$mods",'f' ];
               } elsif (-1<index $modifiers,'e') {
                  push @modifiers, [ qr/$regex/,$perl_mods,$mods,'f' ];
               } else {
                  push @modifiers, [ qr/$regex/,$perl_mods,"${mods}i",'f' ];
               } $mod_files_flag=1;
            } 
         }

         sub regx_prog
         {
            my @topcaller=caller;
            print "regx_prog() CALLER=",
               (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::debug;
            print $Net::FullAuto::FA_lib::MRLOG "regx_prog() CALLER=",
               (join ' ',@topcaller),"\n"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            my $ex=$_[0];my $type=$_[1];
            my $sub = sub {
               my $result=0;my $string='';$_[1]||='';
               if ($type eq 'f' && $_[1] ne ''
                     && -1<index ${$ex}[0],'/') {
                  if ($_[1] eq '/') {
                     $string=$_[0];
                  } else {
                     $_[1]=~s/\/+$//;
                     $string="$_[1]/$_[0]";
                  }
               } else { $string=$_[0] }
               if (-1<index ${$ex}[1],'s') {
                  if (-1<index ${$ex}[1],'g') {
                     if (-1<index ${$ex}[1],'i') {
                        $result=1 if $string=~m#${$ex}[0]#sgi;
                     } else {
                        $result=1 if $string=~m#${$ex}[0]#sg;
                     }
                  } else {
                     if (-1<index ${$ex}[1],'i') {
                        $result=1 if $string=~m#${$ex}[0]#si;
                     } else {
                       $result=1 if $string=~m#${$ex}[0]#s;
                     }
                  }
               } elsif (-1<index ${$ex}[1],'m') {
                  if (-1<index ${$ex}[1],'g') {
                     if (-1<index ${$ex}[1],'i') {
                        $result=1 if $string=~m#${$ex}[0]#mgi;
                     } else {
                        $result=1 if $string=~m#${$ex}[0]#mg;
                     }
                  } else {
                     if (-1<index ${$ex}[1],'i') {
                        $result=1 if $string=~m#${$ex}[0]#mi;
                     } else {
                       $result=1 if $string=~m#${$ex}[0]#m;
                     }
                  }
               } elsif (-1<index ${$ex}[1],'g') {
                  if (-1<index ${$ex}[1],'i') {
                     $result=1 if $string=~m#${$ex}[0]#gi;
                  } else {
                     $result=1 if $string=~m#${$ex}[0]#g;
                  }
               } else {
                  $result=1 if $string=~m#${$ex}[0]#;
               } return $result,${$ex}[2]||='';
            };
            $sub;
         }
      }
      my $len_dir='';
      if (!$ms_share && !$ms_domain && !$cygwin) {
         $len_dir=(length $base_or_dest_folder)+2;
      } elsif ($base_or_dest_folder=~/$cmd_handle->{_cygdrive_regex}/) {
         my $tmp_basedest=$base_or_dest_folder;
         $tmp_basedest=~s/$cmd_handle->{_cygdrive_regex}//;
         $len_dir=length ".Directory.of..$tmp_basedest";
      } elsif ($ms_share) {
         $len_dir=length
            ".Directory.of...$_[3].$_[4].$base_or_dest_folder";
         $len_dir=$len_dir-2
            if substr($base_or_dest_folder,-2) eq '/.';
      } elsif ($base_or_dest_folder=~/^\w:/) {
         $len_dir=length ".Directory.of..$base_or_dest_folder";
      } elsif ($cygwin) {
         my $tmp_bd=unpack('x1 a*',$base_or_dest_folder);
         $tmp_bd=substr($tmp_bd,(index $tmp_bd,'/'));
         $len_dir=length ".Directory.of..$tmp_bd";
      } else {
         $len_dir=length ".Directory.of....$base_or_dest_folder";
      }
      my $time='';my $files_flag='';my $mn=0;my $dy=0;
      my $yr=0;my $hr=0;my $mt=0;my $pm='';my $size='';
      my $file='';my $fchar='';my $u='';my $tm='';
      my $g='';my $o='';my $topkey='';my $lchar_flag='';
      my $excluded_parent_dir=0;my $included_parent_dir=0;
      my $fileyr=0;my $bit=0;my $chmod='';my $cnt=0;
      my $cur_dir_excluded=0;my $file_count=0;my $dofiles=0;
      my @keys=();my $addbytes=0;my $nt5=0;
      my $prevkey='';my $savekey='';my $savetotal=0;
      ${$cmd_handle->{"_${bd}hash"}}{'/'}=[ 'ALL', {},
                      'DEPLOY_SOMEFILES_OF_CURDIR' ];
      my $key='/';my $bytesize=0;my $total=0;
#$xxxnext=0;
#if (!$cygwin) {
#open(BK,">brianout.txt");
#print BK ${$_[1]};
#CORE::close BK;
#}
      my @sublines=();
      FL: foreach my $line (split /^/, ${$_[1]}) {
         my $parse=1;my $trak=0;
         if ($savekey) {
            $key=$savekey;
            $total=$savetotal;
            $dofiles=0;
            $savekey='';
            $savetotal=0;
         }
#if ($xxxnext) {
#$xxxnext--;
#print "NEXTLINE=$line\n";
#}
#if ($line=~/-and-paste code/s && !$cygwin) {
#$xxxnext=4;
#$xxxnext=7 if $line=~/-and-paste code/s
#}
         next if $line=~/^\s*$/;
         WH: while ($parse || ($line=pop @sublines)) {
#if ($trak) {
#print "LINE FROM POP SUBLINE=$line and KEY=$key\n";<STDIN>;
#$trak=0;
#}
            $parse=0;
            $mn=0;$dy=0;$yr=0;$hr=0;
            $mt='';$pm='';$size='';$file='';
            if ($ms_share || $ms_domain
                          || $cygwin) { # If Base is MSWin
               next if $cnt++<4;
               chomp($line=~tr/\0-\37\177-\377//d);
               if (39<length $line) {
                  if (unpack('x6 a4',$line)=~/^\d\d\d\d$/) {
                     ($mn,$dy,$yr,$hr,$mt,$pm,$size,$file)=
                      unpack('a2 x1 a2 x3 a2 x2 a2 x1 a2 a1 @24 a14 @39 a*'
                            ,$line);
                      $nt5=1;
                  } else {
                     ($mn,$dy,$yr,$hr,$mt,$pm,$size,$file)=
                      unpack('a2 x1 a2 x1 a2 x2 a2 x1 a2 a1 @24 a14 @39 a*'
                            ,$line);
                  }
               } else { $mn=unpack('a2',$line) }
#if ($key=~/careers/) {
#print "MSWin_LINE=$line and KEY=$key and MN=$mn and file=$file and MT=$mt and SIZE=$size and UNPACK=",unpack('a1',$size),"\n";<STDIN>;
#}
               next if $mn eq '' || $mn eq '  '
                              || unpack('a1',$size) eq '<';
               foreach my $pid_ts (@FA_lib::pid_ts) {
                  next FL if $file eq "rm${pid_ts}.bat"
                              || $file eq "cmd${pid_ts}.bat"
                              || $file eq "end${pid_ts}.flg"
                              || $file eq "err${pid_ts}.txt"
                              || $file eq "out${pid_ts}.txt";
               }
               if ($file eq '' && $mn ne ' D') { next }
            } else { # Else Base is UNIX
#if ($line=~/entry_flash.swf/s && !$cygwin) {
#print "UNIX_LINE=$line<--\n";#<STDIN>;
#}
               $fchar='';$u='';$g='';$o='';$chmod='';
               chomp($line);
               next if $line eq '';
               my $lchar=substr($line,-1);
               if ($lchar eq '*' || $lchar eq '/' || $lchar eq ':') {
                  if ($lchar eq ':' && !$lchar_flag) {
                     $len_dir--;
                     $lchar_flag=1;
                  } chop $line;
               }
               my $endofline=substr($line,-2);
               if ($line=~s/^\s*([0-9]+)\s//) {
                  $bytesize=$1;
                  ($fchar,$u,$g,$o)=unpack('a1 a3 a3 a3',$line);
                  $addbytes+=$bytesize;
                  $dofiles=1;
                  if ($endofline eq '..' || $endofline eq ' .') { next }
               } else {
                  ($fchar,$u,$g,$o)=unpack('a1 a3 a3 a3',$line);
                  if ($fchar eq 't') {
#print "TOTAL=$total and ADDBYTES=$addbytes and PREVKEY=$prevkey\n";
#print $Net::FullAuto::FA_lib::MRLOG "TOTAL=$total and ADDBYTES=$addbytes and "
#                     "PREVKEY=$prevkey\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if ($dofiles && $total!=$addbytes) {
#print "WE HAVE A PROBLEM HOUSTON and KEY=$prevkey<--\n";
print $Net::FullAuto::FA_lib::MRLOG "WE HAVE A PROBLEM HOUSTON and KEY=$prevkey<--\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        @sublines=();
                        $savekey=$key;
                        $savetotal=unpack('x6 a*',$line);
                        $key=$prevkey;
                        die 'redo ls' if $key eq '/';
                        $addbytes=0;
                        while (1) {
print "LOOPING IN WHILE TO CORRECT LS -> KEY=$key\n";
#$Net::FullAuto::FA_lib::fa_debug.="LOOPING IN WHILE TO CORRECT LS -> KEY=$key\n";
                           ($stdout,$stderr)=$cmd_handle->cmd(
                              "ls -lRs $key");
                           &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                           my $add_bytes=0;
#print "LS LOOPING STDOUT=$stdout\n";
#$Net::FullAuto::FA_lib::fa_debug.="LS LOOPING STDOUT=$stdout\n";
                           foreach my $line (split /^/, $stdout) {
                              chomp($line);
                              next if $line eq '';
                              if ($line=~/^total /) {
                                 $total+=unpack('x6 a*',$line);
#print "TOTAL=$total and LINE=$line\n";
#$Net::FullAuto::FA_lib::fa_debug.="TOTAL=$total and LINE=$line\n";
                                 next;
                              }
                              my $lchar=substr($line,-1);
                              if ($lchar eq '*' || $lchar eq '/'
                                     || $lchar eq ':') {
                                 if ($lchar eq ':' && !$lchar_flag) {
                                    $len_dir--;
                                    $lchar_flag=1;
                                 } chop $line;
                              }
                              my $endofline=substr($line,-2);
#print "NOW LINE=$line\n";
#$Net::FullAuto::FA_lib::fa_debug.="NOW LINE=$line\n";
                              if ($line=~s/^\s*([0-9]+)\s//) {
                                 my $bytesize=$1;
                                 next if $bytesize!~/\d+/;
                                 ($fchar,$u,$g,$o)=unpack('a1 a3 a3 a3',$line);
                                 $add_bytes+=$bytesize;
                                 if ($endofline eq '..'
                                       || $endofline eq ' .') { next }
                                 push @sublines, $line;
                              }
                           } last if $add_bytes==$total;
                           $total=0;
                        } next WH;
                     } else {
                        $total=unpack('x6 a*',$line);
#print "WHAT IS TOTALNOW=$total and LINE=$line\n";
#$Net::FullAuto::FA_lib::fa_debug.="WHAT IS TOTALNOW=$total and LINE=$line\n";
                        if (-1<index $total,'stdout:') {
                           $total=~s/^(\d+)(stdout:.*)$/$1/;
                           push @sublines, $2;
                        }
                        $addbytes=0;
                     }
                  }
               }
               my $per=lc("$u$g$0");
               if ($fchar=~/[-dl]/ && (-1<index $per,'s'
                     || -1<index $per,'t')) {
                  if (-1<index lc($u),'s') {
                     if (-1<index lc($g),'s') {
                        if (-1<index lc($o),'t') {
                           $bit=7;
                        } else {
                           $bit=6;
                        }
                     } else {
                        if (-1<index lc($o),'t') {
                           $bit=5;
                        } else {
                           $bit=4;
                        }
                     }
                  }
                  if ($bit<6 && -1<index lc($g),'s') {
                     if (-1<index lc($o),'t') {
                        $bit=3;
                     } else {
                        $bit=2;
                     }
                  } elsif ($bit<2 && -1<index lc($o),'t') {
                     $bit=1;
                  } else {
                     $bit=0;
                  }
                  $chmod="$bit$Net::FullAuto::FA_lib::perms{$u}";
                  $chmod.="$Net::FullAuto::FA_lib::perms{$g}$Net::FullAuto::FA_lib::perms{$o}";
               }
            }
#if ($key=~/careers/) {
#if ($excluded_parent_dir) {
#   print "KEY=$key and MODS=@modifiers and EXCLUDE_PARENT_DIR=$excluded_parent_dir\n";
#} elsif ($included_parent_dir) {
#   print "KEY=$key and MODS=@modifiers and INCLUDE_PARENT_DIR=$included_parent_dir\n";
#}
#print "CYGWINNNNN=$cygwin and FCHAR=$fchar and MN=$mn and SIZE=$size and KEY=$key\n";<STDIN>;
#}
            if ((!$cygwin && $fchar eq '/') || ($mn eq ' D')) {
#if ($key=~/bmicalculator/) {
#   print "VERYGOOGGDDDDD - WE ARE HERE and MOD=$mod_dirs_flag\n";<STDIN>;
#}
               if ($mod_dirs_flag) {
                  foreach my $modif (@modifiers) {
                     @keys=();
                     next if ${$modif}[3] eq 'f';
                     if (${$modif}[3] eq 'd') {
                        if ($len_dir<length $line) {
                           # Get New Directory Key
                           $prevkey=$key;
                           $key=unpack("x$len_dir a*",$line);
                           if ($ms_share || $ms_domain || $cygwin) {
                              $key=~tr/\\/\//;
                           }
                           $file_count=0;
                           $cur_dir_excluded=0;
                        }
                        if ($key ne '/') {
                           if (-1<index $key,'/') {
                              my $chkkey=$key;
                              while ($chkkey=substr($chkkey,0,
                                    (rindex $chkkey,'/'))) {
                                 unshift @keys, $chkkey;
                                 last if -1==index $chkkey,'/';
                              }
                           } else { unshift @keys, $key }
                        } unshift @keys, '/';
                        $Net::FullAuto::FA_lib::d_sub=regx_prog($modif,'d');
                        my $return=0;my $returned_modif='';
#if ($key eq '/') {
#print "KEY=$key and KEYSNOW33=@keys\n";
#}
                        ($return,$returned_modif)=&$d_sub($key);
#if ($key eq '/') { # && $file=~/index/) {
#print "KEY=$key RETURN=$return and RETURNED_MODIF=$returned_modif\n";<STDIN>;
#}
                        #if ($return || -1<index $returned_modif,'e') {
                        if ($return) {
                           if (-1<index $returned_modif,'e') {
                              ${$cmd_handle->{"_${bd}hash"}}{$key}
                                 =[ 'EXCLUDE', {},
                                 'DEPLOY_NOFILES_OF_CURDIR' ];
#print "BASE_DEST=$base_dest and EXCLUDEDKEY=$key\n";<STDIN>;
                              if ($base_dest eq 'BASE') {
                                 $Net::FullAuto::FA_lib::base_excluded_dirs{$key}='-';
                              }
                              #foreach my $key (pop @keys) {
                              #   if (${$cmd_handle->{"_${bd}hash"}}{$key}[0]
                              #          ne 'EXCLUDE') {
#print "HERE I AMMM555 AND KEY=$key and THIS=",${$cmd_handle->{"_${bd}hash"}}{$key}[0],"\n";<STDIN>;
                              #      ${$cmd_handle->{"_${bd}hash"}}{$key}[0]='SOME';
                              #   }
                              #} 
                              $excluded_parent_dir=$key;
                              $included_parent_dir='';
                           } else {
                              ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'ALL', {},
                                 'DEPLOY_SOMEFILES_OF_CURDIR' ];
                              foreach my $key (@keys) {
                                 if (${$cmd_handle->{"_${bd}hash"}}{$key}[0]
                                       eq 'EXCLUDE') {
#print "HERE I AMMM777 AND KEY=$key\n";<STDIN>;
                                    ${$cmd_handle->{"_${bd}hash"}}{$key}[0]
                                       ='SOME';
                                 }
                              }
                              $excluded_parent_dir='';
                              $included_parent_dir=$key;
                           }
                        } elsif ($excluded_parent_dir &&
                                length $excluded_parent_dir<length
                                $key && unpack("a".length $excluded_parent_dir,
                                $key) eq $excluded_parent_dir) {
#if ($key=~/bmicalculator/) {
#print "OUTHASH_EXCLUDED_PARENT_KEY=$key\n";<STDIN>;
#}
                           ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'EXCLUDE', {},
                                'DEPLOY_NOFILES_OF_CURDIR' ];
                           $included_parent_dir='';
                        } elsif ($included_parent_dir &&
                                length $included_parent_dir<length
                                $key && unpack("a".length $included_parent_dir,
                                $key) eq $included_parent_dir) {
#if ($key=~/bmicalculator/) {
#print "OUTHASH_INCLUDED_PARENT_KEY=$key\n";<STDIN>;
#}
                           ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'ALL', {},
                                'DEPLOY_SOMEFILES_OF_CURDIR' ];
                           $excluded_parent_dir='';
                        } elsif ((-1<index ${$modif}[2],'i') &&
                              (-1==index ${$modif}[2],'e')) {
                           ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'EXCLUDE', {},
                                'DEPLOY_NOFILES_OF_CURDIR' ];
                           $excluded_parent_dir='';
                           $included_parent_dir='';
                        } else {
#if ($key=~/bmicalculator/) {
#print "OUTHASH_ELSE_KEY=$key\n";<STDIN>;
#}
                           ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'ALL', {},
                              'DEPLOY_SOMEFILES_OF_CURDIR' ];
                           $excluded_parent_dir='';
                           $included_parent_dir='';
                        }
                     } else {
#if ($key=~/bmicalculator/) {
#print "YEERRRRR=$key\n";<STDIN>;
#}
                        if ($len_dir<length $line) {
                           # Get New Directory Key
                           $prevkey=$key;
                           $key=unpack("x$len_dir a*",$line);
#print "KEYHERERERERER2222222 and LINE=$line\n" if $key eq 'member/my_health/calculators/bmicalculator/images';
#<STDIN> if $key eq 'member/my_health/calculators/bmicalculator/images';
                           if ($ms_share || $ms_domain) {
                              $key=~tr/\\/\//;
                           }
                           $file_count=0;
                           $cur_dir_excluded=0;
                        }
                        ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'ALL', {},
                           'DEPLOY_SOMEFILES_OF_CURDIR' ];
                     }
                  }
               } else {
                  if ($mod_files_flag &&
                        ${$cmd_handle->{"_${bd}hash"}}{$key}[2]
                        eq 'DEPLOY_SOMEFILES_OF_CURDIR') {
#if ($key=~/bmicalculator/) {
#print "HERE I AMMM888 AND KEY=$key\n";<STDIN>;
#}
                     ${$cmd_handle->{"_${bd}hash"}}{$key}[0]='SOME';
                  }
                  if ($len_dir<length $line) {
                     # Get New Directory Key
                     $prevkey=$key;
                     $key=unpack("x$len_dir a*",$line);
#print "KEYHERERERERER33333 and LINE=$line\n" if $key eq 'member/my_health/calculators/bmicalculator/images';
#<STDIN> if $key eq 'member/my_health/calculators/bmicalculator/images';
                     if ($ms_share || $ms_domain) {
                        $key=~tr/\\/\//;
                     }
                     $file_count=0;
                     $cur_dir_excluded=0;
                  }
                  ${$cmd_handle->{"_${bd}hash"}}{$key}=[ 'ALL', {},
                     'DEPLOY_SOMEFILES_OF_CURDIR' ];
               }
            } elsif ((!$cygwin && $fchar eq '-') ||
                  ($cygwin && $mn ne ' D' && unpack('a5',$size) ne '<DIR>')) {
               $file_count++;
#if ($key eq '/') {
#print "UNIXXXYYLINE=$line and CYGWINNNN=$cygwin and MN=$mn and SIZE=$size and FILE=$file and KEY=$key\n";#<STDIN>;
#}
               if (!$cygwin && $fchar eq '-') {
                  my $up=unpack('x10 a*',"$line");
                  $up=~s/^\s+\d+\s+\S+\s+\S+\s+(\d+\s+.*)$/$1/;
                  ($size,$mn,$dy,$tm,$file)=split / +/, $up, 5;
                  if (-1==index 'JanFebMarAprMayJunJulAugSepOctNovDec',
                        $mn) {
                     ($file=$up)=~s/^.*\d+\s+\w\w\w\s+\d+\s+
                        (?:\d\d:\d\d\s+|\d\d\d\d\s+)+(.*)$/$1/x;
                     ($stdout,$stderr)=$cmd_handle->cmd(
                        "ls -l $file",'__debug__');
                     &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                     my $lchar=substr($stdout,-1);
                     if ($lchar eq '*' || $lchar eq '/'
                            || $lchar eq ':') {
                        if ($lchar eq ':' && !$lchar_flag) {
                           $len_dir--;
                           $lchar_flag=1;
                        } chop $line;
                     }
                     push @sublines, $stdout;
                     next WH;
                  }
                  $mn=$Net::FullAuto::FA_lib::month{$mn} if length $mn==3;
                  $fileyr=0;$hr=0;$mt=0;
                  if (length $tm==4) {
                     $fileyr=$tm;$hr=12;$mt='00';
                  } else {
                     ($hr,$mt)=unpack('a2 @3 a2',"$tm");
                     my $yr=unpack('x1 a2',"$Net::FullAuto::FA_lib::thisyear");
                     $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                     if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
                        --$yr;
                        $yr="0$yr" if 1==length $yr;
                        $fileyr=$Net::FullAuto::FA_lib::curcen.$yr; 
                     } elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
                        my $filetime=timelocal(
                           0,$mt,$hr,$dy,$mn-1,$fileyr);
                        if (time()<$filetime) {
                           --$yr;
                           $yr="0$yr" if 1==length $yr;
                           $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                        }
                     }
#$Net::FullAuto::FA_lib::fa_debug.="GETTING FILEYEAR for KEY=$key and FILE=$file and FILEYR=$fileyr"
#                 ." and THISYEAR=$Net::FullAuto::FA_lib::thisyear and YR=$yr SYR=$yr and CURCEN=$Net::FullAuto::FA_lib::curcen and MN=$mn"
#                 ."\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n";
                  }
               }
#if ($key eq '/') {
#print "CYGWINNNNN\n" if $cygwin;
#print "WITH CAREER AND FILE DIR=$key and FILE=$file and MODFILEFLAG=$mod_files_flag\n";#<STDIN>;
#}
               if ($mod_dirs_flag && ${$cmd_handle->{"_${bd}hash"}}{$key}[0]
                      eq 'EXCLUDE') {
#if ($key eq '/') {
#print "HERE WE ARE EXCLUDING and MODDIR=$mod_dirs_flag and OUTHASHENTRY=",${$cmd_handle->{"_${bd}hash"}}{"$key"}[0],"\n";
#}
                  ${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}
                     =[ 'EXCLUDE','' ];
                  $num_of_excluded++;
               } elsif ($mod_files_flag) {
                  foreach my $modif (@modifiers) {
                     if (${$modif}[3] eq 'f') {
                        $Net::FullAuto::FA_lib::f_sub=regx_prog($modif,'f');
                        my $return=0;my $returned_modif='';
                        ($return,$returned_modif)=
                           &$Net::FullAuto::FA_lib::f_sub($file,$key);
                        my $fileyr=0;
#if ($key eq '/') {
#   print "FILE=$file and RETURN=$return and MODIF=$returned_modif\n";
#   <STDIN>;
#}
                        if ($return || (-1<index $returned_modif,'e')) {
                           if ($return && (-1<index $returned_modif,'e')) {
                              ${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}
                                 =[ 'EXCLUDE','' ];
                              $Net::FullAuto::FA_lib::base_excluded_files{$key}
                                 {$file}='-';
                              if (${$cmd_handle->{"_${bd}hash"}}{$key}[2] eq
                                   'DEPLOY_SOMEFILES_OF_CURDIR') {
                                 ${$cmd_handle->{"_${bd}hash"}}{$key}[2]
                                    ='DEPLOY_NOFILES_OF_CURDIR';
                              }
                              $num_of_excluded++;
                              $cur_dir_excluded++;
                           } else {
                              if (!$ms_share && !$ms_domain && !$cygwin) {
                                 my $up=unpack('x10 a*',$line);
                                 $up=~s/^\s+\d+\s+\S+\s+\S+\s+(\d+\s+.*)$/$1/;
                                 ($size,$mn,$dy,$tm,$file)=split / +/, $up, 5;
                                 $mn=$Net::FullAuto::FA_lib::month{$mn} if length $mn==3;
                                 $fileyr=0;my $hr=0;my $mt='';
                                 if (length $tm==4) {
                                   $fileyr=$tm;$hr=12;$mt='00';
                                 } else {
                                    ($hr,$mt)=unpack('a2 @3 a2',$tm);
                                    my $yr=unpack('x1 a2',$Net::FullAuto::FA_lib::thisyear);
                                    $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                                    if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
                                       --$yr;
                                       $yr="0$yr" if 1==length $yr;
                                       $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                                    } elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
                                       my $filetime=timelocal(
                                          0,$mt,$hr,$dy,$mn-1,$fileyr);
                                       if (time()<$filetime) {
                                          --$yr;
                                          $yr="0$yr" if 1==length $yr;
                                          $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                                       }
                                    }
                                 }
                                 $file=~s/\s*$//g;
                                 next if !$file;
                              } else {
                                 $size=~s/^\s*//;
                                 my $testyr=100+$yr;
                                 $fileyr=$Net::FullAuto::FA_lib::curyear;
                                 if ($testyr<$Net::FullAuto::FA_lib::thisyear) {
                                    $hr=12;$mt='00';
                                    $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                                    #my $syr=$yr;
                                    #if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
                                    #   --$syr;
                                    #   $syr="0$syr" if 1==length $syr;
                                    #   $fileyr=$Net::FullAuto::FA_lib::curcen.$syr;
                                    #} elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
                                    #   my $filetime=timelocal(
                                    #      0,0,$hr,$dy,$mn-1,$fileyr);
                                    #   if (time()<$filetime) {
                                    #      --$syr;
                                    #      $syr="0$syr" if 1==length $syr;
                                    #      $fileyr=$Net::FullAuto::FA_lib::curcen.$syr;
                                    #   }
                                    #}
                                 } elsif ($hr<13) {
                                    $hr=$Net::FullAuto::FA_lib::hours{$hr.$pm};
                                 }
                              } $chmod=" $chmod" if $chmod;
                              my $dt=(3==length $mn)?$Net::FullAuto::FA_lib::month{$mn}:$mn;
#if ($key eq '/') {
#print "GOOOOOOODDDDDFILE===$file and KEY=$key\n";<STDIN>;
#}
#$Net::FullAuto::FA_lib::fa_debug.="FILEYR1=$fileyr and FILE=$file\n" if $base_dest eq 'BASE';
                              ${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}=
                                 [ '',"$dt $dy $hr $mt $fileyr $size$chmod" ];
#if ($key eq '/') {
#print "WE JUST DID OUTHASH and KEY=$key and $#{[keys %{$cmd_handle->{"_${bd}hash"}}]}\n";
#}
                              if (${$cmd_handle->{"_${bd}hash"}}{$key}[2] eq
                                   'DEPLOY_NOFILES_OF_CURDIR') {
                                 ${$cmd_handle->{"_${bd}hash"}}{$key}[2]=
                                    'DEPLOY_SOMEFILES_OF_CURDIR';
                              }
                              $num_of_included++;
                           }
                        } else {
                           ${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}
                              =[ 'EXCLUDE','' ];
                           if (${$cmd_handle->{"_${bd}hash"}}{$key}[2] eq
                                 'DEPLOY_SOMEFILES_OF_CURDIR') {
                              if ($file_count==++$cur_dir_excluded) {
#if ($key eq '/') {
#print "HERE WE ARE and KEY=$key\n";<STDIN>;
#}
                                 ${$cmd_handle->{"_${bd}hash"}}{$key}[2]
                                    ='DEPLOY_NOFILES_OF_CURDIR'
                              }
                           }  
                           $num_of_excluded++;
                        }
                     }
                  }
               } else {
                  my $fileyr=0;
                  if (!$cygwin) {
                     my $up=unpack('x10 a*',"$line");
                     $up=~s/^\s+\d+\s+\S+\s+\S+\s+(\d+\s+.*)$/$1/;
                     ($size,$mn,$dy,$tm,$file)=split / +/, $up, 5;
                     $mn=$Net::FullAuto::FA_lib::month{$mn} if length $mn==3;
                     $fileyr='';my ($hr,$mt)='';
                     if (length $tm==4) {
                        $fileyr=$tm;$hr=12;$mt='00';
                     } else {
                        ($hr,$mt)=unpack('a2 @3 a2',$tm);
                        my $yr=unpack('x1 a2',$Net::FullAuto::FA_lib::thisyear);
                        $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                        if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
                           --$yr;
                           $yr="0$yr" if 1==length $yr;
                           $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                        } elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
                           my $filetime=timelocal(
                              0,$mt,$hr,$dy,$mn-1,$fileyr);
                           if (time()<$filetime) {
                              --$yr;
                              $yr="0$yr" if 1==length $yr;
                              $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                           }
                        }
                     }
                     $file=~s/\s*$//g;
                  } else {
                     $size=~s/^\s*//;
                     my $testyr="1$yr";
                     $fileyr=$Net::FullAuto::FA_lib::curyear;
                     if ($testyr<$Net::FullAuto::FA_lib::thisyear) {
                        $hr=12;$mt='00';
                        $fileyr=$Net::FullAuto::FA_lib::curcen.$yr;
                        #my $syr=$yr;
                        #if ($Net::FullAuto::FA_lib::thismonth<$mn-1) {
                        #   --$syr;
                        #   $syr="0$syr" if 1==length $syr;
                        #   $fileyr=$Net::FullAuto::FA_lib::curcen.$syr;
                        #} elsif ($Net::FullAuto::FA_lib::thismonth==$mn-1) {
                        #   my $filetime=timelocal(
                        #      0,0,$hr,$dy,$mn-1,$fileyr);
                        #   if (time()<$filetime) {
                        #      --$syr;
                        #      $syr="0$syr" if 1==length $syr;
                        #      $fileyr=$Net::FullAuto::FA_lib::curcen.$syr;
                        #   }
                        #}
                     } elsif ($hr<13) {
                        $hr=$Net::FullAuto::FA_lib::hours{$hr.$pm};
                     }
                  } $chmod=" $chmod" if $chmod;
                  my $dt=(3==length $mn)?$Net::FullAuto::FA_lib::month{$mn}:$mn;
#if ($key eq '/') {
#print "GOOOOOOODDDDDFILE222===$file\n";<STDIN>;
#}
#$Net::FullAuto::FA_lib::fa_debug.="FILEYR2=$fileyr and FILE=$file and BASEDEST=$base_dest\n";
                  ${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}=
                     [ '',"$mn $dy $hr $mt $fileyr $size$chmod" ];
#if ($key=~/pdf|common|stylesheet|header/ && $file=~/index/ && !$cygwin) {
#print "JUST UPDATED OUTHASH=",@{${$cmd_handle->{"_${bd}hash"}}{$key}[1]{$file}},"\n";<STDIN>;
#}
                  $num_of_included++;
               }
            } 
         }
      }
   };
   if ($@) {
      return '','redo ls' if unpack('a7',$@) eq 'redo ls';
      if (unpack('a10',$@) eq 'The System') {
         return '',$@;
      } else {
         my $die="The System $hostname Returned"
                ."\n              the Following Unrecoverable Error "
                ."Condition\n              at ".(caller(0))[1]." "
                ."line ".(caller(0))[2]." :\n\n       ".$@;
         print $Net::FullAuto::FA_lib::MRLOG $die
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         return '', "$die";
      }
   } ${$cmd_handle->{"_${bd}hash"}}{"___%EXCluD%E--NUMOFFILES"}=$num_of_included;
   ${$cmd_handle->{"_${bd}hash"}}{"___%EXCluD%E--NUMOFBASEFILES"}
                        =$num_of_included+$num_of_excluded;
   #return \%outhash;

}

package Rem_Command;

# Handle INT SIGNAL interruption
# local $SIG{ INT } = sub{ print "I AM HERE" };

sub new {
   print "Rem_Command::new CALLER=",caller,"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "Rem_Command::new CALLER=",(caller),"\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   our $timeout=$Net::FullAuto::FA_lib::timeout;
   our $test=$Net::FullAuto::FA_lib::test;
   our $debug=$Net::FullAuto::FA_lib::debug;
   my $self = { };
   my $class=ref $_[0]||$_[0];
   my $hostlabel=$_[1];
   my $new_master=$_[2]||'';
   my $_connect=$_[3]||'';
   my $override_login_id=$_[4]||'';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
      $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
      $owner,$group,$fttimeout,$transfer_dir,$rcm_chain,
      $rcm_map,$uname,$ping,$freemem)
      =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   my $chk_id='';
   if ($su_id) { $chk_id=$su_id }
   elsif ($login_id) { $chk_id=$login_id }
   else { $chk_id=$Net::FullAuto::FA_lib::username }
   my $cmd_handle='';my $work_dirs='';$cmd_type='';
   my $ftm_type='';my $stderr='';my $cmd_pid='';my $shell='';
   my $shell_pid=0;
   ($cmd_handle,$work_dirs,$uname,$cmd_type,
      $ftm_type,$smb,$stderr,$freemem,$ip,$hostname,
      $cmd_pid,$shell_pid,$cygdrive,$shell)=&cmd_login(
      $hostlabel,$new_master,$_connect,$override_login_id);
   if ($stderr) {
      my $die="\n       FATAL ERROR! - $stderr";
      print $Net::FullAuto::FA_lib::MRLOG $die if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      return '',$die if wantarray;
      &Net::FullAuto::FA_lib::handle_error($die);
   }
   if ($smb) {
      $self->{_hostlabel}=[ $hostlabel,$Net::FullAuto::FA_lib::DeploySMB_Proxy[0] ];
      $self->{_smb}=1;
   } else {
      $self->{_hostlabel}=[ $hostlabel,'' ];
   }
   $self->{_cmd_handle}=$cmd_handle;
   $self->{_cmd_type}=$cmd_type;
   $self->{_connect}=$_connect;
   $self->{_ftm_type}=$ftm_type;
   $self->{_work_dirs}=$work_dirs;
   $self->{_ip}=$ip;
   $self->{_uname}=$uname;
   $self->{_luname}=$Net::FullAuto::FA_lib::OS;
   $self->{_cmd_pid}=$cmd_pid;
   $self->{_sh_pid}=$shell_pid;
   $self->{_shell}=$shell;
   if ($cygdrive) {
      $self->{_cygdrive}=$cygdrive;
      $self->{_cygdrive_regex}=qr/^$cygdrive\//;
   }
   bless($self,$class);
   $Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$chk_id"}=$self;
   return $self,''

}

sub handle_error
{
   my @topcaller=caller;
   print "Rem_Command::handle_error() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "Rem_Command::handle_error() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   return &Net::FullAuto::FA_lib::handle_error(@_);
}

sub get
{
   my @topcaller=caller;
   print "Rem_Command::get() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "Rem_Command::get() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my $stderr="ERROR MESSAGE! :"
             ."\n\n                The $self->{_connect} method does"
             ."\n                not enable file transfer get()"
             ."\n                functionality. To do file transfer"
             ."\n                transfer use a method such as"
             ."\n                \'connect_secure\' or \'connect_host\'"
             ."\n                etc.\n\n";
   if (wantarray) {
      return '',"\n\n        ".(caller(1))[3]." $stderr       at ".
                $topcaller[1]." - Line $topcaller[2].\n";
   } else {
      &Net::FullAuto::FA_lib::handle_error($stderr); 
   }
}

sub put
{
   my @topcaller=caller;
   print "Rem_Command::put() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "Rem_Command::put() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my $stderr="ERROR MESSAGE! :"
             ."\n\n                The $self->{_connect} method does"
             ."\n                not enable file transfer put()"
             ."\n                functionality. To do file transfer"
             ."\n                transfer use a method such as"
             ."\n                \'connect_secure\' or \'connect_host\'"
             ."\n                etc.\n\n";
   if (wantarray) {
      return '',"\n\n       ".(caller(1))[3]." $stderr       at ".
                $topcaller[1]." - Line $topcaller[2].\n";
   } else {
      &Net::FullAuto::FA_lib::handle_error($stderr);
   }
}

sub cmd_login
{
#my $logreset=1;
#if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
#else { $Net::FullAuto::FA_lib::log=1 }

   my @topcaller=caller;
   print "Rem_Command::cmd_login() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG
     "Rem_Command::cmd_login() CALLER=",
      (join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::log &&
     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $hostlabel=$_[0];
   my $new_master=$_[1]||0;
   my $_connect=$_[2]||'';
   my $override_login_id=$_[3]||'';
print "WE GOT HOSTLABEL=$hostlabel<==\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "WE GOT HOSTLABEL=$hostlabel<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$cdtimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,$_connect);
   if ($override_login_id) {
      $login_id=$override_login_id;
      $su_id='';
   }
print "WE ARE BACK FROM LOOKUP<==\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "WE ARE BACK FROM LOOKUP<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
      $cdtimeout=$Net::FullAuto::FA_lib::cltimeout;
   } elsif (!$cdtimeout) {
      $cdtimeout=$timeout if !$cdtimeout;
   }
   $login_id=$Net::FullAuto::FA_lib::username if !$login_id;
   my $cmd_handle='';my $work_dirs='';my $cmd_type='';
   my $ftm_type='';my $use_su_login='';my $id='';my $cygwin='';
   my $su_login='';my $die='';my $login_passwd='';my $ms_su_id='';
   my $ms_ms_domain='';my $ms_ms_share='';my $ms_login_id='';
   my $stderr='';my $ms_hostlabel='';my $ms_host='';
   my $cmd_errmsg='';my $host='';my $output='';my $shell_pid=0;
   my $retrys=0;my $login_tries=0;my $cmd_pid='';my $shell='';
   if (lc(${$ftr_cnct}[0]) eq 'smb') {
      $smb=1;
      if ($use eq 'hostname') {
         $ms_host=$hostname;
      } else {
         $ms_host=$ip;
      }
      $ms_hostlabel=$hostlabel;
      $ms_su_id=$su_id;
      $ms_login_id=$login_id;
      $ms_ms_domain=$ms_domain;
      $ms_ms_share=$ms_share;
      my $smbtimeout=$cdtimeout;
      ($ip,$hostname,$use,$ms_share,$ms_domain,
         $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
         $owner,$group,$cdtimeout,$transfer_dir,$rcm_chain,
         $rcm_map,$uname,$ping,$freemem)
         =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
         $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]);
      $host=($use eq 'ip')?$ip:$hostname;
      if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
         $cdtimeout=$Net::FullAuto::FA_lib::cltimeout;
      } elsif (!$cdtimeout) {
         $cdtimeout=$timeout if !$cdtimeout;
      }
      $cdtimeout=$smbtimeout if $cdtimeout<$smbtimeout;
      $hostlabel=$Net::FullAuto::FA_lib::DeploySMB_Proxy[0];
      if (!$login_id && !$su_id) {
         $ms_login_id=$login_id=$Net::FullAuto::FA_lib::username;
      }
      my $loginid = ($su_id) ? $su_id : $login_id;
      $use_su_login=1 if $su_id;
      $login_passwd=&Net::FullAuto::FA_lib::getpasswd($Net::FullAuto::FA_lib::DeploySMB_Proxy[0],
             $loginid,$ms_domain,'','','smb');
             #$loginid,$ms_domain,$cmd_errmsg,'','SMB_Proxy');
   } else {
      $login_passwd=&Net::FullAuto::FA_lib::getpasswd($hostlabel,$login_id,'','');
   }
   #&Net::FullAuto::FA_lib::take_semaphore(1234);
   $host=($use eq 'ip')?$ip:$hostname;
   $host='localhost' if exists $same_host_as_Master{$host};
   if ($host eq 'localhost' &&
         exists $Hosts{"__Master_${$}__"}{'Local'}) {
      my $loc=$Hosts{"__Master_${$}__"}{'Local'};
      unless ($loc eq 'connect_ssh'
             || $loc eq 'connect_telnet'
             || $loc eq 'connect_ssh_telnet'
             || $loc eq 'connect_telnet_ssh') {
          my $die="\n       FATAL ERROR - \"Local\" has "
                 ."*NOT* been Properly\n              Defined in the "
                 ."\"$fa_hosts\" File.\n              This "
                 ."Element must have one of the following\n"
                 ."              Values:\n\n       "
                 ."          'connect_ssh'or 'connect_telnet'\n       "
                 ."          'connect_ssh_telnet' or\n       "
                 ."          'connect_telnet_ssh'\n\n"
                 ."       \'$loc\' is INCORRECT.\n\n";
          print $Net::FullAuto::FA_lib::MRLOG $die
             if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
          &Net::FullAuto::FA_lib::handle_error($die,'__cleanup__');
      } elsif ($loc eq 'connect_ssh') {
          $_connect=$loc;
          @connect_method=('ssh');
      } elsif ($loc eq 'connect_telnet') {
          $_connect=$loc;
          @connect_method=('telnet');
      } elsif ($loc eq 'connect_ssh_telnet') {
          $_connect=$loc;
          @connect_method=('ssh','telnet');
      } else {
          $_connect=$loc;
          @connect_method=('telnet','ssh');
      }
   } else { @connect_method=@{$cmd_cnct} }
   my $previous_method='';
   my $ignore='';my $preferred=0;my $outpt='';my $cygdrive='';
   while (1) {
      undef $@;
      eval {
         if ($hostlabel eq "__Master_${$}__" && !$new_master) {
            $cmd_handle=$Net::FullAuto::FA_lib::localhost->{_cmd_handle};
            $cmd_pid=$Net::FullAuto::FA_lib::localhost->{_cmd_pid};
            $shell_pid=$Net::FullAuto::FA_lib::localhost->{_sh_pid};
            #&Net::FullAuto::FA_lib::give_semaphore(1234);
         } else {
print $Net::FullAuto::FA_lib::MRLOG
   "GOINGKKK FOR NEW CMD_HANDLE and CONNECT_METH=@connect_method<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
my $w2loop=0;
            WH: while (1) {
               my $rm_cnt=-1;$sshloginid='';
               CM: foreach my $connect_method (@connect_method) {
                  $rm_cnt++;
                  if ($previous_method && !$preferred) {
                     print "Warning, Preferred Connection ",
                           "$previous_method Failed\n";
                     $preferred=1;
                  } else { $previous_method=$connect_method }
                  $previous_method=$connect_method;
                  if (lc($connect_method) eq 'telnet') {
                     eval { 
                        my $telnetpath='';
                        if (exists $Hosts{"__Master_${$}__"}{'telnet'}) {
                           $telnetpath=$Hosts{"__Master_${$}__"}{'telnet'};
                           $telnetpath.='/' if $telnetpath!~/\/$/;
                        }
                        ($cmd_handle,$cmd_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                           ["${telnetpath}telnet",$host])
                           or &Net::FullAuto::FA_lib::handle_error(
                           "couldn't launch telnet subprocess");
#print "CMD_PIDTELNETNNNNNNN=$cmd_pid<====\n";
                        $cmd_handle=Net::Telnet->new(Fhopen => $cmd_handle,
                           Timeout => $cdtimeout);
                        if ($su_id) {
                           $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                              {'cmd_su_'.++$Net::FullAuto::FA_lib::pcnt}=
                              [ $cmd_handle,$cmd_pid,'','' ];
                        } else {
                           $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                              {'cmd_id_'.++$Net::FullAuto::FA_lib::pcnt}=
                              [ $cmd_handle,$cmd_pid,'','' ];
                        }
                        $cmd_handle->telnetmode(0);
                        $cmd_handle->binmode(1);
                        $cmd_handle->output_record_separator("\r");
                        $cmd_handle->timeout($cdtimeout);
                     };
                     if ($@) {
                        #if ($rm_cnt==$#connect_method) {
                        if (1<=$#connect_method) {
                           undef $@;next;
                        } else {
                           my $die=$@;undef $@;
                           die $die;
                        }
                     }
                     while (my $line=$cmd_handle->get) {
#print "TELNET_CMD_HANDLE_LINE=$line\n";
print $Net::FullAuto::FA_lib::MRLOG "TELNET_CMD_HANDLE_LINE=$line\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        my $showline=$line;
                        chomp($showline=~tr/\0-\11\13-\37\177-\377//d);
                        $showline=~tr/\12/\033/;
                        $showline=~tr/\33//s;
                        $showline=~tr/\33/\12/;
                        $showline=~s/^\12//s;
                        $showline=~s/login.*$//s;
                        print $showline if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                        print $Net::FullAuto::FA_lib::MRLOG $showline
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        chomp($line=~tr/\0-\37\177-\377//d);
                        #if ((20<length $line && unpack('a21',$line)
                        #      eq 'A remote host refused') ||
                        #      (31<length $line && (unpack('a32',$line)
                        #      eq 'ftp: connect: Connection refused' ||
                        #      unpack('a32',$line) eq
                        #      'ftp: connect: Attempt to connect'))) {
                        if (-1<index $line,'Connection refused') {
                           ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9)
                              if &Net::FullAuto::FA_lib::testpid($shell_pid);
                           ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($cmd_pid,9)
                              if &Net::FullAuto::FA_lib::testpid($cmd_pid);
                           if ($su_id) {
                              delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                                 {'cmd_su_'.$Net::FullAuto::FA_lib::pcnt};
                           } else {
                              delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                                 {'cmd_id_'.$Net::FullAuto::FA_lib::pcnt};
                           }
                           if (1<=$#connect_method) {
                           #if ($rm_cnt==$#connect_method) {
                              $stderr=$line;
                              next CM;
                           } else {
                              #&Net::FullAuto::FA_lib::give_semaphore(1234);
                              &Net::FullAuto::FA_lib::handle_error($line);
                           }
                        }
                        if (-1<index $line,'CYGWIN') {
                           if ($su_id) {
                              if ($su_id ne $login_id) {
                                 $login_id=$su_id;
                              } else { $su_id='' }
                              my $value=$Net::FullAuto::FA_lib::Processes{$hostlabel}
                                 {$login_id}{"cmd_su_$Net::FullAuto::FA_lib::pcnt"};
                              delete $Net::FullAuto::FA_lib::Processes{$hostlabel}
                                 {$login_id}{"cmd_su_$Net::FullAuto::FA_lib::pcnt"};
                              $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                                 {"cmd_id_$Net::FullAuto::FA_lib::pcnt"}=$value;
                           }
                           $uname='cygwin';
                           $Net::FullAuto::FA_lib::Hosts{$hostlabel}{'Uname'}='cygwin';
                           $cygwin=1;
                        } elsif (-1<index $line,'AIX') {
                           $uname='aix';
                           $Net::FullAuto::FA_lib::Hosts{$hostlabel}{'Uname'}='aix';
                        }
                        last if $line=~
                           /(?<!Last )login[: ]+$|username[: ]+$/i;
                     }
                     if ($cmd_errmsg &&
                           (-1==index $cmd_errmsg,'Cannot su to')) {
                        $login_passwd=&Net::FullAuto::FA_lib::getpasswd(
                           $hostlabel,$login_id,'',$cmd_errmsg)
                     } else {
                        $login_passwd=&Net::FullAuto::FA_lib::getpasswd(
                           $hostlabel,$login_id,'','')
                     }
                     $cmd_handle->print($login_id);
                     if ($cmd_handle->errmsg) {
                        #&Net::FullAuto::FA_lib::give_semaphore(1234);
                        &Net::FullAuto::FA_lib::handle_error($cmd_handle->errmsg);
                     } $cmd_type='telnet';
                     ($ignore,$stderr)=
                        &File_Transfer::wait_for_ftr_passwd_prompt(
                           { _cmd_handle=>$cmd_handle,
                             _hostlabel=>[ $hostlabel,'' ],
                             _cmd_type=>$cmd_type,
                             _connect=>$_connect });
                     if ($stderr && $rm_cnt!=$#connect_method) {
                        $cmd_handle->close;
                        next CM;
                     } last
                  } elsif (lc($connect_method) eq 'ssh') {
                     $sshloginid=($use_su_login)?$su_id:$login_id;
                     eval {
                        my $sshpath='';
                        if (exists $Hosts{"__Master_${$}__"}{'ssh'}) {
                           $sshpath=$Hosts{"__Master_${$}__"}{'ssh'};
                           $sshpath.='/' if $sshpath!~/\/$/;
                        }
                        ($cmd_handle,$cmd_pid)=&Net::FullAuto::FA_lib::pty_do_cmd(
                           ["${sshpath}ssh",'-v',"$sshloginid\@$host",
                            $Net::FullAuto::FA_lib::slave])
                           or &Net::FullAuto::FA_lib::handle_error(
                           "couldn't launch ssh subprocess");
#print "CMD_PIDSSHHHHHHHHHHH=$cmd_pid<=========\n";
                        $cmd_handle=Net::Telnet->new(Fhopen => $cmd_handle,
                           Timeout => $cdtimeout);
                        if ($su_id) {
                           $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                              {'cmd_su_'.++$Net::FullAuto::FA_lib::pcnt}=
                              [ $cmd_handle,$cmd_pid,'','' ];
                        } else {
                           $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                              {'cmd_id_'.++$Net::FullAuto::FA_lib::pcnt}=
                              [ $cmd_handle,$cmd_pid,'','' ];
                        }
                        $cmd_handle->telnetmode(0);
                        $cmd_handle->binmode(1);
                        $cmd_handle->output_record_separator("\r");
                        $cmd_handle->timeout($cdtimeout);
                     };
                     if ($@) {
                        if ($rm_cnt==$#connect_method) {
                           undef $@;next;
                        } else {
                           my $die=$@;undef $@;
                           die $die;
                        }
                     }
                     if ($cmd_errmsg &&
                           (-1==index $cmd_errmsg,'Cannot su to')) {
                        $login_passwd=&Net::FullAuto::FA_lib::getpasswd(
                           $hostlabel,$login_id,'',$cmd_errmsg)
                     } else {
                        $login_passwd=&Net::FullAuto::FA_lib::getpasswd(
                           $hostlabel,$login_id,'','')
                     } $cmd_type='ssh';
                     ## Wait for password prompt.
                     ($ignore,$stderr)=
                        &File_Transfer::wait_for_ftr_passwd_prompt(
                           { _cmd_handle=>$cmd_handle,
                             _hostlabel=>[ $hostlabel,'' ],
                             _cmd_type=>$cmd_type,
                             _connect=>$_connect });
                     if ($stderr) {
                        if ($rm_cnt!=$#connect_method) {
                           $cmd_handle->close;
                           next CM;
                        } else {
                           #&Net::FullAuto::FA_lib::give_semaphore(1234);
                           &Net::FullAuto::FA_lib::handle_error($stderr);
                        }
                     }
                  } last
               }
               if ($stderr) {
                  if ((20<length $stderr && unpack('a21',$stderr)
                        eq 'A remote host refused') ||
                        (31<length $stderr && (unpack('a32',$stderr)
                        eq 'ftp: connect: Connection refused' ||
                        unpack('a32',$stderr) eq
                        'ftp: connect: Attempt to connect')) && (exists
                        $Net::FullAuto::FA_lib::Hosts{$Net::FullAuto::FA_lib::DeploySMB_Proxy[0]})) {
                     $cmd_handle->close;
                     unless ($cmd_errmsg) {
                        if ($use eq 'hostname') {
                           $ms_host=$hostname;
                        } else {
                           $ms_host=$ip;
                        }
                        $ms_hostlabel=$hostlabel;
                        $ms_su_id=$su_id;
                        $ms_login_id=$login_id;
                        $ms_ms_domain=$ms_domain;
                        $ms_ms_share=$ms_share;
                        ($ip,$hostname,$use,$ms_share,$ms_domain,
                           $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
                           $owner,$group,$cdtimeout,$transfer_dir,$rcm_chain,
                           $rcm_map,$uname,$ping,$freemem)
                           =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label(
                           $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]);
                        if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
                           $cdtimeout=$Net::FullAuto::FA_lib::cltimeout;
                        } elsif (!$cdtimeout) {
                           $cdtimeout=$timeout if !$cdtimeout;
                        }
                        if (!$login_id && !$su_id) {
                           $ms_login_id=$login_id=$Net::FullAuto::FA_lib::username;
                        }
                     } my $loginid = ($su_id) ? $su_id : $login_id;
                     $use_su_login=1 if $su_id;
                     $login_passwd=
                        &Net::FullAuto::FA_lib::getpasswd($Net::FullAuto::FA_lib::DeploySMB_Proxy[0],
                        $loginid,$ms_domain,$cmd_errmsg,
                        '','smb');
                        #'','SMB_Proxy');
                     $cmd_errmsg='';$cmd_type='';
                     if ($_connect eq 'connect_ssh'
                           || $_connect eq 'connect_secure') {
                        @{$cmd_cnct}=('ssh')
                     } elsif ($_connect eq 'connect_telnet'
                           || $_connect eq 'connect_insecure') {
                        @{$cmd_cnct}=('telnet')
                     } elsif ($_connect eq 'connect_host') {
                        @{$cmd_cnct}=('ssh','telnet')
                     } else { @{$cmd_cnct}=('telnet','ssh') }
                     next;
                  } else { &Net::FullAuto::FA_lib::handle_error($@) }
               } last
            }
            my $showcmd=
               "\n\tLoggingK into $host via $cmd_type  . . .\n\n";
            print $showcmd if (!$Net::FullAuto::FA_lib::cron
               || $Net::FullAuto::FA_lib::debug)
               && !$Net::FullAuto::FA_lib::quiet;
            print $Net::FullAuto::FA_lib::MRLOG $showcmd
               if $Net::FullAuto::FA_lib::log
               && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            ## Send password.
            $cmd_handle->print($login_passwd);
            my $uhray=&Net::FullAuto::FA_lib::get_prompt();
            $cmd_handle->print('cmd /Q /C "set /A '.${$uhray}[1].'&echo _-"'.
                         '|| printf \\\\'.${$uhray}[2].'\\\\'.${$uhray}[3].
                         '\\\\137\\\\055 2>/dev/null');
            my $output='';my $ct=0;
            while (1) {
               eval {
                  while (my $line=$cmd_handle->get(Timeout=>5)) {
print "GETTELSSHPROMPTLINEEEEEEEEEEE=$line and ${$uhray}[0]_-<==\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "GETTELSSHPROMPTLINE=$line<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     chomp($line=~tr/\0-\11\13-\37\177-\377//d);
                     $outpt.=$line;
                     $output.=$line;
                     $output=~s/login:.*//s;
                     if ($line=~/(?<!Last )login[: ]*$/m ||
                          unpack('a10',$line) eq 'Login inco'
                           || (-1<index $line,'Perm')) {
                        #&Net::FullAuto::FA_lib::give_semaphore(1234);
                        while (1) {
                           last if $previous_method eq $connect_method[0];
                           shift @connect_method;
                        }
                        $output=~s/^\s*//s;
                        $output=~s/\s*//s;
                        if ($output=~/^.*(Perm.*)$/s) {
                           my $one=$1;
                           if ($output=~/^.*(No more auth.*)$/s) {
                              die "$1\n";
                           } die "$one\n";
                        }
                        die "$output\n";
                     } elsif ($line=~/Connection closed/s) {
                        die "$output\n";
                     }
                     if ($outpt=~/${$uhray}[0]_-(.*)$/s) {
                        $prompt=$1;
                        last;
                     }
                  }
               };
               if ($@) {
                  my $ev_err=$@;
                  if ($ev_err=~/read timed-out/s && $ct++<2) {
                     my $uhray=&Net::FullAuto::FA_lib::get_prompt();
                     $cmd_handle->print('cmd /Q /C "set /A '.${$uhray}[1].
                         '&echo _-"'.
                         '|| printf \\\\'.${$uhray}[2].'\\\\'.${$uhray}[3].
                         '\\\\137\\\\055 2>/dev/null');
                  } elsif ($sshloginid &&
                        $ev_err=~/Permission denied/s) {
                     if ($ev_err=~/No more auth/s) {
                        die $ev_err;
                     } else {
                        $cmd_handle->print(&Net::FullAuto::FA_lib::getpasswd(
                             $hostlabel,$sshloginid,'',$@,
                             '__force__'));
                        my $uhray=&Net::FullAuto::FA_lib::get_prompt();
                        $cmd_handle->print('cmd /Q /C "set /A '
                           .${$uhray}[1].'&echo _-"'.
                           '|| printf \\\\'.${$uhray}[2].'\\\\'.${$uhray}[3].
                           '\\\\137\\\\055 2>/dev/null');
                     }
                  } else { die $ev_err }
               } else { last }
            }
            # Find out what the shell is.
            $cmd_handle->print('set');
            $ct=0;
            while (1) {
               eval {
                  my $outp='';
                  while (my $line=$cmd_handle->getline(
                           Timeout=>5)) {
                     chomp($line=~tr/\0-\37\177-\377//d);
                     $outpt.=$line;
                     if (!$shell && (-1<index lc($line),'shell') &&
                           $line=~/^[Ss][Hh][Ee][Ll[Ll][=|\s]*(.*)$/) {
                        $shell=$1;
                        $shell=~s/^.*[\\\\|\/]([^\\|\/]+)$/$1/;
                        $cmd_handle->print if $shell eq 'csh';
                        last;
                     }
                  }
               };
print $Net::FullAuto::FA_lib::MRLOG "SHELL_PIDRRRRR**BBBB=$shell_pid<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               if ($@) {
                  $cmd_handle->print;
               } elsif (!$shell && $ct++<50) {
                  $cmd_handle->print;
               } else { last }
            }
            &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle,$prompt);
            if ($shell eq 'bash' || $shell eq 'ksh' || $shell eq 'sh') {
               my $fp=$funkyprompt;
               $fp=~s/\\\\/\\\\\\\\/g;
               $cmd_handle->print("PS1=`printf $fp`;export PS1;unset PROMPT_COMMAND");
               while (my $line=$cmd_handle->get) {
                  $out.=$line;
                  chomp($out=~tr/\0-\37\177-\377//d);   
                  last if -1<index $out,'_funkyPrompt_';
               }
            } else {
               $cmd_handle->print("set prompt=`printf $funkyprompt`");
               $cmd_handle->print;
               my $out='';
               while (my $line=$cmd_handle->get) {
                  $out.=$line;
                  chomp($out=~tr/\0-\37\177-\377//d);
                  last if -1<index $out,'_funkyPrompt_';
               }
            } $cmd_handle->prompt('/_funkyPrompt_$/');
            
            $uname=&Net::FullAuto::FA_lib::push_cmd($cmd_handle,
                    'uname',$hostlabel);
            
            if (lc($uname)=~/cygwin/) {
               $uname='cygwin';$cygwin=1;
            } elsif ($uname eq 'AIX') {
               $uname='aix';
            }

            $Net::FullAuto::FA_lib::Hosts{$hostlabel}{'Uname'}=$uname;

            ($shell_pid,$stderr)=Rem_Command::cmd(
               { _cmd_handle=>$cmd_handle,
                 _hostlabel=>[ $hostlabel,'' ] },'echo $$');
            $shell_pid||=0;
            $shell_pid=~/^(\d+)$/;
            $shell_pid=$1;
            if (!$shell_pid) {
               $cmd_handle->print;my $ct=0;
               $cmd_handle->print(
                  'printf \\\\041\\\\041;echo $$;printf \\\\045\\\\045');
               my $allins='';$ct=0;
               while (1) {
                  eval {
                     while (my $line=$cmd_handle->get(
                              Timeout=>5)) {
                        chomp($line=~tr/\0-\37\177-\377//d);
                        $allins.=$line;
print $Net::FullAuto::FA_lib::MRLOG "SHELLPIDLINEEEERRRRRRRR=$allins<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        if ($allins=~/!!(.*)%%/) {
                           $shell_pid=$1;
print $Net::FullAuto::FA_lib::MRLOG "SHELLPIDRRRRR**AAAAA=$shell_pid<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           last;
                        }
                     }
                  };
print $Net::FullAuto::FA_lib::MRLOG "SHELL_PIDRRRRR**BBBB=$shell_pid<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($@) {
                     $cmd_handle->print;
                  } elsif (!$shell_pid && $ct++<50) {
                     $cmd_handle->print;
                  } else { last }
               }
            }
            chomp($shell_pid=~tr/\0-\11\13-\37\177-\377//d);
#print "WHAT IS SHELLPID_CMD_LOGIN=$shell_pid<=**=**=**=**=**=**=**=**=\n";
print $Net::FullAuto::FA_lib::MRLOG
   "SHELLPID_CMD_LOGIN=$shell_pid<=**=**=**=**=**=**=**=**=\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            #&Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
            if ($su_id) {
               ${$Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                  {'cmd_su_'.$Net::FullAuto::FA_lib::pcnt}}[2]=$shell_pid;
            } else {
               ${$Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                  {'cmd_id_'.$Net::FullAuto::FA_lib::pcnt}}[2]=$shell_pid;
            }
            if (!$cygwin) {
               if ($su_id) {
                  $su_login=1;
                  my ($ignore,$su_err)=
                     &Net::FullAuto::FA_lib::su($cmd_handle,$hostlabel,$su_id,
                     $su_id,$hostname,$ip,$use,$error);
                  &Net::FullAuto::FA_lib::handle_error($su_err) if $su_err;
                  # Make sure prompt won't match anything in send data.
                  $cmd_handle->prompt("/$prompt\$/");
                  $cmd_handle->print("export PS1=\'$prompt\';unset PROMPT_COMMAND");

                  ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
                  if ($stderr) {
                     &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                        if $stderr=~/Connection closed/s;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }
               }
            } else {
               ($cygdrive,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$cmd_handle,
                    _hostlabel=>[ $hostlabel,'' ] },
                  "${Net::FullAuto::FA_lib::mountpath}mount -p");
               $cygdrive=~s/^.*(\/\S+).*$/$1/s;
            }
         }
         if (!$uname) {
            &Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
            #&Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
            ($uname,$stderr)=Rem_Command::cmd(
               { _cmd_handle=>$cmd_handle,
                 _hostlabel=>[ $hostlabel,'' ] },'uname');
            $cmd_handle->print;
            if (!$uname) {
               $cmd_handle->print(
                  'printf \\\\041\\\\041;uname;printf \\\\045\\\\045');
               my $allins='';my $ct=0;
               while (my $line=$cmd_handle->get) {
                  chomp($line=~tr/\0-\37\177-\377//d);
                  $allins.=$line;
                  if ($allins=~/!!(.*)%%/) {
                     $uname=$1;
                     last;
                  } else {
                     $cmd_handle->print;
                  } last if $ct++==10;
               }
            }
#print "UNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN=$uname<===\n";
            ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($cmd_handle);
            if ($stderr) {
               &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                  if $stderr=~/Connection closed/s;
               &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
            }
            if (lc($uname)=~/cygwin/) {
               $uname='cygwin';$cygwin=1;
            } elsif ($uname eq 'AIX') {
               $uname='aix';
            }
            $Net::FullAuto::FA_lib::Hosts{$hostlabel}{'Uname'}=$uname;
         }
         if ($smb && $ms_ms_share) {
            my $msloginid = ($ms_su_id) ? $ms_su_id : $ms_login_id;
            my $mspasswd=&Net::FullAuto::FA_lib::getpasswd(
               $hostlabel,$msloginid,
               $ms_share,$cmd_errmsg);
            my $host=$ms_host;
            my $mswin_cwd='';
            ($mswin_cwd,$smb_type,$stderr)=
                  &File_Transfer::connect_share($cmd_handle,
                  $ms_hostlabel);
            &Net::FullAuto::FA_lib::handle_error($stderr,'-3') if $stderr;
            if (!$tran[0] && defined $transfer_dir) {
               $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                          $hostlabel,$cmd_handle,$cmd_type,
                          $cygdrive,$_connect);
               ${$work_dirs}{_pre_mswin}=
                  ${$work_dirs}{_cwd_mswin}=$mswin_cwd;
               ${$work_dirs}{_pre}=${$work_dirs}{_cwd}='';
               ($output,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$cmd_handle,
                    _hostlabel=>[ $hostlabel,
                                  $Net::FullAuto::FA_lib::DeploySMB_Proxy[0] ]
                  },'cd '.${$work_dirs}{_tmp});
               if ($stderr) {
                  @FA_lib::tran=();
                  my $die="Cannot cd to TransferDir -> "
                         .${$work_dirs}{_tmp_mswin}
                         ."\n       $stderr";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
               $Net::FullAuto::FA_lib::tran[0]=${$work_dirs}{_tmp};
               $Net::FullAuto::FA_lib::tran[1]=$hostlabel;
            } else {
               #  ADD CODE HERE FOR DYNAMIC TMP DIR DISCOVERY
               &Net::FullAuto::FA_lib::handle_error(
                  "No TransferDir Defined for $hostlabel");
            }
         } else {
print $Net::FullAuto::FA_lib::MRLOG
   "FTM_TYPE=$ftm_type and CMD_TYPE=$cmd_type ".
   "and CMD_HANDLE=$cmd_handle<====\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $work_dirs=&Net::FullAuto::FA_lib::work_dirs($transfer_dir,
                       $hostlabel,{ _cmd_handle=>$cmd_handle,
                       _uname=>$uname },$cmd_type,$cygdrive,
                       $_connect);
            if ($uname eq 'cygwin') {
               $curdir=&Net::FullAuto::FA_lib::push_cmd($cmd_handle,
                       'cmd /c chdir',$hostlabel);
               my ($drive,$path)=unpack('a1 x1 a*',$curdir);
               ${$work_dirs}{_pre_mswin}=
                  ${$work_dirs}{_cwd_mswin}=$curdir.'\\';
               $path=~s/\\/\//g;
               ${$work_dirs}{_pre}=${$work_dirs}{_cwd}=
                                  $cygdrive.'/'
                                  .lc($drive).$path.'/';
            } else {
               ($curdir,$stderr)=Rem_Command::cmd(
                  { _cmd_handle=>$cmd_handle,
                    _hostlabel=>[ $hostlabel,'' ] },'pwd');
               $curdir.='/' if $curdir ne '/';
               ${$work_dirs}{_pre}=${$work_dirs}{_cwd}=$curdir;
print $Net::FullAuto::FA_lib::MRLOG "CURDIRDETERMINED!!!!!!=$curdir<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            }
         }
      };
      if ($@) {
         $cmd_errmsg=$@;
#print "LOGINPASSERR=$cmd_errmsg and use_su_login=$use_su_login<===\n";
print $Net::FullAuto::FA_lib::MRLOG "LOGINPASSERR=$cmd_errmsg and use_su_login=$use_su_login<===\n";
         print "sub cmd_login ERRMSG=$cmd_errmsg\n" if $debug;
         print $Net::FullAuto::FA_lib::MRLOG "sub cmd_login ERRMSG=$cmd_errmsg\n"
            if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if ((-1<index $cmd_errmsg,'timed-out') ||
               (-1<index $cmd_errmsg,'filehandle isn')) {
print "WHAT IS THE ERROR=$cmd_errmsg<===\n";
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS THE ERROR=$cmd_errmsg<=== and RETRYS=$retrys\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#&Net::FullAuto::FA_lib::handle_error("$@ and LINE=$outpt",'__cleanup__') if $outpt;
            #&Net::FullAuto::FA_lib::give_semaphore(1234);
            if ($retrys<2) {
               $retrys++;
               if (($su_login || $use_su_login) &&
                     exists $Net::FullAuto::FA_lib::Processes{$hostlabel}
                     {$su_id}{"cmd_su_$Net::FullAuto::FA_lib::pcnt"}) {
                  delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
                     {"cmd_su_$Net::FullAuto::FA_lib::pcnt"}
               } elsif (exists $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                     {"cmd_id_$Net::FullAuto::FA_lib::pcnt"}) {
                  delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
                     {"cmd_id_$Net::FullAuto::FA_lib::pcnt"}
               }
               ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9) if
                  $shell_pid && &Net::FullAuto::FA_lib::testpid($shell_pid);
               ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($cmd_pid,9) if
                  &Net::FullAuto::FA_lib::testpid($cmd_pid);
               $cmd_handle->close;next;
            } else {
               my $host= $hostname ? $hostname : $ip;
               $cmd_errmsg="$@\n\n        While Attempting "
                   . "Login to $host\n       -> HostLabel";
               if (-1<index $cmd_errmsg,'timed-out') {
                  $cmd_errmsg.=" \'$hostlabel\'\n\n       Current Timeout "
                             ."Setting is ->  $cdtimeout seconds.";
               } &Net::FullAuto::FA_lib::handle_error($cmd_errmsg);
            }
         } my $die_login_id='';
         if (($su_login || $use_su_login) &&
               exists $Net::FullAuto::FA_lib::Processes{$hostlabel}
               {$su_id}{"cmd_su_$Net::FullAuto::FA_lib::pcnt"}) {
            delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$su_id}
               {"cmd_su_$Net::FullAuto::FA_lib::pcnt"};
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9) if $shell_pid
               && &Net::FullAuto::FA_lib::testpid($shell_pid);
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($cmd_pid,9) if 
               &Net::FullAuto::FA_lib::testpid($cmd_pid);
            $cmd_handle->close;
         } elsif (exists $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
               {"cmd_id_$Net::FullAuto::FA_lib::pcnt"}) {
            delete $Net::FullAuto::FA_lib::Processes{$hostlabel}{$login_id}
               {"cmd_id_$Net::FullAuto::FA_lib::pcnt"};
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($shell_pid,9) if $shell_pid
               && &Net::FullAuto::FA_lib::testpid($shell_pid);
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($cmd_pid,9) if   
               &Net::FullAuto::FA_lib::testpid($cmd_pid);
            $cmd_handle->close;
         }
         if (!$Net::FullAuto::FA_lib::cron) {
            if ($su_login || $use_su_login) {
               &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$su_id,'');
               $die_login_id=$su_id;
            } else {
               &Net::FullAuto::FA_lib::scrub_passwd_file($hostlabel,$login_id,'');
               $die_login_id=$login_id;
            }
         }
         if (-1<index $cmd_errmsg,'Cannot su to') {
            @connect_method=@{$cmd_cnct};
            if (2<=$retrys) {
               $unam=$uname;
               if ($retrys==3) {
                  $su_scrub=&Net::FullAuto::FA_lib::scrub_passwd_file(
                     $hostlabel,$su_id);
               } else { $retrys++;next }
            } else { $retrys++;next }
         } elsif ($cmd_errmsg=~/invalid log|ogin incor|sion den/s
                    && $cmd_errmsg!~/No more auth/s) {
            if ($ms_domain && 2<=$retrys) {
               $cmd_errmsg.="\n       WARNING! - You may be in"
                         ." Danger of locking out MS Domain\n"
                         ."                  ID - $login_id!\n\n";
               if ($retrys==3) {
                  $su_scrub=&Net::FullAuto::FA_lib::scrub_passwd_file(
                     $hostlabel,$login_id);
               } else { $retrys++;next }
            } elsif (2<=$retrys) {
               $unam=$uname;
               $unam='MS Windows' if $unam eq 'cygwin';
               $cmd_errmsg.="\n       WARNING! - You may be in"
                          ." Danger of locking out $unam\n"
                          ."                  $hostlabel ID - "
                          ."$login_id!\n\n";
               if ($retrys==3) {
                  $su_scrub=&Net::FullAuto::FA_lib::scrub_passwd_file(
                     $hostlabel,$login_id);
               } else { $retrys++;next }
            } else { $retrys++;next }
         }
         my $c_t=$cmd_type;$c_t=~s/^(.)/uc($1)/e;
         $die="The System $hostname Returned\n              the "
             ."Following Unrecoverable Error Condition\,\n"
             ."              Rejecting the $c_t Login Attempt "
             ."of the ID\n              -> $die_login_id "
             ."at ".(caller(2))[1]." line ".(caller(2))[2]
             ." :\n\n       $cmd_errmsg";
         $Net::FullAuto::FA_lib::fa_login.=$die;
         if ($ms_domain
                && $cmd_errmsg=~/invalid log|ogin incor|ogon fail/) {
            $die.="\nHint: Your MS Domain -> $ms_domain Login ID may be "
                ."locked out.\n      Contact Your System "
                ."Administrator for Assistance.\n\n";
         } last;
      } else { last }
   }
print $Net::FullAuto::FA_lib::MRLOG
   "GETTTING OUT OF HERE!!!!!==>cmd_login()\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#$Net::FullAuto::FA_lib::log=0 if $logreset;
 return $cmd_handle,$work_dirs,$uname,$cmd_type,$ftm_type,$smb,
        $die,$freemem,$ip,$hostname,$cmd_pid,$shell_pid,$cygdrive,$shell; 

}

sub ftpcmd
{
my $logreset=1;
if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
else { $Net::FullAuto::FA_lib::log=1 }
   my @topcaller=caller;
   print "ftpcmd() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "ftpcmd() CALLER=",
      (join ' ',@topcaller),"\n"
      if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $handle=$_[0];
   my $cmd=$_[1];my $ftperr='';
   my $hostlabel=$handle->{_hostlabel}->[1]
      || $handle->{_hostlabel}->[0];
   my $ftm_type=$handle->{_ftm_type};
   my $output='';my $nfound='';my $allbytes='';
   my $ready='';my $more='';my $retrys=0;
   my $stdout='';my $stderr='';my $hashcount=0;
   my $keepcount=0;my $gpfile='';my $seen=0;
   $gpfile=unpack('a3',$cmd) if 2<length $cmd;
   my $prcnt=0;my $firstvisit=0;my $gf='';
   if ($gpfile eq 'get' || $gpfile eq 'put') {
      my $ex=($gpfile eq 'put')?'!':'';
      ($gpfile=$cmd)=~s/^...\s+(.*)$/$1/;
      chomp $gpfile;my $lsline='';
      ($gf=$gpfile)=~s/^["']([^"']*)["'].*$/$1/;
      if ($gf eq $gpfile && (-1<index $gpfile,' ')) {
         $gf=substr($gf,0,(index $gf,' '));
      }
      $gf=~s/\+/\\\+/g;
      my $gfp='';
      if ($ftm_type eq 'sftp') {
         $gfp=' '.substr($gf,0,(rindex $gf,'/'));
         $gfp='' if (-1==index $gfp,'/');
      }
      ($output,$stderr)=&ftpcmd($handle,"${ex}ls$gfp");
#print "OUTPUTXXXX=$output and STDERR=$stderr<======\n";
      if ($stderr) {
         if (wantarray) {
            return $output,$stderr;
         } else {
            &Net::FullAuto::FA_lib::handle_error($stderr,'-3','__cleanup__');
         }
      } my $gpf=substr($gf,(rindex $gf,'/')+1);
      foreach my $line (split /^/, $output) {
         if (-1<index $line,'total 0') {
            if (wantarray) {
               return '',"$cmd: No Files Found";
            } else {
               #&Net::FullAuto::FA_lib::handle_error("$cmd: No Files Found",'__cleanup__');
               &Net::FullAuto::FA_lib::handle_error("$cmd: No Files Found");
            }
         }
         next if unpack('a1',$line) ne '-';
         chomp($line=~tr/\0-\37\177-\377//d);
         if ($line=~s/$gpf$//) {
#print "LSLINE=$line and GPF=$gpf\n";
            $lsline=$line;last;
         }
      }
      if (!$lsline) {
#print "WHAT IS THE CMD=${ex}ls -l$gfp\n";
         ($output,$stderr)=&ftpcmd($handle,"${ex}ls -l$gfp");
#print "OUTPUT=$output and STDERR=$stderr\n";
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         foreach my $line (split /^/, $output) {
            if (-1<index $line,'total 0') {
               if (wantarray) {
                  return '',"$cmd: No Files Found";
               } else {
                  #&Net::FullAuto::FA_lib::handle_error("$cmd: No Files Found",'__cleanup__');
                  &Net::FullAuto::FA_lib::handle_error("$cmd: No Files Found");
               }
            }
            next if unpack('a1',$line) ne '-';
            chomp($line=~tr/\0-\37\177-\377//d);
            if ($handle->{_luname} eq 'cygwin') {
               if ($line=~/$gf$/i) {
                  $lsline=$line;last;
               }
            } else {
               if ($line=~/$gf$/) {
                  $lsline=$line;last;
               } 
            }
         }
      }
      my $rx1=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
      my $rx2=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d\d\d\s+.*/;
#print "LSLINE1=$lsline<==\n";
      $lsline=~s/^.*\s+($rx1|$rx2)$/$1/;
#print "LSLINE2=$lsline<==\n";
      ($allbytes)=$lsline=~/^(\d+)\s+[JFMASOND]\w\w\s+\d+\s+\S+\s+.*$/;
      if ($ftm_type ne 'sftp') {
         ($output,$stderr)=&ftpcmd($handle,'hash');
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      }
$allbytes||='';
#print "ALLBYTES=$allbytes<==\n";
   } else { $gpfile='' }
   eval {
      $handle->{_ftp_handle}->print($cmd);
   };
   if ($@) {
      &Net::FullAuto::FA_lib::handle_error("$@\n       and COMMAND=$cmd and GPFILE=$gpfile"
                           ."and FTP_HANDLE=$handle->{_ftp_handle}\n",'-4');
   }
   &Net::FullAuto::FA_lib::handle_error($handle->{_ftp_handle}->errmsg)
      if $handle->{_ftp_handle}->errmsg;
   my $cmdflag=0;my $tcmd='';$toout=0;my $loop=0;
   while (1) {
      my $starttime=time();
      eval {
         while (1) {
            if (!$more) {
               $nfound = select
                  $ready=${${*{$handle->{_ftp_handle}}}{net_telnet}}{fdmask},
                  '', '', $handle->{_ftp_handle}->timeout;
            } $output='';
            if ($nfound > 0 || $more) {
               sysread $handle->{_ftp_handle},
                  $output,
                  ${${*{$handle->{_ftp_handle}}}{net_telnet}}{blksize},
                  0;
               $more='' if $more;
            } elsif (!$stdout) {
               $starttime=time();
            }
            $stdout.=$output;
print $Net::FullAuto::FA_lib::MRLOG "FTP-STDOUT=$stdout<=======\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if ($gpfile && !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug) {
               $hashcount=$output;
               $hashcount=($hashcount=~tr/#//);
               if ($allbytes && 1<$hashcount && $ftm_type ne 'sftp') {
                  if ($Net::FullAuto::FA_lib::OS ne 'cygwin') {
                     print $Net::FullAuto::FA_lib::blanklines;
                     #if ($Net::FullAuto::FA_lib::clear) {
                     #   print $Net::FullAuto::FA_lib::clear;
                     #} else { print `clear`."\n" }
                  } elsif (!$firstvisit) {
                     print "\n";
                     $firstvisit=1;
                  }
                  $hashcount=$hashcount*1024; 
                  $keepcount=$keepcount+$hashcount;
                  $keepcount=$allbytes if $allbytes<$keepcount;
                  my $plin="\n\t$keepcount bytes, ";
                  $prcnt=$keepcount/$allbytes;
                  if (unpack('a1',$prcnt) eq '1') {
                     $prcnt=100;
                  } else { $prcnt=substr($prcnt,2,2) }
                  substr($prcnt,0,1)='' if unpack('a1',$prcnt) eq '0';
                  $plin.="${prcnt}% of $gpfile transferred  . . . ";
                  print "$plin\n";
                  sleep 1;
                  if ($keepcount==$allbytes) {
                     print "\n";
                  } else {
                     print $Net::FullAuto::FA_lib::blanklines;
                  }
               } elsif (!$keepcount) {
                  foreach my $line (split /\n+/, $output) {
                     chomp($line=~tr/\0-\11\13-\37\177-\377//d);
                     $line=~tr/#//d;
                     $line=~s/s*ftp> ?$//s if !($line=~s/^\s*$//m);
                     my $upcnt=$line=~/Upload/gs;
                     $upcnt||=0;
                     if ($upcnt) {
                        if ($seen) { next }
                        $seen=1
                     }
                     $line=~s/Upload.*$//s if 1<$upcnt;
                     my $ftcnt=$line=~/Fetch/gs;
                     $ftcnt||=0;
                     if ($ftcnt) {
                        if ($seen) { next }
                        $seen=1
                     }
                     $line=~s/Fetch.*$//s if 1<$ftcnt;
                     $line=~s/\n*Uploading/\n\nUploading/gs;
                     $line=~s/Fetch/\n\nFetch/gs;
                     #$line="\n".$line;
                     #if ($stdout!~/^(U|F)/m) {
                     #if ($ftm_type eq 'sftp') {
                     #   print $line;
                     #} elsif ((-1==index $line,'421 Service not')
                     if ((-1==index $line,'421 Service not')
                           || (-1==index $line,'421 Timeout')
                           || (-1==index $line,'Not connected')
                           || (-1==index $line,'file access p')) {
                        my $tl=$line;
                        $tl=~s/[\r|\n]*//sg;
                        if ($cmdflag) {
                           print "\n";
                        } elsif ($cmd!~/$tl/) {
                           $cmdflag=1;
                        } else {
                           $tcmd.=$line;
                           $cmdflag=1 if $cmd eq $tcmd;
                        } print $line;
                     }
                     if (!$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug) {
                        if (5<length $line) { 
                           if (unpack('a6',$line) eq '150 Op') {
                              print "\n";last;
                           } elsif (unpack('a6',$line) eq '125 St') {
                              print "\n\n";
                           } elsif (unpack('a4',$line) eq '"get') {
                              print "\n";
                           } elsif (unpack('a4',$line) eq '"put') {
                              print "\n";
                           }
                        }
                     }
                     if ($allbytes && $line=~/(\d+) bytes/) {
                        my $bytestransferred=$1;
                        #print "ALLBYTES=$allbytes & BYTESTRANSFERRED=$bytestransferred\n";sleep 2;
                        my $warn="WARNING! - The transfer of file $gf\n             "
                                ."size $allbytes bytes\, aborted at $bytestransferred "
                                ."\n             bytes transferred.";
                        &Net::FullAuto::FA_lib::handle_error($warn,'__return__','__warn__')
                           if $allbytes ne $bytestransferred;
                     }
                  }
               }
            }
            if ($output || $stdout=~/s*ftp> ?$/s) {
               if ((-1<index $stdout,'bash: ') || (-1<index $stdout,'age too lo')) {
print $Net::FullAuto::FA_lib::MRLOG "TOO MANY LOOPS - GOING TO RETRY11<=======\n";
                  $handle->{_ftp_handle}->print("\004");
                  die "421 Timeout - ftm read timed out";
               }
               $loop=0;
               chomp($output=~tr/\0-\11\13-37\177-\377//d);
               $output=~tr/ //d;
               if ($output=~/s*ftp> ?$/s || $stdout=~/s*ftp> ?$/s || $more) {
                  $nfound=select
                     $ready=${${*{$handle->{_ftp_handle}}}{net_telnet}}{fdmask},
                     '', '', 0;
                  if ($nfound) {
                     $more=1;next;
                  } else {
                     $stdout=~s/^(.*?)(\012|\013)+//s;
                     $stdout=~s/s*ftp> ?$//s;
                     $stdout=~tr/#//d;
#if ($stdout=~/(\d+) bytes/) {
# my $bytestransferred=$1;
# print "BYTESTRANSFERRED=$bytestransferred\n";sleep 2;
#}
                     #print "FTPCMD-STDOUT=$stdout" if !$gfile && !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                     last
                  }
               } $starttime=time();
            } elsif ((!$gpfile && $loop++==10) || (-1<index $stdout,'bash: ')) {
print $Net::FullAuto::FA_lib::MRLOG "TOO MANY LOOPS - GOING TO RETRY<22=======\n";
               $handle->{_ftp_handle}->print("\004");
               $stdout="421 Timeout - ftm read timed out";die
            } elsif ($handle->{_ftp_handle}->timeout<time()-$starttime) {
print $Net::FullAuto::FA_lib::MRLOG "ftm read timed out<=======\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "ftm read timed out and OUTPUT=$output<=======\n";
               if ($retrys<2) {
                  $retrys++;
                  $handle->{_ftp_handle}->print("\004");
                  $stdout="421 Timeout - ftm read timed out";die
               } else {
                  my $tmot="421 Timeout - ftm read timed out\n"
                          ."       Timeout=".$handle->{_ftp_handle}->timeout;
                  &Net::FullAuto::FA_lib::handle_error($tmot,'__cleanup__');
               }
            }
         } print "\n" if $output && $gpfile
              && $keepcount && !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
      };
print $Net::FullAuto::FA_lib::MRLOG "FTP-STDOUT-COMPLETED=$stdout<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "FTP-STDOUT-COMPLETED=$stdout and FTM_TYPE=$ftm_type<==\n";
#sleep 15 if !defined $ftm_type;
      if ($stdout=~/^5\d+\s+$/m && $stdout!~/^5\d+\s+bytes.*$/m) {
         $stdout=~/^(5.*)$/m;
         $stderr=$1;
         chomp($stderr=~tr/\0-\37\177-\377//d);
print $Net::FullAuto::FA_lib::MRLOG "FTP-STDERR-500-DETECTED=$stderr<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      } elsif ((-1<index $stdout,":5") && $stdout=~/^(.*:5\d\d\s.*)$/m) {
         my $line=$1;
         chomp($line=~tr/\0-\37\177-\377//d);
         $stderr="$line\n       $!" if $line!~/^\d+\s+bytes/;
      } elsif (-1<index $stdout,'421 Service not avail') {
         $stderr="$stdout\n       $!";
      } elsif ((-1<index $stdout,'421 Service not') ||
               (-1<index $stdout,'421 Timeout') ||
               (-1<index $stdout,'Not connected') ||
               (-1<index $stdout,'file access p')) {
print $Net::FullAuto::FA_lib::MRLOG "YESSS-WE HAVE 421 ERROR!!!!! and HOSTLABEL=$hostlabel\n"
    if -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         my ($ip,$hostname,$use,$ms_share,$ms_domain,
             $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
             $owner,$group,$fctimeout,$transfer_dir,$rcm_chain,
             $rcm_map,$uname,$ping,$freemem)
             =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,
                $handle->{_connect});
         if ($Net::FullAuto::FA_lib::cltimeout ne 'X') {
            $fctimeout=$Net::FullAuto::FA_lib::cltimeout;
         } elsif (!$fctimeout) {
            $fctimeout=$timeout if !$fctimeout;
         }
         my $ftm_errmsg='';
         my $host=($use eq 'ip') ? $ip : $hostname;
         $handle->{_ftp_handle}->print('bye');
         my $sav_ftp_handle='';
         while (my $line=$handle->{_ftp_handle}->get) {
            last if $line=~/_funkyPrompt_$/s;
            if ($line=~/logout/s) {
               $sav_ftp_handle=$handle->{_ftp_handle};
               $handle->{_ftp_handle}->close;
               my $ftp_handle='';
               ($ftp_handle,$stderr)=
                    Rem_Command::new('Rem_Command',
                    "__Master_${$}__",'__new_master__',$_connect);
               &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
               $handle->{_ftp_handle}=$ftp_handle->{_cmd_handle};
               foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                  foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                     foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                              {$sid}}) {
                        if ($sav_ftp_handle eq $Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}) {
                           delete $Net::FullAuto::FA_lib::Processes{$hlabel}
                                  {$sid}{$type};
                        } elsif ($handle->{_ftp_handle} eq $Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}) {
                           substr($type,0,3)='ftp';
                           $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                              $handle->{_ftp_handle};
                        }
                     }
                  }
               }
            }
         }
         if ( -1<index $stdout,'file access p') {
            ($handle->{_ftp_handle},$stderr)=
               &login_retry($ftp_handle,$stdout);
            if ($stderr) {
               $stderr="$stdout\n       $stderr";
               if (wantarray) {
                  return '',$stderr;
               } else {
                  &Net::FullAuto::FA_lib::handle_error($stderr);
               }
            } elsif (!$handle->{_ftp_handle}) {
               if (wantarray) {
                  return '',$stdout;
               } else {
                  &Net::FullAuto::FA_lib::handle_error($stdout);
               }   
            }
         } my $ftm_passwd='';
         if ($su_id) {
            $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
               $hostlabel,$su_id,
               $ms_share,$ftm_errmsg,'__su__');
            if ($ftm_passwd ne 'DoNotSU!') {
               $su_login=1;
            } else { $su_id='' }
         }
         if (!$su_id) {
            $ftm_passwd=&Net::FullAuto::FA_lib::getpasswd(
               $hostlabel,$login_id,
               $ms_share,$ftm_errmsg);
         }
         my $fm_cnt=-1;
         foreach $connect_method (@{$ftr_cnct}) {
            $fm_cnt++;
            if (lc($connect_method) eq 'ftp') {
               my $go_next=0;
               eval {
                  $handle->{_ftp_handle}->print("${Net::FullAuto::FA_lib::ftppath}ftp $host");
                  ## Look for Name Prompt.
                  while (my $line=$handle->{_ftp_handle}->get) {
                     my $tline=$line;
                     $tline=~s/Name.*$//s;
                     if (-1<index $tline,'ftp: connect:') {
                        $tline=~/^.*connect:\s*(.*?\n).*$/s;
                        if ((-1==index $tline,'Address already in use')
                              && (-1==index $tline,'Connection timed out'
                              )) {
                           if ($fm_cnt==$#{$ftr_cnct}) {
                              $go_next=1;last;
                           } else {
                              &Net::FullAuto::FA_lib::handle_error(
                                 "ftp: connect: $1");
                           }
                        } else {
                           $handle->{_ftp_handle}->close
                              if defined fileno $handle->{_ftp_handle};
                           sleep int $handle->{_ftp_handle}->timeout/3;
                           ($handle->{_ftp_handle},$stderr)=
                              &Rem_Command::new('Rem_Command',
                              "__Master_${$}__",$new_master,$_connct);
                           &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                           $handle->{_ftp_handle}=$ftp_handle->{_cmd_handle};
                           $handle->{_ftp_handle}->print(
                              "${Net::FullAuto::FA_lib::ftppath}ftp $host");
                           FH1: foreach my $hlabel (
                                 keys %Net::FullAuto::FA_lib::Processes) {
                              foreach my $sid (
                                    keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                                 foreach my $type (
                                       keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                                       {$sid}}) {
                                    if ($handle->{_ftp_handle}
                                          eq $Net::FullAuto::FA_lib::Processes
                                          {$hlabel}{$sid}{$type}) {
                                       delete
                                          $Net::FullAuto::FA_lib::Processes{$hlabel}
                                          {$sid}{$type};
                                       substr($type,0,3)='ftp';
                                       $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}
                                           {$type}=$handle->{_ftp_handle};
                                       last FH1;
                                    }
                                 }
                              }
                           }
                           $tline=$line;
                           $tline=~s/Name.*$//s;
                        }
                     } elsif (-1<index $tline,'421 Service' ||
                           -1<index $tline,'No address associated with name'
                           || (-1<index $tline,'Connection' &&
                           (-1<index $tline,'Connection closed' ||
                           -1<index $tline,
                           'ftp: connect: Connection timed out'))) {
                        $tline=~s/s*ftp> ?$//s;
                        if ($fm_cnt==$#{$ftr_cnct}) {
                           $go_next=1;last;
                        } else {
                           &Net::FullAuto::FA_lib::handle_error($tline);
                        }
                     } print "TLIN=$tline" if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
                     print $Net::FullAuto::FA_lib::MRLOG $tline
                        if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if (-1<index $tline,
                           'ftp: connect: Connection timed out') {
                        $tline=~s/s*ftp> ?\s*$//s;
                        if ($fm_cnt==$#{$ftr_cnct}) {
                           $go_next=1;last;
                        } else {
                           &Net::FullAuto::FA_lib::handle_error($tline);
                        }
                     } elsif ((-1<index $line,'A remote host refused')
                            || (-1<index $line,
                            'ftp: connect: Connection refused')) {
                        my $host=($use eq 'ip') ? $ip : $hostname;
                        $line=~s/^(.*)?\n.*/$1/s;
                        $die=$line;
                        if ($fm_cnt==$#{$ftr_cnct}) {
                           $go_next=1;last;
                        } else {
                           $die.="Destination Host - $host, HostLabel "
                               ."- $hostlabel\n       refused an "
                               ."attempted connect operation.\n       "
                               ."Check for a running FTP daemon on "
                               .$hostlabel;
                           &Net::FullAuto::FA_lib::handle_error($die);
                        }
                     }
                     if ($line=~/Name.*[: ]+$/si) {
                        $gotname=1;$ftr_cmd='ftp';last;
                     }
                  }
               };
               if ($@) {
                  if ($@=~/read timed-out/) {
                     my $die="&ftm_login() timed-out while\n       "
                            ."waiting for a login prompt from\n       "
                            ."Remote Host - $host,\n       HostLabel "
                            ."- $hostlabel\n\n       The Current Timeout"
                            ." Setting is ".$handle->{_ftp_handle}->timeout
                            ." Seconds.";
                     &Net::FullAuto::FA_lib::handle_error($die);
                  } elsif ($fm_cnt==$#{$ftr_cnct}) {
                     $go_next=1;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($@);
                  }
               } next if $go_next || !$gotname;
               if ($su_id) {
                  $handle->{_ftp_handle}->print($su_id);
               } else {
                  $handle->{_ftp_handle}->print($login_id);
               }
               ## Wait for password prompt.
               ($ignore,$stderr)=
                  &File_Transfer::wait_for_ftr_passwd_prompt(
                     { _cmd_handle=>$handle->{_ftp_handle},
                       _hostlabel=>[ $hostlabel,'' ],
                       _cmd_type=>$cmd_type,
                       _connect=>$_connect });
               $ftm_type='ftp';
               if ($stderr) {
                  if ($fm_cnt==$#{$ftr_cnct}) {
                     return '',$stderr;
                  } else { next }
               } last
            } elsif (lc($connect_method) eq 'sftp') {
               my $sftploginid=($su_id)?$su_id:$login_id;
               $handle->{_ftp_handle}->print("${Net::FullAuto::FA_lib::sftppath}sftp ".
                                             "$sftploginid\@$host");
               FH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
                  foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                     foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                           {$sid}}) {
                        if ($handle->{_ftp_handle} eq $Net::FullAuto::FA_lib::Processes
                              {$hlabel}{$sid}{$type}) {
                           delete
                              $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                           substr($type,0,3)='ftp';
                           $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                              $handle->{_ftp_handle};
                           last FH;
                        }
                     }
                  }
               }
               my $showsftp=
                  "\n\tLoggingL into $host via sftp  . . .\n\n";
               print $showsftp if (!$Net::FullAuto::FA_lib::cron
                  || $Net::FullAuto::FA_lib::debug)
                  && !$Net::FullAuto::FA_lib::quiet;
               print $Net::FullAuto::FA_lib::MRLOG $showsftp
                  if $Net::FullAuto::FA_lib::log
                  && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               ## Wait for password prompt.
               ($ignore,$stderr)=
                  &File_Transfer::wait_for_ftr_passwd_prompt(
                     { _cmd_handle=>$handle->{_ftp_handle},
                       _hostlabel=>[ $hostlabel,'' ],
                       _cmd_type=>$cmd_type,
                       _connect=>$_connect });
               $ftm_type='sftp';
               if ($stderr) {
                  if ($fm_cnt==$#{$ftr_cnct}) {
                     return '',$stderr;
                  } else { next }
               } last
            }
         }
         my %ftp=(
            _ftp_handle => $handle->{_ftp_handle},
            _ftm_type   => $ftm_type,
            _hostname   => $hostname,
            _ip         => $ip,
            _uname      => $uname,
            _luname     => $handle->{_uname},
            _hostlabel  => [ $hostlabel,$handle->{_hostlabel}->[0] ]
         );
         $handle->{_ftp_handle}->prompt("/s*ftp> ?\$/");
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,$ftm_passwd);
         if ($stderr) {
            if (wantarray) {
               return '',$stderr;
            } else {
               return $stderr;
            }
         }
         ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'binary')
            if $ftm_type ne 'sftp';
         if ($stderr) {
            if (wantarray) {
               return '',$stderr;
            } else {
               return $stderr;
            }
         }
         if (exists $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{cd}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
               "cd $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{cd}");
            $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{cd}=
               $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{cd};
            delete $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{cd};
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else {
                  return $stderr;
               }
            }
         } elsif (exists $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{cd}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
               "cd $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{cd}");
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else {
                  return $stderr;
               }
            }
         }
($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'pwd')
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "FTPCMD--PWD=$output\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "DO WE HAVE LCD????=$Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{lcd}<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if (exists $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{lcd}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
               "lcd $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{lcd}");
            $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{lcd}=
               $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{lcd};
            delete $Net::FullAuto::FA_lib::ftpcwd{$sav_ftp_handle}{lcd};
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else {
                  return $stderr;
               }
            }
         } elsif (exists $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{lcd}) {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,
               "lcd $Net::FullAuto::FA_lib::ftpcwd{$handle->{_ftp_handle}}{lcd}");
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else {
                  return $stderr;
               }
            }
         }
         if ($gpfile && $ftm_type ne 'sftp') {
            ($output,$stderr)=&Rem_Command::ftpcmd(\%ftp,'hash');
            if ($stderr) {
               if (wantarray) {
                  return '',$stderr;
               } else {
                  return $stderr;
               }
            }
         }
         $stdout='';$stderr='';
         $handle->{_ftp_handle}->print($cmd);
         next
      } elsif ($ftm_type eq 'sftp') {
         $stdout=~s/^$cmd\s*(.*)\s*sftp>\s*$/$1/s;
         if (exists $handle->{_cmd_handle}) {
            if ($stdout=~/Couldn\'t canonicalise:/s) {
               if ($cmd=~/^ls$|^ls /) {
                  ($output,$stderr)=$handle->cmd($cmd);
                  if ($stderr) {
                     $stderr=$stdout;
                  } else { $stdout=$output }
               } elsif ($cmd=~/^cd /) {
                  ($output,$stderr)=$handle->cmd('pwd');
                  if ($stderr) {
                     $stderr=$stdout;
                  } else {
                     $output=~s/^.*direcotory: (.*)$/$1/;
                     my $out='';
                     ($out,$stderr)=$handle->cmd($cmd);
                     if ($stderr) {
                        $stderr=$stdout;
                     } else {
                        chomp $output;
                        ($out,$stderr)=$handle->cmd("cd $output");
                        if ($stderr) { $stderr=$stdout }
                     }
                  }
               } else { $stderr=$stdout }
            } elsif ((-1<index $stdout,'Permission denied') ||
                  (-1<index $stdout,'t stat remote file')) {
               if ($cmd=~/^ls$|^ls /) {
                  if (!exists $GLOBAL{'nested_ls'}) {
                     $GLOBAL{'nested_ls'}=1;
                     ($output,$stderr)=$handle->cmd($cmd);
                  } else {
                     delete $GLOBAL{'nested_ls'};
                  }
                  if ($stderr) {
                     $stderr=$stdout;
                  } elsif (-1<index $stdout,'t stat remote file') {
                     $stderr=$stdout;
                  } else { $stdout=$output }
               } elsif (unpack('a4',$cmd) eq 'get ') {
                  if ((-1<index $stdout,'t stat remote file') ||
                       (-1<index $stdout,'t get handle')) { 
                     if ($cmd=~/^get\s+\"((?:\/|[A-Za-z]:).*)\"$/) {
                        my $path=$1;
                        $path=~/^(.*)[\/|\\]([^\/|\\]+)$/;
                        my $dir=$1;my $file=$2;my $getfile='';
                        my $testf=&Net::FullAuto::FA_lib::test_file($handle->{_cmd_handle},
                           $path);
                        if ($testf eq 'WRITE' || $testf eq 'READ') {
                           if (exists $handle->{_work_dirs}->{_tmp}) { 
                              ($output,$stder)=$handle->cmd("cp -p $path ".
                                 $handle->{_work_dirs}->{_tmp});
                              &Net::FullAuto::FA_lib::handle_error($stder) if $stder;
                              $getfile=$handle->{_work_dirs}->{_tmp}.
                                      '/'.$file;
print "COPIED and GETFILE=$getfile<==\n";#<STDIN>;
                           } elsif (exists
                                 $handle->{_work_dirs}->{_tmp_mswin}) {
print "COPIED and GETFILE222=$getfile<==\n";#<STDIN>;
                              ($output,$stder)=$handle->cmd("cp -p $path ".
                                 $handle->{_work_dirs}->{_tmp_mswin});
                              &Net::FullAuto::FA_lib::handle_error($stder) if $stder;
                              $getfile=$handle->{_work_dirs}->{_tmp_mswin}.
                                      '\\'.$file;
                           }
                           ($output,$stderr)=
                              &Rem_Command::ftpcmd($handle,"get $getfile");
                           if (!$stderr) {
                              ($output,$stderr)=$handle->cmd(
                                 "rm -f $getfile");
                              &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                           } $stdout=$output;
                        }
                     }
                  }
               } elsif (unpack('a4',$cmd) eq 'put ') {
                  if (-1<index $stdout,'Uploading') {
                     if (-1<index $stdout,'t get handle') {
                     
                     } #elsif (-1<index $stdout,'t open local file') {
                       #}
                  }
               }
            }
         }
      } elsif ($stdout=~/^4\d+\s+/m && $stdout!~/^4\d+\s+bytes.*$/m) {
         my $line='';
         foreach my $lin (split /^/, $stdout) {
            $line.="              $lin" if unpack('a1',$lin) eq '4';
         }
         $stdout='';
         $stderr=$line;
      } elsif ($stdout=~/ftp: \w+: /) {
         my $line='';
         foreach my $lin (split /^/, $stdout) {
            $line.="              $lin";
         }
         $stdout='';
         $stderr=$line;
      } else {
         my $c='';
         ($c=$cmd)=~s/\+/\\\+/sg;
         $stdout=~s/^$c\s*(.*)\s+s*ftp>\s*$/$1/s;
      }
      if (!$stderr && $gpfile) {
         ($output,$stderr)=&ftpcmd($handle,'hash')
            if $ftm_type ne 'sftp';
         print "\n";
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
      }
print $Net::FullAuto::FA_lib::MRLOG "RETURNING FTMSTDOUT=$stdout and FTMSTDERR=$stderr\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
$Net::FullAuto::FA_lib::log=0 if $logreset;
      if (wantarray) {
         return $stdout,$stderr;
      } elsif (!$stdout && $stderr) {
         return $stderr;
      } else { return $stdout }
   }

}

sub cmd
{
   my @topcaller=caller;
   print "\nINFO: Rem_Command::cmd() (((((((CALLER))))))):\n\t",(join ' ',@topcaller),"\n\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "\nRem_Command::cmd() (((((((CALLER))))))):\n\t",
      (join ' ',@topcaller),"\n\n"
      if $Net::FullAuto::FA_lib::log &&
      -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my @args=@_;shift @args;shift @args;
   my $debug=$Net::FullAuto::FA_lib::debug;
   my $command=$_[1];$command||='';
   my $ftp=0;my $live=0;my $display=0;my $log=0;
   my $wantarray= wantarray ? wantarray : '';
   my $cmtimeout='X';my $svtimeout='X';my $sem='';
   my $notrap=0;
   if (defined $_[2] && $_[2]) {
      if ($_[2]=~/^[0-9]+/) {
         $cmtimeout=$_[2];
      } else {
         my $arg=lc($_[2]);
         if ($arg eq '__debug__') {
            $debug=1;
         } elsif ($arg eq '__ftp__') {
            $ftp=1;
         } elsif ($arg eq '__live__' || $arg eq '__LIVE__') {
            $live=1;
         } elsif ($arg eq '__display__' || $arg eq '__DISPLAY__') {
            $display=1;
         } elsif ($arg eq '__log__') {
            $log=1;
         } elsif ($arg eq '__notrap__') {
            $notrap=1;
         } elsif ($wantarray) {
            return 0,'Third Argument for Timeout Value is not Whole Number';
         } else {
            &Net::FullAuto::FA_lib::handle_error(
               'Third Argument for Timeout Value is not Whole Number')
         }
      }
   } my $login_id='';
   if (defined $_[3] && $_[3]) {
      my $arg=lc($_[3]);
      if ($arg eq '__debug__') {
         $debug=1;
      } elsif ($arg eq '__ftp__') {
         $ftp=1;
      } elsif ($arg eq '__live__' || $arg eq '__LIVE__') {
         $live=1;
      } elsif ($arg eq '__display__' || $arg eq '__DISPLAY__') {
         $display=1;
      } elsif ($arg eq '__log__') {
         $log=1;
      } elsif ($arg eq '__notrap__') {
         $notrap=1;
      } else {
         $login_id=$_[3];
      }
   }
   while (1) {
      my $cmd_prompt='';my $cmdprompt='';my $ms_cmd_prompt='';
      if (defined $_[4] && $_[4]) {
         my $arg=lc($_[4]);
         if ($arg eq '__debug__') {
            $debug=1;
         } elsif ($arg eq '__ftp__') {
            $ftp=1;
         } elsif ($arg eq '__live__' || $arg eq '__LIVE__') {
            $live=1;
         } elsif ($arg eq '__display__' || $arg eq '__DISPLAY__') {
            $display=1;
         } elsif ($arg eq '__log__') {
            $log=1;
         } elsif ($arg eq '__notrap__') {
            $notrap=1;
         } elsif (0) {
            $tmp_cmd_prompt=$cmd_prompt=$_[4];
            if (unpack('a2',$cmd_prompt) ne '(?' &&
                  ($cmd_prompt=~/\|\|/s || $cmd_prompt=~/\|[Mm]\|/s)) {
               $cmd_prompt=~s/^(.*)(?:\|\||\|[Mm]\|)//s;
               my $tmp_cmd_prompt=$1;
               pos($cmd_prompt)=0;
               while ($cmd_prompt=~/(\|\||\|[Mm]\|)(.*)/g) {
                  if ($1 eq '||') {
                     $tmp_cmd_prompt.="|$2";
                  } else {
                     $ms_cmd_prompt.="|$2";
                  }
               }
            }
            $cmd_prompt=
               qr/$tmp_cmd_prompt/ if unpack('a2',$cmd_prompt) ne '(?'; 
         }
      } elsif (!$ftp) {
         $cmd_prompt=substr($self->{_cmd_handle}->prompt,1,-2);
      }
      if (defined $_[5] && $_[5]) {
         my $arg=lc($_[5]);
         if ($arg eq '__debug__') {
            $debug=1;$arg='';
         } elsif ($arg eq '__ftp__') {
            $ftp=1;$arg='';
         } elsif ($arg eq '__live__' || $arg eq '__LIVE__') {
            $live=1;$arg='';
         } elsif ($arg eq '__display__' || $arg eq '__DISPLAY__') {
            $display=1;
         } elsif ($arg eq '__log__') {
            $log=1;
         } elsif ($arg eq '__notrap__') {
            $notrap=1;
         } else {
            if (&Net::FullAuto::FA_lib::test_semaphore($_[5])) {
               if ($wantarray) {
                  return 0,"Semaphore Blocking Command";
               } else { return 'Semaphore Blocking Command' }
            } else {
               &Net::FullAuto::FA_lib::take_semaphore($_[5]);
               $sem=$_[5];
            }
         }
      }
      if (!$debug && (grep{lc($_) eq '__debug__'}@_)) {
         $debug=1;
      } elsif (!$ftp && (grep{lc($_) eq '__ftp__'}@_)) {
         $ftp=1;
      } elsif (!$live && (grep{lc($_) eq '__live__'}@_)) {
         $live=1;
      } elsif (!$display && (grep{lc($_) eq '__display__'}@_)) {
         $ftp=1;
      } elsif (!$log && (grep{lc($_) eq '__log__'}@_)) {
         $log=1;
      } elsif (!$notrap && (grep{lc($_) eq '__notrap__'}@_)) {
         $notrap=1;
      }

      if ($cmtimeout eq 'X') {
         if ($ftp) {
            $cmtimeout=$self->{_ftp_handle}->timeout;
            $svtimeout=$self->{_ftp_handle}->timeout;
         } else {
            $cmtimeout=$self->{_cmd_handle}->timeout;
            $svtimeout=$self->{_cmd_handle}->timeout;
         }
      } elsif ($ftp) {
         $svtimeout=$self->{_ftp_handle}->timeout;
         $self->{_ftp_handle}->timeout($cmtimeout);
      } else {
         $svtimeout=$self->{_cmd_handle}->timeout;
         $self->{_cmd_handle}->timeout($cmtimeout);
      }
      my $caller=(caller(1))[3];
      $caller='' unless defined $caller;
      my $fullerror='';my $allines='';
      my $hostlabel=$self->{_hostlabel}->[0];
      if ($login_id) {
         my ($new_cmd,$stderr)=
                   Rem_Command::new('Rem_Command',$hostlabel,
                                    '__new_master__',
                                    $self->{_connect});
         &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
         ($stdout,$stderr)=$new_cmd->cmd($command,@args);
         ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($new_cmd->{_cmd_pid},9) if   
            &Net::FullAuto::FA_lib::testpid($new_cmd->{_cmd_pid});
         $new_cmd->{_cmd_handle}->close;
         &Net::FullAuto::FA_lib::give_semaphore($sem) if $sem;
print "ONEEEEEE\n";
         return $stdout,$stderr if $wantarray;
         return $stdout if !$stderr;
         return $stderr;
      }
      my $output='';my $stdout='';my $stderr='';my $pid_ts='';
      my $end=0;my $newtel='';my $restart='';my $syntax=0;
      my $doeval='';my $dots='';my $dcnt=0;my $login_retry=-1;
print "GOING TO EVAL COMMAND=$command\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "GOING TO EVAL COMMAND=$command\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      eval {
         $stdout='';
         $stderr='';
         $end=0;
         my $line='';my $testline='';
         my $testcmd='';my $ms_cmd='';
print "LIVE=$live and COMMAND=$command and THIS=$_[$#_-1]\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "LIVE=$live and COMMAND=$command ",
                     "and THIS=$_[$#_-1]\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         ($ms_cmd=$command)=~tr/ //s;
         $ms_cmd=(-1<index lc($command),'cmd /c') ? 1 : 0;
         if (0 && !$live && $ms_cmd) {
print $Net::FullAuto::FA_lib::MRLOG "WEVE GOT WINDOWSCOMMAND=$command\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if ($self->{_uname} ne 'cygwin') {
               ($output,$stderr)=Rem_Command::cmd($self,
                  'uname',@args);
               &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               $stderr="remote OS is $output - NOT a cygwin system!\n";
               &Net::FullAuto::FA_lib::handle_error($stderr);
            }
            $pid_ts=$self->{_cmd_pid}.'_'.$Net::FullAuto::FA_lib::invoked[0]
                   .'_'.$Net::FullAuto::FA_lib::increment++;
            push @FA_lib::pid_ts, $pid_ts;
            my $t=$self->{_work_dirs}->{_tmp_mswin}.'\\';
            $t=~s/\\/\\\\/g;
            $t=~s/\\$//mg;
            my $str="echo \"del ${t}end${pid_ts}.flg ${t}cmd${pid_ts}.bat"
                   ." ${t}out${pid_ts}.txt ${t}err${pid_ts}.txt\""
                   ." > ${t}rm${pid_ts}.bat";
            $self->{_cmd_handle}->print($str);
            &Net::FullAuto::FA_lib::clean_filehandle($self->{_cmd_handle});
            my $cmmd='';
            if (-1<index $command,"\n") {
               @command=split /\n/,$command;my $ccnt=0;
               foreach my $cmd (@command) {
                  ($cmmd=$cmd)=~s/^\s*[cC][mM][dD]\s+\/[cC]\s+(.*)$/$1/;
                  $cmmd=~tr/\'/\"/;
                  $cmmd=~s/\\/\\\\/g;
                  $cmmd=~s/\\$//mg;
                  $cmmd=~s/\"/\\\"/g;
                  if (!$ccnt++) {
                     if (unpack('a4',$cmmd) eq 'set ') {
                        $str="echo \"$cmmd\""
                            ." > ${t}cmd${pid_ts}.bat";
                     } else {
                        $str="echo \"$cmmd 2>${t}err${pid_ts}.txt "
                            ."1>${t}out${pid_ts}"
                            .".txt\" > ${t}cmd${pid_ts}.bat";
                     }
                     $self->{_cmd_handle}->print($str);
                     my $lastDB7=0;
                     DB7: while (1) {
                        $self->{_cmd_handle}->print;
                        eval {
                           while (my $line=$self->{_cmd_handle}->get(
                                             Timeout=>$cmtimeout)) {
                              $line=~s/\s//g;
                              if ($line=~/^$cmd_prompt$/) {
                                 $lastDB7=1;last
                              } last if $line=~/$cmd_prompt$/s;
                           }
                        }; last if $lastDB7;
                        if ($@) {
                           if (-1<index $@,'read timed-out') {
                              next;
                           } else { die "$@       $!" }
                        }
                     }
                     $output=join '',$self->{_cmd_handle}->cmd(
                               String => $str,
                               Timeout => $cmtimeout
                            );
                  } else {
                     if (unpack('a4',$cmmd) eq 'set ') {
                        $str="echo \"$cmmd\""
                            ." >> ${t}cmd${pid_ts}.bat";
                     } else {
                        $str="echo \"$cmmd 2>>${t}err${pid_ts}.txt "
                            ."1>>${t}out${pid_ts}"
                            .".txt\" >> ${t}cmd${pid_ts}.bat";
                     }
                     $self->{_cmd_handle}->print($str);
                     my $lastDB8=0;
                     DB8: while (1) {
                        $self->{_cmd_handle}->print;
                        eval {
                           while (my $line=$self->{_cmd_handle}->get(
                                             Timeout=>$cmtimeout)) {
                              $line=~s/\s//g;
                              if ($line=~/^$cmd_prompt$/) {
                                 $lastDB8=1;last
                              } last if $line=~/$cmd_prompt$/s;
                           }
                        }; last if $lastDB8;
                        if ($@) {
                           if (-1<index $@,'read timed-out') {
                              next;
                           } else { die "$@       $!" }
                        }
                     }
                  }
               }
            } else {
               ($cmmd=$command)=~s/^\s*[cC][mM][dD]\s+\/[cC]\s+(.*)$/$1/;
               $cmmd=~tr/\'/\"/;
               $cmmd=~s/\\/\\\\/g;
               $cmmd=~s/\\$//mg;
               $cmmd=~s/\"/\\\"/g;
               $str="echo \"$cmmd 2>${t}err${pid_ts}.txt 1>${t}out${pid_ts}"
                   .".txt\" > ${t}cmd${pid_ts}.bat";
               $self->{_cmd_handle}->print($str);
               #&Net::FullAuto::FA_lib::clean_filehandle($self->{_cmd_handle});
               my $lastDB9=0;
               DB9: while (1) {
                  $self->{_cmd_handle}->print;
                  eval {
                     while (my $line=$self->{_cmd_handle}->get(
                                      Timeout=>$cmtimeout)) {
                        $line=~s/\s//g;
                        if ($line=~/^$cmd_prompt$/) {
                           $lastDB9=1;last
                        } last if $line=~/$cmd_prompt$/s;
                     }
                  }; last if $lastDB9;
                  if ($@) {
                     if (-1<index $@,'read timed-out') {
                        next;
                     } else { die "$@       $!" }
                  }
               }
            }
            $str="echo \"echo \"DONE\" > ${t}end${pid_ts}.flg\" >>"
                ." ${t}cmd${pid_ts}.bat";
            $self->{_cmd_handle}->print($str);
            my $lastDB10=0;
            DB10: while (1) {
               $self->{_cmd_handle}->print;
               eval {
                  while (my $line=$self->{_cmd_handle}->get(
                                      Timeout=>$cmtimeout)) {
                     $line=~s/\s//g;
                     if ($line=~/^$cmd_prompt$/) {
                        $lastDB10=1;last
                     } last if $line=~/$cmd_prompt$/s;
                  }
               }; last if $lastDB10;
               if ($@) {
                  if (-1<index $@,'read timed-out') {
                     next;
                  } else { die "$@       $!" }
               }
            }
            $self->{_cmd_handle}->
               print("echo \"exit\" >> ${t}cmd${pid_ts}.bat");
            my $lastDB11=0;
            DB11: while (1) {
               $self->{_cmd_handle}->print;
               eval {
                  while (my $line=$self->{_cmd_handle}->get(
                                      Timeout=>$cmtimeout)) {
                     $line=~s/\s//g;
                     if ($line=~/^$cmd_prompt$/) {
                        $lastDB11=1;last
                     } last if $line=~/$cmd_prompt$/s;
                  }
               };
               if ($lastDB11) {
                  $self->{_cmd_handle}->print("echo ECHO");
                  eval {
                     my $echo=0;
                     while (my $line=$self->{_cmd_handle}->get(
                                       Timeout=>$cmtimeout)) {
                        $line=~s/\s//g;
                        if ($line=~/ECHO/s) {
                           last if $line=~/$cmd_prompt$/s;
                              $echo=1;
                        } elsif ($echo==1) {
                           last if $line=~/$cmd_prompt$/s;
                        }
                     }
                  };
               } last if $lastDB11;
               if ($@) {
                  if (-1<index $@,'read timed-out') {
                     next;
                  } else { die "$@       $!" }
               }
            }
#print "RUNNING COMMANDBAT $cmmd\n";
            $self->{_cmd_handle}->print("cmd /c start ${t}cmd${pid_ts}.bat");
            &Net::FullAuto::FA_lib::clean_filehandle($self->{_cmd_handle});
            KC: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
               foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                  foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                          {$sid}}) {
                     if ($self->{_cmd_handle} eq ${$Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type}}[0]) {
                        ${$Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}}[3]=
                           "cmd /c start cmd${pid_ts}.bat"; 
                        last KC;
                     }
                  }
               }
            }
            my $err_cownt=0;my $nowerr_cownt=0;
            my $err_size=0;my $err_size_save=0;
($output,$stderr)=$self->cmd('pwd');
print "BIGGOOOPUTPUT=$output<== and PRE=$self->{_work_dirs}->{_pre} and TMP=$self->{_work_dirs}->{_tmp} and CWD=$self->{_work_dirs}->{_cwd}\n";
            my $c=$self->{_work_dirs}->{_tmp}||
                  $self->{_work_dirs}->{_tmp_mswin};
            my $loop_time=0;
            LK: while (1) {
               #$loop_time=time() if !$loop_time;
               #if ($cmtimeout<time()-$loop_time) {
               #   ($output,$stderr)=$self->cmd("ls -l err${pid_ts}.txt");
               #   &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
               #   my $rx1=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
               #   my $rx2=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d\d\d\s+.*/;
               #   $output=~s/^.*\s+($rx1|$rx2)$/$1/;
               #   $output=~/^(\d+)\s+[JFMASOND]\w\w\s+\d+\s+\S+\s+.*$/;
               #   my $size=$1;
#print "CMDOUTPUTSIZE=$size<==\n";
               #   last if $size;
               #   $loop_time=0;
               #}
               my $shell_cmd="if\n[[ -f ${c}end${pid_ts}.flg ]]\nthen" .
                  "\necho END\nelse\necho LOOKING\nfi\n";
               $self->{_cmd_handle}->print($shell_cmd);
               if ($self->{_cmd_handle}->errmsg) {
                  my $err=$self->{_cmd_handle}->errmsg;
                  &Net::FullAuto::FA_lib::handle_error($err);
               } my $looptime=0;$allines='';
               while (1) {
                  my $line=$self->{_cmd_handle}->
                           get(Timeout=>$cmtimeout);
                  $allines.=$line;
                  last if $allines=~/^(END|LOOKING)/m;
                  $self->{_cmd_handle}->print;
                  $looptime=time() if !$looptime;
                  if ($cmtimeout<time()-$looptime) {
                     my $lv_errmsg="read timed-out for command :"
                                  ."\n\n       -> $cmmd"
                                  ."\n\n       invoked on \'$hostlabel\'"
                                  ."\n\n       Current Timeout "
                                  ."Setting is ->  $cmtimeout seconds.\n\n";
                     $self->{_cmd_handle}->timeout($svtimeout);
                     if ($wantarray) {
                        die $lv_errmsg;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($lv_errmsg)
                     }
                  }
               }
               $allines=~s/\s*$//s;
               if ($allines=~/^END/m) {
                  &Net::FullAuto::FA_lib::clean_filehandle($self->{_cmd_handle});
                  my $err_outt='';
                  ($err_outt,$stderr)=$self->cmd("ls -l ${c}err${pid_ts}.txt");
                  &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                  $err_size='';
                  ($err_size=$err_outt)
                     =~s/^\S+\s+\d+\s+\S+\s+\S+\s+(\d+).*$/$1/s;
                  if ($err_size!~/^\d+$/) {
                     ($err_size=$err_outt)
                        =~s/^\S+\s+\d+\s+\S+\s+\S+\s+\S+\s+(\d+).*$/$1/s;
                  }
                  if ($err_size=~/^\d+$/) {
                     if ($err_size==$err_size_save &&
                           $nowerr_cownt+3<$err_cownt++) {
                        #my $cat_err='';
                        #($cat_err,$stderr)=$self->cmd(
                        #  "cat ${c}err${pid_ts}.txt");
#print "CATERRRRRR=$cat_err<==\n";
                        &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                        last LK;
                        #&Net::FullAuto::FA_lib::handle_error($cat_err);
                     } else { $err_size_save=$err_size }
                  }
                  last LK;
               }
               if (exists $self->{_freemem}) {
                  my $time=time;
                  if ($self->{_freemem}->[1]<$time-$Net::FullAuto::FA_lib::freemem_time) {
                     ($stdout,$stderr)=
                        &Rem_Command::cmd($self,"cat /proc/meminfo");
                     &Net::FullAuto::FA_lib::handle_error($stderr) if $stderr;
                     my $current_memory='';
                     foreach my $line (split /^/, $stdout) {
                        if (-1<index $line,'Mem:') {
                           $current_memory=substr(
                              $line,(rindex $line,' ')+1,-1);
                           last;
                        }
                     }
                     if ($current_memory<$Net::FullAuto::FA_lib::starting_memory) {
                        if (!$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug) {
                           print "\nCurrent Available Memory on ",
                              "$self->{_hostlabel}->[1] is $current_memory",
                              ".\n\n";
                           print 
                              "Recovering Memory on $self->{_hostlabel}->[1]"
                              ,"  . . .\n\n";
                        }
                        my $freecmd='';
                        ($freecmd=$self->{_freemem}->[0])=~s/\\/\\\\/g;
                        ($freecmd=$self->{_freemem}->[0])=~s/\\$//mg;
                        $str="echo cmd /c \\\"$freecmd\\\" dir"
                            ." >> freemem${pid_ts}.bat";
                        $self->{_cmd_handle}->print("$str");
                        $allines='';
                        while (my $line=$self->{_cmd_handle}->
                                               get(Timeout=>$cmtimeout)) {
                           $allines.=$line;
                           last if $allines=~/$cmd_prompt$/s;
                        }
                        $str="echo \"exit\""
                            ." >> freemem${pid_ts}.bat";
                        $self->{_cmd_handle}->print("$str");
                        $allines='';
                        while (my $line=$self->{_cmd_handle}->
                                               get(Timeout=>$cmtimeout)) {
                           $allines.=$line;
                           last if $allines=~/$cmd_prompt$/s;
                        }
                        $self->{_cmd_handle}->print(
                           "cmd /c freemem${pid_ts}.bat");
                        $allines='';
                        eval {
                           while (my $line=$self->{_cmd_handle}->
                                              get(Timeout=>$cmtimeout)) {
                              $allines.=$line;
                              last if $allines=~/$cmd_prompt$/s;
                           }
                        };
                        if ($@) {
                           if (-1<index $@,'read timed-out') {
                              $die="$@\n\n       From Command -> "
                                  ."\"cmd /c freemem${pid_ts}.bat\""
                                  ."\n\n       Current Timeout "
                                  ."Setting is ->  $cmtimeout seconds.";
                              &Net::FullAuto::FA_lib::handle_error($die);
                           } else { &Net::FullAuto::FA_lib::handle_error($@) }
                        } select((select($self->{_cmd_handle}),$|=1)[0]);
                        $self->{_cmd_handle}->print("\012");
                        while (my $line=$self->{_cmd_handle}->
                                             get(Timeout=>$cmtimeout)) {
                           chomp $line;
                           next if $line=~/^\s*$/s;
                           last;
                        } select((select($self->{_cmd_handle}),$|=1)[0]);
                        $str="echo \"del freemem${pid_ts}.bat\""
                            ." >> rm${pid_ts}.bat";
                        $self->{_cmd_handle}->print($str);
                        $allines='';
                        while (my $line=$self->{_cmd_handle}->
                                             get(Timeout=>$cmtimeout)) {
                           $allines.=$line;
                           last if $allines=~/$cmd_prompt$/s;
                        }
                        $Net::FullAuto::FA_lib::freemem_time=$time;
                     }
                  }
               }
               if (!$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug) {
                  print $Net::FullAuto::FA_lib::blanklines;
                  #if ($Net::FullAuto::FA_lib::OS ne 'cygwin') {
                  #   print $Net::FullAuto::FA_lib::clear,"\n";
                  #}
                  print "\n       Gathering MSWin Output  $dots";
                  if ($dcnt++<5) {
                     $dots.="  .";
                  } else { $dots='';$dcnt=0 }
                  print "\n\n       From Command =>  $cmmd\n\n";
               } sleep 1;
            }
print "GETTING THIS=${c}out${pid_ts}.txt\n";
            my $trandir='';
            if (($self->{_hostlabel}->[1] ne $Net::FullAuto::FA_lib::DeploySMB_Proxy[0]
                  || $Net::FullAuto::FA_lib::DeploySMB_Proxy[0] ne "__Master_${$}__")
                  && !($self->{_uname} eq 'cygwin' &&
                  ($Net::FullAuto::FA_lib::DeploySMB_Proxy[0] eq "__Master_${$}__"
                  || $self->{_hostlabel}->[0] eq "__Master_${$}__"))) {
               if ($self->{_work_dirs}->{_lcd} ne
                     $self->{_work_dirs}->{_tmp_lcd}) {
                  ($output,$stderr)=&ftpcmd($self,
                     "lcd \"$self->{_work_dirs}->{_tmp_lcd}\"");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                  ($output,$stderr)=&ftpcmd($self,
                     "get \"${c}out${pid_ts}.txt\"");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-3') if $stderr;
                  ($output,$stderr)=&ftpcmd($self,
                     "lcd \"$self->{_work_dirs}->{_lcd}\"");
                  &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
               } else {
                  ($output,$stderr)=&ftpcmd($self,
                     "get \"${c}out${pid_ts}.txt\"");
               }
               if ($err_size) {
                  if ($self->{_work_dirs}->{_lcd} ne
                        $self->{_work_dirs}->{_tmp_lcd}) {
                     ($output,$stderr)=&ftpcmd($self,
                        "lcd \"$self->{_work_dirs}->{_tmp_lcd}\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                     ($output,$stderr)=&ftpcmd($self,
                        "get \"${c}err${pid_ts}.txt\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-3') if $stderr;
                     ($output,$stderr)=&ftpcmd($self,
                        "lcd \"$self->{_work_dirs}->{_lcd}\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-2') if $stderr;
                  } else {
                     ($output,$stderr)=&ftpcmd($self,
                       "get \"${c}err${pid_ts}.txt\"");
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-1') if $stderr;
                  }
               }
            }
            if ($Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp}) {
               $trandir=$Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp};
               if (substr($trandir,-1) ne '/') {
                  $trandir.='/';
               }
            }
            ($stdout,$stderr)=$localhost->cmd(
               "cat ${trandir}out${pid_ts}.txt");
            if ($stderr) {
               $die="$stderr\n\n       From Command -> "
                   ."\"cat ${trandir}out${pid_ts}.txt\"";
               &Net::FullAuto::FA_lib::handle_error($die);
            }
            my $cmd_error='';my $error='';
            if ($err_size) {
               ($cmd_error,$stderr)=$localhost->cmd(
                  "cat ${trandir}err${pid_ts}.txt");
               if ($stderr) {
                  $die="$stderr\n\n       From Command -> "
                      ."\"cat ${trandir}err${pid_ts}.txt\"";
                  &Net::FullAuto::FA_lib::handle_error($die,'-4');
               }
            }
            my $out='';
            if ($Net::FullAuto::FA_lib::OS eq 'cygwin') {
               ($out,$error)=$localhost->cmd(
                  "cmd /c del /S /Q "
                  .$Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp_mswin}
                  ."\\\\out${pid_ts}.txt",
                          '__live__');
               if ($error) {
                  $die="$error\n\n       From Command -> "
                      ."\"cmd /c del /S /Q "
                      .$Net::FullAuto::FA_lib::localhost->{_work_dirs}-{_tmp_mswin}
                      ."\\\\out${pid_ts}.txt\"";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
               ($out,$error)=$localhost->cmd(
                  "cmd /c del /S /Q "
                  .$Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp_mswin}
                  ."\\\\err${pid_ts}.txt",
                          '__live__');
               if ($error) {
                  $die="$error\n\n       From Command -> "
                      ."\"cmd /c del /S /Q "
                      .$Net::FullAuto::FA_lib::localhost->{_work_dirs}->{_tmp_mswin}
                      ."\\\\err${pid_ts}.txt\"";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
               &Net::FullAuto::FA_lib::handle_error(
                  "$cmd_error\n\n       From Command -> $cmmd",'-8')
                  if $cmd_error && !$wantarray;
            } else {
               ($out,$error)=$localhost->cmd(
                  "rm -rf ${trandir}out${pid_ts}.txt");
               if ($error) {
                  $die="$error\n\n       From Command -> "
                      ."\"rm -rf ${trandir}out${pid_ts}.txt\"";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
               ($out,$error)=$localhost->cmd(
                  "rm -rf ${trandir}err${pid_ts}.txt");
               if ($error) {
                  $die="$error\n\n       From Command -> "
                      ."\"rm -rf ${trandir}err${pid_ts}.txt\"";
                  &Net::FullAuto::FA_lib::handle_error($die);
               }
            }
            $str="echo \"del ${t}rm${pid_ts}.bat\""
                ." >> ${t}rm${pid_ts}.bat";
            $self->{_cmd_handle}->print($str);
            $allines='';
            while (my $line=$self->{_cmd_handle}->
                                    get(Timeout=>$cmtimeout)) {
               $allines.=$line;
               last if $allines=~/$cmd_prompt$/s;
            }
            $self->{_cmd_handle}->print("cmd /c ${t}rm${pid_ts}.bat");
            &Net::FullAuto::FA_lib::clean_filehandle($self->{_cmd_handle});
            if ($cmd_error) {
               my $error="$cmd_error\n\n       From Command -> $cmmd";
               &Net::FullAuto::FA_lib::handle_error($error) if !$wantarray;
               die "$error\n\n       at $topcaller[0] "
                   ."$topcaller[1] line ".__LINE__.".\n";
            }
         } elsif ($ftp) {
            ($stdout,$stderr)
                =&ftpcmd($self->{_cmd_handle},$command);
            if ($stderr) {
               my $host=($self->{_hostlabel}->[1])
                       ? $self->{_hostlabel}->[1]
                       : $self->{_hostlabel}->[0];
               my $die="$stderr\n\n       From Command -> "
                      ."\"$command\"\n       for \'$host\'\.";
               &Net::FullAuto::FA_lib::handle_error($die,'-10');
            }
         } else {
            my $bckgrd=0;
            $bckgrd=1 if $command=~s/[\t ][&](?>\s*)$//s;
            my $live_command='';
            if ($command=~/^cd[\t ]/) {
               $live_command="$command 2>&1";
#print "WHAT IS THIS=$command\n";
               if (-1<$#{$self->{_hostlabel}} && $self->{_hostlabel}->[$#{$self->{_hostlabel}}]
                     eq "__Master_${$}__") {
                  my $lcd=$command;$lcd=~s/^cd[\t ]*//;
                  chdir $lcd;
               }
            #} elsif ($wantarray && !$ms_cmd) {
            } elsif ($wantarray) {
               $live_command='('.$command.')'." | sed -e 's/^/stdout: /' 2>&1";
            }
            #} else {
            #   $live_command='('.$command.')';
            #}
            $live_command.=' &' if $bckgrd;
print "LIVE_COMMAND_UNIX=$live_command and TIMEOUT=$cmtimeout and KEYSSELF="
      ,keys %{$self},"\n";# if !$Net::FullAuto::FA_lib::cron && $debug;
            print $Net::FullAuto::FA_lib::MRLOG
               "\n+++++++ RUNNING LIVE COMMAND +++++++: ==>$live_command<==\n\tand ",
               "SELECT_TIMEOUT=$cmtimeout and KEYSSELF=",
               (join ' ',@{[keys %{$self}]}),"\n\n"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            print "\n+++++++ RUNNING LIVE COMMAND +++++++: ==>$live_command<==\n\tand ",
               "SELECT_TIMEOUT=$cmtimeout and KEYSSELF=",
               (join ' ',@{[keys %{$self}]}),"\n\n"
               if !$Net::FullAuto::FA_lib::cron && $debug;
            $self->{_cmd_handle}->timeout($cmtimeout);
            $live_command=~s/\\/\\\\/g;
            $live_command=~s/\\$//mg;
            $self->{_cmd_handle}->print($live_command);
            my $growoutput='';my $ready='';my $firstout=0;
            my $fulloutput='';my $lastline='';my $errflag='';
            my $test_out='';my $first=-1;#my $starttime=0;
            my $starttime=time();my $restart_attempt=1;my $nl='';
            my $select_timeout=2;my $appendout='';my $retry=0;
            my $command_stripped_from_output=0;
            $self->{_cmd_handle}->autoflush(1);my $save='';
            FETCH: while (1) {
               my $output='';$nl='';
               my $tim=time()-$starttime;
               if (!$Net::FullAuto::FA_lib::cron && $debug) {
                  print "INFO: ======= AT THE TOP OF MAIN OUTPUT LOOP =======;".
                     " at Line ".__LINE__."\n" if $first || $starttime;
                  print "INFO: STARTTIME=$starttime and TIMENOW=",time(),
                     " and TIMEOUT=$cmtimeout and Diff=$tim\n";
               }
               print $Net::FullAuto::FA_lib::MRLOG
                     "INFO: ======= AT THE TOP OF MAIN OUTPUT LOOP =======;".
                     " at Line ".__LINE__."\n",
                     "INFO: STARTTIME=$starttime and TIMENOW=",time(),
                     " and TIMEOUT=$cmtimeout and Diff=$tim and SELECT_TIMEOUT=",
                     "$select_timeout\n"
                     if $Net::FullAuto::FA_lib::log &&
                     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               if ($select_timeout==$tim) {
                  $self->{_cmd_handle}->print("\003");
                  ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle(
                     $self->{_cmd_handle});
                  if ($stderr) {
                     &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                        if $stderr=~/Connection closed/s;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }
                  my $errhost='';
                  if ($hostlabel eq "__Master_${$}__") {
                     $errhost=$Net::FullAuto::FA_lib::local_hostname;
                  } else { $errhost=$hostlabel }
                  my $lv_errmsg="$growoutput"
                               ."\n\n       read timed-out for command :"
                               ."\n\n       -> $live_command"
                               ."\n\n       invoked on \'$errhost\'"
                               ."\n\n       Current Timeout "
                               ."Setting is ->  $cmtimeout seconds.\n\n";
                  $self->{_cmd_handle}->timeout($svtimeout);
                  if ($wantarray) {
                     die $lv_errmsg;
                  } else {
                     &Net::FullAuto::FA_lib::handle_error($lv_errmsg)
                  }
               } elsif (select
                     $ready=${${*{$self->{_cmd_handle}}}{net_telnet}}{fdmask},
                     '', '', $select_timeout) {
                  alarm($select_timeout+10);
                  sysread $self->{_cmd_handle},$output,
                     ${${*{$self->{_cmd_handle}}}{net_telnet}}{blksize},0;
                  alarm(0);
                  print $Net::FullAuto::FA_lib::MRLOG
                     "INFO: Got past the Timeout Alarm; at Line ".__LINE__."\n"
                     if $Net::FullAuto::FA_lib::log &&
                     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  $output=~s/[ ]*\015//g;
                  $output=~tr/\0-\11\13-\37\177-\377//d;
                  print $Net::FullAuto::FA_lib::MRLOG
                     "\nRAW OUTPUT: ==>$output<== at Line ",__LINE__,"\n\n"
                     if $Net::FullAuto::FA_lib::log &&
                     -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  print "\nRAW OUTPUT: ==>$output<== at Line ",__LINE__,"\n\n"
                     if !$Net::FullAuto::FA_lib::cron && $debug;
                  $first=1 if $first==0;
                  if (!$firstout) {
                     $firstout=1;
                     if ($output=~/^\s*$cmd_prompt$/) {
                        print "INFO: Got PROMPT - $cmd_prompt; ".
                           "Setting \$firstout=1 and next FETCH\n"
                           if !$Net::FullAuto::FA_lib::cron && $debug;
                        next;
                     } else {
                        print "INFO: Setting \$firstout=1 and CONTINUING\n"
                           if !$Net::FullAuto::FA_lib::cron && $debug;
                     }
                  }
                  if ($first<0) {
                     print "\nOUTPUT BEFORE NEW LINE ENCOUNTERED: ==>$output<== :",
                        " at Line ",__LINE__,"\n\n"
                        if !$Net::FullAuto::FA_lib::cron && $debug;
                     print $Net::FullAuto::FA_lib::MRLOG
                        "\nOUTPUT BEFORE NEW LINE ENCOUNTERED: ==>$output<== :",
                        " at Line ",__LINE__,"\n\n"
                        if $Net::FullAuto::FA_lib::log &&
                        -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $loop=$wait=$sec=$ten=0;$hun=5;
                     if ($appendout) {
                        $output="$appendout$output";
                        $appendout='';
                     }
                     my $test_stripped_output=$output;
                     $test_stripped_output=~s/\s*//gs;
                     my $stripped_live_command=$live_command;
                     $stripped_live_command=~s/\s*//gs;
                     if ($test_stripped_output eq $stripped_live_command) {
                        print "\nSTRIPPED OUTPUT equals STRIPPED LIVE COMMAND",
                           " at Line ",__LINE__,"\n"
                           if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOUR\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $command_stripped_from_output=1;
                        $output='';
                        $first=0;next;
                     } elsif ($output=~/\n/s) {
print "WE HAVE NEW LINES IN THE OUTPUT and OUTPUT=$output<==\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "WE HAVE NEW LINES IN THE OUTPUT and ",
   "OUTPUT=$output<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           die 'logout' if $output=~/imed out/s
                              || $output=~/logout$|closed\.$/mg;
print $Net::FullAuto::FA_lib::MRLOG "GOT PAST DIE<==".index $output,'imed out'."\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        my $last_line='';
                        $output=~/^.*\n(.*)$/s;
                        $last_line=$1;
                        $last_line||='';
                        my $ptest=substr($output,(rindex $output,'|'),-1);
                        $ptest=~s/\s*//g;$ptest||='';
                        if ($last_line && $last_line=~/$cmd_prompt$/s
                              || $bckgrd) {
print "LAST_LINE=$last_line and OUTPUT=$output<=\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "LAST_LINE=$last_line and OUTPUT=$output<=\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           if (-1<index $ptest,'1stdout:') {
                              $output=~s/^.*?1(?:\s|\s*\[[AK]|\<)*
                                 (stdout:.*)$/$1/sx;
                              &display($output,$cmd_prompt,$save)
                                 if $display;
                              $growoutput.=$output;$output='';
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FIVE\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $first=0;
                           } elsif ($output=~
                                 s/^.*(?>1|\s+\<)(?>\s|\s*\[[AK]|\<)+
                                 (stdout:.*)$/$1/sx) {
                              &display($output,$cmd_prompt,$save)
                                 if $display;
                              $growoutput.=$output;$output='';
print $Net::FullAuto::FA_lib::MRLOG "FIRST_SIX\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $first=0;
                           } elsif ($bckgrd && $output=~
                                 s/^.*?s(?:\s|\<)*?e(?:\s|\<)*?d
                                    (?>\s+?-e\s+?).*?stdout.*?
                                    (?:2\s*?\>\s*?\&s*?1\s*?\&)
                                    (?<!stdout:)(.*
                                    \n$cmd_prompt.*)$/$1/sx
                                 && $output!~s/^\s*\<\s*
                                       ($cmd_prompt.*)$/$1/sx
                                 && $output!~s/^\s+
                                        ($cmd_prompt.*)/$1/sx) {
                              #($growoutput.=$output)=~s/$cmd_prompt//;
                              #$growoutput=~s/^(.*)$/       $1/mg;
                              #$growoutput=~s/^(.*)$/$1$cmd_prompt/s;
                              #$growoutput=~s/^\s*//s;
                              $output=~s/$cmd_prompt//;
                              $output=~s/^(.*)$/       $1/mg;
                              $output=~s/^(.*)$/$1$cmd_prompt/s;
                              $output=~s/^\s*//s;
                              &display($output,$cmd_prompt,$save)
                                 if $display;
                              $growoutput.=$output;
                              $output='';$first=0;
print $Net::FullAuto::FA_lib::MRLOG "FIRST_SEVEN\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           } elsif ($output=~
                                 s/^.*sed(?>\s+-e\s+).*stdout.*
                                    (?>2(?>\s|\>|\<|\&)+1)
                                    (?>\s|\<)*(?<!stdout:)(.*
                                    \n$cmd_prompt)$/$1/sx
                                 && $output!~s/^\s*\<(?>\s|\s*\[[AK]\s*)+
                                       ($cmd_prompt)$/$1/sx
                                 && $output!~s/^(?>\s|\s*\[[AK]\s*)+
                                       ($cmd_prompt)/$1/sx) {
                              &display($output,$cmd_prompt,$save)
                                 if $display;
                              $growoutput.=$output;$output='';
print $Net::FullAuto::FA_lib::MRLOG "FIRST_EIGHT\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $first=0;
######## CHANGED LINE BELOW AND TOOK AWAY THE ' ' SPACE AFTER stdout: 080107
                           } elsif ((-1<index $output,'stdout:') &&
                                 $output=~s/^\s*(stdout.*
                                 \n$cmd_prompt)$/$1/sx) {
                              &display($output,$cmd_prompt,$save)
                                 if $display;
                              $growoutput.=$output;$output='';
print $Net::FullAuto::FA_lib::MRLOG "FIRST_EIGHT_AND_A_HALF\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $first=0;
                           } else {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_NINE\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              &display($last_line,$cmd_prompt,$save)
                                 if $display;
                              $first=0;$growoutput.=$last_line;
                              $growoutput=~s/^.*($cmd_prompt)$/$1/s;
                              $output='';
                           }
                        } elsif ($ptest eq
                              "|sed-e's/^/stdout:/'2>&1") {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_TEN\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           $first=0;next;
                        } elsif (unpack('a7',$output) eq 'stdout:') {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_ELEVEN\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           $first=0;
                        } elsif (($output=~s/^(.*)\/(?:\s+\<)(.*)$/$1$2/s
                              && $output=~s/^.*?(?:1|\s+\<)
                              (?:\s|\s*\[[AK]\s*)*
                              (stdout:.*)$/$1/sx) || $output=~
                              s/^.*?(?:1|\s+\<)(?:\s|\s*\[[AK]\s*)*
                              (stdout:.*)$/$1/sx) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_TWELVE\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           $first=0;
#print "WE STRIPPED CMD and OUTPUT=$output<====\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "WE STRIPPED CMD and OUTPUT=$output\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           } else {
print $Net::FullAuto::FA_lib::MRLOG "HERE WE ARE AT A PLACE3 and GO=$growoutput\n"
    if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $appendout=$output;next }
if (!$Net::FullAuto::FA_lib::cron && $debug) {
   print "WE DID NOTHING TO STDOUT - $output\n";#sleep 2;
}
print $Net::FullAuto::FA_lib::MRLOG "WE DID NOTHING TO STDOUT - $output\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

#open(BK,">brianout.txt");
#print BK "$output";
#CORE::close BK;
#print "OPUT=$output<== and ",`od -a brianout.txt`,"\n";
#unlink "brianout.txt";
#open(BK,">brianout.txt");
#print BK "$lv_cmd";
#CORE::close BK;
#print "LV_CMD=$lv_cmd<== and ",`od -a brianout.txt`,"\n";
#unlink "brianout.txt";
#print "EXAMINERR=>OPUT=$output<= and LV_CMD=$lv_cmd<=\n";
                     } elsif ($output=~
                           s/^.*(?:\s|\<)+2(?:\s|\<)*
                              \>(?:\s|\<)*\&(?:\s|\[[AK]|\<)*1
                              (?:\s|\[[AK]|\<)*(
                              (?:stdout:)*.*)$/$1/sx) {
print $Net::FullAuto::FA_lib::MRLOG "HERE WE ARE AT A PLACE555 and GO=$growoutput\n"
    if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        last if $output=~/$cmd_prompt$/
                     } else { $appendout=$output;next }
                  }
print $Net::FullAuto::FA_lib::MRLOG "PAST THE ALARM3\n"
      if $Net::FullAuto::FA_lib::log &&
      -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

print "OUTPUT ***After First-Line Loop***=$output<== and COMSTROUT=$command_stripped_from_output<==\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "OUTPUTNOWWWWWWWWWWW=$output<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if ($command_stripped_from_output &&
                        $output=~/^$cmd_prompt/) {
print "GOT COMMAND_PROMPT AND EMPTY OUTPUT AND LAST FETCH<==\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
                     last FETCH; 
                  } elsif ($output eq 'Connection closed') {
                     if ($wantarray) {
print "TWOOO\n";
                        return 0,$output;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($output)
                     }
                  } elsif ($output eq '>') {
                     my $die="The Command:\n\n       $command"
                            ."\n\nHas a Syntax Error. The Command "
                            ."Shell\n       Entered Interacive Mode '>'";
                     if ($wantarray) {
print "THEREE\n";
                        return 0,$die;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($die)
                     }
                  }
######## CHANGED LINE BELOW AND TOOK AWAY THE ' ' SPACE AFTER stdout: 080107
                  $output=~s/^[ |\t]+(stdout:.*)$/$1/m if !$fullerror;
                  &display($output,$cmd_prompt,$save)
                     if $display;
                  $growoutput.=$output;
#if ($Net::FullAuto::FA_lib::debug) {
#open(BK,">brianout.txt");
#print BK "$growoutput";
#CORE::close BK;
#print "OD_GROWOUTPUT=$growoutput<== and ",`od -a brianout.txt`,"\n";
#unlink "brianout.txt";
#}


                  $test_out="\$growoutput";
if (!$Net::FullAuto::FA_lib::cron && $debug) {
print "THISEVALLL=",($test_out=~/$cmd_prompt$/s),
       " and OUT=$output and CMD_PROMPT=$cmd_prompt\n";
}
#print $Net::FullAuto::FA_lib::MRLOG "THISEVALLL=",($test_out=~/$cmd_prompt$/os),
#                     " and OUT=$output and CMD_PROMPT=$cmd_prompt\n"
#                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  if (15<length $growoutput &&
                        unpack('a16',$growoutput) eq '?Invalid command') {
                     $self->{_cmd_handle}->timeout($svtimeout);
                     &Net::FullAuto::FA_lib::handle_error(
                        "?Invalid Command ftp> -> $live_command");
                  } elsif (-1<index lc($growoutput),'killed by signal 15') {
                     die 'Connection closed';
######## CHANGED LINE BELOW AND TOOK AWAY THE ' ' SPACE AFTER stdout: 080107
                  } elsif ((-1==index $growoutput,'stdout:') &&
                        (-1<index $growoutput,' sync_with_child: ')) {
                     &Net::FullAuto::FA_lib::handle_error($growoutput,'__cleanup__');
                  } elsif (1<($growoutput=~tr/\n//) ||
                             $growoutput=~/($cmd_prompt)$/s) {
                     my $oneline=$1;$oneline||=0;
#print "GROWOUTPUT=$growoutput<===GROWOUTPUT\n" if !$Net::FullAuto::FA_lib::cron && $debug;
#print $Net::FullAuto::FA_lib::MRLOG "GROWOUTPUT=$growoutput<===GROWOUTPUT\n"
#                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     ($lastline=$growoutput)=~s/^.*\n(.*)$/$1/s;
#print "GROWOUT=$growoutput<==\n";
#print "LASTLINE=$lastline<==\n";<STDIN>;
print "NOWLASTLINE=$lastline<==\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "NOWLASTLINE=$lastline<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if ($lastline eq $growoutput &&
                           $growoutput=~/$cmd_prompt$/s
                           && (length $growoutput<7 ||
                           unpack('a7',$growoutput) ne 'stdout:')) { 
print $Net::FullAuto::FA_lib::MRLOG "FIRST_THIRTEEN\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        $first=0;
                        $growoutput='';
                     } else {
                        if ($growoutput=~/$cmd_prompt/s) {
print "GROWOUTPUT2=$growoutput\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "GROWOUTPUT2=$growoutput\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           if ($growoutput=~/stdout: PS1=/m) {
                              ($lastline=$growoutput)=~s/^.*\n(.*)$/$1/s;
                           } else {
                              $growoutput=~s/\n*$cmd_prompt\n*//s;
                           }
                        } elsif (!$lastline) {
                           my $tmp_grow=$growoutput;
                           chomp $tmp_grow;
                           ($lastline=$tmp_grow)=~s/^.*\n(.*)$/$1/s;
                           $lastline.="\n";
                        }
                        my $l=length $live_command;
                        if ($first<0) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEEN and GROW=$growoutput<===\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           if ($growoutput=~/2\s*>\s*&1\s*$/s) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEENa\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $first=0;$growoutput='';
                              $output='';
                           } elsif ($oneline) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEENb\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              if ($growoutput=~s/^$live_command//) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEENc\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 $first=0;
                              }
                           } else {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEENd\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              $growoutput=~s/^(.*?)\012//s;
                              my $f_line=$1;
                              if ($f_line=~/[2]\s*[>]\s*[&][1]\s*$/s) {
print $Net::FullAuto::FA_lib::MRLOG "FIRST_FOURTEENe\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 $first=0;
                              }
                           }
                        }
                     }
#print "DONE TRIMMING GROWOUTPUT=$growoutput\n" if !$Net::FullAuto::FA_lib::cron && $debug;
#print $Net::FullAuto::FA_lib::MRLOG "DONE TRIMMING GROWOUTPUT=$growoutput<==\n".
#      "and FULLOUT=$fulloutput<==\n"
#      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if ($growoutput) {
                        if ($wantarray) {
                           my @strings=split /^/, $growoutput;
                           my $str_cnt=$#strings;
                           #foreach my $line (split /^/, $growoutput) {
                           foreach my $line (@strings) {
print "LETS LOOK AT LINE=$line<== and LASTLINE=$lastline<==\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "LETS LOOK AT LINE=$line<== and LASTLINE=$lastline<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                              if ($line ne $lastline || 0<$str_cnt) {
                                 $str_cnt--;
                                 if ($line=~s/^stdout: ?//) {
                                    $fulloutput.=$line;
                                    $errflag='';
                                 } elsif (($line!~/^\[[AK]$|^\n$/s &&
                                       $line ne $live_command &&
                                       $line!~/\s-e\s\'s\/\^\/stdout
                                       \:\s*\/\'\s2\>\&1\s*$/sx) ||
                                       ($fullerror && $line=~/^\n$/s)) {
#print "DOIN FULLERROR1==>$line<== and STRCNT=$str_cnt\n";# if $debug;
#print $Net::FullAuto::FA_lib::MRLOG "DOIN FULLERROR1==>$line<==\n"
#                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
if (!$line) {
                        my $lastDB43=0;my $testline='';
                        DB43: while (1) {
print $Net::FullAuto::FA_lib::MRLOG "WE ARE INSIDE DB43\n";
                           $self->{_cmd_handle}->autoflush(1);
                           $self->{_cmd_handle}->print("echo FAECHO");
                           eval {
                              while (my $line=$self->{_cmd_handle}->get) {
                                 $line=~tr/\0-\11\13-\37\177-\377//d;
                                 ($testline=$line)=~s/\s//g;
print "DB43output=$testline<==\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "DB43output=$testline<==\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 if ($testline=~/^$cmd_prompt$/) {
                                    $lastDB43=1;last
                                 }
                                 if ($testline=~s/$cmd_prompt$//s) {
                                    $line=~s/$cmd_prompt$//s;
                                    $output.=$line;last;
                                 } else { $output.=$line }
                              }
#print "DONEWITHDB43WILE and OUTPUTNOW=$output\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "DONEWITHDB43WHILE and OUTPUTNOW=$output\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                           }; $self->{_cmd_handle}->autoflush(0);
                           last if $lastDB43;
                           if ($@) {
                              if (-1<index $@,'read timed-out') {
                                 next;
                              } else { die "$@       $!" }
                           }
                        }
                        my $tst_out=$output;
                        $tst_out=~s/\s*//gs;
print "TST_OUTTTTT=$tst_out<==\n";
print $Net::FullAuto::FA_lib::MRLOG "TST_OUTTTT=$tst_out<==\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';

}
                                    if ($fullerror && !$errflag) {
                                       $fullerror.="\n";
                                    } $errflag=1;
                                    $fullerror.=$line;
                                    &display($line,$cmd_prompt,$save)
                                       if $display;
                                 } elsif ($fulloutput || $line!~/^\s*$/s) {
                                    $fulloutput.=$line;
                                    &display($line,$cmd_prompt,$save)
                                       if $display;
                                    $errflag='';
                                 }   
                              }
                           }
                        } elsif ($fulloutput || $line!~/^\s*$/s) {
                           $fulloutput.=$growoutput;
                        }
                     }
print "GROW_ADDED_TO_FULL=$growoutput<==\n" if !$Net::FullAuto::FA_lib::cron && $debug;
print $Net::FullAuto::FA_lib::MRLOG "GROW_ADDED_TO_FULL=$growoutput\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if ($growoutput) {
                        if ($log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*') {
                           print $Net::FullAuto::FA_lib::MRLOG $growoutput;
                        }
                        #&display($output,$cmd_prompt,$save) if $display;
                     }
my $lcntt=0;my $newline='';
foreach my $line (reverse split /^/, $fulloutput) {
   $newline=$line.$newline;
   last if $lcntt++==5;
}
print $Net::FullAuto::FA_lib::MRLOG "DOIN FULLOUTPUTMAYBE==>$newline<==",
   " and LASTLINE=$lastline and CMD_PROMPT=$cmd_prompt<== and FO=$fulloutput<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     if (!$lastline) {
                        if ($retry++<3) {
                           DB18: while (1) {
                              if ($retry<2) {
                                 $self->{_cmd_handle}->print;
                              } else {
print "THIRTEEN003\n";
                                 $self->{_cmd_handle}->print("\003");
                              }
                              my $oline='';
                              while (my $line=$self->{_cmd_handle}->get) {
                                 $oline=$line;
                                 $line=~s/\s//g;
                                 last DB18 if $line=~/^$cmd_prompt$/;
                                 $forcedoutput.=$oline;
                                 last if $line=~/$cmd_prompt$/s;
                              }
                           } $forcedoutput||='';
                           $forcedoutput=~s/^$cmd_prompt$//gm;
                           foreach my $line (split /^/, $forcedoutput) {
                              if ($line=~s/^stdout: ?// &&
                                    ($fulloutput || $line!~/^\s*$/s)) {
                                 $fulloutput.=$line;
                                 &display($line,$cmd_prompt,$save)
                                    if $display;
                                 $errflag='';
                              } elsif ($line!~/^\s*$/ &&
                                    $line ne "$live_command\n" &&
                                    $line ne " -e 's/^/stdout:/' 2>&1\n"
                                    || $fullerror && $line=~/^\n$/s) {
print "DOIN FULLERROR2222==>$line<==\n"; #if $debug;
print $Net::FullAuto::FA_lib::MRLOG "DOIN FULLERROR2222==>$line<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                                 if ($fullerror && !$errflag) {
                                    $fullerror.="\n";
                                 } $errflag=1;
                                 $fullerror.=$line;
                                 if ($fullerror) {
                                    if ($log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*') {
                                       print $Net::FullAuto::FA_lib::MRLOG $fullerror;
                                    }
                                    &display($line,$cmd_prompt,$save)
                                       if $display;
                                 }
                              }
                           }
                           if ($ms_cmd) {
                              $stdout=$fullerror;
                           } else {
                              $stdout=$fulloutput;
                              $stderr=$fullerror;
                           }
                           chomp $stdout if $stdout;
                           chomp $stderr if $stderr;
                           last FETCH;
                        }
                        my $warng="\n       WARNING! The Command\n\n"
                                 ."       ==>$live_command\n\n       "
                                 ."Appears to be Hanging\,in an "
                                 ."Infinite Loop\,\n       or Stopped.\n"
                                 ."       Press <CTRL>-C to Quit.\n\n";
                        print $Net::FullAuto::FA_lib::MRLOG $warng 
                           if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                        if (exists $email_defaults{Usage} &&
                               lc($email_defaults{Usage}) eq
                               'notify_on_error') {
                           my $subwarn="WARNING! Command Appears "
                                      ."to be Hanging or Stopped";
                           my %mail=(
                              'Body'    => "$warng",
                              'Subject' => "$subwarn"
                           );
                           &Net::FullAuto::FA_lib::send_email(\%mail);
                        }
                        if ($ms_cmd) {
                           $stdout=$fullerror;
                        } else {
                           $stdout=$fulloutput;
                           $stderr=$fullerror;
                        }
                        chomp $stdout if $stdout;
                        chomp $stderr if $stderr;
                        last;
                     } elsif (-1<index $lastline, $cmd_prompt) {
print "WE HAVE LASTLINE CMDPROMPT AND ARE GOING TO EXIT and FO=$fulloutput and MS_CMD=$ms_cmd<==\n"
   if !$Net::FullAuto::FA_lib::cron && $debug;
                        #if ($ms_cmd) {
                        #   $stdout=$fullerror;
                        #} else {
                           $stdout=$fulloutput;
                           $stderr=$fullerror;
                        #}
		        chomp $stdout if $stdout;
                        chomp $stderr if $stderr;
                        last;
                     } $growoutput=$lastline;
print $Net::FullAuto::FA_lib::MRLOG "GRO_GONNA_LOOP==>$growoutput<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                     $starttime=0;$select_timeout=0;
                  } else {
                     $starttime=time();$select_timeout=$cmtimeout;
                     $restart_attempt=1;
                  }
print $Net::FullAuto::FA_lib::MRLOG "PAST THE ALARM4\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print $Net::FullAuto::FA_lib::MRLOG "GRO_OUT AT THE BOTTOM==>$growoutput<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               } elsif ($starttime && (($cmtimeout<time()-$starttime)
                     || ($select_timeout<time()-$starttime))) {
print $Net::FullAuto::FA_lib::MRLOG "ELSFI AT THE BOTTOM==>$growoutput<==\n";
                  if (!$restart_attempt) {
print "FOURTEEN003\n";
                     $self->{_cmd_handle}->print("\003");
                     ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle(
                        $self->{_cmd_handle});
                     if ($stderr) {
                        &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                           if $stderr=~/Connection closed/s;
                        &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                     }
                     my $lv_errmsg="read timed-out for command :"
                                  ."\n\n       -> $live_command"
                                  ."\n\n       invoked on \'$hostlabel\'"
                                  ."\n\n       Current Timeout "
                                  ."Setting is ->  $cmtimeout seconds.\n\n";
                     $self->{_cmd_handle}->timeout($svtimeout);
                     if ($wantarray) {
                        die $lv_errmsg;
                     } else {
                        &Net::FullAuto::FA_lib::handle_error($lv_errmsg)
                     }
                  } else {
                     $restart_attempt=0;
                     $starttime=time();$select_timeout=$cmtimeout;
                     $self->{_cmd_handle}->print;
                  }
print $Net::FullAuto::FA_lib::MRLOG
   "NOWWWW ELSFI AT THE BOTTOM==>$growoutput and CMT=$cmtimeout<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
               } elsif (!$starttime) {
print $Net::FullAuto::FA_lib::MRLOG "BLAU DLAS\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
                  $starttime=time();$select_timeout=$cmtimeout;
                  $restart_attempt=1;
               }
            } $stderr=$lastline if $lastline=~/Connection to.*closed/s;
print $Net::FullAuto::FA_lib::MRLOG "cmd() STDERRBOTTOM=$stderr<== and LASTLINE=$lastline<==\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            if ($stderr!~s/^\s*$//s) {
               chomp($stderr);
               &Net::FullAuto::FA_lib::handle_error($stderr) if !$wantarray;
            }
         }
      };
print $Net::FullAuto::FA_lib::MRLOG "PAST THE ALARM5\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      $self->{_cmd_handle}->autoflush(0)
         if defined fileno $self->{_cmd_handle};
      my $eval_error='';
      if ($@) {
         print $Net::FullAuto::FA_lib::MRLOG "WE HAVE A *TRUE* EVAL ".
                      "ERROR! in Rem_Command::cmd()=$@<==\n";
         $eval_error=$@;undef $@;
      }
      if ($ftp) {
         $self->{_ftp_handle}->timeout($svtimeout);
      } else {
         $self->{_cmd_handle}->timeout($svtimeout);
      }
print $Net::FullAuto::FA_lib::MRLOG "EVAL_ERROR=$eval_error and STDERR=$stderr\n"
      if ($Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*')
         && $stderr or $eval_error;
      $eval_error=$stderr if $stderr && !$eval_error; 
      if ($eval_error) {
         #print "ERROR THROWN! in Rem_Command::cmd()\n"
         #   if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
         print $Net::FullAuto::FA_lib::MRLOG "ERROR THROWN in Rem_Command::cmd()\n"
                              if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         chomp($eval_error=~tr/\0-\11\13-\37\177-\377//d);
         $eval_error=~s/^\s+//;
         print "\n        ",(caller(2))[3]," ERROR MESSAGE! :\n".
               "\n        $eval_error\n"
            if !$Net::FullAuto::FA_lib::cron || $Net::FullAuto::FA_lib::debug;
         print $Net::FullAuto::FA_lib::MRLOG (caller(2))[3]." Error Message=$eval_error<==\n"
                              if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         &Net::FullAuto::FA_lib::give_semaphore($sem) if $sem;
         if ((-1<index $command,"kill ") &&
               (-1<index $eval_error,"eof")) {
            my $prc=substr($command,-3);
            if ($wantarray) {
               return "process \#$prc killed","";
            } else { return "process \#$prc killed" }
         } $login_retry++;
print $Net::FullAuto::FA_lib::MRLOG "LOGINRETRY=$login_retry and ",
   "ERROR=$eval_error<== and FTP=$ftp and NOTRAP=$notrap\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if ((-1<index $eval_error,'logout') ||
               (-1<index $eval_error,'Connection closed')
               && !$login_retry && !$cleanup) {
print $Net::FullAuto::FA_lib::MRLOG "MADE IT TO LOGOUT ERROR HANDLING\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            my $sav_self=$self->{_cmd_handle};
            my $curdir=$self->{_work_dirs}->{_cwd}
               || $self->{_work_dirs}->{_cwd_mswin};
print $Net::FullAuto::FA_lib::MRLOG "CURDIR=$curdir\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill($self->{_cmd_pid},9) if
               &Net::FullAuto::FA_lib::testpid($self->{_cmd_pid});
            $self->{_cmd_handle}->close;
            if (!exists $same_host_as_Master{$self->{_hostlabel}->[0]}) {
               ($self,$stderr)=&Net::FullAuto::FA_lib::connect_host(
                  $self->{_hostlabel}->[0],$cmtimeout);
            } else {
               ($self,$stderr)=
                  Rem_Command::new('Rem_Command',
                  "__Master_${$}__",'__new_master__',
                  $self->{_connect});
            }
print $Net::FullAuto::FA_lib::MRLOG "GOT NEW SELF=$self and CURDIR=$curdir\n";
#   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            $self->cwd($curdir);
            CH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
               foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
                  foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                        {$sid}}) {
                     if ($sav_self
                           eq ${$Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type}}[0]) {
                        my $value=$Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type};
                        delete $Net::FullAuto::FA_lib::Processes
                           {$hlabel}{$sid}{$type};
                        substr($type,0,3)='cmd';
                        $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}=
                           $value;
                        last CH;
                     }
                  }
               }
            } next if $self;
         } elsif (!$ftp && !$login_retry && !$notrap && !$cleanup
               && -1==index $eval_error,'space in the') {
print $Net::FullAuto::FA_lib::MRLOG "GOING TO TRY RETRY\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "LOGINRETRY=$login_retry and 1=$self->{_work_dirs}->{_cwd}\n";
            my $save_cwd='';
            if (exists $self->{_work_dirs}->{_cwd_mswin}
                  && $self->{_work_dirs}->{_cwd_mswin}=~/^\\\\/) {
               $save_cwd=$self->{_work_dirs}->{_tmp};
            } else {
               $save_cwd=$self->{_work_dirs}->{_cwd};
            }
print $Net::FullAuto::FA_lib::MRLOG "SAVECWD=$save_cwd\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            my $save_self=$self->{_cmd_handle};
            ($self->{_cmd_handle},$eval_error)=
               &login_retry($self->{_cmd_handle},$eval_error);
               #&login_retry($self->{_cmd_handle},$eval_error,$hostlabel,'');
            if ($self->{_cmd_handle}) {
print "GOING TO TRY AND CHANGE TO $save_cwd\n";
print $Net::FullAuto::FA_lib::MRLOG "GOING TO TRY AND CHANGE TO $save_cwd\n";
               ($output,$stderr)=$self->cwd($save_cwd);
               if ($stderr && (-1==index $stderr,'command success')) {
                  if (wantarray) {
print "FOURRR\n";
                     return '',$eval_error;
                  } else { print "WELLLL\n";&Net::FullAuto::FA_lib::handle_error($eval_error) }
               } else { next }
            } else {
               $self->{_cmd_handle}=$save_self;
            }
         }
print $Net::FullAuto::FA_lib::MRLOG "LOGINRETRY2=$login_retry and ",
   "ERROR=$eval_error<== and FTP=$ftp and NOTRAP=$notrap\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         if (-1<index $eval_error,'filehandle isn') {
            &Net::FullAuto::FA_lib::handle_error($eval_error);
         } elsif ($wantarray) {
print $Net::FullAuto::FA_lib::MRLOG "WE ARE RETURNING ERROR=$eval_error\n"
   if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
#print "FIVEEE\n";
            return '',$eval_error;
         } else { &Net::FullAuto::FA_lib::handle_error($eval_error) }
      }
      pop @FA_lib::pid_ts if $pid_ts;
      $stdout||='';$stderr||='';
      &Net::FullAuto::FA_lib::give_semaphore($sem) if $sem;
print $Net::FullAuto::FA_lib::MRLOG "DO WE EVER REALLY GET HERE? ".
   "and STDOUT=$stdout<== and STDERR=$stderr<==\n"
   if $Net::FullAuto::FA_lib::log &&
   -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      if ($wantarray) {
         return $stdout,$stderr;
      } else { return $stdout }
   }

}

sub display
{
   #print "DISPLAY_CALLER=",caller,"\n";
   my $line=$_[0];
   my $cmd_prompt=$_[1];
   my $save=$_[2];
######## CHANGED LINE BELOW AND ADDED THE ? AFTER stdout: ?  080107
   $line=~s/^stdout: ?//mg;
   if (length $line<length $cmd_prompt) {
      if (-1<index $cmd_prompt,substr($line,(rindex $line,'_'))) {
         $save.=$line;
         return $save;
      } else {
         $save='';
         print $line;
         return $save;
      }
   } elsif ($line=~s/\n*$cmd_prompt//gs) {
      $save='';
      print  $line;
      return $save;
   } elsif (-1<index $cmd_prompt,substr($line,(rindex $line,'_'))) {
      $save.=$line;
      return $save; 
   } else {
      $save='';
      print $line;
      return $save;
   }
}

sub login_retry
{
   my @topcaller=caller;
   print "login_retry() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "login_retry() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log
      && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];my $error=$_[1];
   my $sid='';my $hostlabel='';
   if ($self eq $localhost->{_cmd_handle}) {
      $hostlabel=$localhost->{_hostlabel}->[0];
      my ($ip,$hostname,$use,$ms_share,$ms_domain,
         $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
         $owner,$group,$sdtimeout,$transfer_dir,$rcm_chain,
         $rcm_map,$uname,$ping,$freemem)
         =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel,
             $localhost->{_connect});
         $sid=($su_id)?$su_id:$login_id;
   } else {
      LR: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $slid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                     {$slid}}) {
               if ($self eq ${$Net::FullAuto::FA_lib::Processes{$hlabel}{$slid}{$type}}[0]) {
                  $hostlabel=$hlabel;$sid=$slid;
                  last LR;
               }
            }
         }
      }
   }
#print "ONEEE=",$Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$sid"},"\n";
#print "TWOOO=",$Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$sid"}->{_work_dirs},"\n";
#print "LOGINRETRYHOSTLABEL=$hostlabel<== and SID=$sid<== and CWD=",$Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$sid"}->{_work_dirs}->{_cwd},"\n";
#print $Net::FullAuto::FA_lib::MRLOG "LOGINRETRYHOSTLABEL=$hostlabel<== and SID=$sid<== and CWD=",$Net::FullAuto::FA_lib::Connections{"${hostlabel}__%-$sid"}->{_work_dirs}->{_cwd},"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $new_handle='';my $stderr='';
   my ($ip,$hostname,$use,$ms_share,$ms_domain,
       $cmd_cnct,$ftr_cnct,$login_id,$su_id,$chmod,
       $owner,$group,$sdtimeout,$transfer_dir,$rcm_chain,
       $rcm_map,$uname,$ping,$freemem)
       =&Net::FullAuto::FA_lib::lookup_hostinfo_from_label($hostlabel);
print $Net::FullAuto::FA_lib::MRLOG "WHAT IS THE ERROR=$error\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   if ((-1<index $error,'filehandle isn') ||
         (-1<index $error,'read error') ||
         (-1<index $error,'Connection closed') ||
         !defined fileno $self) {
print $Net::FullAuto::FA_lib::MRLOG "WE ARE GETTING NEW HANDLE\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      my $handleid="$self";
      $self->autoflush(1);
      $self->close;
      KFH: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $sid (
               keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (
                 keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                      {$sid}}) {
               if ($handleid eq ${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[0]) {
print "THISKILL2=${$Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}}[2]\n";
                  ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill(${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[2],9) if
                     &Net::FullAuto::FA_lib::testpid(${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[2]);
                  ($stdout,$stderr)=&Net::FullAuto::FA_lib::kill(${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[1],9) if
                     &Net::FullAuto::FA_lib::testpid(${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[1]);
print "THISKILL1=${$Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type}}[1]\n";
                  delete
                     $Net::FullAuto::FA_lib::Processes{$hlabel}
                     {$sid}{$type};
                  last KFH;
               }
            }
         }
      }
      ($new_handle,$stderr)=&Net::FullAuto::FA_lib::connect_cmd($hostlabel,$timeout);
print $Net::FullAuto::FA_lib::MRLOG "NEW HANDLE=$new_handle and STDERR=$stderr\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      if ($stderr) {
         if (wantarray) { return '',$stderr }
         else { &Net::FullAuto::FA_lib::handle_error($stderr,'-3') }
      } $self->close;
      RL: foreach my $hlabel (keys %Net::FullAuto::FA_lib::Processes) {
         foreach my $sid (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}}) {
            foreach my $type (keys %{$Net::FullAuto::FA_lib::Processes{$hlabel}
                  {$sid}}) {
               if ($self eq ${$Net::FullAuto::FA_lib::Processes
                     {$hlabel}{$sid}{$type}}[0]) {
                  delete
                     $Net::FullAuto::FA_lib::Processes{$hlabel}{$sid}{$type};
                  last RL;
               }
            }
         }
      }
      #if (-1<index $new_handle->{_cmd_handle},'HASH') {
      #   return $new_handle->{_cmd_handle}->{_cmd_handle},'';
      #} else { return $new_handle->{_cmd_handle},'' }
      return $new_handle->{_cmd_handle},'';
   } elsif ($Net::FullAuto::FA_lib::OS ne 'cygwin' && $su_id) {
      $self->print;
      ($id,$stderr)=&Net::FullAuto::FA_lib::unix_id($self,$su_id,
                    $hostlabel,$error);
print $Net::FullAuto::FA_lib::MRLOG "GOT NEW UNIX ID=$id and STDERR=$stderr and SU_ID=$su_id\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
print "GOT NEW UNIX ID=$id and STDERR=$stderr and SU_ID=$su_id\n";
      return '',$error if $stderr;
      if ($id eq $su_id) {
         if (wantarray) { return '',$error }
         else { &Net::FullAuto::FA_lib::handle_error($error,'-3') }
      } else {

                  ($output,$stderr)=&Net::FullAuto::FA_lib::clean_filehandle($self);
                  if ($stderr) {
                     &Net::FullAuto::FA_lib::handle_error('read timed-out','-3')
                        if $stderr=~/Connection closed/s;
                     &Net::FullAuto::FA_lib::handle_error($stderr,'-5');
                  }

         my ($ignore,$su_err)=
            &Net::FullAuto::FA_lib::su($self,$hostlabel,$login_id,
            $su_id,$hostname,$ip,$use,$error);
print "SU_ERR=$su_err\n" if $su_err;
         &Net::FullAuto::FA_lib::handle_error($su_err) if $su_err;
         return $self,'';
      }
   } else { return '',$error }
}

sub cwd
{
print "INSIDE CWD2\n";
   my @topcaller=caller;
   print "Rem_Command::cwd() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "Rem_Command::cwd() CALLER=",
      (join ' ',@topcaller),"\n";# if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   return &File_Transfer::cwd(@_);
}

package Net::FullAuto::MemoryHandle;

use strict;
sub TIEHANDLE {
   my $class = shift;
   bless [], $class;
}

sub PRINT {
   my $self = shift;
   push @$self, join '', @_;
}

sub PRINTF {
   my $self = shift;
   my $fmt = shift;
   push @$self, sprintf $fmt, @_;
}

sub READLINE {
   my $self = shift;
   shift @$self;
}

package Net::FullAuto::FA_DB;

use strict;
use MLDBM::Sync;                       # this gets the default, SDBM_File
use MLDBM qw(DB_File Storable);        # use Storable for serializing
use Fcntl qw(:DEFAULT);                # import symbols O_CREAT & O_RDWR

sub new
{
   our $debug=$Net::FullAuto::FA_lib::debug;
   my $class=shift;
   my $self={};
   $self->{_dbfile}=shift;
   $self->{_dbfile}=~s/\.db$//;
   $self->{_host_queried}={};
   $self->{_line_queried}={};
   bless($self,$class);
}

sub add
{
   our $debug=$Net::FullAuto::FA_lib::debug;
print "ADDCALLER=",caller,"\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "ADDCALLER=".(caller)."\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my $tie_err="can't open tie to $self->{_dbfile}.db";
   my $hostlabel=$_[1];
   my $line=$_[2];
   if (!$line) {
      if (wantarray) {
         return '','ERROR - no entry specified';
      } else {
         &Net::FullAuto::FA_lib::handle_error(
            "FullAutoDB: ERROR - no entry specified\n");
      }
   }
   my $rx1=qr/\d+\s+\w\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
   my $rx2=qr/\d+\s+\w\w\w\s+\d+\s+\d\d\d\d\s+.*/;
   $line=~s/^.*\s+($rx1|$rx2)$/$1/;
   $line=~/^(\d+)\s+(\w\w\w\s+\d+\s+\S+).*$/;
   my $size=$1;my $timestamp=$2;
   my $mt='';my $hr=0;my $dy=0;my $mn=0;my $fileyr=0;
   eval {
      ($mn,$dy,$mt)=split /\s+/, $timestamp;
      if (-1<index $mt,':') {
         ($hr,$mt)=split ':', $mt;
         $fileyr=(localtime)[5];
      } else {
         $fileyr=$mt;$mt=0;
      }
      $timestamp=&Net::FullAuto::FA_lib::timelocal(
         0,$mt,$hr,$dy,$Net::FullAuto::FA_lib::month{$mn}-1,$fileyr);
   };
   if ($@) {
      &Net::FullAuto::FA_lib::handle_error(
         "$@ - LSLINE=$line<- AND TIMESTAMP=$timestamp<- AND MN=$mn<-");
   }
   my $ipc_key="$timestamp$size";
   #my $ipc_key=substr($timestamp,-4);
   &Net::FullAuto::FA_lib::give_semaphore($ipc_key);
   $line="${hostlabel}|%|$line";
   ${$self->{_host_queried}}{"$hostlabel"}='-';
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
      %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
      'MLDBM::Sync',
      "$self->{_dbfile}.db",
      $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
      &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
print "ADDING LINE=$line<==\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "ADDING LINE=$line<==\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{"$line"}=time;
   ${$self->{_line_queried}}{"$line"}='-';
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   return 1,'';
}

sub query
{
   our $debug=$Net::FullAuto::FA_lib::debug;
   my @topcaller=caller;
   print "FA_DB::query() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "FA_DB::query() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $self=$_[0];
   my $tie_err="can't open tie to $self->{_dbfile}.db";
   my $hostlabel=$_[1];
   my $line=$_[2];
   if (!$line) {
      if (wantarray) {
         return '','ERROR - no query specified';
      } else {
         &Net::FullAuto::FA_lib::handle_error(
            "FullAutoDB: ERROR - no query specified\n");
      }
   }
my $logreset=1;
if ($Net::FullAuto::FA_lib::log) { $logreset=0 }
else { $Net::FullAuto::FA_lib::log=1 }
print "LINE TO STRIP TIMEINFO=$line\n" if $Net::FullAuto::FA_lib::debug;
print $Net::FullAuto::FA_lib::MRLOG "LINE TO STRIP TIMEINFO=$line\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $rx1=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d:\d\d\s+.*/;
   my $rx2=qr/\d+\s+[JFMASOND]\w\w\s+\d+\s+\d\d\d\d\s+.*/;
   $line=~s/^.*\s+($rx1|$rx2)$/$1/;
   $line=~/^(\d+)\s+([JFMASOND]\w\w\s+\d+\s+\S+)\s+(.*)$/;
   my $size=$1;my $timestamp=$2;my $filename=$3;
   my $mt='';my $hr=0;my $dy=0;my $mn=0;my $fileyr=0;
   ($mn,$dy,$mt)=split /\s+/, $timestamp;
   if (-1<index $mt,':') {
      ($hr,$mt)=split ':', $mt;
      $fileyr=(localtime)[5];
   } else {
      $fileyr=$mt;$mt=0;
   }
print $Net::FullAuto::FA_lib::MRLOG "TIMEINFO=> MT=$mt HR=$hr DY=$dy MN=$mn FY=$fileyr\n"
      if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
$Net::FullAuto::FA_lib::log=0 if $logreset;
   $timestamp=&Net::FullAuto::FA_lib::timelocal(
      0,$mt,$hr,$dy,$Net::FullAuto::FA_lib::month{$mn}-1,$fileyr);
   my $ipc_key="$timestamp$size";
   $line="${hostlabel}|%|$line";
   ${$self->{_host_queried}}{$hostlabel}='-';
print "STARTING TIE\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "STARTING TIE\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
		   %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},'MLDBM::Sync',
		   "$self->{_dbfile}.db",
		   $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
	   &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
print "DONE WITH TIE\n" if $debug;
print $Net::FullAuto::FA_lib::MRLOG "DONE WITH TIE\n"
                     if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $result=0;
   my %dbcopy=%{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   if (exists $dbcopy{$line}) {
      ${$self->{_line_queried}}{$line}='-';
      $result='File has Already been Transferred';
   } elsif (&Net::FullAuto::FA_lib::test_semaphore($ipc_key)) {
      ${$self->{_line_queried}}{$line}='-';
      $result='Another Process is Transferring File';
   } elsif (!$hr && testtime(\%dbcopy,$filename,$size,
         $mn,$dy,$rx1,$rx2,$hostlabel)) {
      ${$self->{_line_queried}}{$line}='-';
      ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$line}=time;
      $result='File has Already been Transferred';
   } elsif (!$Net::FullAuto::FA_lib::cron) {
      $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
      undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
      untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
      delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
      if (time-$timestamp<600 && $timestamp<time) {
         ${$self->{_line_queried}}{$line}='-';
         return 'File Less then 10 Minutes Old','';
      }
      my $acc='';my $ln='';
      ($acc,$ln)=split /\|\%\|/, $line;
      $ln=~tr/ //s;
      my $banner="\n   The $acc Account File :\n\n      $ln\n\n"
                ."   Is Ready to Transfer\n\n   Choose One :";
      my @output=("Do NOT Transfer NOW","Do NOT Transfer EVER",
                  "TRANSFER Now");
      my $output=&Menus::pick(\@output,$banner,7);
      if ($output eq 'Do NOT Transfer NOW') {
         return "User Declines to Transfer File Now",'';
      } elsif ($output eq ']quit[') {
         &Net::FullAuto::FA_lib::cleanup()
      } elsif ($output eq 'Do NOT Transfer EVER') {
         my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
            %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},'MLDBM::Sync',
            "$self->{_dbfile}.db",
            $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
            &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
         ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$line}=time;
         $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
         undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
         untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
         delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
         ${$self->{_line_queried}}{$line}='-';
         return 'User Declines to EVER Transfer File','';
      } else {
         &Net::FullAuto::FA_lib::take_semaphore($ipc_key);
         ${$self->{_line_queried}}{$line}='-';
         if ($Net::FullAuto::FA_lib::log) {
            print $Net::FullAuto::FA_lib::MRLOG "FA_DB::query() QUERYLINE=",
               "$line\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            print $Net::FullAuto::FA_lib::MRLOG "FA_DB::query() ALL_LINES=",
               (join "\n",sort keys %dbcopy),"\n"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         }
         return 0,'';
      }
   } else {
      if (time-$timestamp<600) {
         ${$self->{_line_queried}}{$line}='-';
         $result='File Less then 10 Minutes Old';
      } else {
         ${$self->{_line_queried}}{$line}='-';
         &Net::FullAuto::FA_lib::take_semaphore($ipc_key);
         if ($Net::FullAuto::FA_lib::log) {
            print $Net::FullAuto::FA_lib::MRLOG "FA_DB::query() QUERYLINE=",
               "$line\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
            print $Net::FullAuto::FA_lib::MRLOG "FA_DB::query() ALL_LINES=",
               (join "\n",sort keys %dbcopy),"\n"
               if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
         }
      }
   }
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
   return $result,'';
}

sub testtime
{
   our $debug=$Net::FullAuto::FA_lib::debug;
   my @topcaller=caller;
   print "FA_DB::testtime() CALLER=",(join ' ',@topcaller),"\n"
      if $Net::FullAuto::FA_lib::debug;
   print $Net::FullAuto::FA_lib::MRLOG "FA_DB::testtime() CALLER=",
      (join ' ',@topcaller),"\n" if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
   my $dbcopy=$_[0];
   my $filename=$_[1];
   my $size=$_[2];
   my $mn=$_[3];my $dy=$_[4];
   my $rx1=$_[5];my $rx2=$_[6];
   my $hostlabel=$_[7];
   foreach my $dbline (keys %{$dbcopy}) {
      my $dbhostlabel='';
      ($dbhostlabel,$dbline)=split /\|\%\|/,$dbline;
      next if $dbhostlabel ne $hostlabel;
      $dbline=~s/^.*\s+($rx1|$rx2)$/$1/;
      $dbline=~/^(\d+)\s+([JFMASOND]\w\w\s+\d+\s+\S+)\s+(.*)$/;
      my $dbsize=$1;my $dbtimestamp=$2;my $dbfilename=$3;
      my $dbmt='';my $dbdy=0;my $dbmn=0;
      ($dbmn,$dbdy,$dbmt)=split /\s+/, $dbtimestamp;
      next if -1==index $dbmt,':';
print $Net::FullAuto::FA_lib::MRLOG "FA_DB::testtime() FILENAME=$filename and DBFN=$dbfilename",
" SIZE=$size and DBS=$dbsize and MN=$mn and DBM=$dbmn and DY=$dy and DBDY=$dbdy\n"
 if $Net::FullAuto::FA_lib::log && -1<index $Net::FullAuto::FA_lib::MRLOG,'*';
      if ($filename eq $dbfilename && $size eq $dbsize
            && $mn eq $dbmn && $dy eq $dbdy) {
         return 1;
      }
   } return 0;
}

sub mod
{
   our $debug=$Net::FullAuto::FA_lib::debug;
   my $self=shift;
   my $tie_err="can't open tie to $self->{_dbfile}.db";
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
      %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
      'MLDBM::Sync',
      "$self->{_dbfile}.db",
      $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
      &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   my $banner="\n   Please Pick a SkipDB Entry to Delete :";
   my @output=keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   my $output=&Menus::pick(\@output,$banner,7);
   delete ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$output};
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
}

sub close
{
   my @caller=caller;
   our $debug=$Net::FullAuto::FA_lib::debug;
print "CLOSE_Caller=",(join ' ',@caller),"\n" if !$Net::FullAuto::FA_lib::cron && $debug;
   my $self=shift;
   my $tie_err="can't open tie to $self->{_dbfile}.db";
   my $synctimepid=time."_".$$."_".$Net::FullAuto::FA_lib::increment++;
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}=tie(
      %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}},
      'MLDBM::Sync',
      "$self->{_dbfile}.db",
      $Net::FullAuto::FA_lib::tieflags,$Net::FullAuto::FA_lib::tieperms) ||
      &Net::FullAuto::FA_lib::handle_error("$tie_err :\n        ".($!));
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->SyncCacheSize('100K');
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->Lock;
   foreach my $line (keys %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}}) {
      my $hostlabel=substr($line,0,(index $line,'|%|'));
      if (exists ${$self->{_host_queried}}{$hostlabel}
            && !exists ${$self->{_line_queried}}{$line}) {
         delete ${$Net::FullAuto::FA_lib::tiedb{$synctimepid}}{$line};
      }
   }
   $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid}->UnLock;
   undef $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   delete $Net::FullAuto::FA_lib::sync_dbm_obj{$synctimepid};
   untie %{$Net::FullAuto::FA_lib::tiedb{$synctimepid}};
   delete $Net::FullAuto::FA_lib::tiedb{$synctimepid};
}

package Net::FullAuto::Getline;
# file: IO/Getline.pm

# Figure 13.2: The Getline module
# line-oriented reading from sockets/handles with access to
# internal buffer.

use strict;
use Carp 'croak';
use IO::Handle;
