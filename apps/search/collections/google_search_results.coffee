_ = require 'underscore'
Backbone = require 'backbone'
GoogleSearchResult = require '../models/google_search_result.coffee'
{ GOOGLE_SEARCH_KEY, GOOGLE_SEARCH_CX } = require "../../../config"

module.exports = class GoogleSearchResults extends Backbone.Collection
  model: GoogleSearchResult

  url: "https://www.googleapis.com/customsearch/v1?key=#{GOOGLE_SEARCH_KEY}&cx=#{GOOGLE_SEARCH_CX}"

  parse:  (response) ->
    _.reject response.items, (item) ->
      # HACK filter out image rights sensitive results
      JSON.stringify(item).match(/kippenberger|zoe.*leonard|pat.*lipsky/i) or
      # Filter out auction results
      item.link?.indexOf('/auction-result') isnt -1 or
      # Filter out 403s
      item.title?.indexOf('403 Forbidden') isnt -1 or
      # Filter out sitemap & xml pages
      item.link?.indexOf('.xml') isnt -1

  moveMatchResultsToTop: (query) ->
    models = @models
    for item, index in @models
      if item.get('display_model') isnt 'show' and item.get('display').toLowerCase() is query.toLowerCase()
        models.splice(0, 0, models.splice(index, 1)[0])
    models
