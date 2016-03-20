module.exports = (env) ->

# Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  M = env.matcher
  _ = env.require('lodash')
  
  uuid = require('node-uuid')
  PlexAPI = require("plex-api")

  Promise.promisifyAll(PlexAPI.prototype)

  class PlexPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("PlexPlayer", {
        configDef: deviceConfigDef.PlexPlayer,
        createCallback: (config, lastState) -> new PlexPlayer(config, lastState)
      })


  class PlexPlayer extends env.devices.AVPlayer

    _state: null
    _currentTitle: null
    _currentType: null
    _currentProgress: null
    _currentShow: null
    _currentProduct: null
    _currentClient: null

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

    constructor: (@config, lastState) ->
      @name = config.name
      @id = config.id

      @_state = lastState?.state?.value
      @_currentTitle = lastState?.currentTitle?.value
      @_currentType = lastState?.currentType?.value
      @_currentProgress = lastState?.currentProgress?.value or 0
      @_currentShow = lastState?.currentShow?.value
      @_currentProduct = lastState?.currentProduct?.value
      @_currentClient = lastState?.currentClient?.value

      @config.guid = uuid.v4() if not config.guid

      PlexConnectionString = {hostname: config.server, port: config.port, product: 'pimatic', identifier: config.guid}
      PlexConnectionString['username'] = config.username if config.username?
      PlexConnectionString['password'] = config.password if config.password?

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
              if entry.state is 'playing' and @_state isnt 'playing'
                @_state = 'playing'
                @emit "state", @_state
              else if entry.state is 'paused' and @_state isnt 'paused'
                @_state = 'paused'
                @emit "state", @_state
              if @_currentProduct isnt entry.product
                @_currentProduct = entry.product
                @emit "currentProduct", @_currentProduct
              if @_currentClient isnt entry.title
                @_currentClient = entry.title
                @emit "currentClient", @_currentClient
              if @_currentTitle isnt item.title
                @_currentTitle = item.title
                @emit "currentTitle", @_currentTitle
              if @_currentType isnt item.type
                @_currentType = item.type
                @emit "currentType", @_currentType
              if @_currentProgress isnt Math.round((item.viewOffset / item.duration) * 100)
                @_currentProgress = Math.round((item.viewOffset / item.duration) * 100)
                @emit "currentProgress", @_currentProgress
              if @_currentShow isnt item.grandparentTitle
                @_currentShow = item.grandparentTitle
                @emit "currentShow", @_currentShow
        if not plexClientFound and @_state isnt 'stopped'
          @_state = 'stopped'
          @emit "state", 'stopped'
          @_currentProduct = ""
          @emit "currentProduct", ""
          @_currentClient = ""
          @emit "currentClient", ""
          @_currentTitle = ""
          @emit "currentTitle", ""
          @_currentType = ""
          @emit "currentType", 0
          @_currentProgress = 0
          @emit "currentProgress", ""
          @_currentShow = ""
          @emit "currentShow",  ""
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
