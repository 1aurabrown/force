Search = require '../../collections/search'
GoogleSearchResults = require './collections/google_search_results'
removeDiacritics = require('diacritics').remove
{ crop, fill } = require '../../components/resizer'
request = require 'superagent'
imageUrl = require './components/image_url'

@image = (req, res, next) ->
  { id, model } = req.params

  img = request.get imageUrl model, id

  img.on 'end', ->
    res.status img.res.statusCode

  req
    .pipe img
    .pipe res

@index = (req, res) ->
  return res.redirect("/") unless req.query.q

  term = removeDiacritics req.query.q
  data = { q: term }
  res.locals.sd.term = term
  page = Number(req.query.page)
  if page && page > 1
    res.locals.sd.page = page
    data.start = (page - 1) * 10

  results = new GlobalSearchResults()
  results.fetch
    dataType: 'jsonp'
    data: data
    cache: true
    cacheTime: 3600 # 1 hour
    success: (results, response) ->
      totalPages = Math.floor(response.queries?.nextPage?[0].totalResults / 10)
      # Google docs say they only supports 99 pages
      # They seem to support a few more but it is unreliable
      totalPages = 99 if totalPages > 99

      models = results.moveMatchResultsToTop term
      res.locals.sd.RESULTS = results.toJSON()
      res.render 'template',
        term: term
        referrer: req.query.referrer
        results: models
        currentPage: page or 1
        totalPages: totalPages
        crop: crop
        fill: fill
    error: ->
      res.render 'template',
        term: term
        referrer: req.query.referrer
        results: []
