module HyperI18n
  class Localize < Hyperloop::ServerOp
    param :acting_user
    param :time
    param :format
    param :localization, default: nil

    def formatted_time
      # All params are strings, so ensure we have a Time object
      Time.parse(params.time.to_s)
    end

    def formatted_format # lol
      # If a string is passed in it will use that as the pattern for formatting, ex:
      #
      # I18n.l(Time.now, format: "%b %d, %Y")
      # => "Aug 20, 2017"
      #
      # If a symbol is passed in it will find that definition from the locales.
      #
      # Since all parameters are Strings, we check if the '%' is in the string.

      # If it is, we just pass the string over without doing anything.
      if params.format.match?(/%/)
        params.format
      # Otherwise, we convert it to a symbol.
      else
        :"#{params.format}"
      end
    end

    step do
      params.localization = ::I18n.l(formatted_time, format: formatted_format)
    end
  end
end
