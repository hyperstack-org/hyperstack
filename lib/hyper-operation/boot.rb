module Hyperloop
  class Application
    class Boot < Operation
      include React::IsomorphicHelpers
      before_first_mount do
        run
      end
    end
  end
end
