package usr_code;

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

our $test=0;our $timeout=0;
require Exporter;
use warnings;
use MemHandle;
#use threads ();
#use Thread::Queue;
our @ISA = qw(Exporter Net::FullAuto::FA_lib);
use Net::FullAuto::FA_lib;

#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################

##  -------------------------------------------------------------
##  SET CONFIGURATION PARAMETERS HERE:
##  -------------------------------------------------------------

############  TEST TOGGLE  ###################

$test=1; # comment-out this line for Production mode

##############################################

############  LOG  TOGGLE  ###################
#$log=1; # comment-out this line to turn off Logging
##############################################

#----------  TEST PARAMETERS  ----------------

our $build_type= $test ? 'test' : '';
our $toggle_rootdir= $build_type ? 'tmp' : 'usr'; 
our $toggle_staticdir= $build_type ? 'tmp' : 'webfs';

#---------------------------------------------

############  SET TIMEOUT  ###################
$timeout=90;
##############################################

######## SET PASSWORD FILE LOCATION  #########
if ($OS eq 'cygwin') {
   $passwd_file_loc="/passwds_ms";
} else {
   $passwd_file_loc="/passwds_ux"
}
##############################################

#####  SET EMAIL AUTOMATION SETTINGS  ########
%email_addresses=(
   'bkelly' => 'Brian.Kelly@fullautosoftware.net',
);
my $email_to=[
               ']USERNAME[',
               'Brian.Kelly@fullautosoftware.net',
             ];
#%email_defaults=(
#   Usage       => 'notify_on_error',
#   Mail_Method => 'smtp',
#   Mail_Server => 'mailserver.fullautosoftware.net',
#   Reply_To    => 'Brian.Kelly@fullautosoftware.net',
#   To          => $email_to,
#   From        => "$progname\@fullautosoftware.net"
#);
##############################################

##  -------------------------------------------------------------
##  WRITE "RESULT" SUBROUTINES HERE:
##  -------------------------------------------------------------

sub get_file_from_one {

   my ($computer_one,$stdout,$stderr);         # Scope Variables

   $computer_one=connect_reverse('');          # Connect to
                                               # Remote Host via
                                               # ssh *and* sftp

   ($stdout,$stderr)=$computer_one->cmd(
                     'echo test > test.txt');  # Run Remote Command

   ($stdout,$stderr)=$computer_one->cmd(
                     'zip /tmp/test test.txt');     # Run Remote Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$computer_one->get(
                     '/tmp/test.zip');              # Get the File

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$localhost->cmd(
                     'unzip test.zip');        # Run Local Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of unzip command from Computer One:".
            "\n\n$stdout\n\n";
   }

}

sub test_this
{
   ($prod1,$stderr)  = &connect_ssh('');
   ($prod2,$stderr)  = &connect_ssh('');
   ($prod10,$stderr) = &connect_host('');
   die $stderr if $stderr; 
   ($dev3,$stderr)   = &connect_ssh('');

   print $Net::FullAuto::FA_lib::MRLOG "OUT OF ALL CONNECT_SSH CALLS\n";

   #$dev3->{_cmd_handle}->print("echo dev3;ps -ef");
   #$output='';
   #while (1) {
   #   eval {
   #      while (my $line=$dev3->{_cmd_handle}->get(Timeout=>1000)) {
   #         $output.=$line;
   #         if ($output=~s/(_funkyPrompt_\s*)+$//s) {
   #            print $output;last;
   #         }
   #      }
   #   };
   #   last if $output!~/^\s*$/;
   #}
   my ($out,$err);
   ($out,$err)=$dev3->cmd("ps -ef",'__display__');
   die if $err;
   print $Net::FullAuto::FA_lib::MRLOG "OUT OF DEV3\n";

   $prod10->{_cmd_handle}->print('sujump');
   $prod10->{_cmd_handle}->get(Timeout=>5);
   sleep 1;
   $prod10->{_cmd_handle}->print('jumpk3lly');
   while (my $line=$prod10->{_cmd_handle}->get) {
      if ($line=~/\$/) { last }
   }
   $prod10->{_cmd_handle}->print('export PS1=_funkyPrompt_');
   while (my $line=$prod10->{_cmd_handle}->get) {
      last if $line=~/_funkyPrompt_/s or $last++==10;
   }
   &Net::FullAuto::FA_lib::clean_filehandle($prod10->{_cmd_handle});
   $prod10->{_cmd_handle}->print("(echo prod10;ps -ef)");
   $output='';my $done=0;
   while (1) {
      eval {
         while (my $line=$prod10->{_cmd_handle}->get(Timeout=>1000)) {
            $output.=$line;
print $Net::FullAuto::FA_lib::MRLOG "PROD10_LINE=$line<==\n";
            if ($output=~s/^(.+)(?:_funkyPrompt_\s*)+$/$1/s) {
               print $output;$done=1;last;
            }
         }
      };
      print "EVAL_OUT=$@\n" if $@;
      last if $done;
      $prod10->{_cmd_handle}->print;
      #last if $output!~/^\s*$/;
   }
   print $Net::FullAuto::FA_lib::MRLOG "OUT OF PROD10 and OUTPUT=$output<==\n";

   $prod1->{_cmd_handle}->print('sujump');
   $prod1->{_cmd_handle}->get(Timeout=>5);
   sleep 1;
   $prod1->{_cmd_handle}->print('jumpk3lly');
   while (my $line=$prod1->{_cmd_handle}->get) {
      if ($line=~/\$/) { last }
   }
   $prod1->{_cmd_handle}->print('export PS1=_funkyPrompt_');
   while (my $line=$prod1->{_cmd_handle}->get) {
      last if $line=~/_funkyPrompt_/s or $last++==10;
   }
   $prod1->{_cmd_handle}->print("(echo prod1;ps -ef)");
   $output='';
   while (1) {
      eval {
         while (my $line=$prod1->{_cmd_handle}->get(Timeout=>1000)) {
            $output.=$line;
            if ($output=~s/(_funkyPrompt_\s*)+$//s) {
               print $output;last;
            }
         }
      };
      last if $output!~/^\s*$/;
   }
   print $Net::FullAuto::FA_lib::MRLOG "OUT OF PROD1 and OUTPUT=$output<==\n";

   $prod2->{_cmd_handle}->print('sujump');
   $prod2->{_cmd_handle}->get(Timeout=>5);
   sleep 1;
   $prod2->{_cmd_handle}->print('jumpk3lly');
   while (my $line=$prod2->{_cmd_handle}->get) {
      if ($line=~/\$/) { last }
   }
   $prod2->{_cmd_handle}->print('export PS1=_funkyPrompt_');
   while (my $line=$prod2->{_cmd_handle}->get) {
      last if $line=~/_funkyPrompt_/s or $last++==10;
   }
   $prod2->{_cmd_handle}->print("(echo prod2;ps -ef)");
   $output='';
   while (1) {
      eval {
         while (my $line=$prod2->{_cmd_handle}->get(Timeout=>1000)) {
            $output.=$line;
            if ($output=~s/(_funkyPrompt_\s*)+$//s) {
               print $output;last;
            }
         }
      };
      last if $output!~/^\s*$/;
   }
   print $Net::FullAuto::FA_lib::MRLOG "OUT OF PROD2 and OUTPUT=$output<==\n";

}

sub risk_report
{
   #($prod1,$stderr)  = &connect_ssh('');
   #($prod2,$stderr)  = &connect_ssh('');
   ($prod10,$stderr) = &connect_ssh('');
   ($cer,$stderr)    = &connect_ssh('');
   ($dev3,$stderr)   = &connect_ssh('');

   $dev3->{_cmd_handle}->print("/home/bkelly/torino/release/sbin/".
                               "linux/plreport_r -c prodtagspace");
   my $time=time;my $tm=0;my %rs_data=();my @data=();
   eval {
      while (my $line=$dev3->{_cmd_handle}->get(Timeout=>120)) {
         $t=time;
         $tm=$t-$time;
         die if (120<=$tm);
         print $line;
      }
   };
   if ($@) {
      print "SENDING CONTROL-C\n";
      $dev3->{_cmd_handle}->print("\003");
   }
   my $output='';
   eval {
      while (my $line=$dev3->{_cmd_handle}->get(Timeout=>120)) {
         $output.=$line;
         last if $output=~s/(_funkyPrompt_\s*)+$//s;
      }
   };
 
   my $trader='';my $account='';my $symbol='';my $activity='';my $ip='';
   my $location='';my %loc=();
   foreach my $line (split /\n/, $output) {
      chomp($line=~tr/\0-\37\177-\377//d);
      next if $line=~/^\s*$/s;
      if (-1<index $line,'trader:') {
         $trader=substr($line,(index $line,'trader: ')+8);
         ($trader,$ip)=split /\s*\@\s*/, $trader;
         chomp $ip;
         $rs_data{$trader}={} if !exists $rs_data{$trader};
         my ($loc,$err);
         if (exists $loc{$ip}) {
            $loc=$loc{$ip};
         } else {
            ($loc,$err)=$localhost->cmd("nslookup $ip");
            chomp($loc=~tr/\0-\37\177-\377//d);
            $loc{$ip}=substr($loc,(index $loc,'Name: ')+9,3);
         }
         if ($loc{$ip} eq 'atl') {
            $location='atlanta';
         } elsif ($loc{$ip} eq 'nj-') {
            $location='new jersey';
         } elsif ($loc{$ip} eq 'jt-') {
            $location='cermak';
         } else { $location='chicago' }
         $rs_data{$trader}{$location}={}
            if !exists $rs_data{$trader}{$location};
         next;
      } elsif (-1<index $line,'account:') {
         $account=substr($line,(index $line,'account: ')+9);
         chomp $account;
         if (!defined $activity) { print "ACTLINE=$line<==\n";<STDIN>; }
         $rs_data{$trader}{$location}{$account}={}
            if !exists $rs_data{$trader}{$location}{$account};
         next;
      } elsif (-1<index $line,'symbol:') {
         my ($ignore1,$ignore2);
         my $sym=substr($line,(index $line,'symbol: ')+8);
         ($symbol,$activity)=split /\(/,$sym;
         $symbol=~s/\s*$//;
         my $exhange='';
         ($exchange,$activity)=split /\)/, $activity;
         $activity=~s/\s*$//;
         $rs_data{$trader}{$location}{$account}{$symbol}=
            [ $activity, $exchange ];
      } else { next }
      if (0 && $trader eq 'mkogan') {
         print "RS_LOCATION=$location\n";
         print "RS_TRADER=$trader\n";
         print "RS_ACCOUNT=$account\n";
         print "RS_SYMBOL=$symbol and ACTIVITY=$activity\n";<STDIN>;
      }
   }

   $prod10->{_cmd_handle}->print('sujump');
   $prod10->{_cmd_handle}->get(Timeout=>5);
   sleep 1;
   $prod10->{_cmd_handle}->print('jumpk3lly');
   while (my $line=$prod10->{_cmd_handle}->get) {
      if ($line=~/\$/) { last }
   }
   $prod10->{_cmd_handle}->print('export PS1=_funkyPrompt_');
   while (my $line=$prod10->{_cmd_handle}->get) {
      last if $line=~/_funkyPrompt_/s or $last++==10;
   }
   $prod10->{_cmd_handle}->print("/usr/local/jump/bin/perl ".
                                 "/home/jump/production/".
                                 "bin/otmReport.pl");
   $output='';
   while (1) {
      eval {
         while (my $line=$prod10->{_cmd_handle}->get(Timeout=>1000)) {
            $output.=$line;
            if ($output=~s/(_funkyPrompt_\s*)+$//s) {
               print $output;last;
            }
         }
      };
      last if $output!~/^\s*$/;
   }

   my $trad='';my $acc='';my $sym='';$trader='';$account='';
   my $ln='';my $lahg='';my $host='';
   $location='chicago';
   foreach my $line (split /\n/, $output) {
      chomp($line=~tr/\0-\37\177-\377//d);
      next if $line=~/^\s*$/s || length $line<28 || $line=~/\.pl\s*$/s;
      if (-1<index $line,'Trad:') {
         ($trad,$acc,$sym)=unpack('x6 a18 a10 a11',$line);
         ($symbol=$sym)=~s/\s*$//s;
         ($trader=$trad)=~s/\s*$//s;
         $data{$trader}={} if !exists $data{$trader};
         $data{$trader}{$location}={}
            if !exists $data{$trader}{$location}; 
         ($account=$acc)=~s/\s*$//s;
         $data{$trader}{$location}{$account}={}
            if !exists $data{$trader}{$location}{$account};
         $data{$trader}{$location}{$account}{$symbol}=[]
            if !exists $data{$trader}{$location}{$account}{$symbol};
      } elsif (-1<index $line,'Line:') {
         $ln=unpack('x6 a*',$line);
         $ln=~s/\s*$//;
         push @{$data{$trader}{$location}{$account}{$symbol}},$ln;
      } elsif (-1<index $line,'Host:') {
         my $hst=unpack('x6 a*',$line);
         $host=substr($hst,0,(index $hst,' '));
         push @{$data{$trader}{$location}{$account}{$symbol}},$host;
         $lahg=substr($hst,(index $hst,' ')+2);
         push @{$data{$trader}{$location}{$account}{$symbol}},$lahg;
      }
      if (0 && $trader eq 'mkogan') {
         print "10_LOCATION=$location<==\n";
         print "10_TRADER=$trader<==\n";
         print "10_ACCOUNT=$account<==\n";
         print "10_SYMBOL=$symbol<==\n";
         print "10_LINE=$ln<==\n";
         print "10_HOST=$host<==\n";
         print "10_LOG=$lahg<==\n";
         $lahg='';
         print "IS HERE??=$trader<==\n";<STDIN>;
      }
   }

   foreach my $trad (keys %data) {
      next if $trad=~/TransactionE/;
      foreach my $loc (keys %{$data{$trad}}) {
         foreach my $acc (keys %{$data{$trad}{$loc}}) { 
            foreach my $sym (keys %{$data{$trad}{$loc}{$acc}}) {
               if (!exists $rs_data{$trad}{$loc}{$acc}{$sym}) {
                  $exch=${$rs_data{$trad}{$loc}{$acc}{$sym}}[1];
                  $exch||='';
                  print "This Account is    MISSING              ==> ".
                     pack("A11",$trad).
                     pack("A12",$loc).
                     pack("A7",$exch).
                     pack("A7",$acc).
                     pack("A11",$sym)."\n".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[0]."\n".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[1]."  ".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[2]."\n\n"; 
               } elsif (${$rs_data{$trad}{$loc}{$acc}{$sym}}[0]
                     eq 'inactive') {
                  $exch=${$rs_data{$trad}{$loc}{$acc}{$sym}}[1];
                  $exch||='';
                  print "This Account shows INACTIVE when ACTIVE ==> ".
                     pack("A11",$trad).
                     pack("A12",$loc).
                     pack("A7",$exch).
                     pack("A7",$acc).
                     pack("A11",$sym)."\n".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[0]."\n".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[1]."  ".
                     ${$data{$trad}{$loc}{$acc}{$sym}}[2]."\n\n";
               }
            }
         } 
      }
   }
}


sub build
{
   my @hosts=();
   #my @hosts=('');
   my %connections=();my $handle='';my $stdout='';my $stderr='';
   my %threads=();my $queue=new Thread::Queue;
   $rite=&threads->create(\&rite,$queue);
   foreach my $host (@hosts) {
      $threads{$host}=[];
      ($handle,$stderr)=&connect_ssh($host);
      $handle->{_cmd_handle}->print('sujump');
      $handle->{_cmd_handle}->get(Timeout=>5);
      sleep 1;
      $handle->{_cmd_handle}->print('jumpk3lly');
      while (my $line=$handle->{_cmd_handle}->get) {
         if ($line=~/\$/) { last }
      }
      $handle->{_cmd_handle}->print('export PS1=_funkyPrompt_');
      while (my $line=$handle->{_cmd_handle}->get) {
         last if $line=~/_funkyPrompt_/s or $last++==10;
      }
      my $ps='';my $first_handle=0;
      ($ps,$stderr)=$handle->cmd('ps -e | grep "Gate\|java"');
      my ($pid,$gw,$log);
      foreach my $line (split /\n/, $ps) {
         $line=~s/^\s*//;
         $pid=substr($line,0,(index $line,' '));
         $gw=substr($line,(rindex $line,' ')+1);
         my $output='';
         ($output,$error)=$handle->cmd(
                 "ls -l /proc/$pid/task/$pid/fd");
         foreach my $lg (split /\n/, $output) {
            next if -1==index $lg,'logs';
            $log=substr($lg,(rindex $lg,'-> ')+3);
            last;
         }
         print "PID=$pid and GW=$gw and LOG=$log<==\n";
         my $hand='';
         ($hand,$stderr)=&connect_ssh($host);
         $hand->{_cmd_handle}->print('sujump');
         $hand->{_cmd_handle}->get(Timeout=>5);
         sleep 1;
         $hand->{_cmd_handle}->print('jumpk3lly');
         while (my $line=$hand->{_cmd_handle}->get) {
            if ($line=~/\$/) { last }
         }
         $hand->{_cmd_handle}->print('export PS1=_funkyPrompt_');
         while (my $line=$hand->{_cmd_handle}->get) {
            last if $line=~/_funkyPrompt_/s or $last++==10;
         }
         push @{$threads{$host}},&threads->create(
                        \&act,$hand,$log,$queue);
      }
   }
   foreach my $host (@hosts) {
      foreach my $thread (@{$threads{$host}}) {
         $thread->join;
      } print "GOOD\n";
   }
   $queue->enqueue(undef);
   $rite->join;
}

sub rite {
   eval {
   my $queue=shift;
   my $fh;
   open ($fh,">hello".int(rand 10000).".txt");
   while (my $line=$queue->dequeue) {
      print $fh "GOOD";
      print $fh $line;
   }
   print $fh "CLOSING UP AND GOING HOME and QUEUE=$queue\n";
   close $fh;
   };
   print "WHAT IS WRITE ERROR=$@\n" if $@;
}

sub act {
  my $handle=shift;
  my $log=shift;
  my $queue=shift;
print "LOGGG=$log<==\n";
  my $crap='';
  $handle->{_cmd_handle}->print("tail -f $log");
  my $last=0;
  my $fh;
  eval {
     while (my $line=$handle->{_cmd_handle}->get(Timeout=>1000)) {
print "OUTPUTLINE=${$handle->{_hostlabel}}[0] $line<==\n";
        $crap.=$line;
        $queue->enqueue(${$handle->{_hostlabel}}[0].' '.$line);
        last if $crap=~/_funkyPrompt_/s;
        #last if $crap=~/_funkyPrompt_/s or $last++==10;
     }
  };
  print "CRAP=$@\n";
  #kill("TERM",$handle->{_cmd_pid});
}
   
sub RemindBrian
{
   print $invoked[1];
   my ($day,$month,$date,$time)=split /\s+/, $invoked[1];
   ($time)=split ':', $time;
   if ($day eq 'THU' && $time<4) {
      ($output,$stderr)=$localhost->cmd("touch remindbrian.txt");
      &handle_error($stderr,'-1') if $stderr;
   }
   ($output,$stderr)=$localhost->cmd("ls -l remindbrian.txt");
   if ($stderr) {
      return if -1<index $stderr,'No such file or directory';
      &handle_error($stderr,'-1');
   } else {
      my %mail=(
         'Usage'   => 'notify_on_error',
         'To'      => [ 'Brian.Kelly@fullautosoftware.net',
                        'Admim@fullautosoftware.net' ],
         'From'    => '\"Automated Reminder@fullautosoftware.net\"',
         'Body'    => 'DO IT NOW!!!!!!!!!',
         'Subject' => 'YOU GOTTA DO YOUR TIME SHEET!!!',
         'Priority'=> 1,
      );
      &send_email(\%mail);
   }
}

########### END OF SUBS ########################

#################################################################
##  Do NOT alter code BELOW this block.
#################################################################

## Important! The '1' at the Bottom is NEEDED!
1
