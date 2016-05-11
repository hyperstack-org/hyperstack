module ReactiveRecord

  class Base

    def self.when_not_saving(model)
      if @records[model].detect { |record| record.saving? }
        poller = every (0.1) do
          unless @records[model].detect { |record| record.saving? }
            poller.stop
            yield model
          end
        end
      else
        yield model
      end
    end

  end

end
