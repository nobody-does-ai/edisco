#!/usr/bin/perl
# vim: ts=2 sw=2 ft=perl
eval 'exec perl -x -wS $0 ${1+"$@"}'
  if 0;
$|++;
use common::sense;
use autodie;
use Nobody::Util;
use Nobody::PP;
use Getopt::WonderBra;
sub help {
};
sub version {
};
our(@VERSION) = qw( 0 1 0 );
my $inodes=0;
my $source=0;
my $uniq=0;
my $read=0;
my $test=0;
use 5.35.0;
use Env qw( @PATH );
sub lspath() {
  eex(\@PATH);
  local(@_)=proc_opts(@ARGV);
#      (($#)) || set PATH
#      (($#!=1)) && echo "expected one name" && return 1
#      local -n var="$1"
#      shift
#      if $read; then
#        set -- $(cat)
#      else
#        IFS=":"
#        set -- $var 
#      fi
#      IFS="$SIFS"
#      if $uniq; then
#        #printf 'debug1: %s\n' "$@" >&2
#        local -A "seen=()"
#        local -a "res=()"
#        set -- $( stat -c '%d:%i %n' $(printf '%s/\n' "$@") 2>/dev/null )
#        while [ -n "$*" ]; do
#          local inode="$1" path="$2"
#          shift 2
#          if test -z "${seen[$inode]}"; then
#            res+=( "${path%/}" )
#            seen[$inode]="$path"
#          fi
#        done
#        set -- "${res[@]}"
#      fi
#      if test -n "$test"; then
#        #printf 'debug2: %s\n' "$@" >&2
#        local -i num=$#
#        for j; do test -$test "$j" && set -- "$@" "$j"; done
#        shift $num
#      fi
#      #printf 'debug3: %s\n' "$@" >&2
#      if $inodes; then
#        stat -c '%d:%i %n' $(printf '%s/\n' "$@")
#      elif $source; then
#        IFS=:
#        echo "${!var}=$*"
#      else
#        printf '%s\n' "$@"
#      fi
};
lspath;
sub proc_opts {
  @ARGV=getopt("redisu",@ARGV);
  while(($_=shift(@ARGV))ne'--'){
    if(m{^-d$}){
      $test="d";
    } elsif(m{^-e$}){
      $test="e";
    } elsif(m{^-i$}){
      $inodes=1;
    } elsif(m{^-s$}){
      $source=1;
    } elsif(m{^-u$}){
      $uniq=1;
    } else {
      die "bad opt: $_";
    };
    if ($source && $inodes){
      die "can't do both source and inodes!";
    };
  };
};
