loader = require './loader'

firstShow = true
currentAgent = null

showAgent = (name) ->
  config = atom.config.get('clippy.agent')
  name = name ?= atom.config.get('clippy.agent')

  show = ->
    currentAgent.show()
    if firstShow
      firstShow = false
      currentAgent.speak('Hello, I\'m here to help you use Atom.')

  load = ->
    if currentAgent
      show()
      return

    loader name, (agent) ->
      currentAgent = agent
      show()

  if config != name
    atom.config.set('clippy.agent', name)

    if currentAgent
      currentAgent.hide false, ->
        currentAgent = null
        firstShow = true
        load()
      return

  load()

hideAgent = ->
  if currentAgent
    currentAgent.hide()

toggleAgent = ->
  if !currentAgent or currentAgent._hidden
    showAgent()
  else
    currentAgent.hide()

toggleSounds = ->
  val = atom.config.get('clippy.playSounds')
  atom.config.set('clippy.playSounds', !val)

service =
  animate: (animation) ->
    if currentAgent and not currentAgent._hidden
      currentAgent.animate animation

  speak: (text) ->
    if currentAgent and not currentAgent._hidden
      currentAgent.speak text

Object.defineProperty(service, 'animations', {
  enumerable: true,
  configurable: false,
  get: ->
    if currentAgent and not currentAgent._hidden
      currentAgent.animations()
    else
      []
});

module.exports =
  service: service,

  toggleAgent: toggleAgent,
  showAgent: showAgent,
  hideAgent: hideAgent,
  toggleSounds: toggleSounds
