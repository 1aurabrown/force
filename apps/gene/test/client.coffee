_ = require 'underscore'
benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
Gene = require '../../../models/gene'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'

describe 'GeneView', ->

  before (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      benv.render resolve(__dirname, '../templates/index.jade'), {
        sd: {}
        asset: (->)
        gene: new Gene fabricate 'gene'
      }
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  beforeEach ->
    { GeneView } = mod = benv.requireWithJadeify resolve(__dirname, '../client.coffee'), ['RelatedArtistsTemplate']
    for klass in ['ArtistFillwidthList', 'FilterArtworksView', 'FollowButton', 'ShareView', 'RelatedGenesView', 'BlurbView']
      @[klass] = sinon.stub()
      @[klass]::fetchAndRender = sinon.stub()
      @[klass]::router = { navigate: sinon.stub() }
      @[klass]::params = new Backbone.Model
      @[klass]::el = $('<div>')
      mod.__set__ klass, @[klass]
    $.onInfiniteScroll = sinon.stub()
    sinon.stub Backbone, 'sync'
    @view = new GeneView
      el: $('body')
      model: new Gene fabricate 'gene'

  afterEach ->
    Backbone.sync.restore()

  describe '#initialize', ->

    it 'sets up a share view', ->
      @ShareView.calledWithNew().should.be.ok

    it 'sets up a blurb view', ->
      @BlurbView.calledWithNew().should.be.ok

    it 'inits a follow button view', ->
      @FollowButton.calledWithNew().should.be.ok

    it 'does not setup artists if the gene is a subject matter gene', ->
      @view.renderArtistFillwidth = sinon.stub()
      @view.model.set type: { name: 'Technique' }
      @view.initialize {}
      @view.renderArtistFillwidth.called.should.not.be.ok

  describe '#setupMode', ->

    it 'switches to artwork mode when gene is subject matter', ->
      sinon.stub @view, 'artworksMode'
      @view.model.isSubjectMatter = -> true
      @view.initialize {}
      @view.artworksMode.called.should.be.ok

    it 'resets the filter params if its a subject matter gene', ->
      @view.params.on 'reset', spy = sinon.spy()
      @view.model.isSubjectMatter = -> true
      @view.setupMode()
      spy.called.should.be.ok

  describe '#onFollowRoute', ->

    it 'follows the gene if coming from /follow'
  describe '#setupArtistFillwidth', ->

    it 'inits a artist fillwidth view', ->
      @view.setupArtistFillwidth()
      Backbone.sync.args[0][2].success [fabricate 'artist', name: 'Andy Foobar']
      @ArtistFillwidthList::fetchAndRender.called.should.be.ok

  describe '#artistMode', ->

    it 'switches back to artist mode', ->
      @view.$el.attr 'data-state', 'artworks'
      @view.artistMode()
      @view.$('#gene-filter').attr('data-state').should.equal 'artists'

    it 'navigates to the gene root', ->
      @view.router.navigate = sinon.stub()
      @view.artistMode()
      @view.router.navigate.args[0][0].should.equal "/gene/#{@view.model.get 'id'}"

  describe '#artworksMode', ->

    it 'sets the state to artwork mode', ->
      @view.artworksMode()
      @view.$('#gene-filter').data('state').should.equal 'artworks'
