deslugify = require '../index'

describe 'deslugify', ->
  it 'deals with reasonable slugs', ->
    deslugify('gagosian-gallery').should.equal 'Gagosian Gallery'
    deslugify('simon-lee-gallery').should.equal 'Simon Lee Gallery'
    deslugify('joseph-k-levene-fine-art-ltd').should.equal 'Joseph K Levene Fine Art Ltd'

  it 'deals with trailing numbers', ->
    deslugify('whitney-museum-of-american-art1').should.equal 'Whitney Museum Of American Art'
    deslugify('whitney-museum-of-american-art-1').should.equal 'Whitney Museum Of American Art'
    deslugify('whitney-museum-of-american-art-82').should.equal 'Whitney Museum Of American Art'
    deslugify('whitney-museum-of-american-art_999').should.equal 'Whitney Museum Of American Art'
    deslugify('1-whitney-museum-of-american-art_999').should.equal '1 Whitney Museum Of American Art'

  it 'preserves strings which are entirely numeric', ->
    deslugify('1990').should.equal '1990'
    deslugify('2000').should.equal '2000'

  it 'handles special cases', ->
    deslugify('film-video').should.equal 'Film / Video'

  it 'handles slugs with symbol words in them', ->
    deslugify('fleisher-slash-ollman').should.equal 'Fleisher / Ollman'
    deslugify('bernarducci-dot-meisel-gallery').should.equal 'Bernarducci.Meisel Gallery'
    deslugify('m-plus-b').should.equal 'M + B'
