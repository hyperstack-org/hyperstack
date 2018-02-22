module Vis
  module DataCommon
    def [](id)
      get(id)
    end

    def get(*args)
      if `Opal.is_a(args.$last(), Opal.Hash)`
        args.push(options_to_native(args.pop))
      end
      res = `self["native"].get.apply(self["native"], Opal.to_a(args))`
      if `res !== null && Opal.is_a(res, Opal.Array)`
        native_to_hash_array(res)
      else
        `res !== null ? Opal.Hash.$new(res) : #{nil}`
      end
    end

    def get_ids(options)
      @native.JS.getIds(options_to_native(options))
    end
  end
end