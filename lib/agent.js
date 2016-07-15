"use babel";

import $ from "jquery";
import Queue from "./queue";
import Animator from "./animator";
import Balloon from "./balloon";

class Agent {

  constructor(path, data, sounds) {
    this._hidden = true;
    this.path = path;
    this._queue = new Queue(this._onQueueEmpty.bind(this));
    this._el = $("<div class=\"clippy\"></div>").hide();
    $(document.body).append(this._el);
    this._animator = new Animator(this._el, path, data, sounds);
    this._balloon = new Balloon(this._el);
    this._setupEvents();
  }

  gestureAt(x, y) {
    const d = this._getDirection(x, y);
    const gAnim = `Gesture${d}`;
    const lookAnim = `Look${d}`;
    const animation = this.hasAnimation(gAnim) ? gAnim : lookAnim;
    this.play(animation);
  }

  hide(fast, callback) {
    if (!this._hidden) {
      this._hidden = true;
      this.stop();

      if (fast) {
        this._el.hide();
        this.stop();
        this.pause();
        if (callback) {
          callback();
        }
        return;
      }

      this._playInternal("Hide", () => {
        this._el.hide();
        this.pause();
        if (callback) {
          callback();
        }
      });
    }
  }

  moveTo(x, y, duration) {
    const dir = this._getDirection(x, y);
    const anim = `Move${dir}`;

    if (duration === undefined) {
      duration = 1000;
    }

    this._addToQueue(complete => {
      if (duration === 0) {
        this._el.css({
          top: y,
          left: x
        });
        this.reposition();
        complete();
        return;
      }

      if (!this.hasAnimation(anim)) {
        this._el.animate({
          top: y,
          left: x
        }, duration, complete);
        return;
      }

      const callback = (name, state) => {
        if (state === Animator.States.EXITED) {
          complete();
        }
        if (state === Animator.States.WAITING) {
          this._el.animate({
            top: y,
            left: x
          }, duration, () => {
            this._animator.exitAnimation();
          });
        }
      };

      this._playInternal(anim, callback);
    });
  }

  _playInternal(animation, callback) {
    if (this._isIdleAnimation() && this._idleDfd && this._idleDfd.state() === "pending") {
      this._idleDfd.done(() => this._playInternal(animation, callback));
    }
    this._animator.showAnimation(animation, callback);
  }

  play(animation, timeout, cb) {
    if (!this.hasAnimation(animation)) {
      return false;
    }
    if (timeout === undefined) {
      timeout = 5000;
    }
    this._addToQueue(complete => {
      let completed = false;
      const callback = (name, state) => {
        if (state === Animator.States.EXITED) {
          completed = true;
          if (cb) {
            cb();
          }
          complete();
        }
      };
      if (timeout) {
        window.setTimeout(() => {
          if (completed) {
            return;
          }
          this._animator.exitAnimation();
        }, timeout);
      }
      this._playInternal(animation, callback);
    });
    return true;
  }

  show(fast) {
    let left, top;
    if (this._hidden) {
      this._hidden = false;
      if (fast) {
        this._el.show();
        this.resume();
        this._onQueueEmpty();
        return;
      }
      if (this._el.css("top") === "auto" || !this._el.css("left") === "auto") {
        left = $(window).width() * 0.8;
        top = ($(window).height() + $(document).scrollTop()) * 0.8;
        this._el.css({
          top,
          left
        });
      }
      this.resume();
      this.play("Show");
    }
  }

  speak(text, opts, hold) {
    this._addToQueue(complete => this._balloon.speak(complete, text, opts, hold));
  }

  closeBalloon() {
    this._balloon.hide();
  }

  delay(time=250) {
    this._addToQueue(complete => {
      this._onQueueEmpty();
      window.setTimeout(complete, time);
    });
  }

  stopCurrent() {
    this._animator.exitAnimation();
    this._balloon.close();
  }

  stop() {
    this._queue.clear();
    this._animator.exitAnimation();
    this._balloon.hide();
  }

  hasAnimation(name) {
    return this._animator.hasAnimation(name);
  }

  animations() {
    return this._animator.animations();
  }

  animate(name) {
    const animations = this.animations();
    let anim = animations[animations.indexOf(name)];
    if (anim == null) {
      anim = animations[Math.floor(Math.random() * animations.length)];
    }
    if (!name && anim.indexOf("Idle") === 0) {
      return this.animate();
    }
    this.play(anim);
  }

  _getDirection(x, y) {
    const offset = this._el.offset();
    const h = this._el.height();
    const w = this._el.width();
    const centerX = offset.left + w / 2;
    const centerY = offset.top + h / 2;
    const a = centerY - y;
    const b = centerX - x;
    const r = Math.round((180 * Math.atan2(a, b)) / Math.PI);
    if (-45 <= r && r < 45) {
      return "Right";
    }
    if (45 <= r && r < 135) {
      return "Up";
    }
    if (135 <= r && r <= 180 || -180 <= r && r < -135) {
      return "Left";
    }
    if (-135 <= r && r < -45) {
      return "Down";
    }
    return "Top";
  }

  _onQueueEmpty() {
    if (this._hidden || this._isIdleAnimation()) {
      return;
    }
    const idleAnim = this._getIdleAnimation();
    this._idleDfd = $.Deferred();
    this._animator.showAnimation(idleAnim, this._onIdleComplete.bind(this));
  }

  _onIdleComplete(name, state) {
    if (state === Animator.States.EXITED) {
      this._idleDfd.resolve();
    }
  }

  _isIdleAnimation() {
    const c = this._animator.currentAnimationName;
    return c && c.indexOf("Idle") === 0;
  }

  _getIdleAnimation() {
    const animations = this.animations();
    const r = [];
    let i = 0;
    while (i < animations.length) {
      const a = animations[i];
      if (a.indexOf("Idle") === 0) {
        r.push(a);
      }
      i++;
    }
    const idx = Math.floor(Math.random() * r.length);
    return r[idx];
  }

  _setupEvents() {
    $(window).on("resize", this.reposition.bind(this));
    this._el.on("mousedown", this._onMouseDown.bind(this));
    this._el.on("dblclick", this._onDoubleClick.bind(this));
  }

  _onDoubleClick() {
    if (!this.play("ClickedOn")) {
      this.animate();
    }
  }

  reposition() {
    if (!this._el.is(":visible")) {
      return;
    }
    const o = this._el.offset();
    const bH = this._el.outerHeight();
    const bW = this._el.outerWidth();
    const wW = $(window).width();
    const wH = $(window).height();
    const sT = $(window).scrollTop();
    const sL = $(window).scrollLeft();
    let top = o.top - sT;
    let left = o.left - sL;
    const m = 5;
    if (top - m < 0) {
      top = m;
    } else {
      if ((top + bH + m) > wH) {
        top = wH - bH - m;
      }
    }
    if (left - m < 0) {
      left = m;
    } else {
      if (left + bW + m > wW) {
        left = wW - bW - m;
      }
    }
    this._el.css({
      left,
      top
    });
    this._balloon.reposition();
  }

  _onMouseDown(e) {
    if (e.which === 1) {
      e.preventDefault();
      this._startDrag(e);
    }
  }

  _startDrag(e) {
    this.pause();
    this._balloon.hide(true);
    this._offset = this._calculateClickOffset(e);
    this._moveHandle = this._dragMove.bind(this);
    this._upHandle = this._finishDrag.bind(this);
    $(window).on("mousemove", this._moveHandle);
    $(window).on("mouseup", this._upHandle);
    this._dragUpdateLoop = window.setTimeout(this._updateLocation.bind(this), 10);
  }

  _calculateClickOffset(e) {
    const mouseX = e.pageX;
    const mouseY = e.pageY;
    const o = this._el.offset();
    return {
      top: mouseY - o.top,
      left: mouseX - o.left
    };
  }

  _updateLocation() {
    this._el.css({
      top: this._targetY,
      left: this._targetX
    });
    this._dragUpdateLoop = window.setTimeout(this._updateLocation.bind(this), 10);
  }

  _dragMove(e) {
    e.preventDefault();
    const x = e.clientX - this._offset.left;
    const y = e.clientY - this._offset.top;
    this._targetX = x;
    this._targetY = y;
  }

  _finishDrag() {
    window.clearTimeout(this._dragUpdateLoop);
    $(window).off("mousemove", this._moveHandle);
    $(window).off("mouseup", this._upHandle);
    this._balloon.show();
    this.reposition();
    this.resume();
  }

  _addToQueue(func) {
    this._queue.queue(func);
  }

  pause() {
    this._animator.pause();
    this._balloon.pause();
  }

  resume() {
    this._animator.resume();
    this._balloon.resume();
  }

}

export default Agent;
