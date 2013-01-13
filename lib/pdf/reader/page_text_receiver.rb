# coding: utf-8

require 'forwardable'
require 'pdf/reader/page_layout'

module PDF
  class Reader

    # Builds a UTF-8 string of all the text on a single page by processing all
    # the operaters in a content stream.
    #
    class PageTextReceiver < PageReceiver

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @state.show_text_callback do |string, kerning|
          internal_show_text(string, kerning)
        end
        @characters = []
        @mediabox = page.attributes[:MediaBox]
      end

      def content
        PageLayout.new(@characters, @mediabox).to_s
      end

      #####################################################
      # XObjects
      #####################################################
      def invoke_xobject(label)
        @state.invoke_xobject(label) do |xobj|
          case xobj
          when PDF::Reader::FormXObject then
            xobj.walk(self)
          end
        end
      end

      private

      def show_glyph_callback()
          unless chars == SPACE
            scaled_glyph_width = magnitude(text_rendering_matrix.a, text_rendering_matrix.b)
            @characters << TextRun.new(@current_x, @current_y, scaled_glyph_width, font_size, @current_glyph)
          end
        end
      end

    end
  end
end
