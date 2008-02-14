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
  class Encoding

    def self.factory(enc)
      enc = enc['Encoding'] if enc.kind_of?(Hash)
      case enc
        when nil then nil
        when "Identity-H" then PDF::Reader::Encoding::IdentityH.new
        when "MacRomanEncoding" then PDF::Reader::Encoding::MacRomanEncoding.new
        when "SymbolEncoding" then PDF::Reader::Encoding::SymbolEncoding.new
        when "WinAnsiEncoding" then PDF::Reader::Encoding::WinAnsiEncoding.new
        when "ZapfDingbatsEncoding" then PDF::Reader::Encoding::ZapfDingbatsEncoding.new
        else raise UnsupportedFeatureError, "#{enc} is not currently a supported encoding"
      end
    end

    def to_utf8(str, tounicode = nil)
      # abstract method, of sorts
      raise RuntimeError, "Called abstract method"
    end

    class IdentityH < Encoding
      def to_utf8(str, map = nil)
        raise ArgumentError, "a ToUnicode cmap is required to decode an IdentityH string" if map.nil?

        array_enc = []

        # iterate over string, reading it in 2 byte chunks and interpreting those
        # chunks as ints
        str.unpack("n*").each do |c|
          # convert the int to a unicode codepoint
          array_enc << map.decode(c)
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    # The default encoding for OSX <= v9
    # see: http://en.wikipedia.org/wiki/Mac_OS_Roman
    class MacRomanEncoding < Encoding
      # convert a MacRomanEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # content of this method borrowed from REXML::Encoding.decode_cp1252
        array_latin9 = str.unpack('C*')
        array_enc = []
        array_latin9.each do |num|
          case num
            # change necesary characters to equivilant Unicode codepoints
          when 0x80; array_enc << 0x00C4
          when 0x81; array_enc << 0x00C5
          when 0x82; array_enc << 0x00C7
          when 0x83; array_enc << 0x00C9
          when 0x84; array_enc << 0x00D1
          when 0x85; array_enc << 0x00D6
          when 0x86; array_enc << 0x00DC
          when 0x87; array_enc << 0x00E1
          when 0x88; array_enc << 0x00E0
          when 0x89; array_enc << 0x00E2
          when 0x8A; array_enc << 0x00E4
          when 0x8B; array_enc << 0x00E3
          when 0x8C; array_enc << 0x00E5
          when 0x8D; array_enc << 0x00E7
          when 0x8E; array_enc << 0x00E9
          when 0x8F; array_enc << 0x00E8
          when 0x90; array_enc << 0x00EA
          when 0x91; array_enc << 0x00EB
          when 0x92; array_enc << 0x00ED
          when 0x93; array_enc << 0x00EC
          when 0x94; array_enc << 0x00EE
          when 0x95; array_enc << 0x00EF
          when 0x96; array_enc << 0x00F1
          when 0x97; array_enc << 0x00F3
          when 0x98; array_enc << 0x00F2
          when 0x99; array_enc << 0x00F4
          when 0x9A; array_enc << 0x00F6
          when 0x9B; array_enc << 0x00F5
          when 0x9C; array_enc << 0x00FA
          when 0x9D; array_enc << 0x00F9
          when 0x9E; array_enc << 0x00FB
          when 0x9F; array_enc << 0x00FC
          when 0xA0; array_enc << 0x2020
          when 0xA1; array_enc << 0x00B0
          when 0xA2; array_enc << 0x00A2
          when 0xA3; array_enc << 0x00A3
          when 0xA4; array_enc << 0x00A7
          when 0xA5; array_enc << 0x2022
          when 0xA6; array_enc << 0x00B6
          when 0xA7; array_enc << 0x00DF
          when 0xA8; array_enc << 0x00AE
          when 0xA9; array_enc << 0x00A9
          when 0xAA; array_enc << 0x2122
          when 0xAB; array_enc << 0x00B4
          when 0xAC; array_enc << 0x00A8
          when 0xAD; array_enc << 0x2260
          when 0xAE; array_enc << 0x00C6
          when 0xAF; array_enc << 0x00D8
          when 0xB0; array_enc << 0x221E
          when 0xB1; array_enc << 0x00B1
          when 0xB2; array_enc << 0x2264
          when 0xB3; array_enc << 0x2265
          when 0xB4; array_enc << 0x00A5
          when 0xB5; array_enc << 0x00B5
          when 0xB6; array_enc << 0x2202
          when 0xB7; array_enc << 0x2211
          when 0xB8; array_enc << 0x220F
          when 0xB9; array_enc << 0x03C0
          when 0xBA; array_enc << 0x222B
          when 0xBB; array_enc << 0x00AA
          when 0xBC; array_enc << 0x00BA
          when 0xBD; array_enc << 0x03A9
          when 0xBE; array_enc << 0x00E6
          when 0xBF; array_enc << 0x00F8
          when 0xC0; array_enc << 0x00BF
          when 0xC1; array_enc << 0x00A1
          when 0xC2; array_enc << 0x00AC
          when 0xC3; array_enc << 0x221A
          when 0xC4; array_enc << 0x0192
          when 0xC5; array_enc << 0x2248
          when 0xC6; array_enc << 0x2206
          when 0xC7; array_enc << 0x00AB
          when 0xC8; array_enc << 0x00BB
          when 0xC9; array_enc << 0x2026
          when 0xCA; array_enc << 0x00A0
          when 0xCB; array_enc << 0x00C0
          when 0xCC; array_enc << 0x00C3
          when 0xCD; array_enc << 0x00D5
          when 0xCE; array_enc << 0x0152
          when 0xCF; array_enc << 0x0153
          when 0xD0; array_enc << 0x2013
          when 0xD1; array_enc << 0x2014
          when 0xD2; array_enc << 0x201C
          when 0xD3; array_enc << 0x201D
          when 0xD4; array_enc << 0x2018
          when 0xD5; array_enc << 0x2019
          when 0xD6; array_enc << 0x00F7
          when 0xD7; array_enc << 0x25CA
          when 0xD8; array_enc << 0x00FF
          when 0xD9; array_enc << 0x0178
          when 0xDA; array_enc << 0x2044
          when 0xDB; array_enc << 0x20AC
          when 0xDC; array_enc << 0x2039
          when 0xDD; array_enc << 0x203A
          when 0xDE; array_enc << 0xFB01
          when 0xDF; array_enc << 0xFB02
          when 0xE0; array_enc << 0x2021
          when 0xE1; array_enc << 0x00B7
          when 0xE2; array_enc << 0x201A
          when 0xE3; array_enc << 0x201E
          when 0xE4; array_enc << 0x2030
          when 0xE5; array_enc << 0x00C2
          when 0xE6; array_enc << 0x00CA
          when 0xE7; array_enc << 0x00C1
          when 0xE8; array_enc << 0x00CB
          when 0xE9; array_enc << 0x00C8
          when 0xEA; array_enc << 0x00CD
          when 0xEB; array_enc << 0x00CE
          when 0xEC; array_enc << 0x00CF
          when 0xED; array_enc << 0x00CC
          when 0xEE; array_enc << 0x00D3
          when 0xEF; array_enc << 0x00D4
          when 0xF0; array_enc << 0xF8FF
          when 0xF1; array_enc << 0x00D2
          when 0xF2; array_enc << 0x00DA
          when 0xF3; array_enc << 0x00D8
          when 0xF4; array_enc << 0x00D9
          when 0xF5; array_enc << 0x0131
          when 0xF6; array_enc << 0x02C6
          when 0xF7; array_enc << 0x02DC
          when 0xF8; array_enc << 0x00AF
          when 0xF9; array_enc << 0x02D8
          when 0xFA; array_enc << 0x02D9
          when 0xFB; array_enc << 0x02DA
          when 0xFC; array_enc << 0x00B8
          when 0xFD; array_enc << 0x02DD
          when 0xFE; array_enc << 0x02DB
          when 0xFF; array_enc << 0x02C7
          else
            array_enc << num
          end
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class SymbolEncoding < Encoding
      # convert a SymbolEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        array_symbol = str.unpack('C*')
        array_enc = []
        array_symbol.each do |num|
          case num
          when 0x22; array_enc << 0x2200
          when 0x24; array_enc << 0x2203
          when 0x27; array_enc << 0x220B
          when 0x2A; array_enc << 0x2217
          when 0x2D; array_enc << 0x2212
          when 0x40; array_enc << 0x2245
          when 0x41; array_enc << 0x0391
          when 0x42; array_enc << 0x0392
          when 0x43; array_enc << 0x03A7
          when 0x44; array_enc << 0x0394
          when 0x45; array_enc << 0x0395
          when 0x46; array_enc << 0x03A6
          when 0x47; array_enc << 0x0393
          when 0x48; array_enc << 0x0397
          when 0x49; array_enc << 0x0399
          when 0x4A; array_enc << 0x03D1
          when 0x4B; array_enc << 0x039A
          when 0x4C; array_enc << 0x039B
          when 0x4D; array_enc << 0x039C
          when 0x4E; array_enc << 0x039D
          when 0x4F; array_enc << 0x039F
          when 0x50; array_enc << 0x03A0
          when 0x51; array_enc << 0x0398
          when 0x52; array_enc << 0x03A1
          when 0x53; array_enc << 0x03A3
          when 0x54; array_enc << 0x03A4
          when 0x55; array_enc << 0x03A5
          when 0x56; array_enc << 0x03C2
          when 0x57; array_enc << 0x03A9
          when 0x58; array_enc << 0x039E
          when 0x59; array_enc << 0x03A8
          when 0x5A; array_enc << 0x0396
          when 0x5C; array_enc << 0x2234
          when 0x5E; array_enc << 0x22A5
          when 0x60; array_enc << 0xF8E5
          when 0x61; array_enc << 0x03B1
          when 0x62; array_enc << 0x03B2
          when 0x63; array_enc << 0x03C7
          when 0x64; array_enc << 0x03B4
          when 0x65; array_enc << 0x03B5
          when 0x66; array_enc << 0x03C6
          when 0x67; array_enc << 0x03B3
          when 0x68; array_enc << 0x03B7
          when 0x69; array_enc << 0x03B9
          when 0x6A; array_enc << 0x03D5
          when 0x6B; array_enc << 0x03BA
          when 0x6C; array_enc << 0x03BB
          when 0x6D; array_enc << 0x03BC
          when 0x6E; array_enc << 0x03BD
          when 0x6F; array_enc << 0x03BF
          when 0x70; array_enc << 0x03C0
          when 0x71; array_enc << 0x03B8
          when 0x72; array_enc << 0x03C1
          when 0x73; array_enc << 0x03C3
          when 0x74; array_enc << 0x03C4
          when 0x75; array_enc << 0x03C5
          when 0x76; array_enc << 0x03D6
          when 0x77; array_enc << 0x03C9
          when 0x78; array_enc << 0x03BE
          when 0x79; array_enc << 0x03C8
          when 0x7A; array_enc << 0x03B6
          when 0x7E; array_enc << 0x223C
          when 0xA0; array_enc << 0x20AC
          when 0xA1; array_enc << 0x03D2
          when 0xA2; array_enc << 0x2032
          when 0xA3; array_enc << 0x2264
          when 0xA4; array_enc << 0x2215
          when 0xA5; array_enc << 0x221E
          when 0xA6; array_enc << 0x0192
          when 0xA7; array_enc << 0x2663
          when 0xA8; array_enc << 0x2666
          when 0xA9; array_enc << 0x2665
          when 0xAA; array_enc << 0x2660
          when 0xAB; array_enc << 0x2194
          when 0xAC; array_enc << 0x2190
          when 0xAD; array_enc << 0x2191
          when 0xAE; array_enc << 0x2192
          when 0xAF; array_enc << 0x2193
          when 0xB2; array_enc << 0x2033
          when 0xB3; array_enc << 0x2265
          when 0xB4; array_enc << 0x00D7
          when 0xB5; array_enc << 0x221D
          when 0xB6; array_enc << 0x2202
          when 0xB7; array_enc << 0x2022
          when 0xB8; array_enc << 0x00F7
          when 0xB9; array_enc << 0x2260
          when 0xBA; array_enc << 0x2261
          when 0xBB; array_enc << 0x2248
          when 0xBC; array_enc << 0x2026
          when 0xBD; array_enc << 0xF8E6
          when 0xBE; array_enc << 0xF8E7
          when 0xBF; array_enc << 0x21B5
          when 0xC0; array_enc << 0x2135
          when 0xC1; array_enc << 0x2111
          when 0xC2; array_enc << 0x211C
          when 0xC3; array_enc << 0x2118
          when 0xC4; array_enc << 0x2297
          when 0xC5; array_enc << 0x2295
          when 0xC6; array_enc << 0x2205
          when 0xC7; array_enc << 0x2229
          when 0xC8; array_enc << 0x222A
          when 0xC9; array_enc << 0x2283
          when 0xCA; array_enc << 0x2287
          when 0xCB; array_enc << 0x2284
          when 0xCC; array_enc << 0x2282
          when 0xCD; array_enc << 0x2286
          when 0xCE; array_enc << 0x2208
          when 0xCF; array_enc << 0x2209
          when 0xD0; array_enc << 0x2220
          when 0xD1; array_enc << 0x2207
          when 0xD2; array_enc << 0xF6DA
          when 0xD3; array_enc << 0xF6D9
          when 0xD4; array_enc << 0xF6DB
          when 0xD5; array_enc << 0x220F
          when 0xD6; array_enc << 0x221A
          when 0xD7; array_enc << 0x22C5
          when 0xD8; array_enc << 0x00AC
          when 0xD9; array_enc << 0x2227
          when 0xDA; array_enc << 0x2228
          when 0xDB; array_enc << 0x21D4
          when 0xDC; array_enc << 0x21D0
          when 0xDD; array_enc << 0x21D1
          when 0xDE; array_enc << 0x21D2
          when 0xDF; array_enc << 0x21D3
          when 0xE0; array_enc << 0x25CA
          when 0xE1; array_enc << 0x2329
          when 0xE2; array_enc << 0xF8E8
          when 0xE3; array_enc << 0xF8E9
          when 0xE4; array_enc << 0xF8EA
          when 0xE5; array_enc << 0x2211
          when 0xE6; array_enc << 0xF8EB
          when 0xE7; array_enc << 0xF8EC
          when 0xE8; array_enc << 0xF8ED
          when 0xE9; array_enc << 0xF8EE
          when 0xEA; array_enc << 0xF8EF
          when 0xEB; array_enc << 0xF8F0
          when 0xEC; array_enc << 0xF8F1
          when 0xED; array_enc << 0xF8F2
          when 0xEE; array_enc << 0xF8F3
          when 0xEF; array_enc << 0xF8F4
          when 0xF1; array_enc << 0x232A
          when 0xF2; array_enc << 0x222B
          when 0xF3; array_enc << 0x2320
          when 0xF4; array_enc << 0xF8F5
          when 0xF5; array_enc << 0x2321
          when 0xF6; array_enc << 0xF8F6
          when 0xF7; array_enc << 0xF8F7
          when 0xF8; array_enc << 0xF8F8
          when 0xF9; array_enc << 0xF8F9
          when 0xFA; array_enc << 0xF8FA
          when 0xFB; array_enc << 0xF8FB
          when 0xFC; array_enc << 0xF8FC
          when 0xFD; array_enc << 0xF8FD
          when 0xFE; array_enc << 0xF8FE
          else
            array_enc << num
          end
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class WinAnsiEncoding < Encoding
      # convert a WinAnsiEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # content of this method borrowed from REXML::Encoding.decode_cp1252
        # for further reading:
        # http://www.intertwingly.net/stories/2004/04/14/i18n.html
        array_latin9 = str.unpack('C*')
        array_enc = []
        array_latin9.each do |num|
          case num
            # characters that added compared to iso-8859-1
          when 0x80; array_enc << 0x20AC # 0xe2 0x82 0xac
          when 0x82; array_enc << 0x201A # 0xe2 0x82 0x9a
          when 0x83; array_enc << 0x0192 # 0xc6 0x92
          when 0x84; array_enc << 0x201E # 0xe2 0x82 0x9e
          when 0x85; array_enc << 0x2026 # 0xe2 0x80 0xa6
          when 0x86; array_enc << 0x2020 # 0xe2 0x80 0xa0
          when 0x87; array_enc << 0x2021 # 0xe2 0x80 0xa1
          when 0x88; array_enc << 0x02C6 # 0xcb 0x86
          when 0x89; array_enc << 0x2030 # 0xe2 0x80 0xb0
          when 0x8A; array_enc << 0x0160 # 0xc5 0xa0
          when 0x8B; array_enc << 0x2039 # 0xe2 0x80 0xb9
          when 0x8C; array_enc << 0x0152 # 0xc5 0x92
          when 0x8E; array_enc << 0x017D # 0xc5 0xbd
          when 0x91; array_enc << 0x2018 # 0xe2 0x80 0x98
          when 0x92; array_enc << 0x2019 # 0xe2 0x80 0x99
          when 0x93; array_enc << 0x201C
          when 0x94; array_enc << 0x201D
          when 0x95; array_enc << 0x2022
          when 0x96; array_enc << 0x2013
          when 0x97; array_enc << 0x2014
          when 0x98; array_enc << 0x02DC
          when 0x99; array_enc << 0x2122
          when 0x9A; array_enc << 0x0161
          when 0x9B; array_enc << 0x203A
          when 0x9C; array_enc << 0x0152 # 0xc5 0x93
          when 0x9E; array_enc << 0x017E # 0xc5 0xbe
          when 0x9F; array_enc << 0x0178
          else
            array_enc << num
          end
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class ZapfDingbatsEncoding < Encoding
      # convert a ZapfDingbatsEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # mapping to unicode taken from:
        #   http://unicode.org/Public/MAPPINGS/VENDORS/ADOBE/zdingbat.txt
        array_symbol = str.unpack('C*')
        array_enc = []
        array_symbol.each do |num|
          case num
          when 0x21; array_enc << 0x2701
          when 0x22; array_enc << 0x2702
          when 0x23; array_enc << 0x2703
          when 0x24; array_enc << 0x2704
          when 0x25; array_enc << 0x260E
          else
            array_enc << num
          end
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end
  end
end
