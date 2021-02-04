module HyperSpec
  module Internal
    module WindowSizing
      def wait_for_size(width, height)
        start_time = Capybara::Helpers.monotonic_time
        stable_count_w = 0
        stable_count_h = 0
        prev_size = [0, 0]
        begin
          sleep 0.05
          curr_size = Capybara.current_session.current_window.size
          return if [width, height] == curr_size
          # some maximum or minimum is reached and size doesnt change anymore
          stable_count_w += 1 if prev_size[0] == curr_size[0]
          stable_count_h += 1 if prev_size[1] == curr_size[1]
          return if stable_count_w > 2 || stable_count_h > 2
          prev_size = curr_size
        end while (Capybara::Helpers.monotonic_time - start_time) < Capybara.current_session.config.default_max_wait_time
        raise Capybara::WindowError, "Window size not stable within #{Capybara.current_session.config.default_max_wait_time} seconds."
      end
    end
  end
end
