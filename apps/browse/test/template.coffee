jade = require 'jade'
path = require 'path'
fs = require 'graceful-fs'
cheerio = require 'cheerio'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
OrderedSet = require '../../../models/ordered_set'
FeaturedLink = require '../../../models/featured_link'
Item = require '../../../models/item'
Items = require '../../../collections/items'
OrderedSets = require '../../../collections/ordered_sets'

render = ->
  filename = path.resolve __dirname, "../templates/index.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Browse', ->
  describe 'with no browse categories', ->
    beforeEach ->
      @template = render()(
        sd: {}
        asset: (->)
        showBrowseCategories: true
      )

    it "includes not include genes three genes and images", ->
      # featuredGenes
      @template.should.not.containEql 'browse-featured-gene'

      # popularCategories
      @template.should.not.containEql 'browse-popular-categories'

      @template.should.containEql 'browse-filter'

  describe 'with all 3 ordered sets', ->
    beforeEach ->
      [featuredGenes, popularCategories, geneCategories] = [
        new OrderedSets({ key: 'browse:featured-genes' }),
        new OrderedSets({ key: 'browse:popular-categories' }),
        new OrderedSets({ key: 'browse:gene-categories' })
      ]

      # featuredGenes
      featuredGenes.add new OrderedSet( fabricate('set'), {
        key: "browse:featured-genes"
        name: "Featured Categories"
        item_type: "FeaturedLink"
      })
      featuredGenesLinks = new Items null, 'featured-gene-links'
      featuredGenesLinks.add(new Item( fabricate 'featured_link', { title: 'Featured Gene 1'} ))
      featuredGenesLinks.add(new Item( fabricate 'featured_link', { title: 'Featured Gene 2'} ))
      featuredGenes.at(0).set items: featuredGenesLinks

      # popularCategories
      popularCategories.add new OrderedSet( fabricate('set'), {
        key: "browse:popular-categories"
        name: "Popular Categories"
        item_type: "OrderedSet"
      })
      popularCategoriesOrderedSet = new OrderedSet( fabricate 'set', { name: 'Popular Category'} )
      popularCategoriesItems = new Items null, 'popular-categories-set'
      popularCategoriesItems.add popularCategoriesOrderedSet
      popularCategories.at(0).set items: popularCategoriesItems

      popularCategoriesOrderedSetItems = new Items null, 'popular-categories-ordered-set-items'
      popularCategoriesOrderedSetItems.add new Item( fabricate 'featured_link', { title: 'Chinese Art' } )
      popularCategoriesOrderedSetItems.add new Item( fabricate 'featured_link', { title: 'Color Fields' } )
      popularCategoriesOrderedSet.set items: popularCategoriesOrderedSetItems

      @template = render()(
        sd: {}
        asset: (->)
        featuredGenes: featuredGenes
        popularCategories: popularCategories
        geneCategories: geneCategories
        showBrowseCategories: true
      )

    it "includes all three genes and images", ->
      # featuredGenes
      @template.should.containEql 'browse-featured-gene'
      @template.should.containEql 'Featured Gene 1'
      @template.should.containEql 'Featured Gene 2'

      # popularCategories
      @template.should.containEql 'browse-popular-categories'
      @template.should.containEql 'Popular Category'
      @template.should.containEql 'Chinese Art'
      @template.should.containEql 'Color Fields'

    it 'includes partners (static list for now)', ->
      $ = cheerio.load @template
      @template.should.containEql 'Browse Partners'
      $(".bpc-partners a[href='/galleries']").text().should.equal "Galleries A-Z"
      $(".bpc-partners a[href='/institutions']").text().should.equal "Institutions A-Z"
      $(".bpc-partners a[href='/sfmoma']").text().should.equal "SFMOMA"
      $(".bpc-partners a[href='/britishmuseum']").text().should.equal "The British Museum"
      $(".bpc-partners a[href='/gagosian-gallery']").text().should.equal "Gagosian Gallery"
      $(".bpc-partners a[href='/pace-gallery']").text().should.equal "Pace Gallery"
      $(".bpc-partners a[href='/white-cube']").text().should.equal "White Cube"
      $(".bpc-partners a[href='/acquavella-galleries']").text().should.equal "Acquavella Galleries"
      $(".bpc-partners a[href='/partners']").text().should.equal "See All"

  describe 'with no ordered sets', ->
    beforeEach ->
      @template = render()(
        sd: {}
        asset: (->)
      )

    it "does not error", ->
      @template.should.containEql 'Browse Works'
