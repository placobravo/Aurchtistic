#!/bin/bash

kill -SIGSTOP -$2
printf "\n\n Holl'up! \n\n"
echo "I'm a suspend function."
echo "Subshell had ID $1"
echo "Shell id is $$"
pstree -p $$
pstree -p $1

read -p "Yes, let me cook! " choice
if [ $choice = "y" ]; then
	echo "Ok, I'm cooking!"
	echo
	kill -SIGCONT -$2
else
	echo "Ok, quitting and giving you back terminal"
	echo
	kill -SIGKILL -$1
	kill -SIGCONT -$2
fi
exit 0
