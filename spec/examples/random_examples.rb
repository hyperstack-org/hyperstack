require 'spec_helper'
require 'test_components'

describe "random examples", js: true do

  it "can pass an array subclass as a param" do
    mount "Tester" do
      class SubArray < Array
      end

      class HelloWorld < React::Component::Base
        param :array, type: SubArray
        render do
          i = 10
          div {
            div { "params.array.is_a? #{params.array.class}" }
            params.array.each {|i| h1 {i.to_s}}
          }
        end
      end

      class Tester < React::Component::Base
        def render
          normal_array = [1, 2]
          sub_array = SubArray.new
          sub_array << 1; sub_array << 2
          DIV do
            # this works
            HelloWorld(array: normal_array)
            # this doesn't
            DIV { "out here a sub_array is a #{sub_array.class}" }
            HelloWorld(array: sub_array)
          end
        end
      end
    end
    pause
  end

  it "pass a native hash as a param" do
    mount "Tester" do

      class React::RenderingContext
        def self.remove_nodes_from_args(args)
          args[0].each do |key, value|
            begin
              value.as_node if value.is_a?(Element)
            rescue Exception
            end
          end if args[0] && args[0].is_a?(Hash)
        end
      end

      class HelloWorld < React::Component::Base
        param :hash
        render do
          debugger
          "hash[key] = #{`#{params.hash['key']}`}"
        end
      end

      class Tester < React::Component::Base
        def render
          HelloWorld(hash: `{key: 'the key'}`)
        end
      end
    end
    page.should have_content("hash[key] = 'the key'")
    pause
  end


  it "can destroy on the fly" do

    5.times do |i|
      FactoryGirl.create(:test_model, test_attribute: "I am model #{i}")
    end

    mount "RecordsComp" do
      class RecordsComp < React::Component::Base
        # you had state.credits as an expression... not sure that is what you wanted
        render(:div, class: "state.credits") do
          h2.title { 'Records' }
          #RecordFormComp()
          hr { nil }
          table.table.table_bordered do
            thead { tr { th { 'Date' }
                         th { 'Title' }
                         #th { 'Amount' }
                         th { 'Actions' } } }
            tbody do
              TestModel.each do |record|
                RecordComp key: record[:id], record: record
              end
            end
          end
        end
      end

      class RecordComp < React::Component::Base
        param :key, type: String
        param :record, type: TestModel  # type is optional here

        def handle_delete
          params.record.destroy do |result|
            alert 'unable to delete record' unless result
          end
        end

        def render
          tr do
            # currently you should access attributes using
            # dot notation only.  Currently the [] operator
            # accesses record values directly without setting up
            # any reactive response.  This will probably change
            # with release of Hypermesh
            td { params.record.created_at }
            td { params.record.test_attribute }
            #td { amount_format(params.record[:amount]) }
            td { a.btn.btn_danger { 'Delete' }.on(:click) { handle_delete } }
          end
        end

        def amount_format(amount)
          '$ ' + amount.to_s.reverse.gsub(/...(?!-)(?=.)/,'\&,').reverse
        end
      end
    end

    pause

  end
end
