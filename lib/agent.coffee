$ = require('atom').$
Queue = require './queue'
Animator = require './animator'
Balloon = require './balloon'

class Agent

  constructor: (path, data, sounds) ->
    @_hidden = true
    @path = path
    @_queue = new Queue($.proxy(@_onQueueEmpty, this))
    @_el = $("<div class=\"clippy\"></div>").hide()
    # $(document.body).append @_el
    atom.workspaceView.append @_el
    @_animator = new Animator(@_el, path, data, sounds)
    @_balloon = new Balloon(@_el)
    @_setupEvents()

  gestureAt: (x, y) ->
    d = @_getDirection(x, y)
    gAnim = "Gesture" + d
    lookAnim = "Look" + d
    animation = (if @hasAnimation(gAnim) then gAnim else lookAnim)
    @play animation

  hide: (fast, callback) ->
    if not @_hidden
      @_hidden = true
      el = @_el
      @stop()
      if fast
        @_el.hide()
        @stop()
        @pause()
        callback()  if callback
        return
      @_playInternal "Hide", ->
        el.hide()
        @pause()
        callback()  if callback
        return

  moveTo: (x, y, duration) ->
    dir = @_getDirection(x, y)
    anim = "Move" + dir
    duration = 1000  if duration is `undefined`
    @_addToQueue ((complete) ->

      # the simple case
      if duration is 0
        @_el.css
          top: y
          left: x

        @reposition()
        complete()
        return

      # no animations
      unless @hasAnimation(anim)
        @_el.animate
          top: y
          left: x
        , duration, complete
        return
      callback = $.proxy((name, state) ->

        # when exited, complete
        complete()  if state is Animator.States.EXITED

        # if waiting,
        if state is Animator.States.WAITING
          @_el.animate
            top: y
            left: x
          , duration, $.proxy(->

            # after we're done with the movement, do the exit animation
            @_animator.exitAnimation()
            return
          , this)
        return
      , this)
      @_playInternal anim, callback
      return
    ), this
    return

  _playInternal: (animation, callback) ->
    # if we're inside an idle animation,
    if @_isIdleAnimation() and @_idleDfd and @_idleDfd.state() is "pending"
      @_idleDfd.done $.proxy(->
        @_playInternal animation, callback
        return
      , this)
    @_animator.showAnimation animation, callback

  play: (animation, timeout, cb) ->
    return false  unless @hasAnimation(animation)
    timeout = 5000  if timeout is `undefined`
    @_addToQueue ((complete) ->
      completed = false

      # handle callback
      callback = (name, state) ->
        if state is Animator.States.EXITED
          completed = true
          cb()  if cb
          complete()
        return


      # if has timeout, register a timeout function
      if timeout
        window.setTimeout $.proxy(->
          return  if completed

          # exit after timeout
          @_animator.exitAnimation()
          return
        , this), timeout
      @_playInternal animation, callback
      return
    ), this
    true

  show: (fast) ->
    if @_hidden
      @_hidden = false
      if fast
        @_el.show()
        @resume()
        @_onQueueEmpty()
        return
      if @_el.css("top") is "auto" or not @_el.css("left") is "auto"
        left = $(window).width() * 0.8
        top = ($(window).height() + $(document).scrollTop()) * 0.8
        @_el.css
          top: top
          left: left

      @resume()
      @play "Show"

  speak: (text, hold) ->
    @_addToQueue ((complete) ->
      @_balloon.speak complete, text, hold
    ), this

  closeBalloon: ->
    @_balloon.hide()

  delay: (time) ->
    time = time or 250
    @_addToQueue (complete) ->
      @_onQueueEmpty()
      window.setTimeout complete, time

  stopCurrent: ->
    @_animator.exitAnimation()
    @_balloon.close()
    return

  stop: ->
    # clear the queue
    @_queue.clear()
    @_animator.exitAnimation()
    @_balloon.hide()

  ###
  @param {String} name
  @returns {Boolean}
  ###
  hasAnimation: (name) ->
    @_animator.hasAnimation name


  ###
  Gets a list of animation names
  @return {Array.<string>}
  ###
  animations: ->
    @_animator.animations()


  ###
  Play a random animation
  @return {jQuery.Deferred}
  ###
  animate: ->
    animations = @animations()
    anim = animations[Math.floor(Math.random() * animations.length)]

    # skip idle animations
    return @animate()  if anim.indexOf("Idle") is 0
    @play anim


  ###
  Utils ***********************************
  ###

  ###
  @param {Number} x
  @param {Number} y
  @return {String}
  @private
  ###
  _getDirection: (x, y) ->
    offset = @_el.offset()
    h = @_el.height()
    w = @_el.width()
    centerX = (offset.left + w / 2)
    centerY = (offset.top + h / 2)
    a = centerY - y
    b = centerX - x
    r = Math.round((180 * Math.atan2(a, b)) / Math.PI)

    # Left and Right are for the character, not the screen :-/
    return "Right"  if -45 <= r and r < 45
    return "Up"  if 45 <= r and r < 135
    return "Left"  if 135 <= r and r <= 180 or -180 <= r and r < -135
    return "Down"  if -135 <= r and r < -45

    # sanity check
    "Top"


  ###
  Queue and Idle handling ***********************************
  ###

  ###
  Handle empty queue.
  We need to transition the animation to an idle state
  @private
  ###
  _onQueueEmpty: ->
    return  if @_hidden or @_isIdleAnimation()
    idleAnim = @_getIdleAnimation()
    @_idleDfd = $.Deferred()
    @_animator.showAnimation idleAnim, $.proxy(@_onIdleComplete, this)

  _onIdleComplete: (name, state) ->
    @_idleDfd.resolve()  if state is Animator.States.EXITED

  ###
  Is the current animation is Idle?
  @return {Boolean}
  @private
  ###
  _isIdleAnimation: ->
    c = @_animator.currentAnimationName
    c and c.indexOf("Idle") is 0


  ###
  Gets a random Idle animation
  @return {String}
  @private
  ###
  _getIdleAnimation: ->
    animations = @animations()
    r = []
    i = 0

    while i < animations.length
      a = animations[i]
      r.push a  if a.indexOf("Idle") is 0
      i++

    # pick one
    idx = Math.floor(Math.random() * r.length)
    r[idx]


  ###
  Events ***********************************
  ###
  _setupEvents: ->
    $(window).on "resize", $.proxy(@reposition, this)
    @_el.on "mousedown", $.proxy(@_onMouseDown, this)
    @_el.on "dblclick", $.proxy(@_onDoubleClick, this)

  _onDoubleClick: ->
    @animate() unless @play("ClickedOn")

  reposition: ->
    return  unless @_el.is(":visible")
    o = @_el.offset()
    bH = @_el.outerHeight()
    bW = @_el.outerWidth()
    wW = $(window).width()
    wH = $(window).height()
    sT = $(window).scrollTop()
    sL = $(window).scrollLeft()
    top = o.top - sT
    left = o.left - sL
    m = 5
    if top - m < 0
      top = m
    else top = wH - bH - m  if (top + bH + m) > wH
    if left - m < 0
      left = m
    else left = wW - bW - m  if left + bW + m > wW
    @_el.css
      left: left
      top: top


    # reposition balloon
    @_balloon.reposition()

  _onMouseDown: (e) ->
    if (e.which == 1)
      e.preventDefault()
      @_startDrag e


  ###
  Drag ***********************************
  ###
  _startDrag: (e) ->

    # pause animations
    @pause()
    @_balloon.hide true
    @_offset = @_calculateClickOffset(e)
    @_moveHandle = $.proxy(@_dragMove, this)
    @_upHandle = $.proxy(@_finishDrag, this)
    $(window).on "mousemove", @_moveHandle
    $(window).on "mouseup", @_upHandle
    @_dragUpdateLoop = window.setTimeout($.proxy(@_updateLocation, this), 10)

  _calculateClickOffset: (e) ->
    mouseX = e.pageX
    mouseY = e.pageY
    o = @_el.offset()
    top: mouseY - o.top
    left: mouseX - o.left

  _updateLocation: ->
    @_el.css
      top: @_targetY
      left: @_targetX

    @_dragUpdateLoop = window.setTimeout($.proxy(@_updateLocation, this), 10)

  _dragMove: (e) ->
    e.preventDefault()
    x = e.clientX - @_offset.left
    y = e.clientY - @_offset.top
    @_targetX = x
    @_targetY = y

  _finishDrag: ->
    window.clearTimeout @_dragUpdateLoop

    # remove handles
    $(window).off "mousemove", @_moveHandle
    $(window).off "mouseup", @_upHandle

    # resume animations
    @_balloon.show()
    @reposition()
    @resume()

  _addToQueue: (func, scope) ->
    func = $.proxy(func, scope)  if scope
    @_queue.queue func

  ###
  Pause and Resume ***********************************
  ###
  pause: ->
    @_animator.pause()
    @_balloon.pause()

  resume: ->
    @_animator.resume()
    @_balloon.resume()

module.exports = Agent
