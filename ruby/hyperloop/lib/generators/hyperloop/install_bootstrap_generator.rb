require_relative 'install_generator_base'
module Hyperloop
  class  InstallBootstrapGenerator < Rails::Generators::Base

    desc "Adds the bits you need for the Bootstrap 3.0 framework"

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
      add_to_manifest 'client_and_server.js' do
        "BS = require('react-bootstrap');\n"
      end
    end

    def add_style_sheet_pack_tag
      inject_into_file 'app/views/layouts/application.html.erb', after: /stylesheet_link_tag.*$/ do
        <<-JAVASCRIPT

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">
        JAVASCRIPT
      end
    end

    def run_yarn
      yarn 'react-bootstrap'
      yarn 'bootstrap@3'
    end

    def build_webpack
      system('bin/webpack') unless options['no-build']
    end

    def add_sample_component
      create_file 'app/hyperloop/components/bs_sampler.rb' do
        <<-RUBY
class BsSampler < Hyperloop::Component
  render(DIV) do
    BS::Grid() do
      BS::Row(class: "show-grid") do
        BS::Col(xs: 12, md: 8) do
          CODE { "BS::Col(xs: 12, md: 8)" }
        end
        BS::Col(xs: 6, md: 4) do
          CODE { "BS::Col(xs: 6, md: 4)" }
        end
      end
      BS::Row() do
        BS::Alert(bsStyle: "warning") do
          STRONG { "Holy guacamole!" }
          SPAN { " Best check yo self, you're not looking too good." }
        end
      end
    end
  end
end
        RUBY
      end
    end
  end
end
