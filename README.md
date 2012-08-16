## planningExport

The original purpose of this script was to export tasks tracked with Hamster to
JIRA. But I made sure it can accept other providers and could connect to other
time tracking systems.

Find out more about Hamster at:
http://projecthamster.wordpress.com/

Export::Connector::JIRA was built to run against the, old, old JIRA 4.1 I have
at work. Because I could not get the rest/auth API working on this version, I
rely a lot on the content of the page returned by JIRA. I will probably break
on newer versions.

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-sa/3.0/88x31.png" /></a><br />This work by <a xmlns:cc="http://creativecommons.org/ns#" href="https://github.com/freongrr/" property="cc:attributionName" rel="cc:attributionURL">Fabien Cortina</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-ShareAlike 3.0 Unported License</a>.
