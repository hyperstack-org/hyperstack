module Selenium
  module WebDriver
    module Firefox
      class Profile
        class << self
          attr_accessor :firebug_version

          def firebug_version
            @firebug_version ||= '2.0.19-fx'
          end
        end

        def frame_position
          @frame_position ||= 'detached'
        end

        def frame_position=(position)
          @frame_position = %w[left right top detached].detect do |side|
            position && position[0].downcase == side[0]
          end || 'detached'
        end

        def enable_firebug(version = nil)
          version ||= Selenium::WebDriver::Firefox::Profile.firebug_version
          add_extension(File.expand_path("../../../../bin/firebug-#{version}.xpi", __FILE__))

          # For some reason, Firebug seems to trigger the Firefox plugin check
          # (navigating to https://www.mozilla.org/en-US/plugincheck/ at startup).
          # This prevents it. See http://code.google.com/p/selenium/issues/detail?id=4619.
          self['extensions.blocklist.enabled'] = false

          # Prevent "Welcome!" tab
          self['extensions.firebug.showFirstRunPage'] = false

          # Enable for all sites.
          self['extensions.firebug.allPagesActivation'] = 'on'

          # Enable all features.
          %w[console net script].each do |feature|
            self["extensions.firebug.#{feature}.enableSites"] = true
          end

          # Closed by default, will open detached.
          self['extensions.firebug.framePosition']     = frame_position
          self['extensions.firebug.previousPlacement'] = 3
          self['extensions.firebug.defaultPanelName']  = 'console'

          # Disable native "Inspect Element" menu item.
          self['devtools.inspector.enabled'] = false
          self['extensions.firebug.hideDefaultInspector'] = true
        end
      end
    end
  end
end
