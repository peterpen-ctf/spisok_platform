Establish VPN connection
========================

  Push your MM-AD login and password to 'mm-creds', then run
  $ openvpn mm-tcp.conf


MM-AD server
============

  HOST: serv2.math.spbu.ru (192.168.64.12)
  LDAP port : 389
  LDAPS port: 636


LDAP example usage
==================

  requires: ldapsearch (On Fedora install 'openldap-clients' package)

  $ ldapsearch -x -D <YOUR_MM_LOGIN>@math.spbu.ru -W -H ldap://serv2.math.spbu.ru -b 'dc=math,dc=spbu,dc=ru' 'sAMAccountName=dluciv'
