_ = require 'underscore'
flatCompact = _.compose _.flatten, _.compact
Backbone = require 'backbone'
Notifications = require '../../../../collections/notifications.coffee'
Artworks = require '../../../../collections/artworks.coffee'
Q = require 'bluebird-q'

module.exports = class FeaturedArtworks extends Backbone.Collection
  limit: 4

  initialize: (models, { @user } = {}) -> #

  fetchFeatured: ->
    dfd = $.Deferred()
    @featured = new Artworks
    @featured.fetchSetItemsByKey 'homepage:featured-artworks', success: dfd.resolve, error: dfd.resolve
    dfd.promise()

  fetchPersonalized: ->
    return unless @user
    @personalized = new Notifications [], state: pageSize: @limit
    @personalized.fetch()

  takeResponse: ->
    _.take flatCompact([
      @setSource(@personalized, 'personalized')?.models
      @setSource(@featured, 'featured').models
    ]), @limit

  setSource: (collection, source) ->
    collection?.invoke 'set', source: source
    collection

  fetch: (options = {}) ->
    Q.allSettled(_.compact([
      @fetchPersonalized()
      @fetchFeatured()
    ]))
    .then =>
      @reset @takeResponse(), silent: true
      @trigger 'sync', this, @toJSON(), options
      return
