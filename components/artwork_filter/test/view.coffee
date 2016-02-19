_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ fabricate, fabricate2 } = require 'antigravity'
{ resolve } = require 'path'
Artist = require '../../../models/artist'

describe 'ArtworkFilterView', ->
  before (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        sd: {}
      Backbone.$ = $
      @ArtworkFilterView = benv.requireWithJadeify resolve(__dirname, '../view'), ['template', 'filterTemplate', 'headerTemplate']
      @ArtworkFilterView.__set__ 'ArtworkColumnsView', sinon.stub().returns { length: -> 999 }
      @ArtworkFilterView.__set__ 'ArtworkTableView', sinon.stub().returns { length: -> 999 }
      @ArtworkFilterView.__set__ 'BorderedPulldown', sinon.stub().returns { undelegateEvents: -> 1 }
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @model = new Artist fabricate 'artist', id: 'foo-bar'
    @view = new @ArtworkFilterView model: @model, mode: 'grid'

  afterEach ->
    Backbone.sync.restore()

  describe '#initialize', ->
    beforeEach ->
      sinon.spy @ArtworkFilterView::, 'remove'

    afterEach ->
      @view.remove.restore()

    describe '#render', ->
      it 'renders the container template', ->
        @view.$el.html().should.containEql 'artwork-filter'
        @view.$el.html().should.containEql 'artwork-section'

    it 'fetches the filter', ->
      Backbone.sync.args[0][1].url().should.containEql '/api/v1/filter/artworks'

    it 'fetches the artworks', ->
      Backbone.sync.args[1][1].url().should.containEql '/api/v1/filter/artworks?artist_id=foo-bar'

    it 'removes itself if the initial filter state returns without any works', ->
      Backbone.sync.args[0][2].success {}
      @view.remove.called.should.be.true()

    it 'removes itself if the initial filter state errors', ->
      Backbone.sync.args[0][2].error {}
      @view.remove.called.should.be.true()

    it 'starts in grid mode', ->
      @view.viewMode.get('mode').should.equal 'grid'

  describe '#changeViewMode', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'sets the view mode when the toggle is clicked', ->
      @view.$('.artwork-filter-view-mode__toggle[data-mode=list]').click()
      @view.viewMode.get('mode').should.eql 'list'

    it 're-renders the artworks when the view mode is changed', ->
      sinon.spy @ArtworkFilterView::, 'view'
      @view.$('.artwork-filter-view-mode__toggle[data-mode=list]').click()
      @ArtworkFilterView::view.called.should.be.true()

  describe '#renderFilter', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'renders the filter template', ->
      @view.$filter.html().should.containEql '<h2>Works</h2>'

  describe '#handleState', ->
    describe '#handleFilterState', ->
      it 'sets the state for the filter container depending on the request event', ->
        # _.isUndefined(@view.$filter.attr 'data-state').should.be.true()
        @view.filter.trigger 'request'
        @view.$filter.attr('data-state').should.equal 'loading'
        @view.filter.trigger 'sync'
        @view.$filter.attr('data-state').should.equal 'loaded'
        @view.filter.trigger 'request'
        @view.$filter.attr('data-state').should.equal 'loading'
        @view.filter.trigger 'error'
        @view.$filter.attr('data-state').should.equal 'loaded'

    describe '#handleArtworksState', ->
      it 'sets the state for the artworks container + button depending on the request event', ->
        _.isUndefined(@view.$artworks.attr 'data-state').should.be.true()
        @view.artworks.trigger 'request'
        @view.$artworks.attr('data-state').should.equal 'loading'
        @view.artworks.trigger 'sync'
        @view.$artworks.attr('data-state').should.equal 'loaded'
        @view.artworks.trigger 'request'
        @view.$artworks.attr('data-state').should.equal 'loading'
        @view.artworks.trigger 'error'
        @view.$artworks.attr('data-state').should.equal 'loaded'

  describe '#getRemaining', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'calculates the remaining works to display', ->
      @view.artworks.trigger 'sync'
      @view.remaining().should.eql 11959

  describe '#loadNextPage', ->
    it 'loads the next page when the button is clicked', ->
      Backbone.sync.callCount.should.equal 2
      @view.artworks.params.get('page').should.equal 1
      @view.loadNextPage()
      @view.artworks.params.get('page').should.equal 2
      Backbone.sync.callCount.should.equal 3
      _.last(Backbone.sync.args)[2].data.should.eql 'size=9&page=2'
      @view.loadNextPage()
      @view.artworks.params.get('page').should.equal 3
      Backbone.sync.callCount.should.equal 4
      _.last(Backbone.sync.args)[2].data.should.eql 'size=9&page=3'

    describe 'error', ->
      it 'reverts the params', ->
        @view.artworks.params.attributes.should.eql size: 9, page: 1
        @view.loadNextPage()
        _.last(Backbone.sync.args)[2].data.should.eql 'size=9&page=2'
        Backbone.sync.restore()
        sinon.stub(Backbone, 'sync').yieldsTo 'error'
        # Tries to get next page but errors
        @view.loadNextPage()
        _.last(Backbone.sync.args)[2].data.should.eql 'size=9&page=3'
        # Next try should have the same params
        @view.loadNextPage()
        _.last(Backbone.sync.args)[2].data.should.eql 'size=9&page=3'

  describe '#selectCriteria', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'pulls the filter criteria out of the link and selects it', ->
      @view.$('.artwork-filter-select').first().click()
      @view.filter.selected.attributes.should.eql medium: 'painting'
      @view.$('.artwork-filter-select').last().click()
      @view.filter.selected.attributes.should.eql medium: 'jewelry'

    it 'pulls the sort criteria out of the link and selects it', ->
      @view.$('.bordered-pulldown-options a').first().click()
      @view.filter.selected.attributes.should.eql sort: '-published_at'
      @view.$('.bordered-pulldown-options a').last().click()
      @view.filter.selected.attributes.should.eql sort: 'year'

  describe '#fetchArtworks', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'fetches the artworks, passing in the selected filters + view params', ->
      @view.$('.artwork-filter-select:eq(0)').click()
      _.last(Backbone.sync.args)[2].data.should.containEql medium: 'painting'
      @view.$('.artwork-filter-select:eq(1)').click()
      _.last(Backbone.sync.args)[2].data.should.containEql medium: 'work-on-paper'
      @view.$('.artwork-filter-select').last().click()
      _.last(Backbone.sync.args)[2].data.should.containEql medium: 'jewelry'

  describe '#fetchArtworksFromBeginning', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    it 'fetches resets the params before fetching artworks when a filter is clicked', ->
      @view.$('.artwork-filter-select:eq(0)').click()
      @view.$('.artwork-filter-select:eq(1)').click()
      _.last(Backbone.sync.args)[2].data.should.containEql medium: 'work-on-paper'

  describe '#toggleBoolean', ->
    beforeEach ->
      Backbone.sync.args[0][2].success fabricate2 'filter_artworks'

    xit 'fetches the artworks, toggling the boolean filter criteria', ->
      @view.$('input[type="checkbox"]').first().click()
      @view.filter.selected.attributes.should.eql price_range: '-1:1000000000000'
      _.last(Backbone.sync.args)[2].data.should.eql price_range: '-1:1000000000000'
      @view.$('input[type="checkbox"]').first().click()
      @view.filter.selected.attributes.should.eql {}
      _.last(Backbone.sync.args)[2].data.should.not.containEql price_range: '-1:1000000000000'
