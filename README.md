
pimatic-plex
===========

pimatic plugin for controlling the [Plex players](http://www.plex.tv/).

To get the plugin working is needs the IP of the server and the name of the player.
In this example it is "macbook-pro":
![player name](http://www.trugen.net/info.png "Player name")
 
The first time the plugin is loaded it will generate an guid and load the ip of the player if it currently is started.


###device config example:

```json
{
  "id": "plex-player",
  "name": "Living room",
  "class": "PlexPlayer",
  "server": "192.168.1.102",
  "port": 32400,
  "player": "abc123",
  "playerIp": "192.168.1.103",
  "intervall": 60000,
  "guid": "xxxx-xxxx-xxxx-xxxx",
  "username": "abc123" # Optional
  "password": "abc123" # Optional
}
```

###device rules examples:

Currently no predicates for the plex plugin. If you would like to do something when the state changes u could use the attribute predicate.<br>
if $plex-player.state equals \"play\" then dim lights<br>
if $plex-player.type equals \"movie\" then switch speakers on <br>
