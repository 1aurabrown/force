_ = require 'underscore'
Backbone = require 'backbone'
mediator = require '../../../lib/mediator.coffee'
CurrentUser = require '../../../models/current_user.coffee'
FeatureRouter = require './router.coffee'
FilterView = require './filter.coffee'
SaleArtworkView = require '../../../components/artwork_item/views/sale_artwork.coffee'
ClockView = require '../../../components/clock/view.coffee'
trackArtworkImpressions = require('../../../components/analytics/impression_tracking.coffee').trackArtworkImpressions
Sale = require '../../../models/sale.coffee'
CurrentUser = require '../../../models/current_user.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
Artworks = require '../../../collections/artworks.coffee'
Profile = require '../../../models/profile.coffee'
Partner = require '../../../models/partner.coffee'
ShareView = require '../../../components/share/view.coffee'

artworkColumns = -> require('../../../components/artwork_columns/template.jade') arguments...
setsTemplate = -> require('../templates/sets.jade') arguments...
artistsTemplate = -> require('../templates/artists.jade') arguments...
auctionRegisterButtonTemplate = -> require('../templates/auction_register_button.jade') arguments...
auctionCountdownTemplate = -> require('../templates/auction_countdown.jade') arguments...
filterTemplate = -> require('../templates/artwork_filter.jade') arguments...

module.exports = class FeatureView extends Backbone.View

  events:
    'click .auction-info-register-button .avant-garde-button-black': 'triggerLoginPopup'
    'click .featured-set-artist-expand': 'seeAllArtists'

  maxArtists: 60
  minArtworksForFilter: 8
  artworkFilteringSetup: false

  initialize: (options) ->
    @handleTab options.tab if options.tab

    @setupCurrentUser()

    @feature = @model

    # Make the sale available as soon as possible
    @feature.on 'change:sale', =>
      @sale = @feature.get 'sale'
      @updateMetaType()

    @feature.fetchSets
      setsSuccess: (sets) =>
        @sets = sets
        @$('#feature-sets-container').html setsTemplate(sets: @sets)
        @initializeSale @sets
      artworkPageSuccess: @artworkPageSuccess
      artworksSuccess: @doneFetchingSaleArtworks

    @setupShareButtons()

  artworkPageSuccess: (fullCollection, newSaleArtworks) =>
    @createArtworkColumns()

    artworks = Artworks.fromSale(new Backbone.Collection newSaleArtworks)

    unless @artworkFilteringSetup
      if @isAuction() and fullCollection.length > @minArtworksForFilter
        @setupArtworkFiltering fullCollection, artworks
        @renderArtistList artworks

    @appendArtworks artworks

  isAuction: =>
    @sale?.isAuction()

  doneFetchingSaleArtworks: (saleFeaturedSet) =>
    @setupArtworks saleFeaturedSet

    @artworks = saleFeaturedSet.get('data')

    @filterView?.setArtworks @artworks

    @artworks.on 'filterSort', =>
      @$('#feature-artworks').html ''
      @artworkColumns.undelegateEvents()
      @artworkColumns = undefined

      @createArtworkColumns()
      @appendArtworks @artworks
      @renderArtistList @artworks if saleFeaturedSet and saleFeaturedSet.get('display_artist_list')

    @filterView?.trigger 'doneFetching'

  setupArtworkFiltering: (saleArtworksCollection) ->
    @$('#feature-artworks').before filterTemplate auction: @sale

    @filterView = new FilterView
      el: @$('.feature-artwork-filter')
      startingSort: 'artist-a-to-z'

    @artworkFilteringSetup = true

  updateMetaType: ->
    type = if @isAuction() then 'auction' else 'sale'
    $('head').append("<meta property='og:event' content='#{type}'>")

  createArtworkColumns: ->
    @artworkColumns ?= new ArtworkColumnsView
      el: @$('#feature-artworks')
      collection: new Artworks
      displayPurchase: true
      setHeight: 400
      gutterWidth: 0
      showBlurbs: true
      isAuction: @isAuction()

  appendArtworks: (artworks) ->
    @artworkColumns.appendArtworks artworks.models
    @setupSaleArtworks artworks, @sale

  initializeSale: (sets) ->
    saleSets = _.filter sets, (set) -> set.get('item_type') is 'Sale'
    for set in saleSets
      @initializeAuction @sale, set if @isAuction()

  setupArtworks: (set) ->
    artworks = set.get 'data'
    @setupArtworkImpressionTracking artworks.models

  initializeAuction: (sale, set) ->
    $.when.apply(null, _.compact([
      @setupAuctionUser sale
      sale.fetch()
    ])).then =>
      @renderAuctionInfo sale

  renderAuctionInfo: (sale) ->
    @$('#feature-description-register-container').html auctionRegisterButtonTemplate
      sale: sale
      registered: @currentUser?.get('registered_to_bid')?
    @$('#feature-auction-info-countdown-container').html auctionCountdownTemplate(sale: sale)
    @setupClock sale

  setupClock: (sale) ->
    @clock = new ClockView
      modelName: 'Auction'
      model: sale
      el: @$('.auction-info-countdown')
    @clock.start()

  setupArtworkImpressionTracking: (artworks) ->
    trackArtworkImpressions artworks, @$el

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()
    @artworkCollection = @currentUser?.defaultArtworkCollection()

  setupAuctionUser: (sale) ->
    return unless @currentUser
    @currentUser.checkRegisteredForAuction
      saleId: sale.get('id')
      success: (isRegistered) =>
        @currentUser.set 'registered_to_bid', isRegistered

  setupSaleArtworks: (artworks, sale) ->
    artworks.each (artwork) =>
      new SaleArtworkView
        currentUser: @currentUser
        el: @$(".artwork-item[data-artwork='#{artwork.id}']")
        model: artwork
        sale: sale
    @renderPartnerLogo artworks
    if @artworkCollection
      @artworkCollection.addRepoArtworks artworks
      @artworkCollection.syncSavedArtworks()

  renderPartnerLogo: (artworks) ->
    partner = artworks?.first()?.get('partner')
    return if not partner or @renderedPartnerLogo
    @renderedPartnerLogo = true
    new Partner(partner).fetch
      error: => @$('#feature-auction-logo').remove()
      success: (partner) =>
        new Profile(id: partner.get 'default_profile_id').fetch
          error: => @$('#feature-auction-logo').remove()
          success: (prof) =>
            @$('#feature-auction-logo').attr 'src', prof.icon().imageUrl()

  setupShareButtons: ->
    new ShareView el: @$('.feature-share')

  getArtworksOrderedByArtist: (collection) ->
    collection.comparator = (model) -> model.get('artist')?.sortable_id
    collection.sort()
    collection.models

  uniqueArtworksByArtist: (artworks) ->
    artists = {}
    artworks.filter (artwork) ->
      artistId = artwork.get('artist')?.id
      return false unless artistId
      return false if artists[artistId]
      artists[artistId] = true
      true

  renderArtistList: (artworks) ->
    artworks = @getArtworksOrderedByArtist(artworks)
    artworks = @uniqueArtworksByArtist artworks

    return unless artworks.length

    n = Math.floor artworks.length/2
    n = 1 if n < 1

    lists = _.groupBy(artworks, (a, b) -> Math.floor(b/n))
    artworkGroups = _.toArray(lists)

    # fix uneven lists
    if artworkGroups.length > 2
      artworkGroups[0].push artworkGroups.pop(2)[0]

    $lastColumn = @$('.artwork-column:last-of-type')
    $lastColumn.prepend artistsTemplate(
      artworkGroups: artworkGroups
      artistListTruncated: artworks.length > @maxArtists
    )
    @$('.artwork-column').parent().css 'visibility', 'visible'

    # Rebalance columns now that the artist list has been added
    @artworkColumns.rebalance(@$('.feature-set-item-artist-list').css('height')?.replace('px',''), $lastColumn.index())

  seeAllArtists: (e) ->
    @$('.artist-list-truncated').removeClass('artist-list-truncated')
    $(e.target).remove()

  handleTab: (tab) ->
    new FeatureRouter feature: @feature
    Backbone.history.start pushState: true

  triggerLoginPopup: (e) =>
    unless @currentUser
      mediator.trigger 'open:auth', { mode: 'register', copy: 'Sign up to bid on artworks', redirectTo: @sale.registerUrl() }
      e.preventDefault()
