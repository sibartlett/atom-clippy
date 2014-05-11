$ = require('atom').$

class Queue
  constructor: (@_onEmptyCallback) ->
    @_queue = []

  queue: (func) ->
    @_queue.push func
    @_progressQueue()  if @_queue.length is 1 and not @_active

  _progressQueue: ->
    # stop if nothing left in queue
    unless @_queue.length
      @_onEmptyCallback()
      return
    f = @_queue.shift()
    @_active = true

    # execute function
    completeFunction = $.proxy(@next, this)
    f completeFunction
    return

  clear: ->
    @_queue = []
    return

  next: ->
    @_active = false
    @_progressQueue()
    return

module.exports = Queue
