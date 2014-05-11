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

  configDefaults:
    showOnStartup: true
    playSounds: true
    agent: 'Clippy'

  activate: ->

    # atom.workspaceView.command 'clippy:show', show
    # atom.workspaceView.command 'clippy:hide', hide
    atom.workspaceView.command 'clippy:toggle', toggleAgent
    atom.workspaceView.command 'clippy:toggle-sounds', toggleSounds

    atom.workspaceView.command 'clippy:switch-agent-to-clippy', ->
      switchAgent 'Clippy'

    atom.workspaceView.command 'clippy:switch-agent-to-bonzi', ->
      switchAgent 'Bonzi'

    atom.workspaceView.command 'clippy:switch-agent-to-f1', ->
      switchAgent 'F1'

    atom.workspaceView.command 'clippy:switch-agent-to-genie', ->
      switchAgent 'Genie'

    atom.workspaceView.command 'clippy:switch-agent-to-genius', ->
      switchAgent 'Genius'

    atom.workspaceView.command 'clippy:switch-agent-to-links', ->
      switchAgent 'Links'

    atom.workspaceView.command 'clippy:switch-agent-to-merlin', ->
      switchAgent 'Merlin'

    atom.workspaceView.command 'clippy:switch-agent-to-peedy', ->
      switchAgent 'Peedy'

    atom.workspaceView.command 'clippy:switch-agent-to-rocky', ->
      switchAgent 'Rocky'

    atom.workspaceView.command 'clippy:switch-agent-to-rover', ->
      switchAgent 'Rover'

    atom.workspaceView.command 'clippy:animate', ->
      console.log 'animating'
      animate()

    if atom.config.get('clippy.showOnStartup')
      setTimeout show, 1500
