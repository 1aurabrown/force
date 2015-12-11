sd = require('sharify').data
Backbone = require 'backbone'
Artwork = require '../../../models/artwork.coffee'
ArtworkRouter = require './router.coffee'
{ track } = require '../../../lib/analytics.coffee'

module.exports.init = ->
  artwork = new Artwork sd.ARTWORK, parse: true

  new ArtworkRouter artwork: artwork
  Backbone.history.start pushState: true

  track.impression 'Artwork page', id: artwork.id
  require('./analytics.coffee')(artwork)

  # Reflection doesn't like easter eggs :(
  return if navigator.userAgent.match('PhantomJS')
  require('./ascii_easter_egg.coffee')(artwork)
  require('./skrillex_easter_egg.coffee')(artwork)
  require('./doge_easter_egg.coffee')(artwork)

  # HACK: Hide auction results for ADAA
  $.ajax
    url: "#{sd.API_URL}/api/v1/related/fairs",
    data: artwork: sd.ARTWORK.id
    success: (fairs) ->
      if 'adaa-the-art-show-2015' in (fair.id for fair in fairs)
        $('.artwork-auction-results-button').hide()