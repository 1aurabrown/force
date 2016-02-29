_ = require 'underscore'
Backbone = require 'backbone'
template = require('./index.jade')

module.exports = class ColorFilterView extends Backbone.View
  events:
    'click svg .clickable' : 'setColor'
    'click .cf-sidebar__colors_clear-right' : 'clear'

  colors: ['darkblue', 'lightblue', 'darkgreen', 'lightgreen', 'yellow', 'gold', 'orange', 'darkorange', 'red', 'pink', 'darkviolet', 'violet', 'black-and-white']

  initialize: ({ @params, @aggregations }) ->
    throw new Error 'Requires a params model' unless @params?
    throw new Error 'Requires an aggregations collection' unless @aggregations?

    @initialRender()

    @$clickableColors = @$('svg .clickable')
    @$checkmark = @$('.icon-check')
    @$clear = @$('.cf-sidebar__colors_clear-right')

    @listenTo @params, 'change:color', @renderSelectedAndEmptyStates
    @listenTo @aggregations, 'reset', @renderSelectedAndEmptyStates

  setColor: (e) ->
    $target = $(e.currentTarget)
    @params.set color: $target.data('value'), page: 1

  initialRender: ->
    @$el.html template

  clear: ->
    @params.unset('color')

  renderSelectedAndEmptyStates: =>
    # First remove all empty states
    _.each(@$clickableColors, (color) =>
      $(color).removeAttr('data-empty')
      @$checkmark.removeClass($(color).data('value'))
    )

    # Add selected states
    selected = @params.get('color')
    if selected
      @$checkmark.addClass(selected)
      @$clear.show()
      @$checkmark.show()
    else
      @$clear.hide()
      @$checkmark.hide()

    # Add empty states
    respColors = _.pluck @aggregations.get('COLOR').get('counts'), 'name'
    emptyColors = _.difference(@colors, respColors)
    _.each(emptyColors, (color) ->
      @$("svg path[data-value='#{color}']").attr('data-empty', true)
    )