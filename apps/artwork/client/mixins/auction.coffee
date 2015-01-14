_ = require 'underscore'
ClockView = require '../../../../components/clock/view.coffee'
BidderPositions = require '../../../../collections/bidder_positions.coffee'
SaleArtwork = require '../../../../models/sale_artwork.coffee'
AuctionDetailView = require '../auction_detail.coffee'

module.exports =
  setupAuction: (sale) ->
    @auction = @sale
    @setupAuctionDetailView()

    return if @artwork.get 'sold'
    # This hides the normal availablity status UI
    # which we just wind up using if the artwork is already sold
    # (via 'Buy Now')
    @$('.artwork-detail').addClass 'is-auction'

  setupClock: ->
    @clock = new ClockView
      modelName: 'Auction'
      model: @auction
      el: @$Clock = @$('#artwork-clock')
    @$Clock.addClass 'is-fade-in'
    @clock.start()

  setupSaleArtwork: ->
    @saleArtwork = new SaleArtwork
      id: @artwork.id
      artwork: @artwork
      sale: @auction
    @saleArtwork.fetch()

  setupAuctionDetailView: ->
    $.when.apply(null, _.compact([
      @setupClock()
      @setupAuctionUser()
      @setupSaleArtwork()
      @setupBidderPositions()
    ])).then =>
      # Set up everything but the auction detail view
      # if the artwork is already sold (via 'Buy Now')
      unless @artwork.get 'sold'
        @auctionDetailView = new AuctionDetailView(
          user: @currentUser
          bidderPositions: @bidderPositions
          saleArtwork: @saleArtwork
          auction: @auction
          el: @$('#auction-detail')
        ).render()

  setupBidderPositions: ->
    return unless @currentUser
    @bidderPositions = new BidderPositions null,
      saleArtwork: @saleArtwork
      sale: @auction
    @bidderPositions.fetch()

  setupAuctionUser: ->
    return unless @currentUser
    @currentUser.checkRegisteredForAuction
      success: (isRegistered) =>
        @currentUser.set 'registered_to_bid', isRegistered
