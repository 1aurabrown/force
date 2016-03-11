{ MEDIUM, CURRENT_USER } = require('sharify').data
AuthModalView = require '../../../components/auth_modal/view.coffee'
CTABarView = require '../../../components/cta_bar/view.coffee'

module.exports = (artist) ->
  return unless MEDIUM is 'search' and not CURRENT_USER?

  name = 'artist_cta'
  ctaHeadline = "Get updates on new shows and works by #{artist.get('name')}."
  modalCopy = "Get the latest new shows and works by #{artist.get('name')}."

  ctaBarView = new CTABarView
    headline: ctaHeadline
    name: name
    mode: ''
    persist: true
    modalOptions:
      copy: modalCopy
      destination: "#{artist.href().replace "/artist/", "/artist_2"}/follow"

  unless ctaBarView.previouslyDismissed()
    $('body').append ctaBarView.render().$el

    $('#artwork-section').waypoint (direction) ->
      ctaBarView.transitionIn() if direction is 'down'
    , { offset: 'bottom-in-view' }
