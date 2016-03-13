module.exports = (env) ->

# Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  M = env.matcher
  _ = env.require('lodash')
  
  uuid = require('node-uuid')
  PlexAPI = require("plex-api")

  Promise.promisifyAll(PlexAPI.prototype);

  class PlexPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("PlexPlayer", {
        configDef: deviceConfigDef.PlexPlayer,
        createCallback: (config) -> new PlexPlayer(config)
      })


  class PlexPlayer extends env.devices.AVPlayer

    _state: "stopped"
    _currentTitle: ""
    _currentType: ""
    _currentProgress: 0
    _currentShow: ""
    _currentProduct: ""
    _currentClient: ""

    actions:
      play:
        description: "starts playing"
      pause:
        description: "pauses playing"
      stop:
        description: "stops playing"
      next:
        description: "play next song"
      previous:
        description: "play previous song"
      volume:
        description: "Change volume of player"

    attributes:
      state:
        description: "the current state of the player"
        type: "string"
      currentTitle:
        description: "the current playing title"
        type: "string"
      currentType:
        description: "the current type of object"
        type: "string"
      currentProgress:
        description: "the current progress of title"
        type: "number"
        unit: '%'
      currentShow:
        description: "the current playing show"
        type: "string"
      currentProduct:
        description: "the current product"
        type: "string"
      currentClient:
        description: "the current client"
        type: "string"

    constructor: (@config) ->
      @name = config.name
      @id = config.id
      
      @config.guid = uuid.v4() if not config.guid

      PlexConnectionString = {hostname: config.server, port: config.port, product: 'Pimatic', identifier: config.guid}
      PlexConnectionString['username'] = config.username if config.username
      PlexConnectionString['password'] = config.password if config.password

      @_plexClient = new PlexAPI(PlexConnectionString)
      
      @_getConfig()
      

      setInterval( ( => @_getStatus() ), @config.interval)

      super()

    play:() -> @_plexClient.query("/system/players/" + @config.playerIp + "/playback/play").then((state) => @_getStatus())
    pause:() -> @_plexClient.query("/system/players/" + @config.playerIp + "/playback/pause").then((state) => @_getStatus())
    stop:() -> @_plexClient.query("/system/players/" + @config.playerIp + "/playback/stop").then((state)  => @_getStatus())
    next:() -> @_plexClient.query("/system/players/" + @config.playerIp + "/playback/stepForward").then(()  => @_getStatus())
    previous:() -> @_plexClient.query("/system/players/" + @config.playerIp + "/playback/stepBack").then(()  => @_getStatus())
    getState: -> Promise.resolve(@_state)
    getCurrentTitle: -> Promise.resolve(@_currentTitle)
    getCurrentType: -> Promise.resolve(@_currentType)
    getCurrentProgress: -> Promise.resolve(@_currentProgress)
    getCurrentShow: -> Promise.resolve(@_currentShow)
    getCurrentProduct: -> Promise.resolve(@_currentProduct)
    getCurrentClient: -> Promise.resolve(@_currentClient)

    _getStatus: () ->
      @_plexClient.query("/status/sessions").then( (result) =>
        plexClientFound = false
        for item in result._children
          for entry in item._children
            if entry._elementType is 'Player' and entry.machineIdentifier isnt @config.player and entry.title isnt @config.player
              env.logger.debug("Found unknown %s with id %s and name %s.", entry.product, entry.machineIdentifier, entry.title)
            if entry._elementType is 'Player' and (entry.machineIdentifier is @config.player or entry.title is @config.player)
              plexClientFound = true
              if entry.state is 'playing' and @_state != 'playing'
                @_state = 'playing'
                @emit "state", @_state
              else if entry.state is 'paused' and @_state != 'paused'
                @_state = 'paused'
                @emit "state", @_state
              if @_currentProduct != entry.product
                @_currentProduct = entry.product
                @emit "currentProduct", @_currentProduct
              if @_currentClient != entry.title
                @_currentClient = entry.title
                @emit "currentClient", @_currentClient
              if @_currentTitle != item.title
                @_currentTitle = item.title
                @emit "currentTitle", @_currentTitle
              if @_currentType != item.type
                @_currentType = item.type
                @emit "currentType", @_currentType
              if @_currentProgress != Math.round((item.viewOffset / item.duration) * 100)
                @_currentProgress = Math.round((item.viewOffset / item.duration) * 100)
                @emit "currentProgress", @_currentProgress
              if @_currentShow != item.grandparentTitle
                @_currentShow = item.grandparentTitle
                @emit "currentShow", @_currentShow
        if plexClientFound == false and @_state != 'stopped'
          @_state = 'stopped'
          @emit "state", @_state
          @_currentProduct = ""
          @emit "currentProduct", @_currentProduct
          @_currentClient = ""
          @emit "currentClient", @_currentClient
          @_currentTitle = ""
          @emit "currentTitle", @_currentTitle
          @_currentType = ""
          @emit "currentType", @_currentType
          @_currentProgress = 0
          @emit "currentProgress", @_currentProgress
          @_currentShow = item.grandparentTitle
          @emit "currentShow", @_currentShow
      )

    _getConfig: () ->
      @_plexClient.query("/clients").then( (result) =>
        for item in result._children
          if item.name is @config.player
            env.logger.debug("Setting playerIp to %s since it is named %s.", item.address, entry.title)
            @config.playerIp = item.address
      )

  plexPlugin = new PlexPlugin
  return plexPlugin
