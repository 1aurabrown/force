_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
Profile = require '../../../models/profile'
Artworks = require '../../../collections/artworks'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
{ stubChildClasses } = require '../../../test/helpers/stubs'
{ ArtworkCollection } = ArtworkCollections = require '../../../collections/artwork_collections.coffee'

describe 'UserProfileView', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      sinon.stub Backbone, 'sync'
      benv.render resolve(__dirname, '../templates/index.jade'), {
        profile: profile = new Profile(fabricate 'profile')
        sd: {}
        asset: (->)
      }, =>
        UserProfileView = benv.require resolve(__dirname, '../client/user_profile')
        stubChildClasses UserProfileView, @,
          ['ArtworkColumnsView']
          ['appendArtworks']
        $.onInfiniteScroll = sinon.stub()
        @view = new UserProfileView
          el: $('#profile')
          model: profile
        done()

  afterEach ->
    Backbone.sync.restore()
    benv.teardown()

  describe '#openWebsite', ->
    beforeEach ->
      @openedWindowSpy = sinon.stub()
      @openedWindowSpy.opener = 1
      @openSpy = sinon.stub(window, "open").returns(@openedWindowSpy)

    xit 'sets window.opener to null', ->
      @view.model.set 'website', 'http://example.org'
      @view.openWebsite()
      @openSpy.called.should.be.ok
      @openSpy.args[0][0].should.equal 'http://example.org'
      @openSpy.args[0][1].should.equal '_blank'
      @openedWindowSpy.opener?.should.be.null

  describe '#setState', ->

    it 'sets the state for just articles', ->
      @view.articles = new Backbone.Collection [{}]
      @view.favorites = null
      @view.setState()
      @view.$el.attr('data-has').should.equal 'articles'

  it 'sets the state for just favorites', ->
      @view.articles = null
      @view.favorites = new Backbone.Collection [{}]
      @view.setState()
      @view.$el.attr('data-has').should.equal 'favorites'

  describe '#renderFavorites', ->

    it 'sets up a artwork columns view', ->
      @view.favorites = new Backbone.Collection [{}]
      @view.renderFavorites()
      @ArtworkColumnsView.calledWithNew.should.be.ok

describe 'CollectionView', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      $.onInfiniteScroll = sinon.stub()
      sinon.stub Backbone, 'sync'
      benv.render resolve(__dirname, '../templates/collection.jade'), {
        profile: profile = new Profile(fabricate 'profile')
        collection: new Backbone.Model(name: 'saved-artwork')
        sd: {}
        asset: (->)
      }, =>
        { CollectionView } = mod = benv.require resolve __dirname, '../client/collection'
        stubChildClasses mod, @, ['ArtworkColumnsView', 'ShareModal', 'FavoritesEmptyStateView'], ['appendArtworks']
        @view = new CollectionView
          el: $('body')
          artworkCollection: new ArtworkCollection id: 'saved-artwork', user_id: 'craig'
          user: new Backbone.Model accessToken: 'foobaz'
        done()

  afterEach ->
    Backbone.sync.restore()
    benv.teardown()

  describe '#initialize', ->

    it 'sets a columns view', ->
      (@view.columnsView?).should.be.ok

  describe '#nextPage', ->

    it 'adds a page to the columns view', ->
      @view.columnsView.appendArtworks = sinon.stub()
      @view.nextPage()
      Backbone.sync.args[0][2].success [fabricate 'artwork', title: 'Andy Foobar at the Park']
      _.last(@view.columnsView.appendArtworks.args)[0][0].get('title').should.equal 'Andy Foobar at the Park'

    it 'includes the access token', ->
      @view.columnsView.appendArtworks = sinon.stub()
      @view.nextPage()
      Backbone.sync.args[0][2].data.access_token.should.containEql 'foobaz'

  describe '#openShareModal', ->

    it 'opens a share modal for the collection', ->
      @view.artworkCollection.set name: "Andy Foobar's Dulloroids", id: 'andy-foobar'
      @view.openShareModal()
      @ShareModal.args[0][0].description.should.containEql "Andy Foobar's Dulloroids"

  describe '#onSync', ->

    it 'appends works', ->
      @view.onSync [], [fabricate 'artwork', id: 'andy-foobar-skull']
      @view.columnsView.appendArtworks.args[0][0][0].get('id').should.equal 'andy-foobar-skull'

    it 'renders total count', ->
      @view.artworkCollection.artworks.totalCount = 978
      @view.onSync [], [fabricate 'artwork', id: 'andy-foobar-skull']
      @view.$el.html().should.containEql '978 works'

  describe '#renderEmpty', ->

    it 'renders an emtpy state', ->
      @view.renderEmpty()
      @FavoritesEmptyStateView.called.should.be.ok

  describe '#onRemove', ->

    xit 'removes the artwork', ->
      @view.columnsView.render = sinon.stub()
      @view.artworkCollection.artworks.reset [fabricate('artwork'), fabricate('artwork')]
      @view.onRemove @view.artworkCollection.artworks.first()
      @view.artworkCollection.artworks.length.should.equal 1

    xit 're-renders the column view', ->
      @view.columnsView.render = sinon.stub()
      @view.artworkCollection.artworks.reset [fabricate('artwork'), fabricate('artwork')]
      @view.onRemove @view.artworkCollection.artworks.first()
      @view.columnsView.render.called.should.be.ok

describe 'Slideshow', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      $.onInfiniteScroll = sinon.stub()
      sinon.stub Backbone, 'sync'
      benv.render resolve(__dirname, '../templates/collection.jade'), {
        profile: profile = new Profile(fabricate 'profile')
        collection: new Backbone.Model(name: 'saved-artwork')
        sd: {}
        asset: (->)
      }, =>
        Slideshow = require '../client/slideshow'
        @view = new Slideshow
          el: $('body')
          artworks: new Artworks [fabricate 'artwork']
          user: new Backbone.Model accessToken: 'foobaz'
        done()

  afterEach ->
    Backbone.sync.restore()
    benv.teardown()

  describe '#render', ->

    it 'renders the artworks', ->
      @view.artworks.reset [fabricate 'artwork', title: 'Foobars in the Pond']
      @view.render()
      @view.$el.html().should.containEql 'Foobars in the Pond'

  describe '#next', ->

    beforeEach ->
      @view.artworks.reset (fabricate('artwork')  for i in [0..10])
      @view.render()

    it 'moves the next active artwork', ->
      @view.next()
      @view.$('.is-active').index().should.equal 2
      @view.next()
      @view.$('.is-active').index().should.equal 3

  describe '#renderActive', ->

    beforeEach ->
      @view.artworks.reset (fabricate('artwork')  for i in [0..10])
      @view.render()

    it 'sets the active item', ->
      @view.index = 4
      @view.renderActive()
      @view.$('.is-active').index().should.equal 4

  describe '#toggle', ->

    beforeEach ->
      @view.artworks.reset (fabricate('artwork')  for i in [0..10])
      @view.render()

    it 'resets the active artwork', ->
      @view.next()
      @view.next()
      @view.toggle()
      @view.$('.is-active').index().should.equal 0

