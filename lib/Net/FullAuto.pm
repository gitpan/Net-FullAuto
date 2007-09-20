package Net::FullAuto;

################################################################
#
#   WARNING:  THIS IS A ***BETA*** RELEASE OF Net::FullAuto
#
#   Net::FullAuto is powerful network process automation
#   software that has been in un-released development for
#   more than seven years. For this reason, you may find
#   it to be useful for many process automation projects.
#   Because it has been worked on for so long, it may appear
#   to be stable, and pass a number of non-intensive tests.
#
#   DO NOT - REPEAT - DO !!NOT!! USE IN A PRODUCTION
#   ENVIRONMENT! This is newly released software that has
#   *NOT* had the benefit of wide exposure - and the presence
#   of here-to-now undetected bugs and design flaws is a
#   virtual certainty. DO NOT USE IN IN/FOR A PROCESS WHERE
#   DATA LOSS IS UNRECOVERABLE. DO NOT USE IN/FOR A PROCESS
#   WHERE DATA INTEGRITY IS CRITICAL. DO NOT USE IN/FOR A
#   PROCESS THAT IS TIME SENSITIVE, UNMONITORED, OR
#   PERSISTENCE CRITICAL. DO NOT USE THIS SOFTWARE WITHOUT
#   ANOTHER METHOD FOR EXECUTING THE PROCESS YOU WISH TO
#   AUTOMATE WITH Net::FullAuto. DO NOT USE IN/FOR A PROCESS
#   WHERE FAILURE OF "ANY KIND" IS UNACCEPTABLE.
#
#   Beware that it is provided "as is", and comes with
#   absolutely no warranty of any kind, either express or
#   implied.  If you use the contents of this distribution,
#   you do so at your own risk, and you agree to free the
#   author(s) of any consequences arising from such use,
#   either intended or otherwise.
#
################################################################

our $VERSION='0.08';
use 5.002;

BEGIN {
   my @ARGS=@ARGV;
   my $quiet=0;
   my $args='';
   foreach (@ARGS) {
      if ($_ eq '--password') {
         $args.='--password ';
         shift @ARGS;
         $args.='******** ';
         next;
      } elsif ($_ eq '--quiet') { 
         $quiet=1; 
      } $args.="$_ ";
   } chop $args;
   my $nl=(grep { $_ eq '--cron' } @ARGV)?'':"\n";
   print "Command Line -> $0 $args\n" if !$nl;
   print "STARTING FULLAUTO on ". localtime() . "\n"
      unless $quiet;
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(fa_login);

use Term::Menus;

sub fa_login
{
   return &Term::Menus::fa_login(@_);
}
1;

__END__;


######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man FullAuto.pm | groff -man -Tps > FullAuto.ps

=head1 NAME

Net::FullAuto - Perl Based Secure Distributed Computing Network Process
Automation Utility

=head1 NOTE TO USERS

 This is the initial (2007-09-06) BETA RELEASE of Net::FullAuto. I have
 attemped to provide just enough documentation so that users and testers can
 "hopefully" get it up and running for VERY basic operations. Your
 help in this effort is NEEDED and will be GREATLY APPRECIATED. Please
 contact me at my email address -

=over 2

=item

B<Brian.Kelly@fullautosoftware.net>

=back

 and let me know of ANY and ALL bugs, issues, problems, questions
 as well as suggestions for improvements to both the documentation
 and module itself. I will make every effort to get back to you quickly.

 Update the module from CPAN *often* - as I anticipate adding documentation
 and fixing bugs and making improvements almost daily for the immediate
 future.

 THANKS - and GOOD LUCK with your Net::FullAuto project!

 Brian Kelly, September 6, 2007

=head1 BETA Notice

 WARNING:  THIS IS A ***BETA*** RELEASE OF Net::FullAuto

 Net::FullAuto is powerful network process automation
 software that has been in un-released development for
 more than seven years. For this reason, you may find
 it to be useful for many process automation projects.
 Because it has been worked on for so long, it may appear
 to be stable, and pass a number of non-intensive tests.

 DO NOT - REPEAT - DO !!NOT!! USE IN A PRODUCTION
 ENVIRONMENT! This is newly released software that has
 *NOT* had the benefit of wide exposure - and the presence
 of here-to-now undetected bugs and design flaws is a
 virtual certainty. DO NOT USE IN IN/FOR A PROCESS WHERE
 DATA LOSS IS UNRECOVERABLE. DO NOT USE IN/FOR A PROCESS
 WHERE DATA INTEGRITY IS CRITICAL. DO NOT USE IN/FOR A
 PROCESS THAT IS TIME SENSITIVE, UNMONITORED, OR
 PERSISTENCE CRITICAL. DO NOT USE THIS SOFTWARE WITHOUT
 ANOTHER METHOD FOR EXECUTING THE PROCESS YOU WISH TO
 AUTOMATE WITH Net::FullAuto. DO NOT USE IN/FOR A PROCESS
 WHERE FAILURE OF "ANY KIND" IS UNACCEPTABLE.

 Beware that it is provided "as is", and comes with
 absolutely no warranty of any kind, either express or
 implied.  If you use the contents of this distribution,
 you do so at your own risk, and you agree to free the
 author(s) of any consequences arising from such use,
 either intended or otherwise.

=head1 SYNOPSIS

C<use Net::FullAuto;>

see METHODS section below

=head1 DESCRIPTION

Net::FullAuto is a Perl based Secure Distributed Computing Network Process
Automation Utility. It's a MOUTHFUL - and it IS everything implied in it's
description. Net::FullAuto is a command environent based implementation that
truly embodies the term "The Network **IS** the Computer!!" 

Net::FullAuto utilizes ssh and sftp (can also use telnet and ftp, though for
security reasons, this is NOT recommended) to bring the command enviroments
of any number of remote computers (OS of remote computer does not matter),
together in **ONE** convenient scripting space. With Net::FullAuto, you write
code once, on one computer, and have it execute on multiple computers
simultaneously, in an interactive dynamic fashion, AS IF the many computers
were truly ONE.

Net::FullAuto is POWERFUL. Net::FullAuto can be run by a user in a Menu driven,
interactive mode (using the Term::Menus module - also written by Brian Kelly),
OR via UNIX or Windows/Cygwin cron in a fully automated (and secure) fashion.

Example: A user needs to pull data from a database, put it in text file, zip
and encrypt it, and then transfer that file to another computer on the other
side of the world via the internet - in ONE step, and in a SECURE fashion.

Net::FullAuto is the ANSWER! Assume Net::FullAuto is installed on computer one,
the database is on computer two, and the remote computer in China is computer
three. When the user types the script using FullAuto, FullAuto will connect
via ssh AND sftp (simultaneously) to computer two, and via sftp to computer
three. Using an sql command utility on computer two, data can be extracted
and piped to a text file on computer two. Then, FullAuto will run a command
for a zip utility over ssh on computer two to zip the file. Next (assume the
encryption software is on computer one) FullAuto will transfer this file to
computer one, where it can be encrypted with licensed encryption software, and
then finally, the encrypted file can be transferred to computer three via sftp.
Email and pager software can be used for automated notification as well.

Example: The same process above needs to run at 2:00am unattended.

No Problem! FullAuto can be run via cron to perform the same actions above
without user involvement.

FullAuto is RELIABLE and FAULT TOLERANT. Each individual command run on a
remote computer returns to FullAuto BOTH stdout (output) and stderr (error
messages). With this feature, users and programmers can write code to
essentially trap remote errors "locally" and respond with a host of error
recovery approaches. Everything from sending an e-mail, to re-running the
command, to switching remote computers and much more is available as error
handling options. The only limits are the skills and ingenuity of the
programmers and administrators using FullAuto. If FullAuto loses a connection
to a remote host, automatic attempts will be made to re-connect seemlessly -
with errors reported when the specified number of attempts fail.

FullAuto is EASY. FullAuto uses a mix of traditional and object-oriented
features to maximize ease of use and maintenance. Due to the unique nature of
distributed computing, combined with the need for ease of maintaining
a lot of configuration information (i.e. ip addresses, host names, login
ID's, passwords, etc), along with any number of *routines* or *processes*, as
well as the need for robust security, FullAuto has a unique layout and
architechture. Normally in perl, programmers segregate functional code in
separate script files or perl modules or packages. FullAuto supports this as
well, but advocates keeping *process* code confined to a single routine in a
kind of "process library" file. This is in order that FullAuto can provide
additional built-in features like a command-handle to the local machine without
having to explicitly create it. Or, being able to connect to a remote host with
syntax as simple as:

$computer_one=connect_ssh('COMPUTER_ONE');

IT REALLY IS THAT EASY!

Commands also are easy:

($stdout,$stderr)=$computer_one->cmd('ls -l');

And NO CLEANUP is necessary - FullAuto handles this AUTOMATICALLY.

This is a COMPLETE *routine* or *process*:

sub ls_one {

   my ($computer_one,$stdout,$stderr);             # Scope Variables

   $computer_one=connect_ssh('COMPUTER_ONE');      # Connect to Remote Host

   ($stdout,$stderr)=$computer_one->cmd('ls -l');  # Run Command

   if ($stderr) {                                  # Check Results
      print "We Have and ERROR! : $stderr\n";
   } else {
      print "Output of ls command from Computer One:\n\n$stdout\n\n";
   }
}                                                  # DONE!! 

AGAIN - IT REALLY IS THAT EASY!

As with most things in life, what many or most consider a blessing,
others consider a curse. Perl's motto is "There's more than one way to do it."
(TIMTOWTDI) Not everyone thinks this is utopia. Perl also attempts "to make
easy tasks easy and difficult tasks possible." FullAuto - written in perl -
*IS* PERL. It is essentially a perl extension and therefore adheres to the
same goals as perl itself: i.e. - there's no "one" correct way to use FullAuto.

FullAuto is SECURE. It uses ssh and sftp for communication accross computers, 
and uses powerful encryption to store passwords to remote resources. When
running FullAuto, a user on the first iteration of a process will be prompted
to enter a password for each and every remote resource (or even local resource,
since FullAuto can and does use ssh to acquire enhanced user-rights on the
local computer.) Every following iteration will then prompt for a password
ONLY ONCE (or a password can even be passed in via command or method arguement)
with every other needed password retrieved from an encrypted datafile which
utilizes the user's main login password as the "salt".

For added security, and enhanced user functionality, FullAuto can be installed
on UNIX computers to use "setuid". (Windows/Cygwin does not support "setuid" -
so this feature is not available on Windows computers. This is the ONLY Windows
limitation.) With FullAuto setup to use "setuid", users can be configured to
run complex distributed processes in a secure fashion without the permissions
ACTUALLY needed by the remote (or even local) resources. On top of that, it is
possible to create a process administered by numerous individuals such that NO
ONE PERSON KNOWS OR HAS ACCESS TO ALL THE PASSWORDS. For example, a database
administrator on a remote computer can "loan" his username and password to drop
a table (for instance) for a process that will be run by another user remotely.
During the first iteration, after the user enters her/his password, the DB can
then (when prompted), enter his/her password which will then be encrypted
LOCALLY with the user's password as the salt. With the encrypted datafile and
perl code protected from user write (or even read) access via setuid on UNIX
computers (setup and administered by yet another individual or group - such as
the root user), there is no way for either the DB to discover the user's
password, or the user to discover the DB's password! Even the root user of the
local computer running FullAuto will not be able to discover these passwords!
(When setuid is setup and used PROPERLY). This setup will allow users to run
FullAuto processes WITHOUT access to the passwords controlling remote access,
or for that matter, the CODE running those processes! 

Reasons to use this module are:

=over 2

=item *

You want the output of the ps -e command from a remote UNIX computer.
Example:

   In the file "fa_hosts.pm" add the connection information for
   the remote computer (This will suffice for all following examples):

       {
          'Label'         => 'COMPUTER_ONE',
          'IP'            => '10.200.210.37',
          'HostName'      => 'compter_one.w2k.fullautosoftware.net',
          'Login'         => 'bkelly',
          'LogFile'       => "/cygdrive/d/fullauto/logs/FAlog${$}d".
                             "${FA_lib::invoked[2]}".
                             "${FA_lib::invoked[3]}.txt",
       },

   In the file "usr_code.pm" add the *process* subroutine code:

       sub ps_one {

          my ($computer_one,$stdout,$stderr);        # Scope Variables

          $computer_one=connect_ssh('COMPUTER_ONE'); # Connect to
                                                     # Remote Host via
                                                     # ssh only

          ($stdout,$stderr)=$computer_one->cmd('ps -e'); # Run Command

          if ($stderr) {                             # Check Results
             print "We Have and ERROR! : $stderr\n";
          } else {
             print "Output of ps -e command from Computer One:".
                   "\n\n$stdout\n\n";
          }

       }

Run FullAuto:  (Hint: the --< # >-- line are instructions and are
                not displayed when the program actually runs)

--< 1 >-<Type Command and <ENTER> >---------------------------

       fullauto.pl --usr_code ps_one

--< The user sees: >------------------------------------------

STARTING FULLAUTO on Wed Jun  6 12:27:08 2007

  Starting fullauto.pl . . .



  Running in TEST mode

  computer_one Login <bkelly> :

--< 2 >-<ENTER>-(Hint: since 'Login' was specified in
                 fa_hosts.pm 'bkelly' appears as the default)-

  Password:

--< 3 >-<Type Password and <ENTER> >--------------------------

--> Logging into localhost via ssh  . . .

        Logging into computer_one.w2k.fullautosoftware.net via ssh  . . .

 Output of ps -e command from Computer One:

   PID TTY          TIME CMD
     1 ?        00:00:03 init
     2 ?        00:00:00 migration/0
     3 ?        00:00:00 ksoftirqd/0
   80 ?        00:00:00 aio/0
  2805 ?        00:00:08 syslogd
  2820 ?        00:00:00 irqbalance
  2839 ?        00:00:00 portmap
  2859 ?        00:00:00 rpc.statd
  2891 ?        00:00:00 rpc.idmapd
  2949 ?        00:00:00 ypbind
  2969 ?        00:00:45 nscd
  2987 ?        00:00:01 smartd
  2997 ?        00:00:00 acpid
  3059 ?        00:00:00 xinetd
  3072 ?        00:00:14 ntpd
  3092 ?        00:00:19 sendmail
  3111 ?        00:00:00 gpm
  3121 ?        00:00:03 crond
  3153 ?        00:00:00 xfs
  3172 ?        00:00:00 atd
  3188 ?        00:00:00 dbus-daemon-1
  3201 ?        00:05:09 hald
  3210 tty1     00:00:00 mingetty
  1432 ?        00:02:34 rvd
 14675 ?        00:00:00 kdbd
 17052 ?        00:00:00 postmaster
 24389 ?        00:00:00 chatserv_d
 16463 ?        00:00:06 java
 11700 ?        00:04:48 cmefx
   905 ?        00:00:00 automount
   563 ?        00:00:00 sshd
   564 pts/30   00:00:00 bash
   641 pts/30   00:00:00 ps
   642 pts/30   00:00:00 sed

 FULLAUTO COMPLETED SUCCESSFULLY on Wed Jun  6 12:28:30 2007

=item *

You want to zip and transfer a remote file from COMPUTER_ONE
to your local computer and then unzip it:

   In the file "usr_code.pm" add the *process* subroutine code:

       sub get_file_from_one {

          my ($computer_one,$stdout,$stderr);         # Scope Variables

          $computer_one=connect_host('COMPUTER_ONE'); # Connect to
                                                      # Remote Host via
                                                      # ssh *and* sftp

          ($stdout,$stderr)=$computer_one->cmd(
                            'echo test > test.txt');  # Run Remote Command

          ($stdout,$stderr)=$computer_one->cmd(
                            'zip test test.txt');     # Run Remote Command

          if ($stderr) {                              # Check Results
             print "We Have and ERROR! : $stderr\n";
          } else {
             print "Output of zip command from Computer One:".
                   "\n\n$stdout\n\n";
          }

          ($stdout,$stderr)=$computer_one->get(
                            'test.zip');              # Get the File

          if ($stderr) {                              # Check Results
             print "We Have and ERROR! : $stderr\n";
          } else {
             print "Output of zip command from Computer One:".
                   "\n\n$stdout\n\n";
          }

          ($stdout,$stderr)=$localhost->cmd(
                            'unzip test.zip');        # Run Local Command

       }

Run FullAuto:  (Hint: the --< # >-- line are instructions and are
               not displayed when the program actually runs)

--< 1 >-<Type Command and <ENTER> >---------------------------

       fullauto.pl --usr_code get_file_from_one

--< The user sees: >------------------------------------------

STARTING FULLAUTO on Wed Jun  6 12:27:08 2007

  Starting fullauto.pl . . .



  Running in TEST mode

  computer_one Login <bkelly> :

--< 2 >-<ENTER>-(Hint: since 'Login' was specified in
                 fa_hosts.pm 'bkelly' appears as the default)-

  Password:

--< 3 >-<Type Password and <ENTER> >--------------------------


 --> Logging into localhost via ssh  . . .


        Logging into localhost via ssh  . . .


        Logging into computer_one.w2k.fullautosoftware.net via sftp  . . .


        Logging into computer_one.w2k.fullautosoftware.net via ssh  . . .


 Output of zip command from Computer One:

 updating: test.txt (stored 0%)

 get "/tmp/test.zip"


 Fetching /tmp/test.zip to test.zip
 /tmp/test.zip                                   0%    0     0.0KB/s   --:-- ETA
 /tmp/test.zip                                 100%  153     0.2KB/s   00:00

 Output of zip command from Computer One:

 Fetching /tmp/test.zip to test.zip
 /tmp/test.zip                                 100%  153     0.2KB/s   00:00


=back

=head1 SETUP

FullAuto requires some preliminary setup before it can be used.

=over 2

=item * C<fa_hosts.pm>S<  >Setup and Location

=back

=over 3

=item

In order to manage connection configuration information in the easiest way possible, all host information must be stored in anonymous hash blocks in a file named C<fa_hosts.pm>. This file can be located in one of two places. There is a default C<fa_hosts.pm> file included with the distribution, and you can locate it wherever C<FullAuto> was installed. Usually this is in the C</lib> directory under C</usr> or C</usr/local/>. A typical location would be C</usr/local/lib/perl5/site_perl/5.8/Net/FullAuto/fa_hosts.pm>. Hosts blocks I<can> be added directly to this file (provided that file is given write permissions: i.e. C<chmod u+w fa_hosts.pm>) 

=back

=over 2

=item * C<usr_code.pm>S<  >Setup and Location

=back

=over 3

=item

In order to create the most flexibility, power and convencience, FullAuto requires the use of a C<usr_code.pm> module file. This file can be located in one of two places. There is a default C<usr_code.pm> file included with the distribution, and you can locate it wherever C<FullAuto> was installed. Usually this is in the C</lib> directory under C</usr> or C</usr/local/>. A typical location would be C</usr/local/lib/perl5/site_perl/5.8/Net/FullAuto/fa_hosts.pm>. Custom subroutines I<can> be added directly to this file (provided that file is given write permissions: i.e. C<chmod u+w usr_code.pm>)

=back

=over 3

=item * Setting the C<$fa_hosts> location variable

=back

=over 3

=item

You can (and should) define where you wish to store custom C<fa_hosts.pm> files with the C<$fa_hosts> variable. 

B<IMPORTANT!> - Be sure that this variable is defined in your invoking script. IT MUST BE PLACED IN A C<BEGIN {}> block B<I<BEFORE>> the C<use FullAuto;> line:

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   padding-right: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
<code>BEGIN { our $fa_hosts='/home/user/my_hosts.pm' }<br>
use FullAuto;<br>
. . .</code>
</P>

=end html

=back

=over 3

=item * Setting the C<$usr_code> location variable

=back

=over 3

=item

You can (and should) define where you wish to store custom C<usr_code.pm> files
with the C<$usr_code> variable.

B<IMPORTANT!> - Be sure that this variable is defined in your invoking script. I
T MUST BE PLACED IN A C<BEGIN {}> block B<I<BEFORE>> the C<use FullAuto;> line:

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   padding-right: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
<code>BEGIN { our $usr_code='/home/user/my_code.pm' }<br>
use FullAuto;<br>
. . .</code>
</P>

=end html

=back

=over 2

=item

B<NOTE>:  An  'C<fa_hosts>'  configuration module file does NOT need to be named
  C<fa_hosts.pm> . Any name can be used, so long as the internal package name is
 the same as the file name. For example, a file named  C<host_blocks.pm>  needs to have the line  C<package host_blocks;>  as the first line of the file.

=back

S<     >B<NOTE>: It is common to use BOTH location variables together:

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   padding-right: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
<code>BEGIN { our $usr_code='/home/user/my_code.pm';<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
our $fa_hosts='/home/user/my_hosts.pm' }<br>
use FullAuto;<br>
. . .</code>
</P>

=end html

=over 2 

=item * TypicalS<  C<fa_hosts.pm>  >File Contents

=back

=over

=item

S<The following is typical contents of a  C<fa_hosts.pm>
 showing two host blocks with minimal configuration:>

=begin html

<code>
<br><br>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
package fa_hosts;<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
require Exporter;<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
use warnings;<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
our @ISA     = qw(Exporter);<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
our @EXPORT  = qw(@Hosts);<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
@Hosts=(<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##&nbsp&nbspDo NOT alter code ABOVE this block.<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##  -------------------------------------------------------------<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##&nbsp&nbspADD HOST BLOCKS HERE:<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##  -------------------------------------------------------------<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp{<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
Label&nbsp&nbsp&nbsp&nbsp&nbsp=> 'REMOTE COMPUTER ONE',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
IP&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp=> '198.201.10.01',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
Hostname&nbsp&nbsp=> 'Linux_Host_One',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp},<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp{<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
Label&nbsp&nbsp&nbsp&nbsp&nbsp=> 'REMOTE COMPUTER TWO',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
IP&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp=> '198.201.10.02',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
Hostname&nbsp&nbsp=> 'Linux_Host_Two',<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp},<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##&nbsp&nbspDo NOT alter code BELOW this block.<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
);<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
## Important! The '1' at the Bottom is NEEDED!<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
1
</code>

=end html

=back

=over 2

=item * TypicalS<  C<usr_code.pm>  >File Contents

=back

=over

=item

S<The following is typical contents of a  C<usr_code.pm>
 showing two simple subroutines:>

=begin html

<code>
<br><br>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
package usr_code;<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
require Exporter;<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
use warnings;<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
our @ISA     = qw(Exporter Net::FullAuto::FA_lib);<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
use Net::FullAuto::FA_lib;<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##&nbsp&nbspDo NOT alter code ABOVE this block.<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
sub hello_world {<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
print $localhost->cmd('echo "hello world"');<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
}<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
sub remote_hostname {<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
my ($computer_one,$stdout,$stderr);
&nbsp&nbsp&nbsp&nbsp
# Scope Variables<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
$computer_one=connect_ssh('REMOTE COMPUTER ONE');
# Connect to<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
&nbsp&nbsp&nbsp&nbsp
# Remote Host via ssh<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
($stdout,$stderr)=$computer_one->cmd('hostname');<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
print "REMOTE ONE HOSTNAME=$stdout\n";<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
}<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
########### END OF SUBS ########################<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
##&nbsp&nbspDo NOT alter code BELOW this block.<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
#################################################################<br><br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
## Important! The '1' at the Bottom is NEEDED!<br>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
1
</code>

=end html

=back

=head2 S<  >C<fa_hosts.pm>S<  >HOST BLOCK KEY ELEMENTS

=over 2

=item * Key Elements

=over 2

B<Label>S<  >- string to identify host blockS<   >(This is a REQUIRED Element)

S<                 >C<Label =>>C< 'Any_Unique_String',>

=back

S<      >The C<L>C<abel> Key Element is the method by which FullAuto locates the connection information in theS<  >C<fa_hosts.pm>S<   >file.

=back

=over 2

=item

B<IP>S<       >- ip address of remote hostS<   >(Either an IP address or Hostname Element is REQUIRED)

S<                 >C<IP =>>C< '198.201.10.01',>

=back

=over 2

=item

B<Hostname>S<  >- hostname of remote hostS<   >(Either an IP address or Hostname Element is REQUIRED)

S<                 >C<Hostname =>>C< 'Remote_Host_One',>

=back

=over 2

=item

B<LoginID>S<  >- optional login id for remote host

S<                 >C<LoginID =>>C<'Username'>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
The <code>LoginID</code> Key Element is <i>optional</i> because FullAuto defaults to use the login id of the current user running <code>fullauto</code> (or script using the <code>FullAuto.pm</code>&nbsp&nbspmodule). The password associated with ALL login ids - either default or indicated with this key element - are protected in an encrypted password file, and added and retrieved <i>automatically</i> when <code>fullauto</code> is run. If the password associated with the host and login id cannot be located in the password file, the user will be prompted to add it.
</P>

=end html

=over 2

=item

B<LogFile>S<  >- optional log file name and location

S<                 >C<LogFile =>>C< "/tmp/FAlog${$}d" .
"$Net::FullAuto::FA_lib::invoked[2]" .
"$Net::FullAuto::FA_lib::invoked[3].txt",>

=back

=head1 METHODS

=over 2

=item * Create New Host Objects

=over 2

=back

B<connect_secure> - connect to remote host via ssh & sftp

=over 2

=item

C<($secure_host_object,$error) = connect_secure('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
All Connect Methods return a <i>host object</i> if connection
is successful, or error message(s)<br>
in the error variable if the method is requested to return a list.
Otherwise, if the method is<br>requested to only return a scalar:
</P>

=end html

=over 2

=item

C<$secure_host_object = connect_secure('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
Any connection errors will result in complete termination of
the process.</P>

<P CLASS="indented">
The <CODE>$secure_host_object</CODE> represents both ssh AND sftp connections
together in ONE<br>object. The <CODE>HOSTLABEL</CODE> tag is a label to an
anonymous hash block defined in the file <code>fa_hosts.pm</code>.<br>
(See the <b>fa_hosts</b> section for instructions on configuring host
connection information.)</P>
</P>
<P CLASS="indented">
The important thing to understand, is that there is no other code
needed to connect to remote<br>hosts. Net::FullAuto handles all
connection details, such as dynamic remote-prompt discovery,<br>
AUTOMATICALLY. No need to define <i>or even know</i> what the remote
prompt is. This feature<br>'alone' is a major departure from most
other scriptable remote command and file transfer utilities.</P>

=end html

=over 2

=item

THIS IS THE RECOMMENDED I<BEST METHOD> for CONNECTING.

=back

B<connect_ssh> - connect to remote host via ssh

=over 2

=item

C<($ssh_host_object,$error) = connect_ssh('HOSTLABEL');>

C<$ssh_host_object = connect_ssh('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
This method returns an ssh connection <i>only</i> - any attempt to
use file-transfer features with this object<br>will throw an error.
</P><P CLASS="indented">
Use this method if you don't need file-transfer capability in
your process.
</P>

=end html

B<connect_sftp> - connect to remote host via sftp

=over 2

=item

C<($sftp_host_object,$error) = connect_sftp('HOSTLABEL');>

C<$sftp_host_object = connect_sftp('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
This method returns an sftp connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you don't need
remote command-line capability in your process.</P>

=end html

B<connect_host> - connect to remote host via ssh  OR telnet
                                         and sftp OR ftp

=over 2

=item

C<($host_object,$error) = connect_host('HOSTLABEL');>

C<$host_object = connect_host('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
This method is the most <i>powerful</i> of all the connect methods.
When this method is used, it will first attempt to<br>connect to the 
remote host via ssh and sftp. However, if for any reason either or
both ssh and sftp fail to connect,<br>then it will attempt to connect
via telnet and/or ftp. (Use connect_reverse for the opposite behavior.)
<br>This method returns either a ssh or telnet connection and either a
sftp or ftp connection. (Note: you could get a connection that is
telnet/sftp or ssh/ftp)
</P><P CLASS="indented">
Note: This is the most powerful method, but not the most secure, becasue
it's possible to connect with telnet and/or ftp. Use this when process
completion is more important than having optimum connection security.
</P>

=end html

B<connect_insecure> - connect to remote host via telnet & ftp

=over 2

=item

C<($insecure_host_object,$error) = connect_insecure('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 45pt;
   padding-right: 45pt;
   }
-->
</STYLE>
<P CLASS="indented">
All Connect Methods return a <i>host object</i> if connection
is successful, or error message(s)<br>
in the error variable if the method is requested to return a list.
Otherwise, if the method is<br>requested to only return a scalar:
</P>

=end html

=over 2

=item

C<$insecure_host_object = connect_insecure('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
Any connection errors will result in complete termination of
the process.</P>

<P CLASS="indented">
The <CODE>$insecure_host_object</CODE> represents both telnet AND ftp 
connections together in ONE<br>object. The <CODE>HOSTLABEL</CODE> tag 
is a label to an anonymous hash block defined in the file 
<code>fa_hosts.pm</code>.<br>(See the <b>fa_hosts</b> section for 
instructions on configuring host connection information.)</P>
</P>

=end html

=over 2

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING - 
use C<connect_secure()> whenever possible.

=back

B<connect_telnet> - connect to remote host via telnet

=over 2

=item

C<($ssh_host_object,$error) = connect_telnet('HOSTLABEL');>

C<$ssh_host_object = connect_telnet('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
This method returns a telnet connection <i>only</i> - any attempt to
use file-transfer features with this object<br>will throw an error.
</P><P CLASS="indented">
Use this method if you don't need file-transfer capability in
your process.
</P>

=end html

=over 2

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_ssh()> whenever possible.

=back

B<connect_ftp> - connect to remote host via ftp

=over 2

=item

C<($ftp_host_object,$error) = connect_ftp('HOSTLABEL');>

C<$ftp_host_object = connect_ftp('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
This method returns an ftp connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you don't need
remote command-line capability in your process.</P>

=end html

=over 2

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_sftp()> whenever possible.

=back

B<connect_ssh_telnet> - connect to remote host via ssh OR telnet

=over 2

=item

C<($host_object,$error) = connect_ssh_telnet('HOSTLABEL');>

C<$host_object = connect_ssh_telnet('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
When this method is used, it will first attempt to<br>connect to the
remote host via ssh. However, if for any reason ssh fails to connect,
<br>then it will attempt to connect via telnet. (Use connect_telnet_ssh 
for the opposite behavior.)<br>This method returns either a ssh or telnet 
connection.
</P><P CLASS="indented">
Note: This is a powerful method, but not the most secure, becasue
it's possible to connect with telnet. Use this when process
completion is more important than having optimum connection security.
</P><P CLASS="indented">
This method returns a remote command-line connection <i>only</i>
- any attempt to use file-transfer features with this object<br>
will throw an error.</P><P CLASS="indented">
Use this method if you don't need file-transfer capability in
your process.
</P>

=end html

B<connect_telnet_ssh> - connect to remote host via telnet OR ssh

=over 2

=item

C<($host_object,$error) = connect_telnet_ssh('HOSTLABEL');>

C<$host_object = connect_telnet_ssh('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
When this method is used, it will first attempt to<br>connect to the
remote host via telnet. However, if for any reason telnet fails to connect,
<br>then it will attempt to connect via ssh. (Use connect_ssh_telnet
for the opposite behavior.)<br>This method returns either a telnet or ssh 
connection.
</P><P CLASS="indented">
Note: This is a powerful method, but not the most secure, becasue
it's possible to connect with telnet. Use this when process
completion is more important than having optimum connection security.
Also, this method will return a telnet connection FIRST if available. Use 
this if connection reliability is important, but performance is more
important than security.
</P><P CLASS="indented">
This method returns a remote command-line connection <i>only</i> 
- any attempt to use file-transfer features with this object<br>
will throw an error.</P><P CLASS="indented">
Use this method if you don't need file-transfer capability in
your process.
</P>

=end html

=over 2

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_ssh()> whenever possible.

=back

B<connect_sftp_ftp> - connect to remote host via sftp OR ftp

=over 2

=item

C<($host_object,$error) = connect_sftp_ftp('HOSTLABEL');>

C<$host_object = connect_sftp_ftp('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
When this method is used, it will first attempt to<br>connect to the
remote host via sftp. However, if for any reason telnet fails to connect,
<br>then it will attempt to connect via ftp. (Use connect_ftp_sftp
for the opposite behavior.)<br>This method returns either a sftp or ftp
connection.
</P><P CLASS="indented">
Note: This is a powerful method, but not the most secure, becasue
it's possible to connect with ftp. Use this when process
completion is more important than having optimum connection security.
</P><P CLASS="indented">
This method returns a file-transfer connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you don't need
remote command-line capability in your process.</P>

=end html

B<connect_ftp_sftp> - connect to remote host via ftp OR sftp

=over 2

=item

C<($host_object,$error) = connect_ftp_sftp('HOSTLABEL');>

C<$host_object = connect_ftp_sftp('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
When this method is used, it will first attempt to<br>connect to the
remote host via ftp. However, if for any reason sftp fails to connect
<br>then it will attempt to connect via sftp. (Use connect_sftp_ftp
for the opposite behavior.)<br>This method returns either a ftp or sftp
connection.
</P><P CLASS="indented">
Note: This is a powerful method, but not the most secure, because
it's possible to connect with ftp. Use this when process
completion is more important than having optimum connection security.
Also, this method will return a ftp connection FIRST if available. Use
this if connection reliability is important, but performance is more
important than security.
</P><P CLASS="indented">
This method returns an file-transfer connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you don't need
remote command-line capability in your process.</P>

=end html

=over 2

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_sftp()> whenever possible.

=back

B<connect_reverse>  - connect to remote host via telnet OR ssh
                                             and ftp    OR sftp

=over 2

=item

C<($connect_reverse_object,$error) = connect_reverse('HOSTLABEL');>

C<$connect_reverse_object = connect_reverse('HOSTLABEL');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
When this method is used, it will first attempt to<br>connect to the
remote host via ssh and sftp. However, if for any reason either or
both telnet and ftp fail to connect,<br>then it will attempt to connect
via ssh and/or sftp. (Use connect_host for the opposite behavior.)
<br>This method returns either a telnet or ssh connection and either a
ftp or sftp connection. (Note: you could get a connection that is
telnet/sftp or ssh/ftp)
</P><P CLASS="indented">
Note: This is a powerful method, but not the most secure, because
it's possible to connect with telnet and/or ftp. Use this when process
completion is more important than having optimum connection security.
Also, this method will return a telnet/ftp connection FIRST if available. Use
this if connection reliability is important, but performance is more
important than security.
</P>

=end html

=back

=over 2

=item * Host Object Methods

=over 2

=back

B<cmd> - run command line commands on the remote host

=over 2

=item

C<($cmd_output,$error) = $connect_secure_object-E<gt>cmd('hostlabel');>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
There is a <code>cmd</code> method available with every connect_object.
For all objects that contain both remote command-line and file-transfer
connections, the <code>cmd</code> method gives access ONLY to the 
remote command-line feature. To access the ftp cmd options, use the
following syntax:
</P>

=end html

=over 2

=item

C<($ftp_cmd_output,$error) = $connect_secure_object-E<gt>{_ftp_handle}-E<gt>cmd('help');>

=back 

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
For all objects that contain only a file-transfer
connection, the <code>cmd</code> method gives access ONLY to the
file-transfer command-line feature.
</P>

=end html

=over 2

=item

C<($sftp_cmd_output,$error) = $connect_sftp_object-E<gt>cmd('help');>

=back

=back

=head1 EXAMPLES

=head1 AUTHOR

Brian M. Kelly <Brian.Kelly@fullautosoftware.net>

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007
by Brian M. Kelly.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License.
(http://www.opensource.org/licenses/gpl-license.php).
