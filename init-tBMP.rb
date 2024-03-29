#!/usr/bin/env ruby

# AgeFive
# Modernizing Riven in Ruby
#
# init-tBMP: Temporary launcher
#
# Created by Sören Nils Kuklau
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

require 'Backend/RivenBitmap'

# tBMP = RivenBitmap.new('/Users/chucker/Repositories/agefive/non-svn/tBMP', 0, 1382)
# 
# tBMP.dumpBMP('/Users/chucker/Repositories/agefive/non-svn/tBMP.bmp')

tBMP = RivenBitmap.new('/Users/chucker/Repositories/agefive/non-svn/1_gsubelevshaft.100-maybe.tBMP', 0, 120696)
tBMP.dumpBMP('/Users/chucker/Repositories/agefive/non-svn/1_gsubelevshaft.100-maybe.bmp')


# tBMP = RivenBitmap.new('/Users/chucker/Repositories/agefive/non-svn/200', 0, 844)
# 
# tBMP.dumpBMP('/Users/chucker/Repositories/agefive/non-svn/200.bmp')
