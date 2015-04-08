$ = require 'jquery'

class Balloon

  WORD_SPEAK_TIME: 200
  CLOSE_BALLOON_DELAY: 2000
  _BALLOON_MARGIN: 15

  constructor: (@_targetEl) ->
    @_hidden = true
    @_balloon = $("<div class=\"clippy-balloon\"><div class=\"clippy-tip\"></div><div class=\"clippy-content\"></div></div> ").hide()
    @_content = @_balloon.find(".clippy-content")
    $(document.body).append @_balloon

  reposition: ->
    sides = [
      "top-left"
      "top-right"
      "bottom-left"
      "bottom-right"
    ]
    i = 0

    while i < sides.length
      s = sides[i]
      @_position s
      break  unless @_isOut()
      i++

  _position: (side) ->
    o = @_targetEl.offset()
    h = @_targetEl.height()
    w = @_targetEl.width()
    o.top -= $(window).scrollTop()
    o.left -= $(window).scrollLeft()
    bH = @_balloon.outerHeight()
    bW = @_balloon.outerWidth()
    @_balloon.removeClass "clippy-top-left"
    @_balloon.removeClass "clippy-top-right"
    @_balloon.removeClass "clippy-bottom-right"
    @_balloon.removeClass "clippy-bottom-left"
    left = undefined
    top = undefined
    switch side
      when "top-left"

        # right side of the balloon next to the right side of the agent
        left = o.left + w - bW
        top = o.top - bH - @_BALLOON_MARGIN
      when "top-right"

        # left side of the balloon next to the left side of the agent
        left = o.left
        top = o.top - bH - @_BALLOON_MARGIN
      when "bottom-right"

        # right side of the balloon next to the right side of the agent
        left = o.left
        top = o.top + h + @_BALLOON_MARGIN
      when "bottom-left"

        # left side of the balloon next to the left side of the agent
        left = o.left + w - bW
        top = o.top + h + @_BALLOON_MARGIN
    @_balloon.css
      top: top
      left: left

    @_balloon.addClass "clippy-" + side

  _isOut: ->
    o = @_balloon.offset()
    bH = @_balloon.outerHeight()
    bW = @_balloon.outerWidth()
    wW = $(window).width()
    wH = $(window).height()
    sT = $(document).scrollTop()
    sL = $(document).scrollLeft()
    top = o.top - sT
    left = o.left - sL
    m = 5
    return true  if top - m < 0 or left - m < 0
    return true  if (top + bH + m) > wH or (left + bW + m) > wW
    false

  speak: (complete, text, hold) ->
    @_hidden = false
    @show()
    c = @_content

    # set height to auto
    c.height "auto"
    c.width "auto"

    # add the text
    c.text text

    # set height
    c.height c.height()
    c.width c.width()
    c.text ""
    @reposition()
    @_complete = complete
    @_sayWords text, hold, complete

  show: ->
    return if @_hidden
    @_balloon.show()

  hide: (fast) ->
    if fast
      @_balloon.hide()
      return
    @_hiding = window.setTimeout($.proxy(@_finishHideBalloon, this), @CLOSE_BALLOON_DELAY)

  _finishHideBalloon: ->
    return  if @_active
    @_balloon.hide()
    @_hidden = true
    @_hiding = null

  _sayWords: (text, hold, complete) ->
    @_active = true
    @_hold = hold
    words = text.split(/[^\S-]/)
    time = @WORD_SPEAK_TIME
    el = @_content
    idx = 1
    @_addWord = $.proxy(->
      return unless @_active
      if idx > words.length
        delete @_addWord

        @_active = false
        unless @_hold
          complete()
          @hide()
      else
        el.text words.slice(0, idx).join(" ")
        idx++
        @_loop = window.setTimeout($.proxy(@_addWord, this), time)
    , this)
    @_addWord()

  close: ->
    if @_active
      @_hold = false
    else @_complete()  if @_hold

  pause: ->
    window.clearTimeout @_loop
    if @_hiding
      window.clearTimeout @_hiding
      @_hiding = null

  resume: ->
    if @_addWord
      @_addWord()
    else @_hiding = window.setTimeout($.proxy(@_finishHideBalloon, this), @CLOSE_BALLOON_DELAY)  if not @_hold and not @_hidden

module.exports = Balloon
