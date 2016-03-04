_ = require 'underscore'
Backbone = require 'backbone'
{ API_URL } = require('sharify').data
FilterArtworks = require '../../../collections/filter_artworks.coffee'

class Params extends Backbone.Model
  defaults: { size: 9, page: 1 }

  next: ->
    @set 'page', @get('page') + 1

  prev: ->
    @set 'page', @get('page') - 1


module.exports = class ArtworkColumns extends FilterArtworks
  url: ->
    "#{API_URL}/api/v1/filter/artworks?artist_id=#{@artistId}"

  initialize: (models, options = {}) ->
    { @artistId } = options
    @params = new Params
    super

  prepareCounts: -> # no op

  fetch: (options = {}) ->
    @xhr.abort() if @xhr? and @xhr.readyState isnt 4
    options.data = _.extend (options.data or {}), @params.attributes
    @xhr = FilterArtworks::fetch.call this, options

  fetchFromBeginning: (options = {}) ->
    @params.clear().set(@params.defaults)
    @fetch options

  nextPage: (options = {}) ->
    return if @xhr? and @xhr.readyState isnt 4
    @params.next()
    options.error = _.wrap options.error, (error, collection, response, options) =>
      @params.prev()
      error? collection, response, options
    options.remove = false
    @fetch options
