"use babel";

import Agent from "./agent";

const ASSETS_PATH = "atom://clippy/agents/";
const BASE_PATH = "../agents/";

export default (name, cb) => {
  const path = ASSETS_PATH + name;
  const data = require(`${BASE_PATH + name}/agent`);
  const sounds = require(`${BASE_PATH + name}/sounds-ogg`);
  const agent = new Agent(path, data, sounds);
  cb(agent);
};
