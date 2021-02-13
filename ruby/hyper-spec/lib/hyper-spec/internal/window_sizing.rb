module HyperSpec
  module Internal
    module WindowSizing
      private

      STD_SIZES = {
        small: [480, 320],
        mobile: [640, 480],
        tablet: [960, 640],
        large: [1920, 6000],
        default: [1024, 768]
      }

      def determine_size(width, height)
        width, height = [height, width] if width == :portrait
        width, height = width if width.is_a? Array
        portrait = true if height == :portrait
        width ||= :default
        width, height = STD_SIZES[width] if STD_SIZES[width]
        width, height = [height, width] if portrait
        [width + debugger_width, height]
      end

      def debugger_width
        RSpec.configuration.debugger_width ||= begin
          hs_internal_resize_to(1000, 500) do
            sleep RSpec.configuration.wait_for_initialization_time
          end
          inner_width = evaluate_script('window.innerWidth')
          1000 - inner_width
        end
        RSpec.configuration.debugger_width
      end

      def hs_internal_resize_to(width, height)
        Capybara.current_session.current_window.resize_to(width, height)
        yield if block_given?
        wait_for_size(width, height)
      end

      def wait_for_size(width, height)
        @start_time = Capybara::Helpers.monotonic_time
        @stable_count_w = @stable_count_h = 0
        prev_size = [0, 0]
        loop do
          sleep 0.05
          curr_size = evaluate_script('[window.innerWidth, window.innerHeight]')

          return true if curr_size == [width, height] || stalled?(prev_size, curr_size)

          prev_size = curr_size
          check_time!
        end
      end

      def check_time!
        if (Capybara::Helpers.monotonic_time - @start_time) >
           Capybara.current_session.config.default_max_wait_time
          raise Capybara::WindowError,
                'Window size not stable within '\
                "#{Capybara.current_session.config.default_max_wait_time} seconds."
        end
      end

      def stalled?(prev_size, curr_size)
        # some maximum or minimum is reached and size doesn't change anymore
        @stable_count_w += 1 if prev_size[0] == curr_size[0]
        @stable_count_h += 1 if prev_size[1] == curr_size[1]
        @stable_count_w > 4 || @stable_count_h > 4
      end
    end
  end
end
