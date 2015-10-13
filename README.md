
pimatic-plex
===========

##Important
This plugin is still under development, please remain calm.. :sunglasses:

pimatic plugin for controlling the [Plex players](http://www.plex.tv/).

###device config example:

```json
{
  "id": "plex-player",
  "name": "Living room",
  "class": "PlexPlayer",
  "server": "192.168.1.102",
  "port": 1400,
  "player": "abc123",
  "intervall": 60000,
  "username": "abc123" # Optional
  "password": "abc123" # Optional
}
```

###device rules examples:

Currently no predicates for the plex plugin. If you would like to do something when the state changes u could use the attribute predicate.<br>
if $plex-player.state equals \"play\" then dim lights<br>
if $plex-player.type equals \"movie\" then switch speakers on <br>
