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
      jscode = <<-CODE
      (function() {
        if (typeof Opal !== "undefined" && Opal.Hyperloop !== undefined) {
          try {
            return Opal.Hyperloop.$const_get("HTTP")["$active?"]();
          } catch(err) {
            if (typeof jQuery !== "undefined" && jQuery.active !== undefined) {
              return (jQuery.active > 0);
            } else {
              return false;
            }
          }
        } else if (typeof jQuery !== "undefined" && jQuery.active !== undefined) {
          return (jQuery.active > 0);
        } else {
          return false;
        }
      })();
      CODE
      page.evaluate_script(jscode)
    rescue Exception => e
      puts "wait_for_ajax failed while testing state of ajax requests: #{e}"
    end

    def finished_all_ajax_requests?
      !running?
    rescue Capybara::NotSupportedByDriverError
      true
    rescue Exception => e
      e.message == 'either jQuery or Hyperloop::HTTP is not defined'
    end
  end
end
