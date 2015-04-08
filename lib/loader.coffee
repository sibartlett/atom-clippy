$ = require 'jquery'
Agent = require './agent'

ASSETS_PATH = 'atom://clippy/agents/'
BASE_PATH = '../agents/'

loader = (name, successCb) ->
  path = ASSETS_PATH + name
  dataPath = BASE_PATH + name + '/agent'
  soundsPath = BASE_PATH + name + '/sounds-ogg'
  data = require dataPath
  sounds = require soundsPath
  currentAgent = new Agent(path, data, sounds)
  successCb currentAgent
  return

module.exports = loader
