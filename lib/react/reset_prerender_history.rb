module React::IsomorphicHelpers
  class << self
    alias pre_history_patch_load_context load_context
    def load_context(unique_id = nil, name = nil)
      `console.history = []` if (!unique_id || !@context || @context.unique_id != unique_id) && on_opal_server?
      pre_history_patch_load_context(unique_id, name)
    end
  end
end if RUBY_ENGINE == 'opal'
