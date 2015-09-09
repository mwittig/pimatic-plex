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
      player:
        description: "The name of plex player"
        type: "string"
      interval:
        interval: "Interval in ms so read the plex state"
        type: "integer"
        default: 5000
  }
}