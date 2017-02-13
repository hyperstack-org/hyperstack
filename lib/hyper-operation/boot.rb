module Hyperloop
  class Boot < HyperOperation
    include React::IsomorphicHelpers
    before_first_mount do
      run
    end
  end
end
