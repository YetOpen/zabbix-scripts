2016.07.15
----------

Updated the bash script to fork in background, thanks to @Ufo28.

The script doesn't lock anymore Zabbix agent, and forks the update process in background. This ensures much faster reply and 
avoids timeout problems with the agent.
