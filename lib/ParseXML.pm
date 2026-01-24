package ParseXML;
use XML::Parser::Expat;
use common::sense;
use Nobody::Util;
use autodie;

sub parse {
  local(@_)=@_;
  unshift(@_,__PACKAGE__) unless UNIVERSAL::isa($_[0],__PACKAGE__);
  my($class)=class(shift);
  for( parser(shift) ) {
    say pp($_);
  };
}
sub new {
  bless({_=>{name=>shift, kids=>[]}},class(shift));
};
sub parser {
  my($class);
  if(safe_isa($_[0],__PACKAGE__)) {
    $class=class(shift);
  } else {
    $class=__PACKAGE__;
  };
  my($self)=$class->new;
  my($text)=path($_[0])->slurp;
  my $parser = XML::Parser::Expat->new;
  my($pos);
  my(@pos);
  my($event)=0;
  for($SIG{ALRM}){
    $_=sub {
      say "event: $event";
      alarm(0.1);
    };
  };
  alarm(0.1);
  $parser->setHandlers(
    'Start' => sub {
      shift;
      ++$event;
      my(%attr);
      say "$pos";
      my($self)=$class->new;
      push(@$pos,$self);
      ($pos[@pos],$pos)=($pos,$self->{_children});

      while(@_) {
        sleep(0.5);
        my($key,$val)=(shift,shift);
        my($len)=length($val);
        $val={huge=>$len} if $len>100000000;
        for($attr{$key}) {
          if(!defined){
            $_=$val;
          } elsif(ref ne 'ARRAY'){
            $_=[$_,$val];
          } else {
            push(@$_,$val);
          };
        };
      };
    },
    'End'   => sub {
      ++$event;
      $pos=pop(@pos);
    }
  );
  $parser->parsestring($text);
  return $self;
}
1;
