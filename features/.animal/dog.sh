: "${H_ANYSH_DIR:=$HOME/.anysh}"
source "$H_ANYSH_DIR/hidden/source.sh"
  h_source  'util'  'path'
   h_source   'getopt'   'make'
h_source 'cat'
#h_source 'alice'
h_source'bob' 2> /dev/null
source'chris' 2> /dev/null


h_is_dog_sourced() { # This is the 'h_is_dog_sourced' function.
  return 0
}

a_dog() { # This is the 'a_dog' function.
  h_echo 'dog'
  a_cat
}

   a_ok_A-Za-z0-9_-   () # This is the 'a_ok_A-Za-z0-9_-' function.
   {
     echo 'called a_ok_A-Za-z0-9_-'
   }

#a_ng1() {
#  echo 'called a_ng1'
#}

a_ng2:() {
  echo 'called a_ng2:'
}

#a_ng3( ) {
#  echo 'called a_ng3'
#}
