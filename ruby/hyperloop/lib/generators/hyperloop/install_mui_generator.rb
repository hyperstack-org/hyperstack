require_relative 'install_generator_base'
module Hyperloop
  class  InstallMuiGenerator < Rails::Generators::Base

    desc "Adds the bits you need for the MUI framework"

    class_option 'no-build', type: :boolean

    def insure_yarn_loaded
      begin
        yarn_version = `yarn --version`
        raise Errno::ENOENT if yarn_version.blank?
      rescue Errno::ENOENT
        raise Thor::Error.new("please insure the yarn command is available if using webpacker")
      end
    end

    def add_to_manifests
      add_to_manifest('client_and_server.js') { "Mui = require('muicss/react');\n" }
      add_to_manifest('application.scss') { "@import '~muicss/lib/sass/mui'\n" }
    end

    def add_style_sheet_pack_tag
      inject_into_file 'app/views/layouts/application.html.erb', after: /stylesheet_link_tag.*$/ do
        "\n    <%= stylesheet_pack_tag    'application' %>\n"
      end
    end

    def run_yarn
      yarn 'muicss'
    end

    def build_webpack
      system('bin/webpack') unless options['no-build']
    end

    def add_sample_component
      create_file 'app/hyperloop/components/mui_sampler.rb' do
        <<-RUBY
class MuiSampler < Hyperloop::Component
  render(DIV) do
    Mui::Appbar()
    Mui::Container() do
      Mui::Button(color: :primary) { 'button' }
    end
  end
end
        RUBY
      end
    end
  end
end
