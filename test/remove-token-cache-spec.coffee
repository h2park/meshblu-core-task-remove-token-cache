RemoveTokenCache = require '..'
crypto = require 'crypto'
redis  = require 'fakeredis'
uuid   = require 'uuid'

describe 'RemoveTokenCache', ->
  beforeEach ->
    @redisKey = uuid.v1()
    @uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid
    @sut = new RemoveTokenCache
      cache: redis.createClient(@redisKey)
      pepper: 'totally-a-secret'
      uuidAliasResolver: @uuidAliasResolver
    @cache = redis.createClient @redisKey

  describe '->do', ->
    beforeEach (done) ->
      @cache.set 'barber-slips:SPm/FSHcK75+KK0L2IPO7fas6zdlbPlYT3BLOWt9BiA=', '', done

    describe 'when the uuid/token combination is in the cache', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'asdf'
            auth:
              uuid:  'barber-slips'
              token: 'Just a little off the top'

        @sut.do request, (error, @response) => done error

      it 'should respond with a 204', ->
        expect(@response).to.deep.equal
          metadata:
            responseId: 'asdf'
            code: 204
            status: 'No Content'

      it 'should remove the token', (done) ->
        @cache.exists 'barber-slips:SPm/FSHcK75+KK0L2IPO7fas6zdlbPlYT3BLOWt9BiA=', (error, exists) =>
          return done error if error?
          expect(exists).to.equal 0
          done()
