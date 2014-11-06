_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
rewire = require 'rewire'
Backbone = require 'backbone'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
Artwork = require '../../../models/artwork'

describe 'ArtworkFilterRouter', ->
  before (done) ->
    benv.setup =>
      benv.expose $: require 'jquery'
      Backbone.$ = $
      @ArtworkFilterRouter = rewire '../router'
      ArtworkFilterView = benv.requireWithJadeify resolve(__dirname, '../view'), ['template', 'filterTemplate', 'headerTemplate']
      @ArtworkFilterRouter.__set__ 'ArtworkFilterView', ArtworkFilterView
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @router = new @ArtworkFilterRouter model: new Artwork(fabricate 'artwork')

  afterEach ->
    Backbone.sync.restore()

  describe '#params', ->
    it 'stringifies the selected filter attributes', ->
      @router.view.filter.selected.set foo: 'bar', baz: 'qux'
      @router.params().should.equal 'foo=bar&baz=qux'

  describe '#currentFragment', ->
    it 'returns the current path with query string optionally attached based on what the filter state is', ->
      @router.view.filter.by foo: 'bar', baz: 'qux'
      @router.currentFragment().should.containEql '?foo=bar&baz=qux'
      @router.view.filter.deselect 'foo'
      @router.currentFragment().should.containEql '?baz=qux'
      @router.view.filter.deselect 'baz'
      @router.currentFragment().should.not.containEql '?'

  describe '#filteredParams', ->
    it 'doesnt return ignored', ->
      @router.searchString = -> '?foo=bar&utm_source=email&baz=qux&gallery=cool&price_range=-1%3A1000000000000'
      spy = sinon.spy @router.view.filter, 'by'
      @router.navigateBasedOnParams()
      spy.args[0][0].should.eql gallery: 'cool', price_range: '-1:1000000000000'
