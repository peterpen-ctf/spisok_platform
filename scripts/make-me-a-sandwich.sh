echo 'Control-\ to exit, Control-C to complete restart'
trap exit SIGQUIT
while true; do
  rake ramaze:dbreset
  rake ramaze:start
done
