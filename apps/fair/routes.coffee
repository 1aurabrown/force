_ = require 'underscore'
Profile = require '../../models/profile.coffee'
Fair = require '../../models/fair.coffee'
Search = require '../../collections/search.coffee'
cache = require '../../lib/cache'
client = cache.client
kinds = require '../favorites_follows/kinds'
{ crop, fill } = require '../../components/resizer'

@overview = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  # TODO: Dependent on attribute of fair
  res.locals.sd.BODY_CLASS = 'body-transparent-header'
  res.locals.sd.SECTION = 'overview'
  res.render 'overview'

@info = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  res.locals.sd.SECTION = 'info'
  res.render 'index'

@fairPosts = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  res.locals.sd.SECTION = 'posts'
  res.render 'index'

@browse = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  res.locals.sd.SECTION = 'browse'
  res.render 'index'

@forYou = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  res.locals.sd.SECTION = 'forYou'
  res.render 'index'

@search = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  return res.redirect("/#{req.params.id}") unless term = req.query.q
  fair = res.locals.fair
  fairSearch = new Search
  search = new Search
  success = _.after 2, ->
    res.locals.sd.SECTION = 'search'
    res.render 'index',
      term: term
      fairResults: fairSearch.models
      results: search.models
      crop: crop
      fill: fill

  fairSearch.fetch
    data:
      term: term
      fair_id: res.locals.fair.get('id')
    cache: true
    success: (results) ->
      fairSearch.updateLocationsForFair(fair)
      success()
    error: res.backboneError

  search.fetch
    data:
      term: term
    cache: true
    success: ->
      success()
    error: res.backboneError

@favorites = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  return res.redirect("/#{req.params.id}") unless req.user
  res.locals.sd.SECTION = 'favorites'
  res.render 'favorites', profileId: req.user.get('default_profile_id')

@follows = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  return res.redirect("/#{req.params.id}") unless req.user
  if (route = req.params.type) in _.keys(kinds)
    res.locals.sd.KIND = kinds[route] or 'artist'
    res.locals.sd.SECTION = 'follows'
    res.render 'favorites',
      profileId: req.user.get('default_profile_id')
      type: route
  else
    next()

# Fetches show for partner and redirects to the show permalink
@showRedirect = (req, res, next) ->
  return next() unless res.locals.sd.FAIR
  fair = res.locals.fair
  fair.fetchShowForPartner req.params.partner_id,
    error: res.backboneError
    success: (show) -> res.redirect "/show/#{show.id}"

# Busts cache for this fair, admin-only
@bustCache = (req, res, next) ->
  return next() unless req.user?.get('type') is 'Admin'
  fairId = req.params.id
  if client
    client.del("fair:#{fairId}")
    res.redirect "/#{fairId}"
  else
    res.redirect "/#{fairId}"
