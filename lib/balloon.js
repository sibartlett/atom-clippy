"use babel";

import $ from "jquery";

class Balloon {

  constructor(targetEl) {
    this._targetEl = targetEl;
    this._hidden = true;
    this._balloon = $("<div class=\"clippy-balloon\"><div class=\"clippy-tip\"></div><div class=\"clippy-content\"></div></div> ").hide();
    this._content = this._balloon.find(".clippy-content");
    $(document.body).append(this._balloon);
  }

  reposition() {
    const sides = ["top-left", "top-right", "bottom-left", "bottom-right"];
    let i = 0;
    const results = [];
    while (i < sides.length) {
      const s = sides[i];
      this._position(s);
      if (!this._isOut()) {
        break;
      }
      results.push(i++);
    }
    return results;
  }

  _position(side) {
    const o = this._targetEl.offset();
    const h = this._targetEl.height();
    const w = this._targetEl.width();
    o.top -= $(window).scrollTop();
    o.left -= $(window).scrollLeft();
    const bH = this._balloon.outerHeight();
    const bW = this._balloon.outerWidth();
    this._balloon.removeClass("clippy-top-left");
    this._balloon.removeClass("clippy-top-right");
    this._balloon.removeClass("clippy-bottom-right");
    this._balloon.removeClass("clippy-bottom-left");
    let left;
    let top;
    switch (side) {
    case "top-left":
      left = o.left + w - bW;
      top = o.top - bH - this._BALLOON_MARGIN;
      break;
    case "top-right":
      left = o.left;
      top = o.top - bH - this._BALLOON_MARGIN;
      break;
    case "bottom-right":
      left = o.left;
      top = o.top + h + this._BALLOON_MARGIN;
      break;
    case "bottom-left":
      left = o.left + w - bW;
      top = o.top + h + this._BALLOON_MARGIN;
    }
    this._balloon.css({
      top,
      left
    });
    this._balloon.addClass(`clippy-${side}`);
  }

  _isOut() {
    const o = this._balloon.offset();
    const bH = this._balloon.outerHeight();
    const bW = this._balloon.outerWidth();
    const wW = $(window).width();
    const wH = $(window).height();
    const sT = $(document).scrollTop();
    const sL = $(document).scrollLeft();
    const top = o.top - sT;
    const left = o.left - sL;
    const m = 5;
    if (top - m < 0 || left - m < 0) {
      return true;
    }
    if ((top + bH + m) > wH || (left + bW + m) > wW) {
      return true;
    }
    return false;
  }

  speak(complete, text, opts={}, hold=false) {
    this._hidden = false;
    this.show();
    const c = this._content;
    c.height("auto");
    c.width("auto");
    c.text(text);
    if (opts.prompt) {
      opts.prompt = this.promptLinks(opts.prompt, () => {
        complete();
        this._finishHideBalloon();
      });
      this.appendPrompt(c, opts.prompt.map(e => e.clone()));
    }
    c.height(c.height());
    c.width(c.width());
    c.text("");
    this.reposition();
    this._complete = complete;
    this._sayWords(text, opts, hold, complete);
  }

  show() {
    if (this._hidden) {
      return;
    }
    this._balloon.show();
  }

  hide(fast) {
    if (fast) {
      this._balloon.hide();
      return;
    }
    this._hiding = window.setTimeout(this._finishHideBalloon.bind(this), this.CLOSE_BALLOON_DELAY);
  }

  _finishHideBalloon() {
    if (this._active) {
      return;
    }
    this._balloon.hide();
    this._hidden = true;
    this._hiding = null;
  }

  _sayWords(text, opts, hold, complete) {
    this._active = true;
    this._hold = hold;
    const words = text.split(/[^\S-]/);
    const time = this.WORD_SPEAK_TIME;
    const el = this._content;
    let idx = 1;
    this._addWord = () => {
      if (!this._active) {
        return;
      }
      if (idx > words.length) {
        delete this._addWord;
        this._active = false;
        if (opts.prompt) {
          this.appendPrompt(el, opts.prompt);
        } else if (!this._hold) {
          complete();
          this.hide();
        }
      } else {
        el.text(words.slice(0, idx).join(" "));
        idx++;
        this._loop = window.setTimeout(this._addWord.bind(this), time);
      }
    };
    this._addWord();
  }

  appendPrompt(view, links) {
    const div = $("<div class='prompt'>").append(links);
    view.append("<br><br><br>").append(div);
  }

  promptLinks(promptMap, complete) {
    const results = [];
    for (const label in promptMap) {
      const fn = promptMap[label];
      const link = $("<a href=\"#\">").text(label).on("click", () => {
        complete();
        setTimeout(fn);
      });
      results.push(link);
    }
    return results;
  }

  close() {
    if (this._active) {
      this._hold = false;
    } else if (this._hold) {
      this._complete();
    }
  }

  pause() {
    window.clearTimeout(this._loop);
    if (this._hiding) {
      window.clearTimeout(this._hiding);
      return this._hiding = null;
    }
  }

  resume() {
    if (this._addWord) {
      this._addWord();
    } else if (!this._hold && !this._hidden) {
      this._hiding = window.setTimeout(this._finishHideBalloon.bind(this), this.CLOSE_BALLOON_DELAY);
    }
  }

}

Balloon.prototype.WORD_SPEAK_TIME = 200;

Balloon.prototype.CLOSE_BALLOON_DELAY = 2000;

Balloon.prototype._BALLOON_MARGIN = 15;

export default Balloon;
