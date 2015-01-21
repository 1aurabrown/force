_ = require 'underscore'
cheerio = require 'cheerio'
benv = require 'benv'
jade = require 'jade'
path = require 'path'
fs = require 'graceful-fs'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
OrderedSet = require '../../../models/ordered_set'
FeaturedLink = require '../../../models/featured_link'
Gene = require '../../../models/gene'
Artists = require '../../../collections/artists'
Artist = require '../../../models/artist'
ArtistsByLetter = require '../collections/artists_by_letter'
Items = require '../../../collections/items'

render = (templateName) ->
  filename = path.resolve __dirname, "../templates/#{templateName}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Artists', ->
  describe 'index page', ->

    before (done) ->
      @artistCollection = new Artists(
        _.times(2, ->
          new Artist(fabricate('artist', { image_versions: ['four_thirds', 'tall'] }))
        )
      )

      @featuredLinksCollection = new Items(
        _.times(3, ->
          link = new FeaturedLink(fabricate('featured_link'))
          link.set 'artist', new Artist(fabricate('artist'))
          link
        ), { id: 'foobar', item_type: 'FeaturedLink' }
      )

      @genes = new Items(_.times(2, =>
        gene = new Gene(fabricate 'gene')
        gene.trendingArtists = @artistCollection.models
        gene
      ), { id: 'foobar', item_type: 'Gene'})

      @featuredArtists = new OrderedSet(name: 'Featured Artists', items: @featuredLinksCollection)

      template = render('index')(
        sd:
          CANONICAL_MOBILE_URL: 'http://localhost:5000'
          API_URL: 'http://localhost:5000'
          APP_URL: 'http://localhost:5000'
          CSS_EXT: '.css.gz'
          JS_EXT: '.js.gz'
          NODE_ENV: 'test'
          CURRENT_PATH: '/artists'
        letterRange: ['a', 'b', 'c']
        featuredArtists: @featuredArtists
        featuredGenes: @genes
      )

      @$template = cheerio.load template

      done()

    it 'renders the alphabetical nav', ->
      @$template.html().should.not.containEql 'undefined'
      @$template.root().find('.alphabetical-index-range').text().should.equal 'abc'

    it 'has a single <h1> that displays the name of the artists set', ->
      $h1 = @$template.root().find('h1')
      $h1.length.should.equal 1
      $h1.text().should.equal 'Featured Artists'

    it 'renders the featured artists', ->
      @$template.root().find('.afc-artist').length.should.equal @featuredLinksCollection.length

    it 'renders the gene sets', ->
      @$template.root().find('.artists-featured-genes-gene').length.should.equal @genes.length

    it 'renders the trending Artists for the genes', ->
      @$template.root().find('.afg-artist').length.should.equal @genes.length * @artistCollection.length

    it 'has jump links to the various gene pages', ->
      $links = @$template.root().find('.avant-garde-jump-link')
      $links.length.should.equal 2
      $links.first().text().should.equal fabricate('gene').name

    it 'uses four_thirds images', ->
      @$template.root().find('.afg-artist img').attr('src').should.containEql 'four_thirds'

  describe 'letter page', ->

    before (done) ->

      @artistsByLetter = new ArtistsByLetter([], { letter: 'a', state: { currentPage: 1, totalRecords: 1000 } })

      @artistsByLetter.add new Artist(fabricate('artist', { image_versions: ['four_thirds', 'tall'] }))
      @artistsByLetter.add new Artist(fabricate('artist', { image_versions: ['four_thirds', 'tall'] }))

      template = render('letter')(
        sd:
          CANONICAL_MOBILE_URL: 'http://localhost:5000'
          APP_URL: 'http://localhost:5000'
          CSS_EXT: '.css.gz'
          JS_EXT: '.js.gz'
          NODE_ENV: 'test'
          CURRENT_PATH: '/artists-starting-with-a'
        letter: 'A'
        letterRange: ['a', 'b', 'c']
        artists: @artistsByLetter
      )

      @$template = cheerio.load template

      done()

    it 'renders the alphabetical nav', ->
      @$template.html().should.not.containEql 'undefined'
      @$template.root().find('.alphabetical-index-range').text().should.equal 'abc'

    it 'has a single <h1> that displays the name of the artists set', ->
      $h1 = @$template.root().find('h1')
      $h1.length.should.equal 1
      $h1.text().should.equal 'Artists – A'

    it 'includes meta tags', ->
      html = @$template.html()
      html.should.containEql '<link rel="next" href="http://localhost:5000/artists-starting-with-a?page=2"'
      html.should.containEql '<meta property="og:title" content="Artists Starting With A'
      html.should.containEql '<meta property="og:description" content="Research and discover artists starting with A on Artsy. Find works for sale, biographies, CVs, and auction results'
