_ = require 'underscore'
HeroUnits = require '../../collections/hero_units'
FeaturedLinks = require '../../collections/featured_links'
{ parse } = require 'url'
Backbone = require 'backbone'
sd = require('sharify').data
cache = require '../../lib/cache'
client = cache.client
welcomeHero = require './welcome'

getRedirectTo = (req) ->
  req.body['redirect-to'] or req.query['redirect-to'] or req.query['redirect_uri'] or parse(req.get('Referrer') or '').path or '/'

@index = (req, res) ->
  heroUnits = new HeroUnits
  featuredLinks = new FeaturedLinks

  render = _.after 2, ->
    heroUnits.unshift(welcomeHero) unless req.user?
    res.render 'index',
      heroUnits: heroUnits.models
      featuredLinks: featuredLinks.models

  heroUnits.fetch
    cache: true
    success: render
    error: res.backboneError

  featuredLinks.fetchSetItemsByKey 'homepage:featured-sections',
    cache: true
    success: render
    error: res.backboneError

@redirectToSignup = (req, res) ->
  res.redirect "/sign_up"

@redirectLoggedInHome = (req, res, next) ->
  pathname = parse(req.url or '').pathname
  req.query['redirect-to'] = '/' if pathname is '/log_in' or pathname is '/sign_up'
  if req.user? then res.redirect getRedirectTo(req) else next()

@bustHeroCache = (req, res, next) ->
  return next() unless req.user?.get('type') is 'Admin'
  heros = new HeroUnits
  if client
    client.del(heros.url)
    res.redirect '/'
  else
    res.redirect '/'
