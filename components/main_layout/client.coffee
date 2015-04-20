Backbone = require 'backbone'
Backbone.$ = $
_ = require 'underscore'
Cookies = require 'cookies-js'
imagesLoaded = require 'imagesloaded'
HeaderView = require './header/view.coffee'
FooterView = require './footer/view.coffee'
sd = require('sharify').data
analytics = require '../../lib/analytics.coffee'
AuctionReminderView = require '../auction_reminder/index.coffee'
setupSplitTests = require '../split_test/setup.coffee'
listenForInvert = require '../eggs/invert/index.coffee'

module.exports = ->
  setupJquery()
  setupViews()
  setupReferrerTracking()
  setupKioskMode()
  syncAuth()
  setupAuctionReminder()
  listenForInvert()
  setupAnalytics()

ensureFreshUser = (data) ->
  return unless sd.CURRENT_USER
  for attr in ['id', 'type', 'name', 'email', 'phone', 'lab_features',
               'default_profile_id', 'has_partner_access', 'collector_level']
    if not _.isEqual data[attr], sd.CURRENT_USER[attr]
      $.ajax('/user/refresh').then -> window.location.reload()

syncAuth = module.exports.syncAuth = ->
  # Log out of Force if you're not logged in to Gravity
  if sd.CURRENT_USER
    $.ajax
      url: "#{sd.API_URL}/api/v1/me"
      success: ensureFreshUser
      error: ->
        $.ajax
          method: 'DELETE'
          url: '/users/sign_out'
          complete: ->
            window.location.reload()

setupAnalytics = ->
  window.analytics?.ready ->
    analytics(mixpanel: (mixpanel ? null), ga: ga)
    analytics.registerCurrentUser()
    setupSplitTests()
  analytics.trackPageview()
  # Log a visit once per session
  unless Cookies.get('active_session')?
    Cookies.set 'active_session', true
    analytics.track.funnel if sd.CURRENT_USER
      'Visited logged in'
    else
      'Visited logged out'

setupKioskMode = ->
  if sd.KIOSK_MODE and sd.KIOSK_PAGE and window.location.pathname != sd.KIOSK_PAGE
    # After five minutes, sign out the user and redirect back to the kiosk page
    setTimeout ->
      if sd.CURRENT_USER
        window.location = "/users/sign_out?redirect_uri=#{sd.APP_URL}#{sd.KIOSK_PAGE}"
      else
        window.location = sd.KIOSK_PAGE
    , (6 * 60 * 1000)

setupReferrerTracking = ->
  # Live, document.referrer always exists, but let's check
  # 'document?.referrer?.indexOf' just in case we're in a
  # test that stubs document
  if document?.referrer?.indexOf and document.referrer.indexOf(sd.APP_URL) < 0
    Cookies.set 'force-referrer', document.referrer
    Cookies.set 'force-session-start', window.location.href

setupViews = ->
  new HeaderView el: $('#main-layout-header'), $window: $(window), $body: $('body')
  new FooterView el: $('#main-layout-footer')

setupJquery = ->
  require '../../node_modules/typeahead.js/dist/typeahead.bundle.min.js'
  require 'jquery.transition'
  require 'jquery.fillwidth'
  require 'jquery.dotdotdot'
  require 'jquery-on-infinite-scroll'
  require '../../lib/vendor/waypoints.js'
  require '../../lib/vendor/waypoints-sticky.js'
  require '../../lib/jquery/hidehover.coffee'
  require('artsy-gemini-upload') $
  require('jquery-fillwidth-lite')($, _, imagesLoaded)
  $.ajaxSettings.headers =
    'X-XAPP-TOKEN': sd.ARTSY_XAPP_TOKEN
    'X-ACCESS-TOKEN': sd.CURRENT_USER?.accessToken

setupAuctionReminder = ->
  if sd.CHECK_FOR_AUCTION_REMINDER and !(Cookies.get('closeAuctionReminder')? or window.location.pathname is '/user/edit')
    new AuctionReminderView
