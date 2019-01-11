module Components
  module Drafts
    module Pro
      module Sidebar
        class PaperItem < React::Component::Base
          param :paper, type: Paper
          param :job
          param :index

          define_state expanded: false

          before_mount { self.class.components << self }

          after_mount do
            Element[dom_node].tooltip({ delay: { show: 750, hide: 0 } }.to_n) if conflicts
          end

          after_update do
            Element[dom_node].tooltip(:destroy)
            Element[dom_node].tooltip({ delay: { show: 750, hide: 0 } }.to_n) if conflicts
          end

          before_unmount { self.class.components.delete(self) }

          def conflicts
            return false if params.job.calculate_conflict_triggers.loading?
            triggers = params.job.calculate_conflict_triggers[:paper_ids]
            triggers.any? && triggers[params.paper.id.to_s]
          end

          def selected?
            params.job.paper == params.paper
          end

          def class_names
            classes = ['paper-list-item list-group-item']
            classes << :active if selected?
            classes << :disabled if conflicts
            classes << params.index.even? ? :even : :odd
            classes.join(' ') # TODO: once upgraded to hyperloop 0.99 or better remove this line
          end

          def size_conflict_message
            "#{params.paper.name} has a maximum size of "\
            "#{params.paper.portrait_width_in_local_units} "\
            "x #{params.paper.portrait_height_in_local_units}"
          end

          def conflict_message
            return '' unless conflicts
            return conflicts unless conflicts == 'size'
            size_conflict_message
          end

          def select_paper
            return if conflicts
            Element['.paper-list-item'].remove_class('active')
            Element["#paper_#{params.paper.id}"].add_class('active')
            after(0) do
              params.job.paper_selected = true
              params.job.paper_id = params.paper.id
              params.job.paper = params.paper
              Drafts::App.update_job_calcs
            end
          end

          def detail_row(detail)
            TH { detail.split(': ')[0] }
            TD { detail.split(': ')[1] }
          end

          render do
            LI(id: "paper_#{params.paper.id}", title: conflict_message,
               class: class_names,
               data: { toggle: :tooltip, placement: 'auto left', container: :body }) do
              DIV(class: 'row paper-row') do
                DIV(class: 'col-sm-8 text-left') do
                  SPAN(class: 'medium-weight') { params.paper.name }
                end
                DIV(class: 'col-sm-4') do
                  unless params.paper.details.blank?
                    SPAN(class: "paper-details-button #{'expanded' if state.expanded}") do
                      SPAN { "#{'Hide' if state.expanded} Details" }
                      I(class: 'material-icons', style: { verticalAlign: 'middle' }) do
                        "expand_#{state.expanded ? :less : :more}"
                      end
                    end.on(:click) do |e|
                      e.prevent_default
                      e.stop_propagation
                      state.expanded! !state.expanded
                    end
                  end
                end
                if state.expanded && !params.paper.details.blank?
                  DIV(class: 'col-sm-12') do
                    TABLE(class: 'table paper-details-list') do
                      TBODY do
                        params.paper.details.each do |detail|
                          TR { detail_row(detail) }
                        end
                        params.paper.description.gsub(%r{<[/]*\w+>}, '')
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
