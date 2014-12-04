_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
FairInfoView = require './info.coffee'
FairPostsView = require './posts.coffee'
FairSearchView = require './search.coffee'
ForYouView = require './for_you.coffee'
OverviewView = require './overview.coffee'
FairFooter = require './footer.coffee'
SearchBar = require './mixins/search_bar.coffee'
FairBrowseView = require '../components/browse/view.coffee'
FairBrowseRouter = require '../components/browse/router.coffee'
Profile = require '../../../models/profile.coffee'
Fair = require '../../../models/fair.coffee'
{ FavoritesView } = require '../../../components/favorites/client/favorites.coffee'
{ FollowsView } = require '../../../components/favorites/client/follows.coffee'
scrollFrame = require 'scroll-frame'

module.exports.FairView = class FairView extends Backbone.View
  _.extend @prototype, SearchBar

  sectionHash:
    info: FairInfoView
    posts: FairPostsView
    search: FairSearchView
    browse: FairBrowseRouter
    favorites: FavoritesView
    follows: FollowsView
    forYou: ForYouView
    overview: OverviewView

  footerRoutes: ['forYou', 'posts', 'search', 'info', 'favorites', 'follows']

  initialize: (options) ->
    @fair = options.fair
    @setupSearch @model, @fair # via SearchBar mixin
    return if options.currentSection is 'browse'
    if @sectionHash[options.currentSection]
      el = if options.currentSection == 'overview' then @$el else @$('.fair-page-content')
      new @sectionHash[options.currentSection]
        model: @model
        fair: @fair
        el: el

      if options.currentSection == 'follows' or options.currentSection == 'favorites'
        @fixFavoritesFollowingTabs @model

      if options.currentSection in @footerRoutes
        new FairFooter
          el: @$('.fair-page-footer')
          fair: @fair
          model: @model

  # Kinda hacky
  fixFavoritesFollowingTabs: (profile) ->
    @$('.follows-tabs.garamond-tablist a').each ->
      $(@).attr href: "#{profile.href()}#{$(@).attr('href')}"

module.exports.init = ->
  fair = new Fair sd.FAIR
  profile = new Profile sd.PROFILE
  new FairView
    model: profile
    fair: fair
    el: $('#fair-page')
    currentSection: sd.SECTION

  if sd.SECTION in ['overview', 'browse']
    new FairBrowseRouter
      fair: fair
      profile: profile

    # Links in the browse section keep your scroll position
    scrollFrame '#fair-browse a'

  # Checks to see if the href is an internal link to:
  # an artwork, artist, show, or post
  #
  # return {Boolean}
  isOutbound = (href) ->
    pattern = /^\/((artwork\/.*$)|(artist\/.*$)|(show\/.*$)|(post\/.*$))/
    href.match(pattern)?

  # Global click handler
  $('body').on 'click', 'a[href]', ->
    href = ($this = $(this)).attr 'href'
    if href and isOutbound href
      $this.attr 'href',
        href +
          '?microsite=1' +
          "&profile_id=#{profile.id}" +
          "&fair_id=#{fair.id}" +
          "&fair_name=#{fair.get('name')}"

  # Start: Remove anytime after ~12/8/2014
  return unless fair.id is 'nada-miami-beach-2014'
  background = null
  $background = $('.feature-image')
  $('#fair-nada-wallpapers').hover ->
    background = $background.css('background-image')
    $background.css
      backgroundImage: 'url("/images/wallpapers-hover.gif")'
      backgroundSize: 'inherit'
  , ->
    $background.css backgroundImage: background
  # End: Remove anytime after ~12/8/2014
