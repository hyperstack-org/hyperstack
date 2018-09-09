require "react/config"

module React
  module IsomorphicHelpers
    def self.included(base)
      base.extend(ClassMethods)
    end

    if RUBY_ENGINE != 'opal'
      def self.load_context(ctx, controller, name = nil)
        @context = Context.new("#{controller.object_id}-#{Time.now.to_i}", ctx, controller, name)
        @context.load_opal_context
        ::Rails.logger.debug "************************** React Server Context Initialized #{name} #{Time.now.to_f} *********************************************"
        @context
      end
    else
      def self.load_context(unique_id = nil, name = nil)
        # can be called on the client to force re-initialization for testing purposes
        if !unique_id || !@context || @context.unique_id != unique_id
          if on_opal_server?
            `console.history = []` rescue nil
            message = "************************ React Prerendering Context Initialized #{name} ***********************"
          else
            message = "************************ React Browser Context Initialized ****************************"
          end
          log(message)
          @context = Context.new(unique_id)
        end
        @context
      end
    end

    def self.context
      @context
    end

    def self.log(message, message_type = :info)
      message = [message] unless message.is_a? Array

      if (message_type == :info || message_type == :warning) && Hyperloop.env.production?
        return
      end

      if message_type == :info
        if on_opal_server?
          style = 'background: #00FFFF; color: red'
        else
          style = 'background: #222; color: #bada55'
        end
        message = ["%c" + message[0], style]+message[1..-1]
        `console.log.apply(console, message)`
      elsif message_type == :warning
        `console.warn.apply(console, message)`
      else
        `console.error.apply(console, message)`
      end
    end

    if RUBY_ENGINE != 'opal'
      def self.on_opal_server?
        false
      end

      def self.on_opal_client?
        false
      end
    else
      def self.on_opal_server?
        `typeof Opal.global.document === 'undefined'`
      end

      def self.on_opal_client?
        !on_opal_server?
      end
    end

    def log(*args)
      IsomorphicHelpers.log(*args)
    end

    def on_opal_server?
      self.class.on_opal_server?
    end

    def on_opal_client?
      self.class.on_opal_client?
    end

    def self.prerender_footers(controller = nil)
      footer = Context.prerender_footer_blocks.collect { |block| block.call controller }.join("\n")
      if RUBY_ENGINE != 'opal'
        footer = (footer + @context.send_to_opal(:prerender_footers).to_s) if @context
        footer = footer.html_safe
      end
      footer
    end

    class Context
      attr_reader :controller
      attr_reader :unique_id

      def self.define_isomorphic_method(method_name, &block)
        @@ctx_methods ||= {}
        @@ctx_methods[method_name] = block
      end

      def self.before_first_mount_blocks
        @before_first_mount_blocks ||= []
      end

      def self.prerender_footer_blocks
        @prerender_footer_blocks ||= []
      end

      def initialize(unique_id, ctx = nil, controller = nil, cname = nil)
        @unique_id = unique_id
        @cname = cname
        if RUBY_ENGINE != 'opal'
          @controller = controller
          @ctx = ctx
          if defined? @@ctx_methods
            @@ctx_methods.each do |method_name, block|
              @ctx.attach("ServerSideIsomorphicMethod.#{method_name}", proc{|args| block.call(args.to_json)})
            end
          end
        end
        Hyperloop::Application::Boot.run(context: self)
        self.class.before_first_mount_blocks.each { |block| block.call(self) }
      end

      def load_opal_context
        send_to_opal(:load_context, @unique_id, @cname)
      end

      def eval(js)
        @ctx.eval(js) if @ctx
      end

      def send_to_opal(method_name, *args)
        return unless @ctx
        args = [1] if args.length == 0
        ::ReactiveRuby::ComponentLoader.new(@ctx).load!
        method_args = args.collect do |arg|
          quarg = "#{arg}".tr('"', "'")
          "\"#{quarg}\""
        end.join(', ')
        @ctx.eval("Opal.React.$const_get('IsomorphicHelpers').$#{method_name}(#{method_args})")
      end

      def self.register_before_first_mount_block(&block)
        before_first_mount_blocks << block
      end

      def self.register_prerender_footer_block(&block)
        prerender_footer_blocks << block
      end
    end

    class IsomorphicProcCall

      attr_reader :context

      def result
        @result.first if @result
      end

      def initialize(name, block, context, *args)
        @name = name
        @context = context
        block.call(self, *args)
        @result ||= send_to_server(*args)
      end

      def when_on_client(&block)
        @result = [block.call] if IsomorphicHelpers.on_opal_client?
      end

      def send_to_server(*args)
        if IsomorphicHelpers.on_opal_server?
          method_string = "ServerSideIsomorphicMethod." + @name + "(" + args.to_json + ")"
          @result = [JSON.parse(`eval(method_string)`)]
        end
      end

      def when_on_server(&block)
        @result = [block.call.to_json] unless IsomorphicHelpers.on_opal_client? || IsomorphicHelpers.on_opal_server?
      end
    end

    module ClassMethods
      def on_opal_server?
        IsomorphicHelpers.on_opal_server?
      end

      def on_opal_client?
        IsomorphicHelpers.on_opal_client?
      end

      def log(*args)
        IsomorphicHelpers.log(*args)
      end

      def controller
        IsomorphicHelpers.context.controller
      end

      def before_first_mount(&block)
        React::IsomorphicHelpers::Context.register_before_first_mount_block(&block)
      end

      def prerender_footer(&block)
        React::IsomorphicHelpers::Context.register_prerender_footer_block(&block)
      end

      if RUBY_ENGINE != 'opal'
        def isomorphic_method(name, &block)
          React::IsomorphicHelpers::Context.send(:define_isomorphic_method, name) do |args_as_json|
            React::IsomorphicHelpers::IsomorphicProcCall.new(name, block, self, *JSON.parse(args_as_json)).result
          end
        end
      else
        require 'json'

        def isomorphic_method(name, &block)
          self.class.send(:define_method, name) do | *args |
            React::IsomorphicHelpers::IsomorphicProcCall.new(name, block, self, *args).result
          end
        end
      end

    end
  end
end
