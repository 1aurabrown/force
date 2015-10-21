_ = require 'underscore'
rewire = require 'rewire'
benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
UserEdit = require '../../models/user_edit.coffee'
AccountForm = benv.requireWithJadeify resolve(__dirname, '../../client/account_form.coffee'), ['template']

describe 'AccountForm', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  beforeEach (done) ->
    sinon.stub Backbone, 'sync'

    @userEdit = new UserEdit fabricate 'user', paddle_number: '1234', location: fabricate '@view.location'
    @view = new AccountForm userEdit: @userEdit
    @view.render()

    done()

  afterEach ->
    Backbone.sync.restore()

  describe '#render', ->
    it 'renders the view', ->
      @view.$el.html().should.containEql 'Information'

    it 'displays bidder number', ->
      @view.$('label.user-bidder-number').text().should.containEql '1234'

  describe '#toggleService', ->
    describe 'link', ->
      beforeEach ->
        @userEdit.set accessToken: 'x-foo-token'
        @view.location = assign: sinon.stub(), href: 'user/edit'
        @view.$('.settings-toggle-service[data-service="twitter"]').click()

      it 'links the correct service', ->
        @view.location.assign.args[0][0].should.containEql '/users/auth/twitter?'

      describe '#toggleLinked', ->
        it 'after linking redirects back to the user edit form', ->
          @view.location.assign.args[0][0].should.containEql 'redirect-to='
          @view.location.assign.args[0][0].should.containEql 'user%2Fedit'

    describe 'unlink', ->
      beforeEach ->
        sinon.stub(UserEdit::, 'isLinkedTo').returns true
        @view.$('.settings-toggle-service[data-service="twitter"]').click()

      afterEach ->
        @userEdit.isLinkedTo.restore()

      it 'destroys the authentication', ->
        Backbone.sync.args[0][0].should.equal 'delete'
        Backbone.sync.args[0][1].url.should.containEql '/api/v1/me/authentications/twitter'

      describe 'success', ->
        beforeEach ->
          Backbone.sync.restore()
          sinon.stub(Backbone, 'sync').yieldsTo 'success'
          (@$button = @view.$('.settings-toggle-service[data-service="twitter"]')).click()

        it 'sets the correct button state', ->
          @$button.data().should.eql service: 'twitter', connected: 'disconnected'

      describe 'error', ->
        beforeEach ->
          Backbone.sync.restore()
          sinon.stub(Backbone, 'sync').yieldsTo 'error', responseJSON: error: 'Something bad.'
          (@$button = @view.$('.settings-toggle-service[data-service="twitter"]')).click()

        it 'renders any errors', ->
          @view.$('#settings-auth-errors').text().should.equal 'Something bad.'

        it 'resets the button state', ->
          _.isUndefined(@$button.attr('data-state')).should.be.true()
