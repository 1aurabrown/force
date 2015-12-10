#
# Inject common project-wide [view locals](http://expressjs.com/api.html#app.locals).
#

uuid = require 'node-uuid'
{ parse, format } = require 'url'
_ = require 'underscore'
_ = require 'underscore.string'
moment = require 'moment'
{ NODE_ENV } = require '../../config'
helpers = require '../template_helpers'
templateModules = require '../template_modules'
artsyXapp = require 'artsy-xapp'

module.exports = (req, res, next) ->

  # Attach libraries to locals
  res.locals._ = _
  res.locals.moment = moment
  res.locals.helpers = helpers
  res.locals[key] = helper for key, helper of templateModules

  # Pass the user agent into locals for data-useragent device detection
  res.locals.userAgent = req.get('user-agent')

  # Inject some project-wide sharify data such as the session id, the current path
  # and the xapp token.
  res.locals.sd.SESSION_ID = req.session?.id ?= uuid.v1()
  res.locals.sd.CURRENT_PATH = parse(req.url).pathname
  res.locals.sd.ARTSY_XAPP_TOKEN = artsyXapp.token

  res.locals.sd.EIGEN = req.headers?['user-agent']?.match('Artsy-Mobile')?
  res.locals.sd.REQUEST_TIMESTAMP = Date.now()
  res.locals.sd.NOTIFICATION_COUNT = req.cookies?['notification-count']

  next()
