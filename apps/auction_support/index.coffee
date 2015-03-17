#
# Auction related routes
#

express = require 'express'
routes = require './routes'

app = module.exports = express()
app.set 'views', __dirname + '/templates'
app.set 'view engine', 'jade'

app.get '/auction-registration/:id', routes.auctionRegistration
app.get '/feature/:id/bid/:artwork', routes.bid
app.get '/auction/:id/buyers-premium', routes.buyersPremium