package fa_code_demo;

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

sub hello_world {
   open (FH,">briangreat.txt");
   FH->autoflush(1);
   my $cnt=0;
   while (1) {
      print FH $cnt++;
#      sleep 2;
      last if $cnt==20;
   }
   print "LOGIN SUCCESSFUL\n";
   print FH "LOGIN SUCCESSFUL ",`date`,"\n";
   close FH;
   &cleanup();
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
   ($host,$stderr)=connect_secure('Ubuntu');
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
      Banner => "\n   Choose a /bin Utility :"
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
