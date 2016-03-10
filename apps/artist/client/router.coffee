_ = require 'underscore'
_s = require 'underscore.string'
sd = require('sharify').data
Backbone = require 'backbone'
initCarousel = require '../../../components/merry_go_round/index.coffee'
HeaderView = require './views/header.coffee'
OverviewView = require './views/overview.coffee'
WorksView = require './views/works.coffee'
ShowsView = require './views/shows.coffee'
ArticlesView = require './views/articles.coffee'
RelatedArtistsView = require './views/related_artists.coffee'
BiographyView = require './views/biography.coffee'
mediator = require '../../../lib/mediator.coffee'
attachCTA = require './cta.coffee'

module.exports = class ArtistRouter extends Backbone.Router
  routes:
    'artist/:id': 'overview'
    'artist/:id/works': 'works'
    'artist/:id/shows': 'shows'
    'artist/:id/articles': 'articles'
    'artist/:id/collections': 'collections'
    'artist/:id/publications': 'publications'
    'artist/:id/related-artists': 'relatedArtists'
    'artist/:id/biography': 'biography'

  initialize: ({ @model, @user, @statuses }) ->
    @options = model: @model, user: @user, statuses: @statuses
    @setupUser()
    @setupCarousel()
    @setupHeaderView()

  setupUser: ->
    @user?.initializeDefaultArtworkCollection()

  setupCarousel: ->
    initCarousel $('.js-artist-carousel')

  setupHeaderView: ->
    @headerView = new HeaderView _.extend el: $('#artist-page-header'), @options

  execute: ->
    return if @view? # Sets up a view once, depending on route
    super
    @renderCurrentView()

  renderCurrentView: ->
    (@$content ?= $('#artist-page-content'))
      .html @view.render().$el

  overview: ->
    @view = new OverviewView @options
    mediator.on 'overview:fetches:complete', =>
      attachCTA @model

  works: ->
    @view = new WorksView @options

  shows: ->
    @view = new ShowsView @options

  articles: ->
    @view = new ArticlesView @options

  relatedArtists: ->
    @view = new RelatedArtistsView @options

  biography: ->
    @view = new BiographyView @options
