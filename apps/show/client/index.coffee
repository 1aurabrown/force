_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
Artworks = require '../../../collections/artworks.coffee'
CarouselView = require '../../../components/carousel/view.coffee'
CurrentUser = require '../../../models/current_user.coffee'
SaveControls = require '../../../components/artwork_item/save_controls.coffee'
PartnerShow = require '../../../models/partner_show.coffee'
ShareView = require '../../../components/share/view.coffee'
PartnerShowButtons = require '../../../components/partner_buttons/show_buttons.coffee'
artworkColumns = -> require('../../../components/artwork_columns/template.jade') arguments...
trackArtworkImpressions = require("../../../components/analytics/impression_tracking.coffee").trackArtworkImpressions

module.exports.PartnerShowView = class PartnerShowView extends Backbone.View

  initialize: (options) ->
    @shareView = new ShareView
      el: @$('.show-share')
    @setupCurrentUser()
    new PartnerShowButtons
      el: @$(".show-header")
      model: @model
    @$showArtworks = @$('.show-artworks')
    @$carousel = @$('#show-installation-shot-carousel')

    @model.fetchInstallShots
      success: (installShots) =>
        if installShots.length > 0
          @carouselView = new CarouselView
            collection: installShots
            height: 480
            hasDimensions: false
          @$carousel.html @carouselView.render().$el
        else
          @$carousel.remove()
      error: =>
        @$carousel.remove()

    window.model = @model
    @model.fetchArtworks
      success: (artworks) =>
        window.artworks = artworks
        if artworks.length > 0
          @collection = artworks
          @$showArtworks.html artworkColumns
            artworkColumns: artworks.groupByColumnsInOrder(3)
            artworkSize: 'large'
          @setupArtworkSaveControls()
          @setupArtworkImpressionTracking()
        else
          @$showArtworks.remove()
      error: => @$showArtworks.remove()

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()
    @artworkCollection = @currentUser?.defaultArtworkCollection()

  setupArtworkImpressionTracking: (artworks=@collection.models) ->
    trackArtworkImpressions artworks, @$showArtworks

  setupArtworkSaveControls: ->
    listItems =
      for artwork, index in @collection.models
        overlay = @$(".artwork-item[data-artwork='#{artwork.get('id')}']").find('.overlay-container')
        new SaveControls
          artworkCollection: @artworkCollection
          el: overlay
          model: artwork
    if @artworkCollection
      @artworkCollection.addRepoArtworks @collection
      @artworkCollection.syncSavedArtworks()

module.exports.init = ->

  new PartnerShowView
    el: $('#show')
    model: new PartnerShow sd.SHOW
