{
  package DblHash;
  use Nobody::Util;
  use Tie::Hash;
  our(@ISA) = qw(Tie::StdHash);
 
  sub call($@){
    my($obj,$sub,@args)=@_;
    $obj->SUPER::$sub(@args);    
  }; 
  sub  TIEHASH   {  shift->call('TIEHASH',@_);   }
  sub  STORE     {  shift->call('STORE',@_);     }
  sub  FETCH     {  shift->call('FETCH',@_);     }
  sub  FIRSTKEY  {  shift->call('FIRSTKEY',@_);  }
  sub  NEXTKEY   {  shift->call('NEXTKEY',@_);   }
  sub  EXISTS    {  shift->call('EXISTS',@_);    }
  sub  DELETE    {  shift->call('DELETE',@_);    }
  sub  CLEAR     {  shift->call('CLEAR',@_);     }
  sub  SCALAR    {  shift->call('SCALAR',@_);    }
}
1;
