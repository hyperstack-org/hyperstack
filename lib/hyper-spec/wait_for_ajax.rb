module HyperSpec
  module WaitForAjax
    def wait_for_ajax
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          sleep 0.25
          break if finished_all_ajax_requests?
        end
      end
    end

    def running?
      result = page.evaluate_script('(function(active) { return active; })(jQuery.active)')
      result && !result.zero?
    rescue Exception => e
      puts "wait_for_ajax failed while testing state of jQuery.active: #{e}"
    end

    def finished_all_ajax_requests?
      unless running?
        sleep 0.25 # this was 1 second, not sure if its necessary to be so long...
        !running?
      end
    rescue Capybara::NotSupportedByDriverError
      true
    rescue Exception => e
      e.message == 'jQuery is not defined'
    end
  end
end
