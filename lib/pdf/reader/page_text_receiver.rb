# coding: utf-8

require 'forwardable'
require 'pdf/reader/page_layout'

module PDF
  class Reader

    # Builds a UTF-8 string of all the text on a single page by processing all
    # the operaters in a content stream.
    #
    class PageTextReceiver < PageReceiver

      SPACE = " "

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

      def internal_show_text(char)
          unless chars == SPACE
            @characters << TextRun.new(@state.glyfx, newy, scaled_glyph_width, @state.font_size, chars)
          end
        end
      end

    end
  end
end
