_ = require 'underscore'
Backbone = require 'backbone'
{ API_URL } = require('sharify').data
Artworks = require '../../../collections/artworks.coffee'

class Params extends Backbone.Model
  defaults: { size: 9, page: 1 }

  next: ->
    @set 'page', @get('page') + 1

  prev: ->
    @set 'page', @get('page') - 1


module.exports = class ArtworkColumns extends Artworks
  url: ->
    "#{API_URL}/api/v1/search/filtered/artist/#{@artistId}"

  initialize: (models, options = {}) ->
    { @artistId } = options
    @params = new Params
    super

  fetch: (options = {}) ->
    @xhr.abort() if @xhr? and @xhr.readyState isnt 4
    options.data = _.extend (options.data or {}), @params.attributes
    @xhr = Artworks::fetch.call this, options

  fetchFromBeginning: (options = {}) ->
    @params.clear().set(@params.defaults)
    @fetch options

  nextPage: (options = {}) ->
    @params.next()
    options.error = _.wrap options.error, (error, collection, response, options) =>
      @params.prev()
      error? collection, response, options
    options.remove = false
    @fetch options
