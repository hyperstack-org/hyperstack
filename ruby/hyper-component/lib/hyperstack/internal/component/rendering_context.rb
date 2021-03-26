module Hyperstack
  module Internal
    module Component
      class RenderingContext
        class NotQuiet < Exception; end
        class << self
          attr_accessor :waiting_on_resources

          def raise_if_not_quiet?
            @raise_if_not_quiet
          end

          def raise_if_not_quiet=(x)
            @raise_if_not_quiet = x
          end

          def quiet_test(component)
            return unless component.waiting_on_resources && raise_if_not_quiet? #&& component.class != RescueMetaWrapper <- WHY  can't create a spec that this fails without this, but several fail with it.
            raise NotQuiet.new("#{component} is waiting on resources")
          end

          def render_string(string)
            @buffer ||= []
            @buffer << string
          end

          def render(name, *args, &block)
            was_outer_most = !@not_outer_most
            @not_outer_most = true
            remove_nodes_from_args(args)
            @buffer ||= [] #unless @buffer
            if block
              element = build do
                saved_waiting_on_resources = nil #waiting_on_resources  what was the purpose of this its used below to or in with the current elements waiting_for_resources
                self.waiting_on_resources = nil
                run_child_block(&block)
                if name
                  buffer = @buffer.dup
                  ReactWrapper.create_element(name, *args) { buffer }.tap do |element|
                    element.waiting_on_resources = saved_waiting_on_resources || !!buffer.detect { |e| e.waiting_on_resources if e.respond_to?(:waiting_on_resources) }
                    element.waiting_on_resources ||= waiting_on_resources if buffer.last.is_a?(String)
                  end
                else
                  buffer = @buffer.collect do |item|
                    if item.is_a? Hyperstack::Component::Element
                      item.waiting_on_resources ||= saved_waiting_on_resources
                      item
                    else
                      RenderingContext.render(:span) { item.to_s }.tap { |element| element.waiting_on_resources = saved_waiting_on_resources }
                    end
                  end
                  if buffer.length > 1
                    buffer
                  else
                    buffer.first
                  end
                end
              end
            elsif name.is_a? Hyperstack::Component::Element
              element = name
            else
              element = ReactWrapper.create_element(name, *args)
              element.waiting_on_resources = waiting_on_resources
            end
            @buffer << element
            self.waiting_on_resources = nil
            element
          ensure
            @not_outer_most = @buffer = nil if was_outer_most
          end

          def build
            current = @buffer
            @buffer = []
            return_val = yield @buffer
            @buffer = current
            return_val
          end

          def delete(element)
            @buffer.delete(element)
            @last_deleted = element
            element
          end
          alias as_node delete

          def rendered?(element)
            @buffer.include? element
          end

          def replace(e1, e2)
            @buffer[@buffer.index(e1)] = e2
          end

          def remove_nodes_from_args(args)
            args[0].each do |key, value|
              begin
                value.delete if value.is_a?(Hyperstack::Component::Element) # deletes Element from buffer
              rescue Exception
              end
            end if args[0] && args[0].is_a?(Hash)
          end

          # run_child_block yields to the child rendering block which will put any
          # elements to be rendered into the current rendering buffer.
          #
          # for example when rendering this div: div { "hello".span; "goodby".span }
          # two child Elements will be generated.
          #
          # However the block itself will return a value, which in some cases should
          # also added to the buffer:
          #
          # If the final value of the block is a
          #
          #   a hyper model dummy value that is being loaded, then wrap it in a span and add it to the buffer
          #   a string (or if the buffer is empty any value), then add it to the buffer
          #   an Element, then add it on the buffer unless it has been just deleted
          #          #
          # Note that the reason we don't always allow Strings to be automatically pushed is
          # to avoid confusing results in situations like this:
          #   DIV { collection.each { |item| SPAN { item } } }
          # If we accepted any object to be rendered this would generate:
          #   DIV { SPAN { collection[0] } SPAN { collection[n] } collection.to_s }
          # which is probably not the desired output.  If it was you would just append to_s
          # to the end of the expression, to force it to be added to the output buffer.
          #
          # However if the buffer is empty then it makes sense to automatically apply the `.to_s`
          # to the value, and push it on the buffer, unless it is a falsy value or an array

          def run_child_block
            result = yield
            check_for_component_return(result)
            if dummy_value?(result)
              # hyper-mesh DummyValues must
              # be converted to spans INSIDE the parent, otherwise the waiting_on_resources
              # flag will get set in the wrong context
              RenderingContext.render(:span) { result.to_s }
            elsif result.is_a?(Hyperstack::Component::Element)
              @buffer << result if @buffer.empty? unless @last_deleted == result
            elsif pushable_string?(result)
              @buffer << result.to_s
            end
            @last_deleted = nil
          end

          def check_for_component_return(result)
            # check for a common error of saying (for example) DIV (without parens)
            # which returns the DIV component class instead of a rendered DIV
            return unless result.try :hyper_component?

            Hyperstack::Component::IsomorphicHelpers.log(
              "a component's render method returned the component class #{result}, did you mean to say #{result}()",
              :warning
            )
          end

          def dummy_value?(result)
            result.respond_to?(:loading?) && result.loading?
          end

          def pushable_string?(result)
            # if the buffer is not empty we will only push on strings, and ignore anything else
            return result.is_a?(String) unless @buffer.empty?

            # if the buffer IS empty then we can push on anything except we avoid nil, false and arrays
            # as these are almost never what you want to render, and if you do there are mechanisms
            # to render them explicitly
            result && result.respond_to?(:to_n) && !result.is_a?(Array)
          end

          def improper_render(message, solution)
          end
        end
      end
    end
  end
end

class Object
  %i[span td th].each do |tag|
    define_method(tag) do |*args, &block|
      args.unshift(tag)
      # legacy hyperloop allowed tags to be lower case as well so if self is a component
      # then this is just a DSL method for example:
      # render(:div) do
      #   span { 'foo' }
      # end
      # in this case self is just the component being rendered, so span is just a method
      # in the component.
      # If we fully deprecate lowercase tags, then this next line can go...
      return send(*args, &block) if respond_to?(:hyper_component?) && hyper_component?

      Hyperstack::Internal::Component::RenderingContext.render(*args) { to_s }
    end
  end

  def para(*args, &block)
    args.unshift(:p)
    # see above comment
    return send(*args, &block) if respond_to?(:hyper_component?) && hyper_component?

    Hyperstack::Internal::Component::RenderingContext.render(*args) { to_s }
  end

  def br
    # see above comment
    return send(:br) if respond_to?(:hyper_component?) && hyper_component?
    
    Hyperstack::Internal::Component::RenderingContext.render(Hyperstack::Internal::Component::Tags::FRAGMENT) do
      Hyperstack::Internal::Component::RenderingContext.render(Hyperstack::Internal::Component::Tags::FRAGMENT) { to_s }
      Hyperstack::Internal::Component::RenderingContext.render(Hyperstack::Internal::Component::Tags::BR)
    end
  end

end
