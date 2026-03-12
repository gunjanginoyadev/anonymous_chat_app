class WaitingQueue {
  constructor() {
    this.queue = [];
  }

  enqueue(user, socket) {
    this.queue.push({user, socket});
  }

  dequeue() {
    return this.queue.shift();
  }

  size() {
    return this.queue.length;
  }

  hasUser(user) {
  return this.queue.some((item) => item.user === user);
  }

  removeBySocket(socket) {
    this.queue = this.queue.filter(user => user.socket !== socket);
  }
}

module.exports = new WaitingQueue();
