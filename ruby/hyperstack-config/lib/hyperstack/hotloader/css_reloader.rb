require 'native'
module Hyperstack
  class Hotloader
    class CssReloader

      def reload(reload_request, document)
        url = reload_request[:url]
        puts "Reloading CSS: #{url}"
        to_append = "t_hot_reload=#{Time.now.to_i}"
        links = Native(`document.getElementsByTagName("link")`)
        (0..links.length-1).each { |i|
          link = links[i]
          if link.rel == 'stylesheet' && is_matching_stylesheet?(link.href, url)
            if  link.href !~ /\?/
              link.href += "?#{to_append}"
            else
              if link.href !~ /t_hot_reload/
                link.href += "&#{to_append}"
              else
                link.href = link.href.sub(/t_hot_reload=\d+/, to_append)
              end
            end
          end
        }
      end

      def is_matching_stylesheet?(href, url)
        # straight match, like in Rack::Sass::Plugin
        if href.index(url)
          true
        else
          # Rails asset pipeline match
          url_base = File.basename(url).sub(/\.s?css+/, '').sub(/\.s?css+/, '')
          href_base = File.basename(href).sub(/\.self-?.*.css.+/, '')
          url_base == href_base
        end

      end
    end
  end
end
