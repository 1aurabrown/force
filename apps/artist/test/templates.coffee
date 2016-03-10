jade = require 'jade'
fs = require 'fs'
benv = require 'benv'
{ resolve } = require 'path'
sinon = require 'sinon'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Artist = require '../../../models/artist'
Nav = require '../nav'
Carousel = require '../carousel'

describe 'Artist header', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      done()

  after ->
    benv.teardown()

  describe 'artist with some artworks', ->
    before (done) ->
      @artist = new Artist fabricate 'artist', published_artworks_count: 1
      @carousel = new Carousel artist: @artist
      @nav = new Nav artist: @artist, statuses:
        artworks: true
        shows: true
        articles: false
        artists: false
        contemporary: true

      benv.render resolve(__dirname, '../templates/index.jade'), {
        sd: CURRENT_PATH: "/artist/#{@artist.id}/shows"
        asset: (->)
        artist: @artist
        nav: @nav
        carousel: @carousel
      }, done

    it 'should not display the no works message if there is more than 0 artworks', ->
      @artist.get('published_artworks_count').should.be.above 0
      $('body').html().should.not.containEql "There are no #{@artist.get('name')} on Artsy yet."

    it 'should not display an auction results link', ->
      $('body').html().should.not.containEql 'artist-auction-results-link'

    it 'renders the appropriate nav', ->
      $navLinks = $('.garamond-bordered-tablist a')
      $navLinks.length.should.equal 4
      $navLinks.first().text().should.equal 'Overview'
      $navLinks.last().text().should.equal 'Related Artists'

  describe 'artist with some artworks (on the overview page)', ->
    beforeEach (done) ->
      @artist = new Artist fabricate 'artist', published_artworks_count: 0
      @carousel = new Carousel artist: @artist
      @nav = new Nav artist: @artist, statuses:
        artworks: false
        shows: true
        articles: false
        artists: false
        contemporary: false

      benv.render resolve(__dirname, '../templates/index.jade'), {
        sd: CURRENT_PATH: "/artist/#{@artist.id}/shows"
        asset: (->)
        artist: @artist
        nav: @nav
        carousel: @carousel
      }, done

    it 'should display the no works message if there is 0 artworks', ->
      @artist.get('published_artworks_count').should.equal 0
      $('body').html().should.containEql "There are no #{@artist.get('name')} works on Artsy yet."

    it 'renders the appropriate nav', ->
      $navLinks = $('.garamond-bordered-tablist a')
      $navLinks.length.should.equal 2
      $navLinks.first().text().should.equal 'Overview'
      $navLinks.last().text().should.equal 'Shows'
      $navLinks.text().should.not.containEql 'Works'

    it 'should not display an artworks section with no artworks', ->
      $('body').html().should.not.containEql 'artwork-section'
