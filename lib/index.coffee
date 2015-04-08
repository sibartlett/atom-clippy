loader = require './loader'

firstShow = true
currentAgent = null

withAgent = (cb) ->
  if (currentAgent)
    cb currentAgent
  else
    loader atom.config.get('clippy.agent'), (agent) ->
      currentAgent = agent
      cb currentAgent

show = ->
  withAgent (agent) ->
    agent.show()
    if firstShow
      firstShow = false
      agent.speak('Hello, I\'m here to help you use Atom.')

hide = ->
  withAgent (agent) ->
    agent.hide()

animate = ->
  withAgent (agent) ->
    agent.animate()

toggleAgent = ->
  withAgent (agent) ->
    if agent._hidden
      agent.show()
      if firstShow
        firstShow = false
        agent.speak('Hello, I\'m here to help you use Atom.')
    else
      agent.hide()

toggleSounds = ->
  val = atom.config.get('clippy.playSounds')
  atom.config.set('clippy.playSounds', !val)

switchAgent = (name) ->
  withAgent (agent) ->
    agent.hide false, ->
      currentAgent = null
      firstShow = true
      atom.config.set('clippy.agent', name)
      show()

module.exports =

  config:
    showOnStartup:
      type: 'boolean'
      default: true
    playSounds:
      type: 'boolean'
      default: true
    agent:
      type: 'string'
      default: 'Clippy'
      enum: [
        'Clippy',
        'Bonzi',
        'F1',
        'Genie',
        'Genius',
        'Links',
        'Merlin',
        'Peedy',
        'Rocky',
        'Rover'
      ]

  activate: ->

    # atom.commands.add 'atom-text-editor', 'clippy:show', show
    # atom.commands.add 'atom-text-editor', 'clippy:hide', hide
    atom.commands.add 'atom-text-editor', 'clippy:toggle', toggleAgent
    atom.commands.add 'atom-text-editor', 'clippy:toggle-sounds', toggleSounds

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-clippy', ->
      switchAgent 'Clippy'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-bonzi', ->
      switchAgent 'Bonzi'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-f1', ->
      switchAgent 'F1'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-genie', ->
      switchAgent 'Genie'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-genius', ->
      switchAgent 'Genius'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-links', ->
      switchAgent 'Links'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-merlin', ->
      switchAgent 'Merlin'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-peedy', ->
      switchAgent 'Peedy'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-rocky', ->
      switchAgent 'Rocky'

    atom.commands.add 'atom-text-editor', 'clippy:switch-agent-to-rover', ->
      switchAgent 'Rover'

    atom.commands.add 'atom-text-editor', 'clippy:animate', ->
      console.log 'animating'
      animate()

    if atom.config.get('clippy.showOnStartup')
      setTimeout show, 1500
