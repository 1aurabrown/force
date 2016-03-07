#
# /article/:id
#

express = require 'express'
routes = require './routes'
{ resize, crop } = require '../../components/resizer'

app = module.exports = express()
app.set 'views', __dirname + '/templates'
app.set 'view engine', 'jade'
app.locals.resize = resize
app.locals.crop = crop

# Permalink routes
app.get '/posts', routes.redirectPost
app.get '/post/:id', routes.redirectPost
app.get '/:id/posts', routes.redirectPost
app.get '/article', routes.redirectArticle
app.get '/magazine', routes.redirectMagazine
app.get '/articles', routes.articles
app.get '/article/:slug', routes.article
app.get '/:slug', routes.section
app.post '/gallery-insights/form', routes.form
app.post '/editorial-signup/form', routes.editorialForm
