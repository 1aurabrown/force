_ = require 'underscore'
Backbone = require 'backbone'
{ API_URL } = require('sharify').data
{ Markdown } = require 'artsy-backbone-mixins'
Artworks = require '../../../collections/artworks.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'
FillwidthView = require '../../../components/fillwidth_row/view.coffee'
splitTest = require '../../../components/split_test/index.coffee'

template = -> require('../templates/layered_search.jade') arguments...
newTemplate = -> require('../templates/layered_search_v2.jade') arguments...

module.exports.Layer = class Layer extends Backbone.Model
  _.extend @prototype, Markdown

  initialize: (options = {}) ->
    @set artwork_id: @collection.artwork.id
    @set fair: @collection.fair if @get('type') is 'fair'
    @artworks = new Artworks
    @artworks.url = "#{API_URL}/api/v1/related/layer/#{@get('type')}/#{@id}/artworks?artwork[]=#{@get('artwork_id')}"

  forSale: ->
    (@get('type') is 'synthetic') and (@id is 'for-sale')

  label: ->
    if @forSale() then @id else @get('type')

  text: ->
    text = if @forSale() then 'all for sale works' else "“#{@get('name')}”"
    "Go to #{text}"

  href: ->
    return '/browse/artworks?price_range=-1%3A1000000000000' if @forSale()
    return "/gene/#{@id}" if @get('type') is 'gene'
    return "/tag/#{@id}" if @get('type') is 'tag'

module.exports.Layers = class Layers extends Backbone.Collection
  url: "#{API_URL}/api/v1/related/layers"
  model: Layer

  initialize: (models, options) ->
    { @artwork, @fair } = options

  fetch: (options = {}) ->
    _.extend options, data: 'artwork[]': @artwork.id
    Backbone.Collection::fetch.call this, options

  parse: (data)->
    # hide all "for sale" layers if the collection has a fair
    # or only for-sale works (which appears to be useless on its own)
    if @fair or data.length is 1
      _.reject data, (layer) -> layer.id is 'for-sale'
    else
      data

  # Ensure fairs are always first, followed by 'Most Similar',
  # and that 'For Sale' is always last
  sortMap: (type, id) ->
    return -1 if (type is 'fair')
    return  0 if (type is 'synthetic') and (id is 'main')
    return  @length if (type is 'synthetic') and (id is 'for-sale')
    1

  comparator: (model) ->
    @sortMap model.get('type'), model.id

module.exports.LayeredSearchView = class LayeredSearchView extends Backbone.View
  template: ->
    template arguments...

  events:
    'click .layered-search-layer-button': 'selectLayer'

  initialize: (options = {}) ->
    { @artwork, @fair } = options
    @setupLayers()

  setupLayers: ->
    @layers = new Layers [], { artwork: @artwork, fair: @fair }
    @layers.fetch
      success: => @render()
      error: => @remove()

  # Activate the clicked layer or
  # activate the first layer if called without a click event
  selectLayer: (e) ->
    id = if e
      e.preventDefault()
      ($target = $(e.currentTarget)).data 'id'
    else
      ($target = @$layerButtons.first()).data 'id'

    @__activeLayer__ = @layers.get id
    @activateLayerButton $target
    @$layeredSearchResults.html '<div class="loading-spinner"></div>'
    @fetchAndRenderActiveLayer()

    analyticsHooks.trigger('switched:layer', label: @__activeLayer__.label()) if e

  fetchAndRenderActiveLayer: ->
    @$layerGeneButton.attr 'data-state', 'inactive'

    if @activeLayer().artworks.length
      # Already fetched
      @renderLayer()
    else
      @activeLayer().artworks.
        fetch success: => @renderLayer()

  activeLayer: ->
    @__activeLayer__ or @layers.first()

  activateLayerButton: ($target) ->
    @$layerButtons.attr 'data-state', 'inactive'
    $target.attr 'data-state', 'active'

  renderLayer: ->
    layer = @activeLayer()

    @$layerGeneButton.
      text(layer.text()).
      attr
        href: layer.href()
        'data-id': layer.id
        'data-type': layer.get 'type'
        'data-state': 'active'

    # Ideally we should be removing this view before re-rendering
    # which would require a small refactor to the ArtworkColumns component
    @artworkColumnsView = new ArtworkColumnsView
      el: @$layeredSearchResults
      collection: layer.artworks
      numberOfColumns: 4
      gutterWidth: 40
      maxArtworkHeight: 400
      isOrdered: false
      seeMore: false
      allowDuplicates: true
      artworkSize: 'tall'

  postRender: ->
    @$layeredSearchResults = @$('#layered-search-results-container')
    @$layerGeneButton = @$('#layered-search-layer-gene-button')
    @$layerButtons = @$('.layered-search-layer-button')
    @selectLayer() # Activate the first tab

  render: ->
    # if there are no layers then remove the view
    return @remove() unless @layers.length

    @$el.html @template(layers: @layers)
    @postRender()
    this
