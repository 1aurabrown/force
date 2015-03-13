_ = require 'underscore'
jade = require 'jade'
path = require 'path'
fs = require 'graceful-fs'

{ fabricate } = require 'antigravity'
CurrentUser = require '../../../../models/current_user'

render = (templateName) ->
  filename = path.resolve __dirname, "../templates/#{templateName}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Header template', ->
  it 'displays the welcome header', ->
    render('index')(sd: { HIDE_HEADER: false }, user: undefined).should.containEql 'main-layout-welcome-header'

  it 'hides the welcome header', ->
    render('index')(sd: { HIDE_HEADER: true }, user: undefined).should.not.containEql 'main-layout-welcome-header'

  it 'shows the admin link for admins', ->
    user = new CurrentUser fabricate('user', type: 'Admin', is_slumming: false)
    html = render('index')(sd: { ADMIN_URL: 'admin.com' }, user: user)
    html.should.not.containEql 'main-layout-welcome-header'
    html.should.containEql 'admin.com'

  it 'hides the admin link for slumming admins', ->
    user = new CurrentUser fabricate('user', type: 'Admin', is_slumming: true)
    html = render('index')(sd: { ADMIN_URL: 'admin.com' }, user: user)
    html.should.not.containEql 'main-layout-welcome-header'
    html.should.not.containEql 'admin.com'

  it 'shows the cms link for users with partner access', ->
    user = new CurrentUser(fabricate 'user', has_partner_access: true)
    html = render('index')(sd: { CMS_URL: 'cms.com' }, user: user)
    html.should.not.containEql 'main-layout-welcome-header'
    html.should.containEql 'cms.com'

describe 'Microsite template', ->
  it 'does not render the welcome header', ->
    render('microsite')(sd: { HIDE_HEADER: true }, user: undefined).should.not.containEql 'main-layout-welcome-header'

  it 'renders the user nav', ->
    user = new CurrentUser fabricate('user')
    html = render('microsite')(sd: {}, user: user)
    html.should.not.containEql 'main-layout-welcome-header'
    html.should.containEql user.get('name')

  it 'works with out user', ->
    html = render('microsite')(sd: { CMS_URL: 'cms.com' })
    html.should.containEql '/log_in'
