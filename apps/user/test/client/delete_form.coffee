_ = require 'underscore'
benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
CurrentUser = require '../../../../models/current_user'

describe 'UserDeleteForm', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  beforeEach (done) ->
    @user = new CurrentUser fabricate 'user'
    sinon.stub($, 'ajax')
    benv.render resolve(__dirname, '../../templates/delete.jade'), sd: {}, asset: (->), user: @user, =>
      UserDeleteForm = benv.requireWithJadeify(resolve(__dirname, '../../client/delete_form'), [])
      UserDeleteForm.__set__ 'FlashMessage', (@flashStub = sinon.stub())
      @view = new UserDeleteForm el: $('#settings'), model: @user
      done()

  afterEach ->
    $.ajax.restore()

  describe 'form contents', ->
    it 'disables the submit button until a confirmation is checked', ->
      @view.$confirm.is(':checked').should.be.false
      @view.$button.is(':disabled').should.be.true
      @view.$confirm.click()
      @view.$confirm.is(':checked').should.be.true
      @view.$button.is(':disabled').should.be.false

    it 'allows the user to enter a reason for deleting', ->
      @view.$explanation.val 'Removing an extra test account.'
      @view.$confirm.click()
      @view.$button.click()
      $.ajax.args[0][0].data.explanation.should.equal @view.$explanation.val()

  describe '#submit', ->
    describe 'success', ->
      beforeEach ->
        $.ajax.restore()
        sinon.stub($, 'ajax').yieldsTo("success")
        @view.$confirm.click()
        @view.$button.click()

      it 'DELETEs the user', ->
        $.ajax.args[0][0].method.should.equal 'DELETE'
        $.ajax.args[0][0].data.explanation.should.equal ''
        $.ajax.args[0][0].data.url.should.equal '/user/delete' # source of the post
        $.ajax.args[0][0].url.should.equal @user.url()

      it 'logs the user out', ->
        $.ajax.args[1][0].method.should.equal 'DELETE'
        $.ajax.args[1][0].url.should.equal '/users/sign_out'

      it 'flashes a success notification', ->
        @flashStub.called.should.be.true
        @flashStub.args[0][0].href.should.eql '/'
        @flashStub.args[0][0].message.should.containEql 'Your account has been deleted, click here to continue'

    describe 'error', ->
      beforeEach ->
        $.ajax.restore()
        sinon.stub($, 'ajax').yieldsTo 'error'

      it 'displays the error message', ->
        @view.$confirm.click()
        @view.$button.click()
        @flashStub.called.should.be.false
        @view.$errors.text().should.containEql 'An error prevented us from deleting your account through this form.'

    it 'adds the access token to the request', ->
      @user.set 'accessToken', '10101000101010101111010101010101'
      @view.$confirm.click()
      @view.$button.click()
      _.isUndefined($.ajax.args[0][0].data.access_token).should.be.false
      $.ajax.args[0][0].method.should.equal 'DELETE'
      $.ajax.args[0][0].data.access_token.should.equal @user.get('accessToken')
