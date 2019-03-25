module Components
  module Drafts
    module Pro
      module Sidebar
        class PaperItem < HyperComponent
          param :paper, type: Paper
          param :job
          param :index

          include Hyperstack::Component::Tracker[:components]

          after_mount do
            DOM[dom_node].tooltip({ delay: { show: 750, hide: 0 } }.to_n) if conflicts
          end

          after_update do
            DOM[dom_node].tooltip(:destroy)
            DOM[dom_node].tooltip({ delay: { show: 750, hide: 0 } }.to_n) if conflicts
          end

          def conflicts
            return false if @Job.calculate_conflict_triggers.loading?
            triggers = @Job.calculate_conflict_triggers[:paper_ids]
            triggers.any? && triggers[@Paper.id.to_s]
          end

          def selected?
            @Job.paper == @Paper
          end

          def class_names
            classes = ['paper-list-item list-group-item']
            classes << :active if selected?
            classes << :disabled if conflicts
            classes << @Index.even? ? :even : :odd
          end


          def size_conflict_message
            "#{@Paper.name} has a maximum size of "\
            "#{@Paper.portrait_width_in_local_units} "\
            "x #{@Paper.portrait_height_in_local_units}"
          end

          def conflict_message
            return '' unless conflicts
            return conflicts unless conflicts == 'size'
            size_conflict_message
          end

          def select_paper
            return if conflicts
            DOM['.paper-list-item'].remove_class('active')
            DOM["#paper_#{@Paper.id}"].add_class('active')
            after(0) do  # maybe able to bulk_update method
              @Job.paper_selected = true
              @Job.paper_id = @Paper.id
              @Job.paper = @Paper
              Drafts::App.update_job_calcs
            end
          end

          def detail_row(detail)
            TH { detail.split(': ')[0] }
            TD { detail.split(': ')[1] }
          end

          render do
            LI(id: "paper_#{@Paper.id}", title: conflict_message,
               class: class_names,
               data: { toggle: :tooltip, placement: 'auto left', container: :body }) do
              DIV(class: 'row paper-row') do
                DIV(class: 'col-sm-8 text-left') do
                  SPAN(class: 'medium-weight') { @Paper.name }
                end
                DIV(class: 'col-sm-4') do
                  unless @Paper.details.blank?
                    SPAN(class: "paper-details-button #{'expanded' if @expanded}") do
                      SPAN { "#{'Hide' if @expanded} Details" }
                      I(class: 'material-icons', style: { verticalAlign: 'middle' }) do
                        "expand_#{@expanded ? :less : :more}"
                      end
                    end.on(:click) do |e|
                      e.prevent_default
                      e.stop_propagation
                      toggle :expanded
                    end
                  end
                end
                if @expanded && !@Paper.details.blank?
                  DIV(class: 'col-sm-12') do
                    TABLE(class: 'table paper-details-list') do
                      TBODY do
                        @Paper.details.each do |detail|
                          TR { detail_row(detail) }
                        end
                        @Paper.description.gsub(%r{<[/]*\w+>}, '')
                              .delete("\r").split("\n").reject(&:blank?).each do |detail|
                          TR { detail_row(detail) }
                        end
                      end
                    end
                  end
                end
              end
            end.on(:click) { select_paper }
          end
        end
      end
    end
  end
end
