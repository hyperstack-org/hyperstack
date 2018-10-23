window.Hyperstack = {
  hotloader: function(port, ping) {
    Opal.Hyperstack.$const_get('HotLoader').$listen(port || 25222, ping || Opal.nil)
  }
}
