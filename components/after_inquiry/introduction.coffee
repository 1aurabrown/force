_ = require 'underscore'
_.mixin require 'underscore.string'
moment = require 'moment'
human = require 'humanparser'

module.exports = class Introduction
  constructor: (user, bookmarks) ->
    @user = user
    @bookmarks = bookmarks

  blurb: ->
    blurb = []
    # Sentence:
    blurb.push @firstName()
    if @user.isCollector()
      blurb.push 'is a collector'
      blurb.push 'and' if @user.id and !@user.hasLocation()
    else
      blurb.push 'is' if @user.hasLocation()
    blurb.push "based in #{@location()}" if @user.hasLocation()
    if @user.id # Logged in:
      blurb.push 'and' if @user.hasLocation()
      blurb.push "has been an Artsy member since #{moment(@user.get('created_at')).format('MMMM YYYY')}."
    else # Logged out:
      if @user.hasLocation() or @user.isCollector()
        blurb.push '.'
      else # Kill this sentence
        blurb = []
    # Sentence:
    blurb.push "#{@firstName()}’s profession is noted as “#{@user.get('profession')}.”" unless _.isEmpty(@user.get 'profession')
    # Sentence:
    blurb.push "#{@firstName()}’s collection includes #{@collectionSentence()}." if @collection()?.length
    blurb = blurb.join(' ').replace ' .', '.'
    return blurb unless _.isEmpty(blurb)

  firstName: ->
    @__firstName__ ?= _.titleize human.parseName(@user.get('name')).firstName

  location: ->
    if (location = @user.location())
      country = location.get 'country'
      domestic = country is "United States"
      region = if domestic then location.get 'state_code' else location.get 'country'
      @__location__ ?=
        _.compact([
          location.get 'city'
          region
        ]).join ', '

  collection: ->
    return unless @bookmarks?
    @__collection__ ?= _.pluck @bookmarks.pluck('artist'), 'name'

  collectionSentence: (limit = 3) ->
    artists = _.first(@collection(), limit)
    if @collection().length > limit
      artists.push "#{(remaining = @collection().length - limit)} other artist#{if remaining > 1 then 's' else ''}"
    artists.join(', ').replace /,\s([^,]+)$/, ' and $1'
