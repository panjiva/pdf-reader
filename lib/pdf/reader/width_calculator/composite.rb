# coding: utf-8

class PDF::Reader
  module WidthCalculator
    # CIDFontType0 or CIDFontType2 use DW (integer) and W (array) to determine
    # codepoint widths, note that CIDFontType2 will contain a true type font
    # program which could be used to calculate width, however, a conforming writer
    # is supposed to convert the widths for the codepoints used into the W array
    # so that it can be used.
    # see Section 9.7.4.1, PDF 32000-1:2008, pp 269-270
    class Composite

      def initialize(font)
        @font = font
        parse_cid_widths(@font.cid_default_width, @font.cid_widths)
        parse_cid_heights_and_positions(@font.cid_default_height, @font.cid_heights)
      end

      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0

        w = @widths[code_point]
        # 0 is a valid width
        return w.to_f unless w.nil?
      end

      #NOTE: heights are negative when the text goes top to bottom
      def glyph_height(code_point)
        return 0 if code_point.nil? || code_point < 0

        h = @heights[code_point]
        # 0 is a valid height
        return h.to_f unless h.nil?
      end

      def glyph_position(code_point)
        return [0,0] if code_point.nil? || code_point < 0

        p = @positions[code_point]
        if not h.nil?
          return h.to_f
        else
          w = glyph_width(code_point)
          return [w/2, @default_position_y] unless w.nil?
        end
      end


      private

      def parse_cid_widths(default, array)
        @widths  = Hash.new(default)
        params = []
        while array.size > 0
          params << array.shift

          if params.size == 2 && params.last.is_a?(Array)
            @widths.merge! parse_width_first_form(params.first, params.last)
            params = []
          elsif params.size == 3
            @widths.merge! parse_width_second_form(params[0], params[1], params[2])
            params = []
          end
        end
      end

      # this is the form 10 [234 63 234 346 47 234] where width of index 10 is
      # 234, index 11 is 63, etc
      def parse_width_first_form(first, widths)
        widths.inject({}) { |accum, glyph_width|
          accum[first + accum.size] = glyph_width
          accum
        }
      end

      # this is the form 10 20 123 where all index between 10 and 20 have width 123
      def parse_width_second_form(first, final, width)
        (first..final).inject({}) { |accum, index|
          accum[index] = width
          accum
        }
      end


      def parse_cid_heights_and_positions(default, array)
        @heights = Hash.new(default[1])
        @positions = {}
        @default_position_y = default[0]
        array.each do |params|
          if params.length == 2
            # this is of the form "cid [w1, vx1, vy1, w2, vx2, vy2, ....]"
            start_id = params[0]
            params[1].each_slice(3).with_index do |a,i|
              @heights[start+i] = a[0]
              @positions[start+i] = [a[1],a[2]]
            end
          elsif params.length == 3
            #this is of the form "cid_start, cid_end, w, vx, vy]"
            (params[0]..params[1]).each do |id|
              @heights[id] = params[2]
              @positions[id] = [params[3],params[4]]
            end
          end
        end
      end

    end
  end
end
