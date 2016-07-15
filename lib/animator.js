"use babel";

import $ from "jquery";

class Animator {

  constructor(el, path, data, sounds) {
    let curr, i, inner;
    this._el = el;
    this._data = data;
    this._path = path;
    this._currentFrameIndex = 0;
    this._currentFrame = undefined;
    this._exiting = false;
    this._currentAnimation = undefined;
    this._endCallback = undefined;
    this._started = false;
    this._sounds = {};
    this.currentAnimationName = undefined;
    this.preloadSounds(sounds);
    this._overlays = [this._el];
    curr = this._el;
    this._setupElement(this._el);
    i = 1;
    while (i < this._data.overlayCount) {
      inner = this._setupElement($("<div></div>"));
      curr.append(inner);
      this._overlays.push(inner);
      curr = inner;
      i++;
    }
  }

  _setupElement(el) {
    const { framesize } = this._data;
    el.css("display", "none");
    el.css({
      width: framesize[0],
      height: framesize[1]
    });
    el.css("background", `url('${this._path}/map.png') no-repeat`);
    return el;
  }

  animations() {
    return Object.keys(this._data.animations);
  }

  preloadSounds(sounds) {
    let i, snd, uri;
    i = 0;
    const results = [];
    while (i < this._data.sounds.length) {
      snd = this._data.sounds[i];
      uri = sounds[snd];
      if (!uri) {
        continue;
      }
      this._sounds[snd] = new Audio(uri);
      results.push(i++);
    }
    return results;
  }

  hasAnimation(name) {
    return !!this._data.animations[name];
  }

  exitAnimation() {
    this._exiting = true;
  }

  showAnimation(animationName, stateChangeCallback) {
    this._exiting = false;
    if (!this.hasAnimation(animationName)) {
      return false;
    }
    this._currentAnimation = this._data.animations[animationName];
    this.currentAnimationName = animationName;
    if (!this._started) {
      this._step();
      this._started = true;
    }
    this._currentFrameIndex = 0;
    this._currentFrame = undefined;
    this._endCallback = stateChangeCallback;
    return true;
  }

  _draw() {
    let bg, i, images, xy;
    images = [];
    if (this._currentFrame) {
      images = this._currentFrame.images || [];
    }
    i = 0;
    const results = [];
    while (i < this._overlays.length) {
      if (i < images.length) {
        xy = images[i];
        bg = `${-xy[0]}px ${-xy[1]}px`;
        this._overlays[i].css({
          "background-position": bg,
          display: "block"
        });
      } else {
        this._overlays[i].css("display", "none");
      }
      results.push(i++);
    }
    return results;
  }

  _getNextAnimationFrame() {
    let branch, i, rnd;
    if (!this._currentAnimation) {
      return undefined;
    }
    if (!this._currentFrame) {
      return 0;
    }
    const currentFrame = this._currentFrame;
    const branching = this._currentFrame.branching;
    if (this._exiting && currentFrame.exitBranch !== undefined) {
      return currentFrame.exitBranch;
    } else if (branching) {
      rnd = Math.random() * 100;
      i = 0;
      while (i < branching.branches.length) {
        branch = branching.branches[i];
        if (rnd <= branch.weight) {
          return branch.frameIndex;
        }
        rnd -= branch.weight;
        i++;
      }
    }
    return this._currentFrameIndex + 1;
  }

  _playSound() {
    const { sound } = this._currentFrame;
    if (!sound) {
      return;
    }
    const audio = this._sounds[sound];
    if (audio && atom.config.get("clippy.playSounds")) {
      audio.play();
    }
  }

  _atLastFrame() {
    return this._currentFrameIndex >= this._currentAnimation.frames.length - 1;
  }

  _step() {
    if (!this._currentAnimation) {
      return;
    }
    const newFrameIndex = Math.min(this._getNextAnimationFrame(), this._currentAnimation.frames.length - 1);
    const frameChanged = !this._currentFrame || this._currentFrameIndex !== newFrameIndex;
    this._currentFrameIndex = newFrameIndex;
    if (!(this._atLastFrame() && this._currentAnimation.useExitBranching)) {
      this._currentFrame = this._currentAnimation.frames[this._currentFrameIndex];
    }
    this._draw();
    this._playSound();
    this._loop = window.setTimeout(this._step.bind(this), this._currentFrame.duration);
    if (this._endCallback && frameChanged && this._atLastFrame()) {
      if (this._currentAnimation.useExitBranching && !this._exiting) {
        this._endCallback(this.currentAnimationName, Animator.States.WAITING);
      } else {
        this._endCallback(this.currentAnimationName, Animator.States.EXITED);
      }
    }
  }

  pause() {
    window.clearTimeout(this._loop);
  }

  resume() {
    this._step();
  }

}

Animator.States = {
  WAITING: 1,
  EXITED: 0
};

export default Animator;
