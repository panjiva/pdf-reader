# coding: utf-8

################################################################################
#
# Copyright (C) 2008 James Healy (jimmy@deefa.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader

  # Util class for working with string encodings in PDF files. Mostly used to
  # convert strings of various PDF-dialect encodings into UTF-8.
  class Encoding # :nodoc:
    CONTROL_CHARS = [0,1,2,3,4,5,6,7,8,11,12,14,15,16,17,18,19,20,21,22,23,
      24,25,26,27,28,29,30,31]
    UNKNOWN_CHAR = 0x25AF # ▯

    attr_reader :unpack

    def initialize(enc)
      @mapping  = {} # maps from character codes to Unicode codepoints
      # also maps control and invalid chars to UNKNOWN_CHAR
      @string_cache  = {} # maps from character codes to UTF-8 strings.

      if enc.kind_of?(Hash)
        self.differences = enc[:Differences] if enc[:Differences]
        enc = enc[:Encoding] || enc[:BaseEncoding]
      elsif enc != nil
        enc = enc.to_sym
      else
        enc = nil
      end

      @enc_name = enc
      @unpack   = get_unpack(enc)
      @map_file = get_mapping_file(enc)

      load_mapping(@map_file) if @map_file
      add_control_chars_to_mapping
    end

    # set the differences table for this encoding. should be an array in the following format:
    #
    #   [25, :A, 26, :B]
    #
    # The array alternates between a decimal byte number and a glyph name to map to that byte
    #
    # To save space the following array is also valid and equivalent to the previous one
    #
    #   [25, :A, :B]
    def differences=(diff)
      raise ArgumentError, "diff must be an array" unless diff.kind_of?(Array)

      @differences = {}
      byte = 0
      diff.each do |val|
        if val.kind_of?(Numeric)
          byte = val.to_i
        else
          @differences[byte] = val
          @mapping[byte] = names_to_unicode[val]
          byte += 1
        end
      end
      @differences
    end

    def differences
      # this method is only used by the spec tests
      @differences ||= {}
    end

    # convert the specified string to utf8
    #
    # * unpack raw bytes into codepoints
    # * replace any that have entries in the differences table with a glyph name
    # * convert codepoints from source encoding to Unicode codepoints
    # * convert any glyph names to Unicode codepoints
    # * replace characters that didn't convert to Unicode nicely with something
    #   valid
    # * pack the final array of Unicode codepoints into a utf-8 string
    # * mark the string as utf-8 if we're running on a M17N aware VM
    #
    def to_utf8(str)
      if utf8_conversion_impossible?
        little_boxes(str.unpack(unpack).size)
      else
        convert_to_utf8(str)
      end
    end

    def int_to_utf8_string(glyph_code)
      @string_cache[glyph_code] ||= internal_int_to_utf8_string(glyph_code)
    end

    # convert an integer glyph code into an Adobe glyph name.
    #
    #     int_to_name(65)
    #     => :A
    #
    # Standard character encodings are defined at the bottom of this file
    # 
    def int_to_name(glyph_code)
      if @enc_name == :"Identity-H" || @enc_name == :"Identity-V"
        nil
      elsif @enc_name == :MacRomanEncoding
        MAC_ROMAN_ENCODING_TO_NAME[glyph_code]
      elsif @enc_name == :WinAnsiEncoding
        WIN_ANSI_ENCODING_TO_NAME[glyph_code]
      elsif @differences
        @differences[glyph_code]
      elsif @enc_name == :StandardEncoding
        STANDARD_ENCODING_TO_NAME[glyph_code]
      else
        raise "#{@enc_name} does not have an int_to_name mapping"
      end
    end

    private

    def internal_int_to_utf8_string(glyph_code)
      ret = [
        @mapping[glyph_code.to_i] || glyph_code.to_i
      ].pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def utf8_conversion_impossible?
      @enc_name == :"Identity-H" || @enc_name == :"Identity-V"
    end

    def little_boxes(times)
      codepoints = [ PDF::Reader::Encoding::UNKNOWN_CHAR ] * times
      ret = codepoints.pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def convert_to_utf8(str)
      ret = str.unpack(unpack).map! { |c| @mapping[c] || c }.pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def get_unpack(enc)
      case enc
      when :"Identity-H", :"Identity-V", :UTF16Encoding
        "n*"
      else
        "C*"
      end
    end

    def get_mapping_file(enc)
      case enc
      when :"Identity-H", :"Identity-V", :UTF16Encoding then
        nil
      when :MacRomanEncoding then
        File.dirname(__FILE__) + "/encodings/mac_roman.txt"
      when :MacExpertEncoding then
        File.dirname(__FILE__) + "/encodings/mac_expert.txt"
      when :PDFDocEncoding then
        File.dirname(__FILE__) + "/encodings/pdf_doc.txt"
      when :SymbolEncoding then
        File.dirname(__FILE__) + "/encodings/symbol.txt"
      when :WinAnsiEncoding then
        File.dirname(__FILE__) + "/encodings/win_ansi.txt"
      when :ZapfDingbatsEncoding then
        File.dirname(__FILE__) + "/encodings/zapf_dingbats.txt"
      else
        File.dirname(__FILE__) + "/encodings/standard.txt"
      end
    end

    def has_mapping?
      @mapping.size > 0
    end

    def names_to_unicode
      @names_to_unicode ||= PDF::Reader::GlyphHash.new
    end

    def load_mapping(file)
      return if has_mapping?

      RUBY_VERSION >= "1.9" ? mode = "r:BINARY" : mode = "r"
      File.open(file, mode) do |f|
        f.each do |l|
          m, single_byte, unicode = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
          @mapping["0x#{single_byte}".hex] = "0x#{unicode}".hex if single_byte
        end
      end
    end

    def add_control_chars_to_mapping
      PDF::Reader::Encoding::CONTROL_CHARS.each do |byte|
        unless @mapping[byte]
          @mapping[byte] = PDF::Reader::Encoding::UNKNOWN_CHAR
        end
      end
      @mapping[nil] = PDF::Reader::Encoding::UNKNOWN_CHAR
    end
  end


  # Definition of the StandardEncoding taken from the Adobe website
  STANDARD_ENCODING_TO_NAME = {
    32 => :space, 33 => :exclam, 34 => :quotedbl, 35 => :numbersign, 36 => :dollar,
    37 => :percent, 38 => :ampersand, 39 => :quoteright, 40 => :parenleft, 41 => :parenright,
    42 => :asterisk, 43 => :plus, 44 => :comma, 45 => :hyphen, 46 => :period, 47 => :slash,
    48 => :zero, 49 => :one, 50 => :two, 51 => :three, 52 => :four, 53 => :five, 54 => :six,
    55 => :seven, 56 => :eight, 57 => :nine, 58 => :colon, 59 => :semicolon, 60 => :less,
    61 => :equal, 62 => :greater, 63 => :question, 64 => :at, 65 => :A, 66 => :B, 67 => :C,
    68 => :D, 69 => :E, 70 => :F, 71 => :G, 72 => :H, 73 => :I, 74 => :J, 75 => :K, 76 => :L,
    77 => :M, 78 => :N, 79 => :O, 80 => :P, 81 => :Q, 82 => :R, 83 => :S, 84 => :T, 85 => :U,
    86 => :V, 87 => :W, 88 => :X, 89 => :Y, 90 => :Z, 91 => :bracketleft, 92 => :backslash,
    93 => :bracketright, 94 => :asciicircum, 95 => :underscore, 96 => :quoteleft, 97 => :a,
    98 => :b, 99 => :c, 100 => :d, 101 => :e, 102 => :f, 103 => :g, 104 => :h, 105 => :i,
    106 => :j, 107 => :k, 108 => :l, 109 => :m, 110 => :n, 111 => :o, 112 => :p, 113 => :q,
    114 => :r, 115 => :s, 116 => :t, 117 => :u, 118 => :v, 119 => :w, 120 => :x, 121 => :y,
    122 => :z, 123 => :braceleft, 124 => :bar, 125 => :braceright, 126 => :asciitilde,
    161 => :exclamdown, 162 => :cent, 163 => :sterling, 164 => :fraction, 165 => :yen,
    166 => :florin, 167 => :section, 168 => :currency, 169 => :quotesingle, 170 => :quotedblleft,
    171 => :guillemotleft, 172 => :guilsinglleft, 173 => :guilsinglright, 174 => :fi, 175 => :fl,
    177 => :endash, 178 => :dagger, 179 => :daggerdbl, 180 => :periodcentered, 182 => :paragraph,
    183 => :bullet, 184 => :quotesinglbase, 185 => :quotedblbase, 186 => :quotedblright,
    187 => :guillemotright, 188 => :ellipsis, 189 => :perthousand, 191 => :questiondown,
    193 => :grave, 194 => :acute, 195 => :circumflex, 196 => :tilde, 197 => :macron, 198 => :breve,
    199 => :dotaccent, 200 => :dieresis, 202 => :ring, 203 => :cedilla, 205 => :hungarumlaut,
    206 => :ogonek, 207 => :caron, 208 => :emdash, 225 => :AE, 227 => :ordfeminine, 232 => :Lslash,
    233 => :Oslash, 234 => :OE, 235 => :ordmasculine, 241 => :ae, 245 => :dotlessi, 248 => :lslash,
    249 => :oslash, 250 => :oe, 251 => :germandbls,
  }

  MAC_ROMAN_ENCODING_TO_NAME = {
    32 => :space, 33 => :exclam, 34 => :quotedbl, 35 => :numbersign, 36 => :dollar,
    37 => :percent, 38 => :ampersand, 39 => :quotesingle, 40 => :parenleft, 41 => :parenright,
    42 => :asterisk, 43 => :plus, 44 => :comma, 45 => :hyphen, 46 => :period,
    47 => :slash, 48 => :zero, 49 => :one, 50 => :two, 51 => :three, 52 => :four,
    53 => :five, 54 => :six, 55 => :seven, 56 => :eight, 57 => :nine, 58 => :colon,
    59 => :semicolon, 60 => :less, 61 => :equal, 62 => :greater, 63 => :question,
    64 => :at, 65 => :A, 66 => :B, 67 => :C, 68 => :D, 69 => :E, 70 => :F, 71 => :G,
    72 => :H, 73 => :I, 74 => :J, 75 => :K, 76 => :L, 77 => :M, 78 => :N, 79 => :O,
    80 => :P, 81 => :Q, 82 => :R, 83 => :S, 84 => :T, 85 => :U, 86 => :V, 87 => :W,
    88 => :X, 89 => :Y, 90 => :Z, 91 => :bracketleft, 92 => :backslash, 93 => :bracketright,
    94 => :asciicircum, 95 => :underscore, 96 => :grave, 97 => :a, 98 => :b, 99 => :c,
    100 => :d, 101 => :e, 102 => :f, 103 => :g, 104 => :h, 105 => :i, 106 => :j,
    107 => :k, 108 => :l, 109 => :m, 110 => :n, 111 => :o, 112 => :p, 113 => :q, 114 => :r,
    115 => :s, 116 => :t, 117 => :u, 118 => :v, 119 => :w, 120 => :x, 121 => :y, 122 => :z,
    123 => :braceleft, 124 => :bar, 125 => :braceright, 126 => :asciitilde,
    128 => :Adieresis, 129 => :Aring, 130 => :Ccedilla, 131 => :Eacute, 132 => :Ntilde,
    133 => :Odieresis, 134 => :Udieresis, 135 => :aacute, 136 => :agrave, 137 => :acircumflex,
    138 => :adieresis, 139 => :atilde, 140 => :aring, 141 => :ccedilla, 142 => :eacute,
    143 => :egrave, 144 => :ecircumflex, 145 => :edieresis, 146 => :iacute, 147 => :igrave,
    148 => :icircumflex, 149 => :idieresis, 150 => :ntilde, 151 => :oacute, 152 => :ograve,
    153 => :ocircumflex, 154 => :odieresis, 155 => :otilde, 156 => :uacute, 157 => :ugrave,
    158 => :ucircumflex, 159 => :udieresis, 160 => :dagger, 161 => :degree, 162 => :cent,
    163 => :sterling, 164 => :section, 165 => :bullet, 166 => :paragraph, 167 => :germandbls,
    168 => :registered, 169 => :copyright, 170 => :trademark, 171 => :acute, 172 => :dieresis,
    173 => :notequal, 174 => :AE, 175 => :Oslash, 176 => :infinity, 177 => :plusminus,
    178 => :lessequal, 179 => :greaterequal, 180 => :yen, 181 => :mu, 182 => :partialdiff,
    183 => :summation, 184 => :product, 185 => :pi, 186 => :integral, 187 => :ordfeminine,
    188 => :ordmasculine, 189 => :Omega, 190 => :ae, 191 => :oslash, 192 => :questiondown,
    193 => :exclamdown, 194 => :logicalnot, 195 => :radical, 196 => :ﬂorin, 197 => :approxequal,
    198 => :Delta, 199 => :guillemotleft, 200 => :guillemotright, 201 => :ellipsis,
    202 => :nobreakspace, 203 => :Agrave, 204 => :Atilde, 205 => :Otilde, 206 => :OE,
    207 => :oe, 208 => :endash, 209 => :emdash, 210 => :quotedblleft, 211 => :quotedblright,
    212 => :quoteleft, 213 => :quoteright, 214 => :divide, 215 => :lozenge, 216 => :ydieresis,
    217 => :Ydieresis, 218 => :fraction, 219 => :currency, 220 => :guilsinglleft,
    221 => :guilsinglright, 222 => :fi, 223 => :fl, 224 => :daggerdbl, 225 => :periodcentered,
    226 => :quotesinglbase, 227 => :quotedblbase, 228 => :perthousane, 229 => :Acircumflex,
    230 => :Ecircumflex, 231 => :Aacute, 232 => :Edieresis, 233 => :Egrave, 234 => :Iacute,
    235 => :Icircumflex, 236 => :Idieresis, 237 => :Igrave, 238 => :Oacute, 239 => :Ocircumflex,
    240 => :apple, 241 => :Ograve, 242 => :Uacute, 243 => :Ucircumflex, 244 => :Ugrave,
    245 => :dotlessi, 246 => :circumflex, 247 => :tilde, 248 => :macron, 249 => :breve,
    250 => :dotaccent, 251 => :ring, 252 => :cedilla, 253 => :hungarumlaut, 254 => :ogonek, 255 => :caron, 
  }


  ##
  # NOTE: the windows encoding has some additional key/value pairs
  # which are not included in the following hash:
  # 
  #     nbspace             160/a0   <- same as no break space
  #     sfthyphen           173/ad   <- same as hyphen
  #     middot              183/b7   <- same as period center
  ##

  WIN_ANSI_ENCODING_TO_NAME = {
    :space => 32, :exclam => 33, :quotedbl => 34, :numbersign => 35, :dollar => 36, :percent => 37,
    :ampersand => 38, :quotesingle => 39, :parenleft => 40, :parenright => 41, :asterisk => 42, :plus => 43,
    :comma => 44, :hyphen => 45, :period => 46, :slash => 47, :zero => 48, :one => 49,
    :two => 50, :three => 51, :four => 52, :five => 53, :six => 54, :seven => 55,
    :eight => 56, :nine => 57, :colon => 58, :semicolon => 59, :less => 60, :equal => 61,
    :greater => 62, :question => 63, :at => 64, :A => 65, :B => 66, :C => 67,
    :D => 68, :E => 69, :F => 70, :G => 71, :H => 72, :I => 73,
    :J => 74, :K => 75, :L => 76, :M => 77, :N => 78, :O => 79,
    :P => 80, :Q => 81, :R => 82, :S => 83, :T => 84, :U => 85,
    :V => 86, :W => 87, :X => 88, :Y => 89, :Z => 90, :bracketleft => 91,
    :backslash => 92, :bracketright => 93, :asciicircum => 94, :underscore => 95, :grave => 96, :a => 97,
    :b => 98, :c => 99, :d => 100, :e => 101, :f => 102, :g => 103,
    :h => 104, :i => 105, :j => 106, :k => 107, :l => 108, :m => 109,
    :n => 110, :o => 111, :p => 112, :q => 113, :r => 114, :s => 115,
    :t => 116, :u => 117, :v => 118, :w => 119, :x => 120, :y => 121,
    :z => 122, :braceleft => 123, :bar => 124, :braceright => 125, :asciitilde => 126, :Adieresis => 196,
    :Aring => 197, :Ccedilla => 199, :Eacute => 201, :Ntilde => 209, :Odieresis => 214, :Udieresis => 220,
    :aacute => 225, :agrave => 224, :acircumflex => 226, :adieresis => 228, :atilde => 227, :aring => 229,
    :ccedilla => 231, :eacute => 233, :egrave => 232, :ecircumflex => 234, :edieresis => 235, :iacute => 237,
    :igrave => 236, :icircumflex => 238, :idieresis => 239, :ntilde => 241, :oacute => 243, :ograve => 242,
    :ocircumflex => 244, :odieresis => 246, :otilde => 245, :uacute => 250, :ugrave => 249, :ucircumflex => 251,
    :udieresis => 252, :dagger => 134, :degree => 176, :cent => 162, :sterling => 163, :section => 167,
    :bullet => 149, :paragraph => 182, :germandbls => 223, :registered => 174, :copyright => 169, :trademark => 153,
    :acute => 180, :dieresis => 168, :AE => 198, :Oslash => 216, :plusminus => 177, :yen => 165,
    :mu => 181, :ordfeminine => 170, :ordmasculine => 186, :ae => 230, :oslash => 248, :questiondown => 191,
    :exclamdown => 161, :logicalnot => 172, :florin => 131, :guillemotleft => 171, :guillemotright => 187, :ellipsis => 133,
    :nobreakspace => 160, :Agrave => 192, :Atilde => 195, :Otilde => 213, :OE => 140, :oe => 156,
    :endash => 150, :emdash => 151, :quotedblleft => 147, :quotedblright => 148, :quoteleft => 145, :quoteright => 146,
    :divide => 247, :ydieresis => 255, :Ydieresis => 159, :currency => 164, :guilsinglleft => 139, :guilsinglright => 155,
    :daggerdbl => 135, :periodcentered => 183, :quotesinglbase => 130, :quotedblbase => 132, :perthousane => 137, :Acircumflex => 194,
    :Ecircumflex => 202, :Aacute => 193, :Edieresis => 203, :Egrave => 200, :Iacute => 205, :Icircumflex => 206,
    :Idieresis => 207, :Igrave => 204, :Oacute => 211, :Ocircumflex => 212, :Ograve => 210, :Uacute => 218,
    :Ucircumflex => 219, :Ugrave => 217, :circumflex => 136, :tilde => 152, :macron => 175, :cedilla => 184,
    :Scaron => 138, :scaron => 154, :brokenbar => 166, :Eth => 208, :eth => 240, :Yacute => 221,
    :yacute => 253, :Thorn => 222, :thorn => 254, :multiply => 215, :onesuperior => 185, :twosuperior => 178,
    :threesuperior => 179, :onehalf => 189, :onequarter => 188, :threequarters => 190,
  }


end
