_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
Artist = require '../../../../models/artist'
artistJSON = require '../fixtures'

describe 'WorksView', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      @WorksView = benv.requireWithJadeify resolve(__dirname, '../../client/views/works'), ['template']
      @model = new Artist artistJSON
      done()

  after ->
    benv.teardown()

  beforeEach ->
    $.onInfiniteScroll = sinon.stub()
    sinon.stub _, 'defer', (cb) -> cb()
    sinon.stub Backbone, 'sync'
    @WorksView.__set__ 'ArtworkFilter', init: @artworkFilterInitStub = sinon.stub().returns(view: new Backbone.View)
    @view = new @WorksView model: @model, statuses: artistJSON.statuses

  afterEach ->
    _.defer.restore()
    Backbone.sync.restore()
    @view.remove()

  describe '#render', ->
    it 'renders the template', ->
      @view.render()
      @view.$('#artwork-section').length.should.equal 1
