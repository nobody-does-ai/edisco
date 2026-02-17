package TsvDoc;
use common::sense;


use lib "lib";
use Nobody::Util;
use Nobody::PP @Nobody::PP::EXPORT_OK;
use Scalar::Util;
use base 'TsvDoc::Impl';
#    use Tie::TsvHash;

*key=\&Tie::TsvHash::key;
use vars qw($debug);
use Carp qw( carp cluck confess croak );

unless(caller){
  require "$ENV{PWD}/bin/up-scale-down-scale.pl"

};
