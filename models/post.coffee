_ = require 'underscore'
_s = require 'underscore.string'
Backbone = require 'backbone'
sd = require('sharify').data
moment = require 'moment'
Profile = require './profile.coffee'
Artwork = require './artwork.coffee'
Artists = require '../collections/artists.coffee'
Artworks = require '../collections/artworks.coffee'
AdditionalImage = require '../models/additional_image.coffee'
Attachments = require '../components/post/collections/post_attachments.coffee'
Reposts = require '../components/post/collections/reposts.coffee'
{ smartTruncate } = require '../components/util/string.coffee'
{ compactObject } = require './mixins/compact_object.coffee'

module.exports = class Post extends Backbone.Model

  urlRoot: "#{sd.API_URL}/api/v1/post"
  href: -> "/post/#{@get('id')}"
  canonicalUrl: -> sd.APP_URL + @href()
  profile: -> new Profile @get('profile')

  # Use the first paragraph.
  # If first paragraph is less than 210 chars,
  # continue pulling in second paragraph.
  # Cut text with ellipsis at 385 chars.
  extendedSummary: ->
    paragraphMin = 210
    maxLimit = 385
    firstParagraph = _s.stripTags _.first(@get('body').split '</p>')
    summary = if firstParagraph.length < paragraphMin
      _s.stripTags(@get 'body')
    else
      firstParagraph
    _s.prune summary, maxLimit, '…'

  onPostPage: (location) ->
    location ?= window?.location?.pathname
    location == @href()

  shareTitle: ->
    profile = @profile()
    if @get('title') and profile?.displayName()
      "#{profile.displayName()}: #{@get('title')}"
    else if profile?.displayName()
      "#{profile.displayName()} on Artsy"
    else if @get('title')
      "#{@get('title')}"
    else
      "Post on @artsy"

  titleOrBody: (length=60) ->
    if @get('title')
      smartTruncate @get('title'), length
    else if @get('summary')
      smartTruncate @get('summary'), length

  metaTitle: ->
    _.compact([
      @titleOrBody()
      @profile()?.displayName()
      "Artsy"
    ]).join(" | ")

  artworkTitles: ->
    return unless @get('artworks')
    _.compact(for artwork in @get('artworks')
      new Artwork(artwork).toOneLine()
    ).join(', ')

  metaDescription: ->
    _.compact([
      smartTruncate(@get('summary'), 200)
      @artworkTitles()
    ]).join(" | ")

  defaultImage: ->
    _.first(@artworks().models)?.defaultImage() or
    @images().first() or
    @attachmentImage()

  # This takes care of attachments that don't implement
  # the usual images interface (i.e. post videos or post links).
  # They *do* often have a single imageSrc, so this returns the
  # usual methods on a bare object so they can be called normally
  # (Useful for post thumbnails)
  attachmentImage: ->
    if @attachments().length
      src = _.first(@attachments()).imageSrc()
      if src
        imageUrlFor: -> src
        imageUrl: -> src

  artworks: ->
    new Artworks(@get('attachments')
      .filter((attachment) -> attachment.type == "PostArtwork" && attachment.artwork )
      .map((attachment) -> attachment.artwork )
    )

  relatedArtists: (limit=10) ->
    artists = _.compact @artworks().map (artwork) ->
      artwork.get('artist')

    if artists?[0...limit]
      new Artists(artists[0...limit])

  hasArworks: -> @artworks()?.length > 0

  images: ->
    images = _.filter @get('attachments'), (attachment) ->
      attachment.type is 'PostImage'
    new Backbone.Collection images, model: AdditionalImage

  postedAt: ->
    moment(@get('last_promoted_at')).fromNow()

  repostedBy: ->
    @get('reposts')?[0]?.profile?.owner?.name

  attachments: -> new Attachments(@get('attachments')).models

  featuredPostsThumbnail: ->
    # Filter for post attachments that are either an Artwork or an Image
    @attachments().filter((attachment) ->
      attachment.get('type') == "PostArtwork" or attachment.get('type') == "PostImage"
    )[0]

  reposts: -> @get('reposts')

  ensureRepostsFetched: (callback) ->
    unless @get('reposts')
      collection = new Reposts()
      collection.fetch
        data:
          post_id: @get('id')
        success: =>
          @set reposts: collection
          callback?(@get('reposts'))
      @set reposts: collection
    else
      callback?(@get('reposts'))

  #
  # Admin for editing, flagging  and reposting
  #
  feature: (options) ->
    @set featured: true
    @save
      success: options?.success
      error: options?.error

  unfeature: (options) ->
    @set featured: false
    @save
      success: options?.success
      error: options?.error

  flag: (options) ->
    @set flagged: true
    @save
      success: options?.success
      error: options?.error

  unflag: (options) ->
    @set flagged: false
    @save
      success: options?.success
      error: options?.error

  repost: (options) ->
    model = new Backbone.Model()
    model.url = "#{sd.API_URL}/api/v1/repost"
    model.save
      post_id: @get('id')
      success: (data, status, xhr) =>
        @get('reposts').add data
        options?.success(data, status, xhr)
      error: options?.error

  unrepost: (repost, options) ->
    model = new Backbone.Model id: @get('id')
    model.url = "#{sd.API_URL}/api/v1/repost"
    model.destroy
      data:
        post_id: @get('id')
      success: options?.success
      error: options?.error

  ensureFeatureArtworksFetched: (callback) ->
    if @get('feature_artworks')
      callback?(@get('feature_artworks'))
    else
      artworks = new Artworks()
      artworks.fetch
        url: "#{@url()}/features/artworks"
        success: (artworks) =>
          @set('feature_artworks', artworks)
          callback?(artworks)

  ensureFeatureArtistsFetched: (callback) ->
    if @get('feature_artists')
      callback?(@get('feature_artists'))
    else
      artists = new Backbone.Collection()
      artists.fetch
        url: "#{@url()}/features/artists"
        success: (artists) =>
          @set('feature_artists', artists)
          callback?(artists)

  toJSONLD: ->
    compactObject {
      "@context": "http://schema.org"
      "@type": "Article"
      image: @get('shareable_image_url')
      title: @titleOrBody(100)
      description: smartTruncate(@get('summary'), 200)
      datePublished: @get('last_promoted_at')
      articleBody: _s.stripTags(@get 'body')
      sourceOrganization:
        name: 'artsy'
        url: 'https://artsy.net'
        logo: "#{sd.ASSET_PATH}og_image.jpg"
    }
