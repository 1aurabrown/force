_ = require 'underscore'
sd = require('sharify').data
qs = require 'querystring'
{ parse } = require 'url'
Cookies = require 'cookies-js'
Backbone = require 'backbone'
ShareModal = require '../../../components/share/modal.coffee'
Transition = require '../../../components/mixins/transition.coffee'
CurrentUser = require '../../../models/current_user.coffee'
SaveButton = require '../../../components/save_button/view.coffee'
RelatedArticlesView = require '../../../components/related_articles/view.coffee'
{ acquireArtwork } = require '../../../components/acquire/view.coffee'
BelowTheFoldView = require './below_the_fold.coffee'
MonocleView = require './monocles.coffee'
AnnyangView = require './annyang.coffee'
CTAView = require './cta.coffee'
Sale = require '../../../models/sale.coffee'
ZigZagBanner = require '../../../components/zig_zag_banner/index.coffee'
Auction = require './mixins/auction.coffee'
RelatedShowView = require './related_show.coffee'
EmbeddedInquiryView = require '../../../components/embedded_inquiry/view.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
VideoView = require './video.coffee'
ImagesView = require '../components/images/view.coffee'
PartnerLocations = require '../components/partner_locations/index.coffee'
{ Following, FollowButton } = require '../../../components/follow_button/index.coffee'
RelatedNavigationView = require '../components/related_navigation/view.coffee'
splitTest = require '../../../components/split_test/index.coffee'
setupArtworkRails = require './setup_artwork_rails.coffee'
detailTemplate = -> require('../templates/_detail.jade') arguments...
actionsTemplate = -> require('../templates/_actions.jade') arguments...
auctionPlaceholderTemplate = -> require('../templates/auction_placeholder.jade') arguments...

module.exports = class ArtworkView extends Backbone.View
  _.extend @prototype, Auction

  events:
    'click a[data-client]': 'intercept'
    'click .circle-icon-button-share': 'openShare'
    'change .aes-radio-button': 'selectEdition'
    'click .artwork-buy-button': 'buy'

  initialize: ({ @artwork }) ->
    @showRails = if splitTest('merchandized_rails').outcome() is 'true' then true else false
    @location = window.location
    @artist = @artwork.related().artist
    @artists = @artwork.related().artists
    @checkQueryStringForAuction()
    @setupCurrentUser()
    @setupRelatedArticles()
    @setupArtistArtworks()
    @setupFollowButtons()
    @setupBelowTheFold() unless @showRails
    setupArtworkRails(@artwork, @artist) if @showRails
    @setupMainSaveButton()
    @setupVideoView()
    @setupAnnyang()
    @setupMonocleView()
    @preventRightClick()
    @setupCTAView()

    @artwork.fetch() # Re-fetch incase of caching

    relatedContentFetches = [
      @artwork.related().sales.fetch()
      @artwork.related().features.fetch()
      @artwork.related().fairs.fetch()
      @artwork.related().shows.fetch()
    ]

    @listenTo @artwork, 'change:sale_message', @renderDetail
    @listenTo @artwork, 'change:ecommerce', @renderDetail
    @listenToOnce @artwork.related().sales, 'sync', @afterSalesFetch
    @listenToOnce @artwork.related().fairs, 'sync', @handleFairs
    @listenToOnce @artwork.related().shows, 'sync', @handleShows

    $.when.apply(null, relatedContentFetches).done =>
      relatedCollections = _.values _.pick(@artwork.related(), ['sales', 'features', 'fairs', 'shows'])
      isAnythingRelated = _.any relatedCollections, (xs) -> xs.length
      unless isAnythingRelated or @showRails
        @belowTheFoldView.setupLayeredSearch()

    relatedNavigationView = new RelatedNavigationView model: @artwork
    @$('.js-artwork-related-navigation').html relatedNavigationView.render().$el

    new ImagesView
      el: @$('.js-artwork-images')
      model: @artwork
      collection: @artwork.related().images

  afterSalesFetch: (sales) ->
    @renderActions()
    @handleSales sales
    @setupPartnerLocations()
    @setupEmbeddedInquiryForm()

  handleFairs: (fairs) ->
    return unless fairs.length and not @showRails
    fair = fairs.first()

    @belowTheFoldView.setupFair fair

  handleSales: (sales) ->
    return unless sales.length and not @showRails

    unless sales.hasAuctions()
      @setupZigZag()

    @sale = sales.first()
    @$('#artist-artworks-section').remove()

    unless @sale.isAuctionPromo() # Replace with auction-artworks view
      @belowTheFoldView.setupSale
        sale: @sale
        saved: @saved
        currentUser: @currentUser

    if @sale.isAuction() or @sale.isAuctionPromo()
      @setupAuction @sale

  handleShows: (shows) ->
    return unless shows.length and not @showRails

    @$('#artist-artworks-section').remove()
    new RelatedShowView
      el: @$('#artwork-related-show-section')
      model: shows.first()
      artwork: @artwork
      currentUser: @currentUser

  setupPartnerLocations: ->
    new PartnerLocations $el: @$el, artwork: @artwork

  preventRightClick: ->
    return if @currentUser?.isAdmin()

    @$('#the-artwork-image').on 'contextmenu', (e) ->
      e.preventDefault()

  checkQueryStringForAuction: ->
    return if @artwork.get('sold')
    { auction_id } = qs.parse(parse(@location.search).query)
    @renderAuctionPlaceholder auction_id if auction_id

  renderAuctionPlaceholder: (auction_id) ->
    @suppressInquiry = true
    @$('.artwork-detail').addClass 'is-auction'
    @$('#auction-detail').html(
      auctionPlaceholderTemplate
        auction_id: auction_id
        artwork_id: @artwork.id
    ).addClass 'is-fade-in'

  setupEmbeddedInquiryForm: ->
    return if @suppressInquiry or not @artwork.isContactable()

    view = new EmbeddedInquiryView
      el: @$('.js-artwork-detail-contact')
      artwork: @artwork

    view.render()

  displayZigZag: ->
    (@$inquiryButton = @$('.artwork-contact-button, .artwork-inquiry-button').first())
    @$inquiryButton.length and not @artwork.get('acquireable') and @artwork.get('forsale')

  setupZigZag: ->
    if @displayZigZag()
      new ZigZagBanner
        persist: true
        name: 'inquiry'
        message: 'Interested in this work?<br>Contact the gallery here'
        $target: @$inquiryButton

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()
    @saved = @currentUser?.defaultArtworkCollection()
    @following = new Following(null, kind: 'artist') if @currentUser?

  setupArtistArtworks: ->
    return unless @artist?.get('artworks_count') > 1
    @listenTo @artist.related().artworks, 'sync', @renderArtistArtworks
    @artist.related().artworks.fetch()

  renderArtistArtworks: ->
    # Ensure the current artwork is not in the collection
    @artist.related().artworks.remove @artwork

    return unless @artist.related().artworks.length and not @showRails
    @$('#artist-artworks-section').addClass('is-fade-in').show()

    new ArtworkColumnsView
      el: @$('#artist-artworks-section .artworks-list')
      collection: @artist.related().artworks
      allowDuplicates: true
      numberOfColumns: 4
      gutterWidth: 40
      maxArtworkHeight: 400
      isOrdered: false
      seeMore: false
      artworkSize: 'tall'

  renderActions: ->
    @$('.artwork-actions').html actionsTemplate
      sd: require('sharify').data
      artwork: @artwork
      artist: @artist
      artists: @artists
      user: @currentUser

  renderDetail: ->
    @$('.artwork-detail').html detailTemplate
      sd: require('sharify').data
      artwork: @artwork
      artist: @artist
      artists: @artists
      user: @currentUser

    # Re-setup buttons
    _.each @followButtons, (view) ->
      view.setElement @$(".artist-follow[data-id='#{view.model.id}']")
    @following.syncFollows(@artists.pluck 'id') if @currentUser

  setupArtistArtworkSaveButtons: (artworks) ->
    return unless artworks.length > 0
    _.defer =>
      for artwork in artworks.models
        @setupSaveButton @$(".overlay-button-save[data-id='#{artwork.id}']"), artwork
      @syncSavedArtworks artworks

  # @param {Object or Array or Backbone.Collection}
  syncSavedArtworks: (artworks) ->
    return unless @saved
    @__saved__ ?= new Backbone.Collection
    @__saved__.add artworks?.models or artworks
    @saved.addRepoArtworks @__saved__
    @saved.syncSavedArtworks()

  setupRelatedArticles: ->
    @artwork.relatedArticles.fetch success: (response) =>
      if response.length
        subView = new RelatedArticlesView
          className: 'ari-cell artwork-related-articles'
          collection: @artwork.relatedArticles
          numToShow: 2
        @$('#artwork-artist-related-extended').append subView.render().$el

  setupBelowTheFold: ->
    @belowTheFoldView = new BelowTheFoldView
      artwork: @artwork
      el: @$('#artwork-below-the-fold-section')

  setupMainSaveButton: ->
    @setupSaveButton @$('.circle-icon-button-save'), @artwork
    @syncSavedArtworks @artwork

  setupSaveButton: ($el, artwork, options = {}) ->
    if @currentUser?.hasLabFeature 'Set Management'
      SaveControls = require '../../../components/artwork_item/save_controls.coffee'
      @$('.circle-icon-button-save').after(
        require('../../../components/artwork_item/save_controls_two_btn/templates/artwork_page_button.jade')()
      )
      new SaveControls
        model: artwork
        el: @$('.artwork-image-actions')
    else
      new SaveButton
        analyticsSaveMessage: 'Added artwork to collection, via artwork info'
        analyticsUnsaveMessage: 'Removed artwork from collection, via artwork info'
        el: $el
        saved: @saved
        model: artwork

  setupFollowButtons: ->
    @followButtons = @artists.map (artist) =>
      new FollowButton
        el: @$(".artist-follow[data-id='#{artist.id}']")
        following: @following
        modelName: 'artist'
        model: artist
        analyticsFollowMessage: 'Followed artist, via artwork info'
        analyticsUnfollowMessage: 'Unfollowed artist, via artwork info'

    @following.syncFollows(@artists.pluck 'id') if @currentUser?

  setupVideoView: ->
    return unless @artwork.get('website')?.match('vimeo|youtu') and
                  @artwork.get('category').match('Video')
    new VideoView el: @el, artwork: @artwork

  setupAnnyang: ->
    return unless @currentUser?.hasLabFeature 'Talk To Artsy'
    new AnnyangView artwork: @artwork

  setupMonocleView: ->
    return unless @currentUser?.hasLabFeature('Monocles')
    @$('.artwork-image').append("<div class='monocle-zoom'></div>")
    @$('.monocle-zoom').css('background-image', "url(#{@artwork.defaultImage().imageUrl('larger')})")
    new MonocleView artwork: @artwork, el: @$('.artwork-image')

  setupCTAView: ->
    new CTAView @artist

  route: (route) ->
    # Initial server rendered route is 'show'
    # No transition unless it's happening client-side
    return if @$el.attr('data-route') is route
    @$el.attr 'data-route-pending', (@__route__ = route)
    Transition.fade @$el,
      duration: 250
      out: =>
        @$el.attr 'data-route', @__route__

  # Handle links with the data-client attribute via pushState
  intercept: (e) ->
    e.preventDefault()
    Backbone.history.navigate $(e.currentTarget).attr('href'), trigger: true, replace: true

  openShare: (e) ->
    e.preventDefault()
    new ShareModal
      width: '350px'
      media: @artwork.defaultImageUrl('large')
      description: @artwork.toAltText()

  selectEdition: (e) ->
    @__selectedEdition__ = e.currentTarget.value

  selectedEdition: ->
    @__selectedEdition__ or
    @artwork.editions.first()?.id

  buy: (e) ->
    ($target = $(e.currentTarget)).addClass 'is-loading'
    acquireArtwork @artwork, $target, @selectedEdition()
