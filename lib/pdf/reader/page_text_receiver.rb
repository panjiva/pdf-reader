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
        super(page)
        @characters = []
        @mediabox = page.attributes[:MediaBox]
      end

      def content
        puts @characters
        PageLayout.new(@characters, @mediabox).to_s
      end

      #####################################################
      # XObjects
      #####################################################
      def invoke_xobject(label)
        super(label) do |xobj|
          case xobj
          when PDF::Reader::FormXObject then
            xobj.walk(self)
          end
        end
      end

      def process_glyph(glyph_code)
        unless current_font.is_space?(glyph_code)
          x = text_rendering_matrix.e
          y = text_rendering_matrix.f
          text = current_font.to_utf8(glyph_code)
          #TODO: figure out what should be done for sideways letters
          width = current_font.glyph_width(glyph_code)/1000.0 * text_rendering_matrix.a
          @characters << TextRun.new(x,y,width,state[:text_font_size],text)
        end
      end
    end

  end
end
