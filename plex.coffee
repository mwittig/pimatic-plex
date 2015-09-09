module.exports = (env) ->

# Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  M = env.matcher
  _ = env.require('lodash')

  PlexControl = require("plex-control").PlexControl
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

      @_plexClient = new PlexAPI(config.server)

      setInterval( ( => @_getStatus() ), @config.interval)

      super()
      
    getState: -> Promise.resolve(@_state)
    getCurrentTitle: -> Promise.resolve(@_currentTitle)
    getCurrentType: -> Promise.resolve(@_currentType)
    getCurrentProgress: -> Promise.resolve(@_currentProgress)
    getCurrentShow: -> Promise.resolve(@_currentShow)
    getCurrentProduct: -> Promise.resolve(@_currentProduct)
    getCurrentClient: -> Promise.resolve(@_currentClient)

    _getStatus: () ->
      @_plexClient.query("/status/sessions").then( (result) =>
        @_state = null
        @_currentTitle = null
        @_currentType = null
        @_currentProgress = null
        @_currentShow = null
        @_currentProduct = null
        @_currentClient = null
        for item in result._children
          
          for entry in item._children
            if entry._elementType is 'Player' and entry.machineIdentifier isnt @config.player
              env.logger.debug("Found unknown %s with id %s and name %s.", entry.product, entry.machineIdentifier, entry.title)
            if entry._elementType is 'Player' and entry.machineIdentifier is @config.player
              console.log(entry.machineIdentifier)
              if entry.state is 'playing'
                  @_state = 'play'
              if entry.state is 'paused'
                  @_state = 'pause'
              @_currentProduct = entry.product
              @_currentClient = entry.title
              @_currentTitle = item.title
              @_currentType = item.type
              @_currentProgress = Math.floor((item.viewOffset / item.duration) * 100)
              @_currentShow = item.grandparentTitle
        @emit "state", @_state
        @emit "currentTitle", @_currentTitle
        @emit "currentType", @_currentType
        @emit "currentProgress", @_currentProgress
        @emit "currentShow", @_currentShow
        @emit "currentProduct", @_currentProduct
        @emit "currentClient", @_currentClient
      )

  class PlexPrevActionHandler extends env.actions.ActionHandler
    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would play previous track of %s", @device.name)
        else
          @device.previous().then( => __("play previous track of %s", @device.name) )
      )


  plexPlugin = new PlexPlugin
  return plexPlugin