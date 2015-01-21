_ = require 'underscore'
Backbone = require 'backbone'
benv = require 'benv'
sinon = require 'sinon'
sd = require('sharify').data
PartnerShow = require '../../../models/partner_show.coffee'
Profile = require '../../../models/profile.coffee'
{ fabricate } = require 'antigravity'
{ resolve } = require 'path'

describe 'Partner Show View', ->

  before (done) ->
    benv.setup =>
      sd.API_URL = 'localhost:3003'

      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      @PartnerShowView = benv.requireWithJadeify resolve(__dirname, '../client/index.coffee'), ['artworkColumns']
      @PartnerShowView.__set__ 'CarouselView', benv.requireWithJadeify resolve(__dirname, '../../../components/carousel/view.coffee'), ['template']
      @PartnerShowView.__set__ 'PartnerShowButtons', @PartnerShowButtons = sinon.stub()
      carouselView = @PartnerShowView.__get__ 'CarouselView'
      carouselView::setStops = sinon.stub()
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @show = new PartnerShow fabricate 'show', { images_count: 6, eligible_artworks_count: 6 }
    @profile = new Profile fabricate 'partner_profile'
    @installShots = [
      fabricate 'artwork_image', { default: true }
      fabricate 'artwork_image'
      fabricate 'artwork_image'
      fabricate 'artwork_image'
      fabricate 'artwork_image'
      fabricate 'artwork_image'
    ]
    @artworks = [
      fabricate 'artwork'
      fabricate 'artwork'
      fabricate 'artwork'
      fabricate 'artwork'
      fabricate 'artwork'
      fabricate 'artwork'
    ]
    @view = new @PartnerShowView.PartnerShowView
      el: $("<div id='show'>
        <div class='show-artworks'></div>
        <div class='show-share'></div>
        <div id='show-installation-shot-carousel'></div>
        </div>")
      model: @show

  afterEach ->
    Backbone.sync.restore()

  describe '#initialize', ->

    it 'always fetches artworks', ->
      # Fetches artworks
      Backbone.sync.args[0][2].url.should.equal "#{@show.url()}/artworks"

    it 'renders artwork columns', ->
      @view.model.should.equal @show

      Backbone.sync.args[0][2].success @artworks
      Backbone.sync.args[0][2].success []

      @view.$('.artwork-item').length.should.equal 6

    it 'removes artwork column containers if none are returned', ->
      Backbone.sync.args[0][2].success []
      @view.$('.artwork-item').should.have.lengthOf 0

    it 'adds the partner shows view', ->
      @PartnerShowButtons.calledWithNew.should.be.ok
