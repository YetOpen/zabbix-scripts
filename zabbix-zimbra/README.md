# Zimbra monitoring with Zabbix

This template offers services autodiscover, version tracking and service status.
It's compatibile with Zimbra 8.6+ (and its services with spaces).

Please note the external script requires sudo privileges to run, so either copy the content of the sudo_zbx-zimbra.conf file to your sudoers 
or link it to /etc/sudoers.d/.
Also copy yo-zimbra.conf to /etc/zabbix/zabbix_agentd.d/ and the script file to your zabbix agent's script directory (usually /etc/zabbix/scripts, if differeny adjust yo-zimbra.conf accordingly).

Restart zabbix-agent and import the template to your server.
The service discovery is set very long (1 day), so it may take that long for services to show up in Zabbix.
The discovery command can take more than the 3s of the default command timeout, used by both agent and server/proxy. In case you see something like 
```
Zabbix agent item "zimbra.discovery" on host "webmail.domain.it" failed: first network error, wait for 15 seconds
```
you should change the `Timeout` value in zabbix_agentd.d/yo-zimbra.conf.

Please note you should **change the timeout on the server/proxy** accordingly.

The bash script was inspired by [blog.linuxnet.ch](https://blog.linuxnet.ch/zimbra-monitoring-with-zabbix/). 

# Zimbra Network Edition backup check

This is a basic check which runs `zmbackupquery` looking for the number of completed backup in the last *n*th hours. 
By default the template check the latest 24h, but you can change or add new check as you prefer. 

In the future it can be improved with different checks for full or incremental backups.

# License & Copyright
Code and documentation copyright 2018 YetOpen S.r.l.. Released under the GPLv3 license.
