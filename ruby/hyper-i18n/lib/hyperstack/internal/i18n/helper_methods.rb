module Hyperstack
  module Internal
    class I18n
      module HelperMethods
        def formatted_date_or_time(date_or_time)
          # If the date_or_time parameter is a String, we must parse it to the correct format.

          return date_or_time unless date_or_time.is_a?(String)

          if date_or_time =~ /^\d+\W\d+\W\d+T?\s?\d+:\d+:\d+/
            Time.parse(date_or_time)
          else
            Date.parse(date_or_time)
          end
        end

        def formatted_format(format)
          # If a string is passed in it will use that as the pattern for formatting, ex:
          #
          # I18n.l(Time.now, format: "%b %d, %Y")
          # => "Aug 20, 2017"
          #
          # If a symbol is passed in it will find that definition from the locales.

          format =~ /%/ ? format : :"#{format}"
        end
      end
    end
  end
end
