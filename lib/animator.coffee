$ = require 'jquery'

class Animator

  constructor: (el, path, data, sounds) ->
    @_el = el
    @_data = data
    @_path = path
    @_currentFrameIndex = 0
    @_currentFrame = `undefined`
    @_exiting = false
    @_currentAnimation = `undefined`
    @_endCallback = `undefined`
    @_started = false
    @_sounds = {}
    @currentAnimationName = `undefined`
    @preloadSounds sounds
    @_overlays = [@_el]
    curr = @_el
    @_setupElement @_el
    i = 1

    while i < @_data.overlayCount
      inner = @_setupElement($("<div></div>"))
      curr.append inner
      @_overlays.push inner
      curr = inner
      i++

  _setupElement: (el) ->
    frameSize = @_data.framesize
    el.css "display", "none"
    el.css
      width: frameSize[0]
      height: frameSize[1]

    el.css "background", "url('" + @_path + "/map.png') no-repeat"
    el

  animations: ->
    r = []
    d = @_data.animations
    for n of d
      r.push n
    r

  preloadSounds: (sounds) ->
    i = 0

    while i < @_data.sounds.length
      snd = @_data.sounds[i]
      uri = sounds[snd]
      continue  unless uri
      @_sounds[snd] = new Audio(uri)
      i++

  hasAnimation: (name) ->
    !!@_data.animations[name]

  exitAnimation: ->
    @_exiting = true

  showAnimation: (animationName, stateChangeCallback) ->
    @_exiting = false
    return false  unless @hasAnimation(animationName)
    @_currentAnimation = @_data.animations[animationName]
    @currentAnimationName = animationName
    unless @_started
      @_step()
      @_started = true
    @_currentFrameIndex = 0
    @_currentFrame = `undefined`
    @_endCallback = stateChangeCallback
    true

  _draw: ->
    images = []
    images = @_currentFrame.images or []  if @_currentFrame
    i = 0

    while i < @_overlays.length
      if i < images.length
        xy = images[i]
        bg = -xy[0] + "px " + -xy[1] + "px"
        @_overlays[i].css
          "background-position": bg
          display: "block"

      else
        @_overlays[i].css "display", "none"
      i++

  _getNextAnimationFrame: ->
    return `undefined`  unless @_currentAnimation

    # No current frame. start animation.
    return 0  unless @_currentFrame
    currentFrame = @_currentFrame
    branching = @_currentFrame.branching
    if @_exiting and currentFrame.exitBranch isnt `undefined`
      return currentFrame.exitBranch
    else if branching
      rnd = Math.random() * 100
      i = 0

      while i < branching.branches.length
        branch = branching.branches[i]
        return branch.frameIndex  if rnd <= branch.weight
        rnd -= branch.weight
        i++
    @_currentFrameIndex + 1

  _playSound: ->
    s = @_currentFrame.sound
    return  unless s
    audio = @_sounds[s]
    audio.play()  if audio && atom.config.get('clippy.playSounds')

  _atLastFrame: ->
    @_currentFrameIndex >= @_currentAnimation.frames.length - 1

  _step: ->
    return  unless @_currentAnimation
    newFrameIndex = Math.min(@_getNextAnimationFrame(), @_currentAnimation.frames.length - 1)
    frameChanged = not @_currentFrame or @_currentFrameIndex isnt newFrameIndex
    @_currentFrameIndex = newFrameIndex

    # always switch frame data, unless we're at the last frame of an animation with a useExitBranching flag.
    @_currentFrame = @_currentAnimation.frames[@_currentFrameIndex]  unless @_atLastFrame() and @_currentAnimation.useExitBranching
    @_draw()
    @_playSound()
    @_loop = window.setTimeout($.proxy(@_step, this), @_currentFrame.duration)

    # fire events if the frames changed and we reached an end
    if @_endCallback and frameChanged and @_atLastFrame()
      if @_currentAnimation.useExitBranching and not @_exiting
        @_endCallback @currentAnimationName, Animator.States.WAITING
      else
        @_endCallback @currentAnimationName, Animator.States.EXITED


  ###
  Pause animation execution
  ###
  pause: ->
    window.clearTimeout @_loop


  ###
  Resume animation
  ###
  resume: ->
    @_step()

Animator.States =
  WAITING: 1
  EXITED: 0

module.exports = Animator
