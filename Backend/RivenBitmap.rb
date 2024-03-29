#!/usr/bin/env ruby

# AgeFive
# Modernizing Riven in Ruby
#
# RivenBitmap: decoding and (if needed) decompressing tBMP bitmaps
#
# Created by Sören Nils Kuklau on 2007-04-29.
# Copyright (c) 2007. Some rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# The full license can be retrieved at:
# http://www.opensource.org/licenses/mit-license.php
#

# The Riven tBMP bitmap format, as detailed at
# http://www.dalcanton.it/tito/esperimenti/riven/tbmp.html as well as
# http://www.mystellany.com/riven/imageformat/, can contain 8- or
# 24-bit images, optionally compressed in a proprietary algorithm.
#
# RivenBitmap can extract the image data for internal use, and optionally
# dump it to a Windows V3 Bitmap file.

# TODO: For now, 8-bit is assumed.

require 'profile'

class RivenBitmap
	attr_reader(:width, :height, :palette)

	def initialize(path, offset, size)
		@path = path
		@offset = offset
		@size = size

		headers

		if truecolor?
			@dataOffset = @offset+8+4
		else
			@palette = palette
		end

		if compressed?
			# time1 = Time.now
			@data = decompressedData
			# puts time1.to_s+" || "+Time.now.to_s
		else
			@data = data
		end
	end

	def headers
		file = File.new(@path, 'r')
		file.seek(@offset)

		@width = file.read(2).unpack('n')[0]
		@height = file.read(2).unpack('n')[0]

		@bytesPerRow = file.read(2).unpack('n')[0]

		@compressed = file.read(1).unpack('C')[0]
		@truecolor = file.read(1).unpack('C')[0]

		file.close
	end

	def truecolor?
		# if @truecolor == 4
		# 	return true
		# else
			return false
		# end
	end

	def compressed?
		if @compressed == 4
			return true
		else
			return false
		end
	end

	def palette
		# in BGR form

		palette = []

		file = File.new(@path, 'r')
		file.seek(@offset+8+4) # skipping headers and unknown field

		palette << file.read(3*256).unpack('CCC'*256)

		@dataOffset = file.pos

		file.close

		return palette
	end

	def data
		file = File.new(@path, 'r')
		file.seek(@dataOffset)

		data = []

		while not file.eof?
			data << file.getc
		end

		return data
	end

	def decompressedData
		@dataOffset += 4 # unknown; can be ignored

		file = File.new(@path, 'r')
		file.seek(@dataOffset)

		inData = []
		inData += file.read(@size - @dataOffset).unpack('C' * (@size - @dataOffset))

		data = []

		pointer = 0

		while true
			
#			puts 'BUG: Value lower than 0' unless data.select { |item| item < 0 }.empty?
			# puts "  Position: "+file.pos.to_s+" out of "+@size.to_s
			# puts "      Size: "+data.size.to_s+" out of "+(@width*@height).to_s

			byte = inData[pointer]
			pointer += 1

			case byte
			when 0x00
				return data

				break
			when 0x01..0x3f
				# output byte*2 pixels
				# puts "output "+(byte*2).to_s+" pixels"
				# (byte*2).times do
				# 	data << file.getc
				# end
				data += inData[pointer+1, byte*2]
				pointer += byte*2

				# puts data.last(byte*2)

				next
			when 0x40..0x7f
				# repeat last 2 pixels byte-0x40 times
				# puts "repeat last 2 pixels "+(byte-0x40).to_s+" times!"

				data += (data.last(2) * (byte-0x40))

				next
			when 0x80..0xbf
				# repeat last 4 pixels byte-0x80 times
				# puts "repeat last 4 pixels "+(byte-0x80).to_s+" times!"

				data += (data.last(4) * (byte-0x80))

				next
			when 0xc0..0xff
				# byte-0xc0 subcommands will follow
				# puts (byte-0xc0).to_s+" subcommands will follow!"
				(byte-0xc0).times do
					# puts 'BUG: Value lower than 0' unless data.select { |item| item < 0 }.empty?
					# puts "  Subposition: "+file.pos.to_s+" out of "+@size.to_s
					# puts "         Size: "+data.size.to_s+" out of "+(@width*@height).to_s

					subbyte = inData[pointer]
					pointer += 1

					case subbyte
					when 0x01..0x0f
						m = subbyte.divmod(16)[1]

						# puts "copy the pixel duplet "+m.to_s+" duplets ago"

						# puts data[-m*2]
						# puts data[(-m*2)+1]

						data += data.slice(-m*2, 2)

						# puts data.last(2)

						next
					when 0x10
						# puts "copy the last pixel duplet, replacing the second pixel with x"

						# puts data.last(2)

						data += data.slice(-2, 1)
						data << inData[pointer]
						pointer += 1

						# puts data.last(2)

						next
					when 0x11..0x1f
						m = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, replacing the second pixel with that "+m.to_s+" bytes ago"

						data += data.slice(-2, 1)
						data += data.slice((-m)-1, 1)

						next
					when 0x20..0x2f
						x = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, adding "+x.to_s+" to the second pixel"

						# puts data.last(2)

						data += data.last(2)
						data[-1] += x

						# puts data.last(2)

						next
					when 0x30..0x3f
						x = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, substracting "+x.to_s+" from the second pixel"

						# puts data.last(2)

						data += data.last(2)
						data[-1] -= x

						# puts data.last(2)

						next
					when 0x40
						# puts "copy the last pixel duplet, replacing the first pixel with x"

						# puts data.last(2)

						data << inData[pointer]
						pointer += 1
						data += data.slice(-2, 1)

						# puts data.last(2)

						next
					when 0x41..0x4f
						m = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, replacing the first pixel with that "+m.to_s+" bytes ago"

						data += data.slice(-m, 1)
						data += data.slice(-2, 1)

						next
					when 0x50
						# puts "output x and y"

						# puts data.last(2)

						data += inData[pointer, 2]
						pointer += 2

						# puts data.last(2)

						next
					when 0x51..0x57
						m = subbyte.divmod(8)[1]

						# puts "copy the pixel from "+m.to_s+" bytes ago, then output x"

						# puts data.slice(-m, 1)

						data += data.slice(-m, 1)
						data << inData[pointer]
						pointer += 1

						# puts data.last(2)

						next
					when 0x59..0x5f
						m = subbyte.divmod(8)[1]

						# puts "output x, then copy the pixel from "+m.to_s+" bytes ago: "+data.slice((-m)-1, 1).to_s

						# puts data.last(2)

						data << inData[pointer]
						pointer += 1
						data += data.slice(-m, 1)

						# puts data.last(2)

						next
					when 0x60..0x6f
						x = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, then replace the first byte with x and add "+x.to_s+" to the second"

						# puts data.last(2)

						data << inData[pointer]
						pointer += 1
						data << (data.slice(-2, 1)[0].to_i + x)

						# puts data.last(2)

						next
					when 0x70..0x7f
						x = subbyte.divmod(16)[1]

						# puts "add a new pixel, then copy one from two bytes ago, substracting "+x.to_s+" from it"

						# puts data.last(2)

						data << inData[pointer]
						pointer += 1
						data << (data.slice(-2, 1)[0].to_i - x)

						# puts data.last(2)

						next
					when 0x80..0x8f
						x = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, then add "+x.to_s+" to the first byte"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i + x)
						data += data.slice(-2, 1)

						# puts data.last(2)

						next
					when 0x90..0x9f
						x = subbyte.divmod(16)[1]

						# puts "copy the last pixel duplet, then add "+x.to_s+" to the first byte and replace the second by y"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i + x)
						data << inData[pointer]
						pointer += 1

						# puts data.last(2)

						next
					when 0xa0
						xy = inData[pointer].divmod(16)
						pointer += 1

						# puts "copy the last pixel duplet, then add "+xy[0].to_s+" to the first byte and "+xy[1].to_s+" to the second"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i + xy[0])
						data << (data.slice(-2, 1)[0].to_i + xy[1])

						# puts data.last(2)

						next
					when 0xa4..0xa7
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 2 pixel duplets from "+m.to_s+" bytes ago, then add another"

						# puts data.slice(-m, 2*2)

						data += data.slice(-m, 2*2)
						data[-1] = inData[pointer]
						pointer += 1

						# puts data.last(2*2)

						next
					when 0xa8..0xab
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 2 pixel duplets from "+m.to_s+" bytes ago"

						# puts data.slice(-m, 2*2)

						data += data.slice(-m, 2*2)

						# puts data.last(2*2)

						next
					when 0xac..0xaf
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 3 pixel duplets from "+m.to_s+" bytes ago, then add another"

						# puts data.slice(-m, 3*2)

						data += data.slice(-m, 3*2)
						data[-1] = inData[pointer]
						pointer += 1

						# puts data.last(3*2)

						next
					when 0xb0
						xy = inData[pointer].divmod(16)
						pointer += 1

						# puts data.last(2)

						# puts "repeat last duplet, adding "+xy[0].to_s+" to the first pixel: "+data.slice(-2, 1)[0].to_s+" and substracting "+xy[1].to_s+" from the second: "+data.slice(-1, 1)[0].to_s

						data << (data.slice(-2, 1)[0].to_i + xy[0])
						data << (data.slice(-2, 1)[0].to_i - xy[1])

						# puts data.last(2)

						next
					when 0xb4..0xb7
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 3 pixel duplets from "+m.to_s+" bytes ago"

						data += data.slice(-m, 3*2)

						next
					when 0xb8..0xbb
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 4 pixel duplets from "+m.to_s+" bytes ago, then add another"

						data += data.slice(-m, 4*2)
						data[-1] = inData[pointer]
						pointer += 1

						next
					when 0xbc..0xbf
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 4 pixel duplets from "+m.to_s+" bytes ago"

						data += data.slice(-m, 4*2)

						next
					when 0xc0..0xcf
						x = subbyte.divmod(16)[1]

						# puts "repeat last duplet, substracting "+x.to_s+" from the first pixel"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i - x)
						data << (data.slice(-2, 1)[0].to_i)

						# puts data.last(2)

						next
					when 0xd0..0xdf
						x = subbyte.divmod(16)[1]

						# puts "repeat last duplet's first pixel, substracting "+x.to_s+", then add another"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i - x)
						data << inData[pointer]
						pointer += 1

						# puts data.last(2)

						next
					when 0xe0
						xy = inData[pointer].divmod(16)
						pointer += 1

						# puts "repeat last duplet, substracting "+xy[0].to_s+" from the first pixel and adding "+xy[1].to_s+" to the second"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i - xy[0])
						data << (data.slice(-2, 1)[0].to_i + xy[1])

						# puts data.last(2)

						next
					when 0xe4..0xe7
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 5 pixel duplets from "+m.to_s+" bytes ago, then add another"

						data += data.slice(-m, 5*2)
						data[-1] = inData[pointer]
						pointer += 1

						next
					when 0xe8..0xeb
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 5 pixel duplets from "+m.to_s+" bytes ago"

						data += data.slice(-m, 5*2)

						next
					when 0xec..0xef
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 6 pixel duplets from "+m.to_s+" bytes ago, then add another"

						data += data.slice(-m, 6*2)
						data[-1] = inData[pointer]
						pointer += 1

						next
					when 0xf0
						xy = inData[pointer].divmod(16)
						pointer += 1

						# puts "repeat last duplet, substracting "+xy[0].to_s+" from the first pixel and "+xy[1].to_s+" from the second"

						# puts data.last(2)

						data << (data.slice(-2, 1)[0].to_i - xy[0])
						data << (data.slice(-2, 1)[0].to_i - xy[1])

						# puts data.last(2)

						next
					when 0xf4..0xf7
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 6 pixel duplets from "+m.to_s+" bytes ago"

						data += data.slice(-m, 6*2)

						next
					when 0xf8..0xfb
						m = inData[pointer]
						pointer += 1
						m += subbyte.divmod(4)[1]*256

						# puts "copy 7 pixel duplets from "+m.to_s+" bytes ago, then add another"

						data += data.slice(-m, 7*2)
						data[-1] = inData[pointer]
						pointer += 1

						next
					when 0xfc
						# FIXME: make more readable and/or less ridiculous

						nrm1 = inData[pointer]
						pointer += 1
						m = inData[pointer]
						pointer += 1

						n = nrm1.divmod(8)[0]
						r = nrm1.divmod(8)[1].divmod(4)[0]
						m += nrm1.divmod(4)[1]*256

						# puts "repeat "+n.to_s+"+2 duplets from "+m.to_s+" pixels ago."

						data += (data.slice(-m, (n+2)*2))

						if r == 0
							# puts "also, replace the last with a new one"
							data[-1] = inData[pointer]
							pointer += 1
						end

						next
					when 0xff
						# http://www.mystellany.com/riven/imageformat/ says unused
						xy = inData[pointer].divmod(16)
						pointer += 1

						# puts "repeat last duplet, substracting "+xy[0].to_s+" from the first pixel and "+xy[1].to_s+" from the second"

						data << (data.slice(-2, 1)[0] - xy[0])
						data << (data.slice(-2, 1)[0] - xy[1])

						next
					else
						# puts "unknown subcommand: "+subbyte.to_s

						next
					end
				end

				next
			end
		end

		(file.close; return data)
	end

	def flipVertically(data)
		oldData = []
		oldData += data
		flippedData = []

		(oldData.length / @bytesPerRow).times do
			flippedData += oldData.slice!(-(@bytesPerRow), @bytesPerRow)
		end

		return flippedData
	end

	def dumpBMP(path)
#		bmpData = flipVertically(@data)
		bmpData = @data

		file = File.new(path, 'w')

		file.write("BM") # magic word
		file.write([1940].pack('L')) # bitmap data size (file size?), apparently ignored
		file.write([0].pack('L')) # vendor info, unused

		if truecolor?
			file.write([(14 + 40)].pack('L')) # bitmap data offset
		else
			file.write([(14 + 40 + (256*4))].pack('L')) # bitmap data offset
		end

		file.write([40].pack('L')) # header size
		file.write([@width].pack('L'))
		file.write([@height].pack('L'))

		file.write([0].pack('S')) # number of color planes

		if truecolor?
			file.write([24].pack('S'))
		else
			file.write([8].pack('S'))
		end

		file.write([0].pack('L')) # no compression

		file.write([(@width*@height)].pack('L')) # image size
		file.write([(72/0.0254).round].pack('L')) # horizontal and vertical
		file.write([(72/0.0254).round].pack('L')) #  resolution in pixels per meter

		if truecolor?
			file.write([16777216].pack('L'))
		else
			file.write([256].pack('L'))
		end

		file.write([0].pack('L')) # important colors

		unless truecolor?
			@palette.each do |color|
				file.write([color[0]].pack('C'))
				file.write([color[1]].pack('C'))
				file.write([color[2]].pack('C'))
				file.write([0].pack('C'))
			end
		end

		# FIXME: need to fill out each row to multiples of four(?)

		file.write(bmpData.pack('C'*bmpData.size))

		file.close
	end
end
