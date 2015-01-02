package fa_code_demo;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright (C) 2000-2015  Brian M. Kelly
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

use strict;
use warnings;
our $test=0;our $timeout=0;
require Exporter;
#use threads ();
#use Thread::Queue;
our @ISA = qw(Exporter Net::FullAuto::FA_Core);
use Net::FullAuto::FA_Core;

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

#---------------------------------------------

############  SET TIMEOUT  ###################
$timeout=90;
##############################################

############  SET TOSSPASS  ##################
#$tosspass=1;
##############################################

#####  SET EMAIL AUTOMATION SETTINGS  ########
%email_addresses=(
   'bkelly' => 'Brian.Kelly@fullautosoftware.net',
);
my $email_to=[
               #']USERNAME[',
               #'Brian.Kelly@fullautosoftware.net',
             ];
%email_defaults=(
   #Usage       => 'notify_on_error',
   Mail_Method => 'smtp',
   Mail_Server => '',
   #Reply_To    => 'Brian.Kelly@bcbsa.com',
   #To          => $email_to,
   #From        => "$progname\@fullautosoftware.net"
);
##############################################

##  -------------------------------------------------------------
##  WRITE "RESULT" SUBROUTINES HERE:
##  -------------------------------------------------------------

sub hello_world {

   print "\n   Net::FullAuto says \"HELLO WORLD!\"\n";

}

sub image_magick {

   # Check for installation
   our $path='';my ($key,$status)=('','');
   ($path,$key,$status)=&persist_get('image_magick_path');
   if ($status=~/DB_NOTFOUND: No matching key\/data pair found/ or !$path) {
      #Look for installation
      my ($stdout,$stderr)=$localhost->cmd("which convert");
      if (-1<index $stdout,'convert') {
         my ($stdout_ver,$stderr)=$localhost->cmd("\"$stdout\" -version");
         if (-1<index $stdout_ver,'ImageMagick') {
            $path=$stdout;
            $status=persist_put($key,$path);
         }
      }
      unless ($path) {
         if ($^O eq 'cygwin') {
            if (-f '/usr/bin/convert.exe') {
               $path='/usr/bin/convert.exe';
            } elsif (-f '/bin/convert.exe') {
               $path='/usr/bin/convert.exe';
            } elsif (-f '/usr/local/bin/convert.exe') {
               $path='/usr/local/bin/convert.exe';
            }
            $status=persist_put($key,$path) if $path;
         } else {
            if (-f '/usr/bin/convert') {
               $path='/usr/bin/convert';
            } elsif (-f '/bin/convert') {
               $path='/usr/bin/convert';
            } elsif (-f '/usr/local/bin/convert') {
               $path='/usr/local/bin/convert';
            }
            $status=persist_put($key,$path) if $path;
         }
      }
      unless ($path) {
         print "\n\n       INFO: FullAuto needs to do a one time ",
               " Search for ImageMagick.\n             This may ",
               "take a few minutes. Future invocations\n       ",
               "      will not require this search.\n\n";
         require File::Find;
         do { 
            sub Wanted {
               return if $path;
               /.cpan/ and $File::Find::prune = 1;
               return if -d;
               if (/^convert(.exe)*$/) {
                  my $out=`$File::Find::name -version 2>&1`;
                  if (-1<index $out,'ImageMagick') {
                     $path=$File::Find::name;
                  }
               }
            }
            my @dirs=();
            push @dirs,('/usr');
            push @dirs,('/opt') if -d '/opt';
            push @dirs,(getpwuid $>)[7];
            File::Find::find(\&Wanted,@dirs);
         };
         $status=persist_put($key,$path);
      }
   }
   print "\n\n   PATH=$path\n";
   my $image_fax_viewer='cmd /c C:\\\\WINDOWS\\\\System32\\\\rundll32.exe '.
         'C:\\\\WINDOWS\\\\System32\\\\shimgvw.dll,ImageView_Fullscreen '.
         'C:\\\\cygwin\\\\fullauto\\\\FullAuto\\\\lib\\\\Net\\\\FullAuto'.
         '\\\\Distro\\\\fullautologo.jpg &';
   `$image_fax_viewer`;

}

sub test_email {

       my %mail=(
          'To'      => [ 'Brian.Kelly@bcbsa.com' ],
          'From'    => 'brian.kelly@fullautosoftware.net',
          'Body'    => "\nFullAuto ERROR =>\n\n"."HA HA".
                       "       in fa_code.pm Line ".__LINE__,
          'Subject' => "FullAuto ERROR Encountered When Connecting to NOWHERE",
       );
       my $ignore='';my $emerr='';
       ($ignore,$emerr)=&send_email(\%mail);
       if ($emerr) {
          die "\n\nEMAIL ERROR =>$emerr<==\n\n";
       } else {
          return;
       }

}

sub compare_fa_code {

   my ($solaris_ssh,$solaris_sftp,$laptop_sftp,$output,$stderr)=
      ('','','','','');
   ($solaris_ssh,$stderr)=connect_ssh('Solaris');
   ($solaris_sftp,$stderr)=connect_sftp('Solaris');
   print "SFTP_CONNECT_STDERR=$stderr\n" if $stderr;
   my $fa_code_p='/usr/local/lib/perl5/site_perl/5.12.1'.
            '/Net/FullAuto/Custom/opens/Code/fa_code.pm';
   ($output,$stderr)=$solaris_ssh->cmd("cp $fa_code_p /export/home/opens");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_ssh->cmd(
      "chown opens /export/home/opens/fa_code.pm");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_sftp->lcd($ENV{HOME});
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_sftp->get('fa_code.pm');
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$solaris_ssh->cmd("rm /export/home/opens/fa_code.pm");
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "mv /home/ubuntu/fa_code.pm /home/ubuntu/fa_code.prod");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($laptop_sftp,$stderr)=connect_sftp('Laptop');
   die $stderr if $stderr;
   ($output,$stderr)=$laptop_sftp->lcd($ENV{HOME});
   print "STDERR=$stderr\n" if $stderr;
   my $fa_code_d='/usr/lib/perl5/site_perl/5.10'.
            '/Net/FullAuto/Custom/KB06606/Code/fa_code.pm';
   ($output,$stderr)=$laptop_sftp->get($fa_code_d);
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "mv $ENV{HOME}/fa_code.pm $ENV{HOME}/fa_code.dev");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "diff $ENV{HOME}/fa_code.dev $ENV{HOME}/fa_code.prod > ".
      "$ENV{HOME}/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
      "rm $ENV{HOME}/fa_code.prod $ENV{HOME}/fa_code.dev");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$laptop_sftp->cwd(
      "/cygdrive/c/Documents and Settings/kb06606/Desktop/Compare fa_code.pm");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$laptop_sftp->put(
      "/home/ubuntu/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
   ($output,$stderr)=$localhost->cmd(
       "rm $ENV{HOME}/fa_code_dev_prod.diff");
   print "OUTPUT=$output\n" if $output;
   print "STDERR=$stderr\n" if $stderr;
}

sub howdy_world {
   open (FH,">FullAuto_howdy_world.txt");
   FH->autoflush(1);
   my $cnt=0;
   while (1) {
      print FH $cnt++;
#      sleep 2;
      last if $cnt==20;
   }
   #----------------------------------------------
   # Connect to Remote Host with *BOTH* ssh & sftp
   #----------------------------------------------
   my ($host,$stderr)=('','');
   my $hostname=`hostname`;
   chomp $hostname;
   my $hostlab='Laptop';
   if ($hostname eq 'opensolaris') {
      ($host,$stderr)=connect_secure('Laptop');
   } elsif ($hostname eq 'reedfish-laptop') {
      ($host,$stderr)=connect_secure('Laptop');
   } else {
      $hostlab='Solaris';
      ($host,$stderr)=connect_secure('Solaris');
   }
   if ($stderr) {
      print "       We Have an ERROR when attempting to connect ",
            "to Ubuntu! :\n$stderr       in fa_code.pm ",
            "Line ",__LINE__,"\n";
      my %mail=(
         'To'      => [ 'Brian.Kelly@bcbsa.com' ],
         'From'    => 'Brian.Kelly@fullautosoftware.net',
         'Body'    => "\nFullAuto ERROR =>\n\n".$stderr.
                      "       in fa_code.pm Line ".__LINE__,
         'Subject' => "FullAuto ERROR Encountered When Connecting to Ubuntu",
      );
      my $ignore='';my $emerr='';
      ($ignore,$emerr)=&send_email(\%mail);
      if ($emerr) {
         die "\n\n       $stderr\n       EMAIL ERROR =>$emerr<==\n\n";
      } else {
         #die $stderr;
         return;
      }
   }
   print "LOGIN SUCCESSFUL\n";
   print FH "LOGIN SUCCESSFUL ",`date`,"\n";
   close FH;
   &cleanup();
}

sub menu_demo {

   my @list=`ls -1 /bin`;
   my %Menu_1=(

      Item_1 => {

         Text    => "/bin Utility - ]Convey[",
         Convey  => [ `ls -1 /bin` ],

      },

      Select => 'Many',
      Banner => "\n   Choose a /bin Utility :\n\n"
   );

   my @selections=&Menu(\%Menu_1,$unattended);
   print "\nSELECTIONS = @selections\n";

}

sub remote_hostname {

    my ($computer_one,$stdout,$stderr);      # Scope Variables

    $computer_one=connect_ssh('REMOTE COMPUTER ONE'); # Connect to
                                             # Remote Host via ssh

    ($stdout,$stderr)=$computer_one->cmd('hostname');

    print "REMOTE ONE HOSTNAME=$stdout\n";

}

sub get_file_from_one {

   my ($computer_one,$stdout,$stderr);         # Scope Variables

   $computer_one=connect_reverse('REMOTE COMPUTER ONE'); # Connect
                                               # to Remote Host via
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

########### END OF SUBS ########################

#################################################################
##  Do NOT alter code BELOW this block.
#################################################################

## Important! The '1' at the Bottom is NEEDED!
1
