module.exports = (artwork) ->
  message = 'Hello, I’m interested in this work'
  message += " by #{artwork.artistName()}" if artwork.get('artist')
  message += '. Could you please confirm its availability'
  message += ' and price' unless artwork.isPriceDisplayable()
  message += '? Thank you.'
