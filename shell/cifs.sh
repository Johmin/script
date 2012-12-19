#!/usr/bin/expect


set timeout 30
spawn mount -t cifs //172.16.81.1/ISO -o username=johmin /mnt 
expect "Password:" 
send "abcd!1234\r\n"
interact

#echo "Johmin" |mount -t cifs //172.16.81.1/ISO -o username=johmin /mnt
