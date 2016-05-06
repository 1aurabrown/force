_ = require 'underscore'
Backbone = require 'backbone'
Show = require '../../../models/partner_show.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
PartnerShowButtons = require '../../../components/partner_buttons/show_buttons.coffee'

{ Following, FollowButton } = require '../../../components/follow_button/index.coffee'

template = -> require('../templates/related_show.jade') arguments...

module.exports = class RelatedShowView extends Backbone.View
  initialize: (options = {}) ->
    { @artwork, @model, @currentUser } = options

    @show = new Show @model.attributes
    @partner = @show.related().partner
    @show.related().artworks.fetchUntilEndInParallel success: (collection) =>
      @setup collection

  setupFollowButton: ->
    @following = new Following(null, kind: 'profile')
    @following.syncFollows [@partner.get('default_profile_id')]

    @followButton = new FollowButton
      context_page: "Artwork page"
      context_module: "Related Show module"
      el: @$('.plus-follow-button')
      following: @following
      modelName: 'profile'
      model: new Backbone.Model(id: @partner.get('default_profile_id'))

  setup: (collection) ->
    @collection = collection
    @collection.remove @artwork
    @render()
    @setupArtworks @collection
    @setupPartnerButtons()
    @setupFollowButton() if @currentUser? and @partner?.get('default_profile_id')
    @$el.addClass 'is-fade-in'

  render: ->
    @$el.show().html(template(show: @show))

  setupPartnerButtons: ->
    new PartnerShowButtons
      el: @$('.partner-buttons-show-buttons')
      model: @show

  setupArtworks: (artworks) ->
    @artworkColumnsView = new ArtworkColumnsView
      el: @$('#artwork-related-show-artworks')
      collection: artworks
      numberOfColumns: 4
      gutterWidth: 40
      maxArtworkHeight: 400
      isOrdered: false
      seeMore: false
      allowDuplicates: true
      artworkSize: 'tall'
