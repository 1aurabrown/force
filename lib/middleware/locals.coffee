#
# Inject common project-wide [view locals](http://expressjs.com/api.html#app.locals).
#

uuid = require 'node-uuid'
{ parse, format } = require 'url'
_ = require 'underscore'
moment = require 'moment'
embedVideo = require 'embed-video'
{ NODE_ENV } = require '../../config'

module.exports = (req, res, next) ->

  # Attach libraries to locals
  res.locals._ = _
  res.locals.moment = moment
  res.locals.embedVideo = embedVideo

  # Pass the user agent into locals for data-useragent device detection
  res.locals.userAgent = req.get('user-agent')

  # Inject some project-wide sharify data such as the session id, the current path
  # and the xapp token.
  res.locals.sd.SESSION_ID = req.session?.id ?= uuid.v1()
  res.locals.sd.CURRENT_PATH = parse(req.url).pathname
  res.locals.sd.ARTSY_XAPP_TOKEN = res.locals.artsyXappToken
  res.locals.sd.HIDE_HEADER = req.cookies?['hide-force-header']?
  res.locals.sd.EIGEN = req.headers?['user-agent']?.match('Eigen')?

  next()
