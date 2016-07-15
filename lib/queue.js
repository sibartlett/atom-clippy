"use babel";

class Queue {

  constructor(onEmptyCallback) {
    this._onEmptyCallback = onEmptyCallback;
    this._queue = [];
  }

  queue(func) {
    this._queue.push(func);
    if (this._queue.length === 1 && !this._active) {
      this._progressQueue();
    }
  }

  _progressQueue() {
    if (!this._queue.length) {
      this._onEmptyCallback();
      return;
    }

    const fn = this._queue.shift();
    this._active = true;
    fn(this.next.bind(this));
  }

  clear() {
    this._active = false;
    this._queue = [];
  }

  next() {
    this._active = false;
    this._progressQueue();
  }

}

export default Queue;
