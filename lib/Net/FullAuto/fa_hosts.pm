package fa_hosts;

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

require Exporter;
use warnings;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(@Hosts);
our $VERSION = 1.00;

@Hosts = (
#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################
##  -------------------------------------------------------------
##  ADD HOST BLOCKS HERE:
##  -------------------------------------------------------------

       {
          'IP'             => '10.2.21.30',
          'HostName'       => 'currencydev1',
          'Label'          => 'CURRENCYDEV1',
          'RCM_Proxy'      => '1',
          'FTM_Proxy'      => '1',
          #'Chmod'          => '775',
          #'Owner'          => 'cca',
          #'Group'          => 'ccp',
          'LoginID'        => 'bkelly',
          #'SU_ID'          => 'root',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_lib::invoked[2]".
                              "$Net::FullAuto::FA_lib::invoked[3].txt",
          'FA_Secure'      => '/fullauto/FA_lib/security',

          # Cipher ############################################
             #  Example:  'Cipher' => 'DES',
             #  Cipher Algorithms may be any of the following:
             #  DES, DES_EDE3, DES_EEE3, IDEA, Blowfish, Rijndael
             #  Blowfish_PP, Rijndael_PP (Perl Implementations)
             #  Default: DES
             #  Recommended: Rijndael_PP (Government AES)
          #####################################################

          'Cipher'         => 'Rijndael_PP',
          'Ping'           => 1,
          'TransferDir'    => '/tmp',
          #'ssh'            => '/opt/freeware/bin',
          #'sftp'           => '/opt/freeware/bin',
          #'telnet'         => '/usr/bin/',
          #'ftp'            => '/usr/bin/',
          #'perl'           => '/usr/local/bin/',
          #'bash'           => '/usr/local/bin/',
       },
       {
          'IP'             => '10.2.4.30',
          'HostName'       => 'FlexUsr6',
          'Label'          => 'FLEXUSR6',
          'RCM_Proxy'      => '1',
          'FTM_Proxy'      => '1',
          #'Chmod'          => '775',
          #'Owner'          => 'cca',
          #'Group'          => 'ccp',
          'LoginID'        => 'flexapp',
          #'SU_ID'          => 'root',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_lib::invoked[2]".
                              "$Net::FullAuto::FA_lib::invoked[3].txt",
          'FA_Secure'      => '/fullauto/FA_lib/security',

          # Cipher ############################################
             #  Example:  'Cipher' => 'DES',
             #  Cipher Algorithms may be any of the following:
             #  DES, DES_EDE3, DES_EEE3, IDEA, Blowfish, Rijndael
             #  Blowfish_PP, Rijndael_PP (Perl Implementations)
             #  Default: DES
             #  Recommended: Rijndael_PP (Government AES)
          #####################################################

          'Cipher'         => 'Rijndael_PP',
          'Ping'           => 1,
          'TransferDir'    => '/tmp',
          #'ssh'            => '/opt/freeware/bin',
          #'sftp'           => '/opt/freeware/bin',
          #'telnet'         => '/usr/bin/',
          #'ftp'            => '/usr/bin/',
          #'perl'           => '/usr/local/bin/',
          #'bash'           => '/usr/local/bin/',
       },
       {
          'IP'            => '10.2.21.37',
          'HostName'      => 'jumpdev5.w2k.jumptrading.com',
          'Label'         => 'JUMPDEV5',
          'LogFile'       => "/cygdrive/d/nightly_build/FA_Logs/".
                             "FAlog${$}d$Net::FullAuto::FA_lib::invoked[2]".
                             "$Net::FullAuto::FA_lib::invoked[3].txt",
          'Local'         => 'connect_ssh_telnet',
       },
       {
          'IP'            => '10.2.21.35',
          'HostName'      => 'jumpdev3.w2k.jumptrading.com',
          'Label'         => 'JUMPDEV3',
       },
       {
          'IP'            => '10.2.21.36',
          'HostName'      => 'jumpdev4.w2k.jumptrading.com',
          'Label'         => 'JUMPDEV4',
          'Login'         => 'bkelly',
       },
       {
          'IP'            => '10.7.2.63',
          'HostName'      => 'nj-car-jtprod2.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD2',
       },
       {
          'IP'            => '10.7.2.62',
          'HostName'      => 'nj-car-jtprod3.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD3',
       },
       {
          'IP'            => '10.7.2.65',
          'HostName'      => 'nj-car-jtprod4.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD4',
       },
       {
          'IP'            => '10.7.2.66',
          'HostName'      => 'nj-car-jtprod5.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD5',
       },
       {
          'IP'            => '10.7.2.67',
          'HostName'      => 'nj-car-jtprod6.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD6',
       },
       {
          'IP'            => '10.7.2.85',
          'HostName'      => 'nj-car-jtprod7.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD7',
       },
       {
          'IP'            => '10.7.2.72',
          'HostName'      => 'nj-car-jtprod8.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD8',
       },
       {
          'IP'            => '10.7.2.73',
          'HostName'      => 'nj-car-jtprod9.w2k.jumptrading.com',
          'Label'         => 'NJ-CAR-JTPROD9',
       },
       {
          'IP'            => '10.6.2.90',
          'HostName'      => 'atl-jtprod1.w2k.jumptrading.com',
          'Label'         => 'ATL-JTPROD1',
       },
       {
          'IP'            => '10.2.3.117',
          'HostName'      => 'jt-prod10',
          'Label'         => 'JT-PROD10',
       },
       {
          'IP'            => '10.8.2.28',
          'HostName'      => 'cer-energygw4.w2k.jumptrading.com',
          'Label'         => 'CER-ENERGYGW4',
       },
       {
          'IP'            => '10.2.21.113',
          'HostName'      => 'jumpdev8.w2k.jumptrading.com',
          'Label'         => 'JUMPDEV8',
          'LogFile'       => "/home/bkelly/FA_Logs/FAlog${$}d".
                             "$Net::FullAuto::FA_lib::invoked[2]".
                             "$Net::FullAuto::FA_lib::invoked[3].txt",
       },
       {
          'IP'            => '10.2.3.168',
          'LoginID'       => 'jump',
          #'HostName'      => '',
          'Label'         => 'EUREXSIM1',
       },

#################################################################
##  Do NOT alter code BELOW this block.
#################################################################
);

1;
