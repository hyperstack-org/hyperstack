class Promise
  def then_build_routes(&block)
    self.then do |*args|
      React::Router::DSL.build_routes(*args, &block)
    end
  end
end
