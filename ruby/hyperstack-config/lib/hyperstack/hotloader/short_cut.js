if (typeof window !== 'undefined') {
  window.Hyperstack = {
    hotloader: function(port, ping) {
      Opal.Hyperstack.$const_get('Hotloader').$listen(port || 25222, ping || Opal.nil)
    }
  }
} else {
  throw 'Attempt to run hotloader during prerendering - make sure you import with the `client_only: true` option'
}
