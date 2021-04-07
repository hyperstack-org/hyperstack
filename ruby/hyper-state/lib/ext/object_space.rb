module ObjectSpace
  def self.each_object(target_klass, &block)
    klasses = [Object]
    i = 0
    loop do
      klass = klasses[i]
      yield klass
      names = `klass.$$const` && `Object.keys(klass.$$const)`
      names.each do |name|
        begin
          k = klass.const_get(name) rescue nil
          next unless `k.$$const`
          next unless k.respond_to?(:is_a?)
          next if klasses.include?(k)

          klasses << k if k.is_a? target_klass
        rescue Exception => e
          next
        end
      end if names
      i += 1
      break if i >= klasses.length
    end
  end
end
