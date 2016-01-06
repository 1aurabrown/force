_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
infoTemplate = -> require('../templates/info.jade') arguments...
analyticsHooks = require '../../../lib/analytics_hooks.coffee'

module.exports = class FairInfo extends Backbone.View

  mapWidth: 300
  mapHeight: 165

  initialize: (options) ->
    @fair = options.fair
    location = @fair.location()
    if @fair.location()
      @displayMap location
    @targetBlankLinks()
    @trackFairVisit()

  trackFairVisit: ->
    analytics.ready -> analyticsHooks.trigger 'fair:impression'

  displayMap: (location) ->
    src = location.mapImageSrc(@mapWidth, @mapHeight)
    @$('img.map').attr('src': src) if src
    @$('.fair-map-link').attr
      'href': location.googleMapsLink()

  targetBlankLinks: ->
    @$('a').attr target: "_blank"
