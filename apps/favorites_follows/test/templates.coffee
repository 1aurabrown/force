jade = require 'jade'
path = require 'path'
fs = require 'fs'
CurrentUser = require '../../../models/current_user'

render = (templateName) ->
  filename = path.resolve __dirname, "../templates/#{templateName}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Favorites and follows tab', ->
  describe 'on the following artists page', ->
    beforeEach ->
      @template = render('follows')(
        sd: { type: 'artists', CURRENT_PATH: '/following/artists' }
        asset: (->)
        user: new CurrentUser({ lab_features: [] })
      )

    it 'should contain three tabs for favorite artworks and followings', ->

      @template.should.containEql "Works"
      @template.should.containEql "Artists"
      @template.should.containEql "Categories"

    it 'should only hightlight the Artists tab ', ->

      @template.should.containEql '<a href="/following/artists" class="garamond-tab is-active">Artists</a>'
      @template.should.containEql '<a href="/following/genes" class="garamond-tab is-inactive">Categories</a>'
      @template.should.containEql '<a href="/favorites" class="garamond-tab is-inactive">Works</a>'

  describe 'on the following genes page', ->
    beforeEach ->
      @template = render('follows')(
        sd: { type: 'genes', CURRENT_PATH: '/following/genes' }
        asset: (->)
        user: new CurrentUser({ lab_features: [] })
      )

    it 'should contain three tabs for favorite artworks and followings', ->

      @template.should.containEql "Works"
      @template.should.containEql "Artists"
      @template.should.containEql "Categories"

    it 'should only hightlight the Genes tab ', ->

      @template.should.containEql '<a href="/following/artists" class="garamond-tab is-inactive">Artists</a>'
      @template.should.containEql '<a href="/following/genes" class="garamond-tab is-active">Categories</a>'
      @template.should.containEql '<a href="/favorites" class="garamond-tab is-inactive">Works</a>'

  describe 'on the favorite artworks page', ->
    beforeEach ->
      @template = render('favorites')(
        sd: { CURRENT_PATH: '/favorites' }
        asset: (->)
        user: new CurrentUser({ lab_features: [] })
      )

    it 'should contain three tabs for favorite artworks and followings', ->

      @template.should.containEql "Works"
      @template.should.containEql "Artists"
      @template.should.containEql "Categories"

    it 'should only hightlight the favorite artworks tab ', ->

      @template.should.containEql '<a href="/following/artists" class="garamond-tab is-inactive">Artists</a>'
      @template.should.containEql '<a href="/following/genes" class="garamond-tab is-inactive">Categories</a>'
      @template.should.containEql '<a href="/favorites" class="garamond-tab is-active">Works</a>'
