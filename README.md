# multi-backup
Two scripts that backup and monitor various types of configurations of Routers, switches and other devices.
But it can backup files and databases as well. You just have to create your own method. 

The goal with this was to automate the backup process and files monitoring while making it relativly easy for my collegues to add devices in the future
without having to know much about scripting. 

The most important part about this is making your own methods in the bak-tasks.sh file. (Will redo this another time with better ways of storing and creating custom methods)

# bak-tasks.sh
Perfoms the backup jobs. 

# bak-monitor.sh
Monitors that todays backupfiles are there. Needs to be run after bak-tasks.sh. 

# devices.json
This is where all the devices are predefined.

I wrote this specifically for my use case. 
Will try to update and improve so that it works for everyone generally.

So far it works on TrueNAS. Have not tested on anyother linux distros. 
