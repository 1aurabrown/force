_ = require 'underscore'
Backbone = require 'backbone'
Errors = require './errors.coffee'
Serializer = require './serializer.coffee'
Validator = require './validator.coffee'

module.exports = class Form
  _.extend @prototype, Backbone.Events

  constructor: (options = {}) ->
    { @model, @$form } = options

    throw new Error 'requires `$form`' unless @$form?

    { @$submit, @$errors } = settings = _.defaults options,
      $submit: @$form.find('button')
      $errors: @$form.find('.js-form-errors')

    @serializer = new Serializer @$form
    @validator = new Validator settings
    @errors = new Errors @$form

  isReady: ->
    @validator.isValid() and not @submitting()

  submit: (e, options = {}, send = 'save') ->
    throw new Error 'requires `model`' unless @model?

    e?.preventDefault()

    return unless @isReady()

    options.error = _.wrap options.error, (error, args...) =>
      @error args...
      error? args...

    @state 'loading'
    @model[send] @data(), options

  error: (model, response, options) ->
    @state 'error'
    @reenable false
    @$errors.text @errors.parse response

  submitting: ->
    return @__submitting__ if @__submitting__
    @__submitting__ = true

    # Defer submit disable so as to allow
    # event handlers to finish propagating
    _.defer =>
      @$submit.prop 'disabled', true

    false

  reenable: (reset = false) ->
    @reset() if reset
    @__submitting__ = false
    @$submit.prop 'disabled', false

  reset: ->
    @$form
      .find 'button, input, textarea'
      .attr 'data-state', null

  state: (state) ->
    @$submit.attr 'data-state', state

  data: ->
    @serializer.data()
