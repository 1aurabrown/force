_ = require 'underscore'
Backbone = require 'backbone'
State = require '../index'

describe 'State', ->
  describe 'single path', ->
    beforeEach ->
      @state = new State steps: [
        'first'
        'second'
        'third'
        'fourth'
      ]

    describe '#current', ->
      it 'returns the first step in the path', ->
        @state.current().should.equal 'first'

    describe '#next', ->
      it 'moves through the steps; stopping at the end', ->
        @state.next().should.equal 'second'
        @state.current().should.equal 'second'
        @state.next().should.equal 'third'
        @state.isEnd().should.be.false
        @state.next().should.equal 'fourth'
        @state.isEnd().should.be.true
        @state.next().should.equal 'fourth'

  describe 'complex path', ->
    beforeEach ->
      @state = new State
        decisions:
          first_decision: ->
            false
          second_decision: ->
            true
          dependent_decision: ({ some_dependency }) ->
            some_dependency

        steps: [
          'first'
          'second'
          first_decision:
            true: ['true_first', 'true_second']
            false: [
              'false_first'
              second_decision:
                true: [
                  'false_true_first'
                  dependent_decision:
                    true: ['false_true_true_first']
                    false: ['false_true_false_first']
                ]
                false: ['false_false_first']
            ]
          'fourth'
        ]

    describe '#next', ->
      it 'moves through the states; making decisions and stopping at the end', ->
        @state.current().should.equal 'first'
        @state.next().should.equal 'second'
        @state.next().should.equal 'false_first' # Makes first_decision
        @state.next().should.equal 'false_true_first' # Makes second_decision

        # Inject dependencies at a later time
        @state.inject some_dependency: false
        @state.next().should.equal 'false_true_false_first' # Makes dependent_decision

    describe '#position; #total', ->
      beforeEach ->
        @state = new State
          decisions:
            on: ->
              'and_on'

          steps: [
            'first'
            'second'
            on:
              and_on: [
                'third'
                'fourth'
              ]
          ]

      it 'keeps track of the position', ->
        @state.current().should.equal 'first'
        @state.position().should.equal 1
        # `total` can only be reliably displayed when on the terminal leaf of a step tree
        @state.total().should.equal 3
        @state.isEnd().should.be.false

        @state.next().should.equal 'second'
        @state.position().should.equal 2
        @state.total().should.equal 3
        @state.isEnd().should.be.false

        @state.next().should.equal 'third'
        @state.position().should.equal 3
        @state.total().should.equal 4
        @state.isEnd().should.be.false

        @state.next().should.equal 'fourth'
        @state.position().should.equal 4
        @state.total().should.equal 4
        @state.isEnd().should.be.true