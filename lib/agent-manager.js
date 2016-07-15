"use babel";

import loader from "./loader";

let firstShow = true;
let currentAgent = null;

const showAgent = name => {
  const config = atom.config.get("clippy.agent");
  name = name || atom.config.get("clippy.agent");

  const show = () => {
    currentAgent.show();
    if (firstShow) {
      firstShow = false;
      currentAgent.speak("Hello, I\'m here to help you use Atom.");
    }
  };

  const load = () => {
    if (currentAgent) {
      show();
      return;
    }
    loader(name, agent => {
      currentAgent = agent;
      show();
    });
  };

  if (config !== name) {
    atom.config.set("clippy.agent", name);
    if (currentAgent) {
      currentAgent.hide(false, () => {
        currentAgent = null;
        firstShow = true;
        load();
      });
      return;
    }
  }

  load();
};

const service = {
  animate(animation) {
    if (currentAgent && !currentAgent._hidden) {
      currentAgent.animate(animation);
    }
  },
  speak(text, opts) {
    if (currentAgent && !currentAgent._hidden) {
      currentAgent.speak(text, opts);
    }
  }
};

Object.defineProperty(service, "animations", {
  enumerable: true,
  configurable: false,
  get() {
    if (currentAgent && !currentAgent._hidden) {
      return currentAgent.animations();
    } else {
      return [];
    }
  }
});

export default {
  service,

  toggleAgent() {
    if (!currentAgent || currentAgent._hidden) {
      showAgent();
    } else {
      currentAgent.hide();
    }
  },

  showAgent,

  hideAgent() {
    if (currentAgent) {
      currentAgent.hide();
    }
  },

  toggleSounds() {
    const val = atom.config.get("clippy.playSounds");
    atom.config.set("clippy.playSounds", !val);
  }

};
