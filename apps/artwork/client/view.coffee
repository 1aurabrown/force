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
AddToPostButton = require '../../../components/related_posts/add_to_post_button.coffee'
RelatedPostsView = require '../../../components/related_posts/view.coffee'
analytics = require '../../../lib/analytics.coffee'
{ acquireArtwork } = require '../../../components/acquire/view.coffee'
FeatureNavigationView = require './feature_navigation.coffee'
BelowTheFoldView = require './below_the_fold.coffee'
{ trackArtworkImpressions } = require '../../../components/analytics/impression_tracking.coffee'
MonocleView = require './monocles.coffee'
AnnyangView = require './annyang.coffee'
BlurbView = require '../../../components/blurb/view.coffee'
Sale = require '../../../models/sale.coffee'
ZigZagBanner = require '../../../components/zig_zag_banner/index.coffee'
Auction = require './mixins/auction.coffee'
RelatedShowView = require './related_show.coffee'
ContactView = require '../components/contact/view.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
VideoView = require './video.coffee'
PartnerLocations = require '../components/partner_locations/index.coffee'
{ Following, FollowButton } = require '../../../components/follow_button/index.coffee'
detailTemplate = -> require('../templates/_detail.jade') arguments...
auctionPlaceholderTemplate = -> require('../templates/auction_placeholder.jade') arguments...

module.exports = class ArtworkView extends Backbone.View
  _.extend @prototype, Auction

  events:
    'click a[data-client]': 'intercept'
    'click .circle-icon-button-share': 'openShare'
    'click .artwork-additional-image': 'changeImage'
    'change .aes-radio-button': 'selectEdition'
    'click .artwork-buy-button': 'buy'
    'click .artwork-more-info .avant-garde-header-small': 'toggleMoreInfo'

  initialize: (options) ->
    { @artwork, @artist } = options

    @checkQueryStringForAuction()
    @setupEmbeddedInquiryForm()
    @setupRelatedPosts()
    @setupPostButton()
    @setupCurrentUser()
    @setupArtistArtworks()
    @setupFollowButton()
    @setupBelowTheFold()
    @setupMainSaveButton()
    @setupArtworkOverview()
    @setupVideoView()
    @setupPartnerLocations()
    @setupAnnyang()
    @setupMonocleView()

    # Handle all related content
    @setupRelatedLayers()
    @on 'related:features', (feature) ->
      @setupFeatureNavigation model: feature, kind: 'feature'
    @on 'related:fairs', (fair) ->
      @belowTheFoldView.setupFair fair
      @setupFeatureNavigation model: fair, kind: 'fair'
      @deltaTrackPageView fair
    @on 'related:sales', (sale) ->
      @sale = new Sale sale.attributes
      @$('#artist-artworks-section').remove()
      @belowTheFoldView.setupSale
        sale: @sale
        saved: @saved
        currentUser: @currentUser
      @setupAuction @sale if @sale.isAuction()
    @on 'related:shows', (show) ->
      @$('#artist-artworks-section').remove()
      new RelatedShowView
        el: @$('#artwork-related-show-section')
        model: show
        artwork: @artwork
        currentUser: @currentUser
    @on 'related:none', ->
      @belowTheFoldView.setupLayeredSearch()
    @on 'related:not_auction', ->
      @setupZigZag()

    # Re-fetch and update detail
    @artwork.on "change:sale_message", @renderDetail, @
    @artwork.on "change:ecommerce", @renderDetail, @
    @artwork.fetch()

    @preventRightClick()

  toggleMoreInfo: (e) ->
    $target = $(e.target)
    $target.find('.arrow-toggle').toggleClass('active')
    $blurb = $target.next()
    $blurb.toggleClass 'is-hidden'

  setupPartnerLocations: ->
    new PartnerLocations $el: @$el, artwork: @artwork

  preventRightClick: ->
    (@$artworkImage ?= @$('#the-artwork-image'))
      .on 'contextmenu', (e) ->
        e.preventDefault()

  checkQueryStringForAuction: ->
    return if @artwork.get('sold')
    { auction_id } = qs.parse(parse(window.location.search).query)
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
    return if @suppressInquiry
    new ContactView el: @$('#artwork-detail-contact'), model: @artwork

  # Currently, Safari 5 is the only browser we support that doesn't support CSS `Calc`
  # This is a hack to give the artwork-container a sane max-width using JS as a substitute
  setupArtworkOverview: ->
    if navigator?.userAgent.search("Safari") >= 0 and navigator?.userAgent.search("Chrome") < 0
      @$('.artwork-overview').css 'max-width': @$('.artwork-container').width() - 250

  displayZigZag: ->
    (@$inquiryButton = @$('.artwork-contact-button, .artwork-inquiry-button').first())
    @$inquiryButton.length and not @artwork.get('acquireable')

  setupZigZag: ->
    if @displayZigZag()
      new ZigZagBanner
        persist: true
        name: 'inquiry'
        message: 'Interested in this work?<br>Request more info here'
        $target: @$inquiryButton

  deltaTrackPageView: (fair) ->
    el = $('#scripts')
    analytics.delta 'fair_artist_view', { fair: fair.get('_id'), id: @artist.get('_id') }, el
    analytics.delta 'fair_partner_view', { fair: fair.get('_id'), id: @artwork.get('partner')._id }, el

  setupRelatedLayers: ->
    $.when.apply(null, @artwork.fetchRelatedCollections()).then =>
      # Find the first related collection that has any results
      relatedCollections = _.filter @artwork.relatedCollections, (xs) -> xs.length
      if relatedCollections.length
        for relatedCollection in relatedCollections
          # Trigger an event and pass on the first result
          @trigger "related:#{relatedCollection.kind}", relatedCollection.first()
      else
        @trigger 'related:none'

      unless @hasAnyAuctions relatedCollections
        @trigger 'related:not_auction'

  hasAnyAuctions: (relatedCollections) ->
    return false unless relatedCollections?.length
    saleCollection = _.find(relatedCollections, (xs) -> xs.kind is 'sales')
    return false unless saleCollection?.length
    _.some(saleCollection.pluck 'is_auction')

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()
    @saved = @currentUser?.defaultArtworkCollection()
    @following = new Following(null, kind: 'artist') if @currentUser?

  setupArtistArtworks: ->
    return unless @artist?.get('artworks_count') > 1
    @listenTo @artist.artworks, 'sync', @renderArtistArtworks
    @artist.artworks.fetch
      published: true

  renderArtistArtworks: ->
    # Ensure the current artwork is not in the collection
    @artist.artworks.remove @artwork

    return unless @artist.artworks.length
    @$('#artist-artworks-section').addClass('is-fade-in').show()

    new ArtworkColumnsView
      el: @$('#artist-artworks-section .artworks-list')
      collection: @artist.artworks
      allowDuplicates: true
      numberOfColumns: 4
      gutterWidth: 40
      maxArtworkHeight: 400
      isOrdered: false
      seeMore: false
      artworkSize: 'tall'

    trackArtworkImpressions @artist.artworks.models, @$('#artwork-artist-artworks-container')

  renderDetail: ->
    @$('.artwork-detail').html detailTemplate
      sd: require('sharify').data
      artwork: @artwork
      artist: @artist
      user: @currentUser

    @followButton.setElement @$('.artwork-artist-follow-button')
    @following?.syncFollows [@artist.id]

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

  setupPostButton: ->
    new AddToPostButton
      el: @$('.ari-container')
      model: @artwork
      modelName: 'artwork'

  setupRelatedPosts: ->
    @listenTo @artwork.relatedPosts, 'sync', @handlePosts, this
    new RelatedPostsView
      el: @$('#artwork-artist-related-posts-container')
      collection: @artwork.relatedPosts
      numToShow: 2
    @$('.ari-right').css
      'min-height': @$('.ari-left').height()

  handlePosts: ->
    if @$('.ari-left').length < 1 and @artwork.relatedPosts.length < 1
      @$('.artwork-related-information').remove()

  setupFeatureNavigation: (options) ->
    new FeatureNavigationView
      model: options.model
      kind: options.kind
      artwork: @artwork
      el: @$('#artwork-feature-navigation')

  setupBelowTheFold: ->
    @belowTheFoldView = new BelowTheFoldView
      artwork: @artwork
      el: @$('#artwork-below-the-fold-section')

  setupMainSaveButton: ->
    @setupSaveButton @$('.circle-icon-button-save'), @artwork
    @syncSavedArtworks @artwork

  setupSaveButton: ($el, artwork, options = {}) ->
    if @currentUser? and 'Set Management' in @currentUser.get('lab_features')
      SaveControls = require '../../../components/artwork_item/save_controls.coffee'
      switch (Cookies.get('save-controls') or analytics.getProperty('ab:save:controls'))
        when 'two button'
          @$('.circle-icon-button-save').after(
            require('../../../components/artwork_item/save_controls_two_btn/templates/artwork_page_button.jade')()
          )
        when 'drop down'
          @$('.circle-icon-button-save').replaceWith(
            require('../../../components/artwork_item/save_controls_drop_down/templates/artwork_page_button.jade')()
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

  setupFollowButton: ->
    @followButton = new FollowButton
      analyticsFollowMessage: 'Followed artist, via artwork info'
      analyticsUnfollowMessage: 'Unfollowed artist, via artwork info'
      el: @$('.artwork-artist-follow-button')
      following: @following
      modelName: 'artist'
      model: @artist
    @following?.syncFollows [@artist.id]

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

  changeImage: (e) ->
    e.preventDefault()
    (@$artworkAdditionalImages ?= @$('.artwork-additional-image')).
      removeClass 'is-active'
    ($target = $(e.currentTarget)).
      addClass 'is-active'
    (@$artworkImage ?= @$('#the-artwork-image')).
      attr('src', $target.data 'href')
    @artwork.setActiveImage($target.data 'id')

  selectEdition: (e) ->
    @__selectedEdition__ = e.currentTarget.value

  selectedEdition: ->
    @__selectedEdition__ or
    @artwork.editions.first()?.id

  buy: (e) ->
    ($target = $(e.currentTarget)).addClass 'is-loading'
    acquireArtwork @artwork, $target, @selectedEdition()
