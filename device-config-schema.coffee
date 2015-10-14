module.exports ={
  title: "pimatic-plex device config schemas"
  PlexPlayer: {
    title: "plex config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      server:
        description: "The address of plex server"
        type: "string"
      port:
        description: "The port of plex server"
        type: "number",
        default: 32400
      guid:
        description: "The internal guid"
        type: "string"
        default: ""
      username:
        description: "The username for the plex server"
        type: "string",
        default: ""
      password:
        description: "The password for the plex server"
        type: "string",
        default: ""
      player:
        description: "The name of plex player"
        type: "string"
      playerIp:
        description: "The name of plex player"
        type: "string"
        default: ""
      interval:
        interval: "Interval in ms so read the plex state"
        type: "integer"
        default: 5000
  }
}