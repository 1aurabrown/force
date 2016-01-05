_ = require 'underscore'
_s = require 'underscore.string'
Backbone = require 'backbone'
PersonalizeState = require './state.coffee'
CurrentUser = require '../../../models/current_user.coffee'
Transition = require '../../../components/mixins/transition.coffee'
track = require('../../../lib/analytics.coffee').track
analyticsHooks = require '../../../lib/analytics_hooks.coffee'
Cookies = require 'cookies-js'
views =
  CollectView: require './views/collect.coffee'
  ArtistsView: require './views/artists.coffee'
  PriceRangeView: require './views/price_range.coffee'
  CategoriesView: require './views/categories.coffee'
  BookmarksView: require './views/bookmarks.coffee'
  FavoritesView: require './views/favorites.coffee'

module.exports.PersonalizeRouter = class PersonalizeRouter extends Backbone.Router
  routes:
    'personalize/:step': 'step'

  initialize: (options) ->
    { @user, @reonboarding } = options

    @state = new PersonalizeState user: @user, reonboarding: @reonboarding
    @$el = $('#personalize-page')

    @listenTo @state, 'transition:next', @next
    @listenTo @state, 'done', @done

    analyticsHooks.trigger 'personalize:impression', label: "User:#{@user.id}"
    analyticsHooks.trigger('personalize:reonboarding') if @reonboarding

    _.defer => @next()

  step: (step) ->
    Transition.fade @$el, out: =>
      @view?.remove()
      @state.set 'current_step', step

      analyticsHooks.trigger 'personalize:step',
        message: "Starting Personalize #{@state.currentStepLabel()}"
        label: "User:#{@user.id}"

      @view = new views["#{_s.classify(step)}View"] state: @state, user: @user
      @$el.html @view.render().$el

  next: ->
    @navigate "/personalize/#{@state.get('current_step')}", trigger: true

  # Check the cookie for a possible post-sign up destination;
  # ensure the cookie is cleared; return a location to redirect to
  #
  # @return {String} destination or root path
  redirectLocation: ->
    destination = Cookies.get 'destination'
    Cookies.expire 'destination' if destination
    destination or '/'

  done: ->
    analyticsHooks.trigger 'personalize:finished', label: "User:#{@user.id}"

    @$el.attr 'data-state', 'loading'

    $.when.apply(null, [
      @user.save()
      $.post('/flash', message: 'Thank you for personalizing your profile')
    ]).always =>
      location.assign @redirectLocation()

module.exports.init = ->
  reonboarding = /reonboarding/.test(window.location.search)
  user = CurrentUser.orNull()
  return unless user
  user.approximateLocation success: -> user.save()
  new PersonalizeRouter user: user, reonboarding: reonboarding
  Backbone.history.start pushState: true
  require('./analytics.coffee')(user)
