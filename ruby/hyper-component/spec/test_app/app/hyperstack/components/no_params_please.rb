class NoParamsPlease < HyperComponent
  def no_params_please
    @message = "hello"
  end
  after_mount { mutate @message = "goodby" }
  before_update :no_params_please
  render { @message }
end
