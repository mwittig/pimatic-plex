module.exports ={
  title: "pimatic-Plex device config schemas"
  PlexPlayer: {
    title: "Plex config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      server:
        description: "The address of Plex server"
        type: "string"
      port:
        description: "The port of Plex server"
        type: "number",
        default: 32400
      guid:
        description: "The internal guid"
        type: "string"
        default: ""
      username:
        description: "The username for the Plex server"
        type: "string",
        default: ""
      password:
        description: "The password for the Plex server"
        type: "string",
        default: ""
      player:
        description: "The name of Plex player"
        type: "string"
      playerIp:
        description: "The ip of Plex player"
        type: "string"
        default: ""
      interval:
        interval: "Interval in ms so read the Plex state"
        type: "integer"
        default: 5000
  }
}