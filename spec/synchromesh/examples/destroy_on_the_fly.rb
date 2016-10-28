require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "random examples", js: true do

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
