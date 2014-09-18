rewire = require 'rewire'
rewiredAnalytics = rewire '../../lib/analytics'
analytics = require '../../lib/analytics'
Artwork = require '../../models/artwork'
sinon = require 'sinon'
sd = require('sharify').data
benv = require 'benv'
_ = require 'underscore'

describe 'analytics', ->

  describe 'with a standard useragent', ->

    before ->
      sinon.stub(analytics, 'getUserAgent').returns "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.102 Safari/537.36"

    after ->
      analytics.getUserAgent.restore()

    beforeEach ->
      sd.MIXPANEL_ID = 'mix that panel'
      sd.GOOGLE_ANALYTICS_ID = 'goog that analytics'
      sd.SNOWPLOW_COLLECTOR_HOST = 'plow that snow'
      @mixpanelStub = { get_property: sinon.stub(), register_once: sinon.stub() }
      @mixpanelStub.track = sinon.stub()
      @mixpanelStub.register = sinon.stub()
      @mixpanelStub.init = sinon.stub()
      @snowplowStub = sinon.stub()

      @gaStub = sinon.stub()
      analytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }, snowplow: @snowplowStub

    describe 'initialize function', ->

      it 'inits ga with the GOOGLE_ANALYTICS_ID', ->
        @gaStub.args[0][0].should.equal 'create'
        @gaStub.args[0][1].should.equal 'goog that analytics'

    describe '#trackPageview', ->

      it 'sends a google pageview', ->
        analytics.trackPageview()
        @gaStub.args[1][0].should.equal 'send'
        @gaStub.args[1][1].should.equal 'pageview'

      it 'doesnt let failed analytics mess up js code', ->
        analytics mixpanel: null, ga: null, location: { pathname: 'foobar' }
        analytics.trackPageview()
        analytics.getProperty('foo')
        analytics.setProperty('foo')

    describe '#modelNameAndIdToLabel', ->

      it 'capitalizes modelname', ->
        analytics.modelNameAndIdToLabel('modelname', 123).should.equal 'Modelname:123'

      it 'errors without modelName or id', ->
        (()-> analytics.modelNameAndIdToLabel()).should.throw()

    describe '#encodeMulti', ->

      it "encodes ids into hex values", ->
        analytics.encodeMulti(['andy', 'warhol']).should.equal 'da41bcef-5ef1fd34'

      it "encodes one id into hex value", ->
        analytics.encodeMulti(['andy']).should.equal 'da41bcef'

    context 'with rewiredAnalytics', ->

      beforeEach (done) ->
        benv.setup =>
          benv.expose
            $: benv.require 'jquery'
            ga: @gaStub
            mixpanel: @mixpanelStub
            snowplow: @snowplowStub
          rewiredAnalytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }, snowplow: @snowplowStub
          done()

      afterEach ->
        benv.teardown()

      describe '#track', ->

        it 'Does not track admins', ->
          model = new Artwork(id: '123')
          sd.CURRENT_USER = { type: 'Admin' }
          rewiredAnalytics.track.click 'Did something', { label: rewiredAnalytics.modelNameAndIdToLabel('artwork', model.get('id')) }
          @gaStub.args.length.should.equal 2

        it 'Tracks normal users', ->
          model = new Artwork(id: '123')
          sd.CURRENT_USER = { type: 'User' }
          rewiredAnalytics.track.click 'Did something', { label: rewiredAnalytics.modelNameAndIdToLabel('artwork', model.get('id')) }
          @gaStub.args.length.should.equal 3

        it 'Tracks logged out users', ->
          model = new Artwork(id: '123')
          sd.CURRENT_USER = null
          rewiredAnalytics.track.click 'Did something', { label: rewiredAnalytics.modelNameAndIdToLabel('artwork', model.get('id')) }
          @gaStub.args.length.should.equal 3

        it 'sends tracking info to both ga and mixpanel', ->
          model = new Artwork(id: '123')
          rewiredAnalytics.track.click 'Did something', { label: rewiredAnalytics.modelNameAndIdToLabel('artwork', model.get('id')) }

          @gaStub.args[2][0].should.equal 'send'
          @gaStub.args[2][1].hitType.should.equal 'event'
          @gaStub.args[2][1].eventCategory.should.equal 'UI Interactions'
          @gaStub.args[2][1].eventAction.should.equal 'Did something'
          @gaStub.args[2][1].nonInteraction.should.equal 0

          @mixpanelStub.track.args[0][0].should.equal 'Did something'
          @mixpanelStub.track.args[0][1].label.should.equal 'Artwork:123'

        it 'sends funnel tracking info to both ga and mixpanel', ->
          model = new Artwork(id: '123')
          rewiredAnalytics.track.funnel 'Did something', { label: 'cool label' }

          @gaStub.args[2][0].should.equal 'send'
          @gaStub.args[2][1].hitType.should.equal 'event'
          @gaStub.args[2][1].eventCategory.should.equal 'Funnel Progressions'
          @gaStub.args[2][1].eventAction.should.equal 'Did something'
          @gaStub.args[2][1].nonInteraction.should.equal 1

          @mixpanelStub.track.args[0][0].should.equal 'Did something'
          @mixpanelStub.track.args[0][1].label.should.equal 'cool label'

      describe '#registerCurrentUser', ->

        it 'Does not track admins', ->
          sd.CURRENT_USER = { type: 'Admin' }
          rewiredAnalytics.registerCurrentUser()
          @mixpanelStub.register.args.length.should.equal 0
          @snowplowStub.args.length.should.equal 0

        it 'Tracks normal users', ->
          sd.CURRENT_USER = { type: 'User', id: 'Driver' }
          rewiredAnalytics.registerCurrentUser()
          @mixpanelStub.register.args.length.should.equal 1
          @mixpanelStub.register.args[0][0]['User Type'].should.equal 'Logged In'
          @snowplowStub.args[0][0].should.equal 'setUserId'
          @snowplowStub.args[0][1].should.equal 'Driver'

        it 'Tracks logged out users', ->
          sd.CURRENT_USER = null
          rewiredAnalytics.registerCurrentUser()
          @mixpanelStub.register.args.length.should.equal 1
          @mixpanelStub.register.args[0][0]['User Type'].should.equal 'Logged Out'

        it "Doesn't include artsy user_id for logged out users", ->
          sd.CURRENT_USER = null
          rewiredAnalytics.registerCurrentUser()
          @snowplowStub.args.length.should.equal 0

      describe '#multi', ->

        it 'sets the object ID to the concatenation of shortened MD5 hashes', (done) ->
          rewiredAnalytics.multi "Did something", "Artwork", [ "thug-slug", "pug-slug" ]
          setTimeout =>
            @gaStub.args[2][0].should.equal 'send'
            @gaStub.args[2][1].should.equal 'event'
            @gaStub.args[2][2].should.equal 'Multi-object Events'
            @gaStub.args[2][3].should.equal 'Did something'
            @gaStub.args[2][4].should.equal 'Artwork:cb7a5c6f-ab197545'
            done()
          , 1000

      describe 'with a DOM', ->

        describe '#trackLinks', ->
          beforeEach ->
            sinon.stub _, 'delay'
            $('body').html """
              <a href="/foobar" class="click-me">Click me</a>
              <a href="/foobar" target="_blank" class="click-me-external">Click me</a>
            """
            rewiredAnalytics.trackLinks '.click-me', 'Clicked the link'
            rewiredAnalytics.trackLinks '.click-me-external', 'Clicked the external link'

          afterEach ->
            _.delay.restore()
            $('body').html ''

          it 'tracks links', ->
            $('.click-me').click()
            @gaStub.args[2][1].eventAction.should.equal 'Clicked the link'

          it 'sets up a delayed callback incase mixpanel doesnt return', ->
            $('.click-me').click()
            _.delay.args[0][1].should.equal 300
            _.delay.args[0][0]() # Run the callback
            window.location.should.containEql '/foobar'

          it 'does not run a delayed callback if the link is external', ->
            $('.click-me-external').click()
            @gaStub.args[2][1].eventAction.should.equal 'Clicked the external link'
            _.delay.called.should.be.false

          describe 'with stubbed track.click', ->
            beforeEach ->
              sinon.stub rewiredAnalytics.track, 'click'

            afterEach ->
              rewiredAnalytics.track.click.restore()

            it 'passes the callback to track', ->
              $('.click-me').click()
              rewiredAnalytics.track.click.args[0][0].should.equal 'Clicked the link'
              rewiredAnalytics.track.click.args[0][2]() # Run the callback
              window.location.should.containEql 'foobar'

      describe '#splitTest', ->

        beforeEach ->
          rewiredAnalytics.__set__ 'sd', { ENABLE_AB_TEST: true }
          rewiredAnalytics.getProperty = -> null
          @_ = rewiredAnalytics.__get__ '_'
          sinon.stub @_, 'random'

        afterEach ->
          @_.random.restore()

        it 'fails if the percents dont add up', ->
          (-> rewiredAnalytics.splitTest 'foo', { a: 0.1, b: 0.2, c: 0.1 }).should.throw(
            "Your percent values for paths must add up to 1.0"
          )

        it 'returns a random path', ->
          @_.random.returns 30
          rewiredAnalytics.splitTest('foo', { a: 0.5, b: 0.2, c: 0.3 }).should.equal 'a'
          @_.random.returns 60
          rewiredAnalytics.splitTest('foo', { a: 0.5, b: 0.2, c: 0.3 }).should.equal 'b'
          @_.random.returns 90
          rewiredAnalytics.splitTest('foo', { a: 0.5, b: 0.2, c: 0.3 }).should.equal 'c'

    describe '#abTest', ->

      it 'returns true if enabled', ->
        rewiredAnalytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }
        rewiredAnalytics.getProperty = -> 'enabled'
        rewiredAnalytics.__set__ 'sd', { ENABLE_AB_TEST: true }
        rewiredAnalytics.abTest('foo').should.be.ok

      it 'returns false if disabled', ->
        rewiredAnalytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }
        rewiredAnalytics.getProperty = -> 'disabled'
        rewiredAnalytics.__set__ 'sd', { ENABLE_AB_TEST: true }
        rewiredAnalytics.abTest('foo').should.not.be.ok

      it 'returns false if ab test is not enabled', ->
        rewiredAnalytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }
        rewiredAnalytics.__set__ 'sd', { ENABLE_AB_TEST: false }
        rewiredAnalytics.abTest('foo').should.not.be.ok

    describe '#delta', ->
      it 'appends a tracker pixel', ->
        sd.DELTA_HOST = 'testhost'
        url = "https://" + sd.DELTA_HOST + "/?id=test_id&fair=test_fair&name=test_event&method=import&pixel=1"
        el = {}
        el.append = sinon.stub()
        data = { id: 'test_id', fair: 'test_fair' }
        analytics.delta('test_event', data, el)
        el.append.called.should.be.ok
        el.append.args[0][0].should.equal '<img src="' + url + '" style="display:none;" />'

  describe 'with a phantomjs useragent', ->

    before ->
      sinon.stub(analytics, 'getUserAgent').returns "PhantomJS"

    after ->
      analytics.getUserAgent.restore()

    beforeEach ->
      sd.MIXPANEL_ID = 'mix that panel'
      sd.GOOGLE_ANALYTICS_ID = 'goog that analytics'
      @mixpanelStub = {}
      @mixpanelStub.track = sinon.stub()

      @mixpanelStub.init = sinon.stub()
      @gaStub = sinon.stub()
      analytics mixpanel: @mixpanelStub, ga: @gaStub, location: { pathname: 'foobar' }

    describe 'initialize function', ->

      it 'doesnt init mixpanel with the MIXPANEL_ID', ->
        @mixpanelStub.init.args.length.should.equal 0

      it 'doesnt init ga with the GOOGLE_ANALYTICS_ID', ->
        @gaStub.args.length.should.equal 0
        @gaStub.args.length.should.equal 0

    describe '#trackPageview', ->

      it 'doesnt track pageviews', ->
        analytics.trackPageview()
        @gaStub.args.length.should.equal 0
        @gaStub.args.length.should.equal 0

      it 'doesnt let failed analytics mess up js code', ->
        analytics mixpanel: null, ga: null, location: { pathname: 'foobar' }
        analytics.trackPageview()
        analytics.snowplowStruct()
