_ = require 'underscore'
_s = require 'underscore.string'
Backbone = require 'backbone'
ArtistFillwidthList = require '../../../../components/artist_fillwidth_list/view.coffee'
ArtworkRailView = require '../../../../components/artwork_rail/client/view.coffee'
template = -> require('../../templates/sections/related_artists.jade') arguments...

module.exports = class RelatedArtistsView extends Backbone.View
  subViews: []

  initialize: ({ @user, @statuses }) ->
    @model.related().artworks.fetch(data: size: 15)

  postRender: ->
    sections = _.pick @statuses, 'artists', 'contemporary'
    _.each sections, (display, key) =>
      $section = @$("#artist-related-#{key}-section")
      if display
        collection = @model.related()[key]
        collection.fetch success: =>
          subView = new ArtistFillwidthList
            el: @$("#artist-related-#{key}")
            collection: collection
            user: @user
          subView.fetchAndRender()
          @subViews.push subView
          @fadeInSection $section
      else
        $section.remove()

    @subViews.push new ArtworkRailView
      $el: @$(".artist-artworks-rail")
      collection: @model.related().artworks
      title: "Works by #{@model.get('name')}"
      viewAllUrl: "#{@model.href()}/works"
      imageHeight: 180

  fadeInSection: ($el) ->
    $el.show()
    _.defer -> $el.addClass 'is-fade-in'
    $el

  render: ->
    @$el.html template
    _.defer => @postRender()
    this

  remove: ->
    _.invoke @subViews, 'remove'
