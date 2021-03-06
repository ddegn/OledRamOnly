DAT objectName          byte "OledSpi", 0
CON
{{

  15h Doesn't work even with CS on I/O pin.
  Change name from "OledAsmScratch150415l" to "StepperSpi150416a."
  18d Abandon 18c.
  18d Use both P2 and shared SPI clock in ADC code.
  The ADC works with using P2 but not when using the shared clock.
  Shared clock wasn't starting low. Fixed.
  18e Try using shared data. Shared data doesn't work.
  18f Try using '595 CS line.
  18g Use separate data pin for ADC.
  18h Abandon 18g.
  18i Try to get rid of redundant code.
  18i Still works.
  18j Try shared data again. Doesn't work with shared data.
  25a Use separate pin for '165 data line. "shiftMisoMask"
  25b Had read and write in jump table wrong.
  Change name from "StepperSpi150425d" to "StepperSpi."
  150617a Change name from "StepperSpi" to "OledSpi"
   
************************************************
* OLED_AsmFast (well, faster)                  *
* Thomas P. Sullivan                           *
* Copyright (c) 2012                           *
* Some original comments left/modified         *
* See end of file for terms of use.            *
************************************************
Revision History:

  Version 140828a modified by Duane Degn.
           SPI calls sped up. Variables and methods
           changed to conform with Parallax Gold
           Standard conventions.
           
  V1.0   - Original program 12-2-2012
  V1.1   - Changes to comments and modification 
           of a few commands.
  V1.2   - Added support for the 128x64 display 12-16-2012

This is a Propeller driver object for the Adafruit
SSDD1306 OLED Display. It has functions to draw
individual pixels, lines, and rectangles. It also
has character functions to print 16x32 characters
derived from the Propeller's internal fonts.


     ┌───────────────────────────────┐    
     │            SSD1306            │    
     │            Adafruit           │    
     │             128x32            │    
     │          OLED Display         │    
     │                               │    
     │  resetPin clockPin VIN    GND │    
     │csPin   D/C   dataPin   3.3    │    
     └─┬───┬───┬───┬───┬───┬───┬───┬─┘    
       │   │   │   │   │   │   │   │


This file is based on the following code sources:
************************************************
* Propeller SPI Engine                    v1.2 *
* Author: Beau Schwabe                         *
* Copyright (c) 2009 Parallax                  *
* See end of file for terms of use.            *
************************************************

...and this code:

*********************************************************************
This is a library for our Monochrome OLEDs based on SSD1306 drivers

  Pick one up today in the adafruit shop!
  ------> http://www.adafruit.com/category/63_98

These displays use SPI to communicate, 4 or 5 pins are required to  
interface

Adafruit invests time and resources providing this open source code, 
please support Adafruit and open-source hardware by purchasing 
products from Adafruit!

Written by Limor Fried/Ladyada  for Adafruit Industries.  
BSD license, check license.txt for more information
All text above, and the splash screen below must be included in
any redistribution
*********************************************************************
Note: The splash screen is way down in the DAT section of this file.
         
}}
CON

  BLACK = 0
  WHITE = 1

  TYPE_128X32                   = 32
  TYPE_128X64                   = 64
  OLED_BUFFER_SIZE    = 1024

  SSD1306_LCDWIDTH              = 128
  SSD1306_LCDHEIGHT32           = 32
  SSD1306_LCDHEIGHT64           = 64
  SSD1306_LCDCHARMAX            = 8

  SSD1306_SETCONTRAST           = $81
  SSD1306_DISPLAYALLON_RESUME   = $A4
  SSD1306_DISPLAYALLON          = $A5
  SSD1306_NORMALDISPLAY         = $A6
  SSD1306_INVERTDISPLAY         = $A7
  SSD1306_DISPLAYOFF            = $AE
  SSD1306_DISPLAYON             = $AF
  SSD1306_SETDISPLAYOFFSET      = $D3
  SSD1306_SETCOMPINS            = $DA
  SSD1306_SETVCOMDETECT         = $DB
  SSD1306_SETDISPLAYCLOCKDIV    = $D5
  SSD1306_SETPRECHARGE          = $D9
  SSD1306_SETMULTIPLEX          = $A8
  SSD1306_SETLOWCOLUMN          = $00
  SSD1306_SETHIGHCOLUMN         = $10
  SSD1306_SETSTARTLINE          = $40
  SSD1306_MEMORYMODE            = $20
  SSD1306_COMSCANINC            = $C0
  SSD1306_COMSCANDEC            = $C8
  SSD1306_SEGREMAP              = $A0
  SSD1306_CHARGEPUMP            = $8D
  SSD1306_EXTERNALVCC           = $1
  SSD1306_SWITCHCAPVCC          = $2

  'Scrolling #defines
  SSD1306_ACTIVATE_SCROLL       = $2F
  SSD1306_DEACTIVATE_SCROLL     = $2E
  SSD1306_SET_VERT_SCROLL_AREA  = $A3
  SSD1306_RIGHT_HORIZ_SCROLL    = $26
  SSD1306_LEFT_HORIZ_SCROLL     = $27
  SSD1306_VERTRIGHTHORIZSCROLL  = $29
  SSD1306_VERTLEFTHORIZSCROLL   = $2A

  SHIFT_OUT_BYTE = 1
  SHIFT_OUT_BUFFER = 2
  
PRI SpiInit'(shiftRegisterOutputPtr_, debugPtr) 
'' Call SpiInit prior to calling Start.
  Pst.str(string(11, 13, "SpiInit Method"))

  'spiLock := lock
  spiLock := locknew
   
  commandAddress := @command 'commandAddress_
  
  oledBufferPtr := @buffer
  
  {Pst.str(string(11, 13, "mailboxAddr = "))
  Pst.Dec(mailboxAddr)
  Pst.str(string(11, 13, "oledBufferPtr = "))
  Pst.Dec(oledBufferPtr)}
  
  'shiftRegisterOutputPtr := shiftRegisterOutputPtr_
  'shiftRegisterInputPtr := shiftRegisterOutputPtr_ + 4
  'shiftRegisterOutputCog := shiftRegisterOutputPtr_
  'shiftRegisterInputCog := shiftRegisterOutputPtr_ + 4
  'adcPtr := shiftRegisterOutputPtr_ + 8
  
  {commandAddress_ += 4
  repeat result from 0 to 2
    csChanMaskX[result] := 1 << byte[csChanPtr][result]
    resetChanMaskX[result] := 1 << byte[csChanPtr + 3][result]
    sleepChanMaskX[result] := 1 << byte[csChanPtr + 6][result]  }
  'debugAddress := debugPtr
 { repeat result from 0 to Header#MAX_DEBUG_SPI_INDEX
    debugAddress0[result] := debugPtr
    debugPtr += 4   }
    
  'clockMask := 1 << clockPin
  'mosiMask := 1 << mosiPin
  'misoMask := 1 << misoPin
  'latch595Mask := 1 << latch595Pin
  'latch165Mask := 1 << latch165Pin
  'csOledChanMask := 1 << csOledChan
  'csAdcChanMask := 1 << csAdcChan
  
  'result := cognew(@oledBuffer, commandAddress)

  waitcnt(clkfreq / 100 + cnt)
  
  'OledInit

PUB ReadableBin(localValue, size) | bufferPtr, localBuffer[12]    
'' This method display binary numbers
'' in easier to read groups of four
'' format.

  bufferPtr := Format.Ch(@localBuffer, "%")
  
  result := size // 4
   
  if result
    size -= result
    bufferPtr := Format.Bin(bufferPtr, localValue >> size, result)
    if size
      bufferPtr := Format.Ch(bufferPtr, "_")
  size -= 4
 
  repeat while size => 0
    bufferPtr := Format.Bin(bufferPtr, localValue >> size, 4)
    if size
      bufferPtr := Format.Ch(bufferPtr, "_")  
    size -= 4
    
  byte[bufferPtr] := 0  
  Pst.Str(@localBuffer)
  
PUB PressToContinue
  
  Pst.str(string(11, 13, "Press to continue."))
  repeat
    result := Pst.RxCount
  until result
  Pst.RxFlush

PRI SafeTx(localCharacter)
'' Debug lock should be set prior to calling this method.

  if (localCharacter > 32 and localCharacter < 127)
    Pst.Char(localCharacter)    
  else
    Pst.Char(60)
    Pst.Char(36) 
    Pst.Hex(localCharacter, 2)
    Pst.Char(62)

DAT

commandAddress          long 0
'shiftRegisterOutputPtr  long 0
'shiftRegisterInputPtr   long 0
oledBufferPtr           long 0
'shiftRegisterOutputSpin long 0

  
DAT

cog                     long 0
command                 long 0
mailbox                 long 0
vccState                long 0
displayType             long 0
displayWidth            long 0
displayHeight           long 0
autoUpdate              long 0
'resetChan               long 1 << Header#RESET_OLED_595
'dataCommandChan         long 1 << Header#DC_OLED_595
'debugAddress            long 0-0
'refreshCount            long 0
  
buffer                  byte 0[OLED_BUFFER_SIZE]
'dataCommandPin          byte 0
'resetPin                byte 2
'adcChannelsInUse        byte Header#DEFAULT_ADC_CHANNELS
'firstAdcChannelInUse    byte Header#DEFAULT_FIRST_ADC_CHANNEL
spiLock                 byte 255

OBJ

  Header : "HeaderOled"
  Pst : "Parallax Serial TerminalDat"
  Format : "StrFmt"
   
PUB Start(vccState_, type_)
'' Start SPI Engine - starts a cog
'' returns false if no cog available

  'Stop
  SpiInit'(shiftRegisterOutputPtr_, debugPtr)
  
  ''Initialize variables 
  longmove(@vccState, @vccState_, 2)

  displayType := type_

  bufferAddress := @buffer
                    
  mailboxAddr := @mailbox
  'refreshCountPtr := @refreshCount
  'bitsFromSpinPtr := @shiftRegisterOutputSpin
  'adcInUsePtr := @adcChannelsInUse
  'firstAdcPtr := @firstAdcChannelInUse
  
  result := cog := cognew(@entry, @command) + 1

  repeat while command
   
  InitDisplay
    
{PUB Stop
'' Stop SPI Engine - frees a cog

  if cog
     cogstop(cog~ - 1)
  command~
 }
PUB LSpi

  repeat while lockset(spiLock)

PUB CSpi

  lockclr(spiLock)
  
PUB SetCommand(cmd)

  LSpi
  command := cmd                '' Write command 
  repeat while command          '' Wait for command to be cleared, signifying receipt
    {if cmd == Header#ADC_SPI
  
      Pst.Str(string(11, 13, "adcRequest = "))
      Pst.Dec(long[debugAddress0])
      Pst.Str(string(" = "))
      ReadableBin(long[debugAddress0], 32)
      Pst.Str(string(11, 13, "activeAdcPtr = "))
      Pst.Dec(long[debugAddress1])
      Pst.Str(string(", adcPtr = "))
      Pst.Dec(adcPtr)
      Pst.Str(string(11, 13, "dataValue = "))
      Pst.Dec(long[debugAddress2])
      Pst.Str(string(" = "))
      ReadableBin(long[debugAddress2], 32)
      Pst.Str(string(11, 13, "bufferAddress = "))
      Pst.Dec(long[debugAddress3])
      Pst.Str(string(11, 13, "dataOut = "))
      Pst.Dec(long[debugAddress4])
      Pst.Str(string(" = "))
      ReadableBin(long[debugAddress4], 32)
      Pst.Str(string(11, 13, "byteCount = "))
      Pst.Dec(long[debugAddress5])
      Pst.Str(string(11, 13, "location clue = "))
      Pst.Dec(long[debugAddress6])
      Pst.Str(string(11, 13, "dataOutToShred = "))
      Pst.Dec(long[debugAddress7])
      Pst.Str(string(" = "))
      ReadableBin(long[debugAddress7], 32)
      Pst.Str(string(11, 13, "adcInUseCog = "))
      Pst.Dec(long[debugAddress8])   }
  CSpi
      
PUB InitDisplay

  if displayType == TYPE_128X32
    displayWidth := SSD1306_LCDWIDTH
    displayHeight := SSD1306_LCDHEIGHT32
  else
    displayWidth := SSD1306_LCDWIDTH
    displayHeight := SSD1306_LCDHEIGHT64

  'SpinLow595(Header#DC_OLED_595) ' ***
  Low(Header#DC_OLED_PIN)
  'SpinHigh595(Header#DC_OLED_595) ' ***
  
  ''Setup reset and pin direction
  'SpinHigh595(Header#RESET_OLED_595) 
  High(Header#RESET_OLED_PIN) 
  ''VDD (3.3V) goes high at start; wait for a ms
  waitcnt(clkfreq / 100000 + cnt)
  ''force reset low
  'SpinLow595(Header#RESET_OLED_595)
  Low(Header#RESET_OLED_PIN)
  ''wait 10ms
  waitcnt(clkfreq / 100000 + cnt)
  ''remove reset
  'SpinHigh595(Header#RESET_OLED_595)
  High(Header#RESET_OLED_PIN)

  if displayType == TYPE_128X32
    ''************************************
    ''Init sequence for 128x32 OLED module
    ''************************************
    Ssd1306Command(SSD1306_DISPLAYOFF)             
    Ssd1306Command(SSD1306_SETDISPLAYCLOCKDIV)     
    Ssd1306Command($80)                            
    Ssd1306Command(SSD1306_SETMULTIPLEX)           
    Ssd1306Command($1F)
    Ssd1306Command(SSD1306_SETDISPLAYOFFSET)       
    Ssd1306Command($0)                             
    Ssd1306Command(SSD1306_SETSTARTLINE | $0)      
    Ssd1306Command(SSD1306_CHARGEPUMP)             
     
    if vccstate == SSD1306_EXTERNALVCC 
      Ssd1306Command($10)
    else 
      Ssd1306Command($14)
     
    Ssd1306Command(SSD1306_MEMORYMODE)             
    Ssd1306Command($00)                            
    Ssd1306Command(SSD1306_SEGREMAP | $1)
    Ssd1306Command(SSD1306_COMSCANDEC)
    Ssd1306Command(SSD1306_SETCOMPINS)             
    Ssd1306Command($02)
    Ssd1306Command(SSD1306_SETCONTRAST)            
    Ssd1306Command($8F)
    Ssd1306Command(SSD1306_SETPRECHARGE)           
     
    if vccstate == SSD1306_EXTERNALVCC 
      Ssd1306Command($22)
    else 'SSD1306_SWITCHCAPVCC 
      Ssd1306Command($F1)
     
    Ssd1306Command(SSD1306_SETVCOMDETECT)          
    Ssd1306Command($40)
    Ssd1306Command(SSD1306_DISPLAYALLON_RESUME)    
    Ssd1306Command(SSD1306_NORMALDISPLAY)          
     
    Ssd1306Command(SSD1306_DISPLAYON)'--turn on oled panel
       ''************************************   
  else ''Init sequence for 128x64 OLED module
       ''************************************
    Ssd1306Command(SSD1306_DISPLAYOFF)             
    Ssd1306Command(SSD1306_SETLOWCOLUMN)  ' low col = 0
    Ssd1306Command(SSD1306_SETHIGHCOLUMN) ' hi col = 0
    Ssd1306Command(SSD1306_SETSTARTLINE)  ' line #0
    Ssd1306Command(SSD1306_SETCONTRAST)            

    if vccstate == SSD1306_EXTERNALVCC 
      Ssd1306Command($9F)
    else 
      Ssd1306Command($CF)

    Ssd1306Command($A1)
    Ssd1306Command(SSD1306_NORMALDISPLAY)
    Ssd1306Command(SSD1306_DISPLAYALLON_RESUME)
    Ssd1306Command(SSD1306_SETMULTIPLEX)           
    Ssd1306Command($3F)
    Ssd1306Command(SSD1306_SETDISPLAYOFFSET)       
    Ssd1306Command($0) 'No offset                            
    Ssd1306Command(SSD1306_SETDISPLAYCLOCKDIV)     
    Ssd1306Command($80)                            
    Ssd1306Command(SSD1306_SETPRECHARGE)

    if vccstate == SSD1306_EXTERNALVCC 
      Ssd1306Command($22)
    else 
      Ssd1306Command($F1)

    Ssd1306Command(SSD1306_SETVCOMDETECT)          
    Ssd1306Command($40)

    Ssd1306Command(SSD1306_SETCOMPINS)          
    Ssd1306Command($12)

    Ssd1306Command(SSD1306_MEMORYMODE)          
    Ssd1306Command($00)

    Ssd1306Command(SSD1306_SEGREMAP | $1)

    Ssd1306Command(SSD1306_COMSCANDEC)

    Ssd1306Command(SSD1306_CHARGEPUMP)

    if vccstate == SSD1306_EXTERNALVCC 
      Ssd1306Command($10)
    else
      Ssd1306Command($14)
     
    Ssd1306Command(SSD1306_DISPLAYON)'--turn on oled panel

  InvertDisplay(false)
  autoUpdateOn
  ClearDisplay

PUB ShiftOut(value)

  mailbox := value           
  SetCommand(Header#OLED_WRITE_ONE_SPI)

PUB WriteBuff(addr)

  mailbox := addr           
  SetCommand(Header#OLED_WRITE_BUFFER_SPI)
       
PUB InvertDisplay(invertFlag)
  'This in an OLED command that inverts the display. Probably faster
  'than complimenting the screen buffer.
  if invertFlag == true
    Ssd1306Command(SSD1306_INVERTDISPLAY)
  else
    Ssd1306Command(SSD1306_NORMALDISPLAY)

PUB StartScrollRight(scrollStart, scrollStop)
  ''startscrollright
  ''Activate a right handed scroll for rows start through stop
  ''Hint, the display is 16 rows tall. To scroll the whole display, run:
  ''display.scrollright($00, $0F) 
  Ssd1306Command(SSD1306_RIGHT_HORIZ_SCROLL)
  Ssd1306Command($00)
  Ssd1306Command(scrollStart)
  Ssd1306Command($00)
  Ssd1306Command(scrollStop)
  Ssd1306Command($01)
  Ssd1306Command($FF)
  Ssd1306Command(SSD1306_ACTIVATE_SCROLL)

PUB StartScrollLeft(scrollStart, scrollStop)
  ''startscrollleft
  ''Activate a right handed scroll for rows start through stop
  ''Hint, the display is 16 rows tall. To scroll the whole display, run:
  ''display.scrollright($00, $0F) 
  Ssd1306Command(SSD1306_LEFT_HORIZ_SCROLL)
  Ssd1306Command($00)
  Ssd1306Command(scrollStart)
  Ssd1306Command($00)
  Ssd1306Command(scrollStop)
  Ssd1306Command($01)
  Ssd1306Command($FF)
  Ssd1306Command(SSD1306_ACTIVATE_SCROLL)

PUB StartScrollDiagRight(scrollStart, scrollStop)
  ''startscrolldiagright
  ''Activate a diagonal scroll for rows start through stop
  ''Hint, the display is 16 rows tall. To scroll the whole display, run:
  ''display.scrollright($00, $0F) 
  Ssd1306Command(SSD1306_SET_VERT_SCROLL_AREA)      
  Ssd1306Command($00)
  Ssd1306Command(displayHeight)
  Ssd1306Command(SSD1306_VERTRIGHTHORIZSCROLL)
  Ssd1306Command($00)
  Ssd1306Command(scrollStart)
  Ssd1306Command($00)
  Ssd1306Command(scrollStop)
  Ssd1306Command($01)
  Ssd1306Command(SSD1306_ACTIVATE_SCROLL)

PUB StartScrollDiagLeft(scrollStart, scrollStop)
  ''startscrolldiagleft
  ''Activate a diagonal scroll for rows start through stop
  ''Hint, the display is 16 rows tall. To scroll the whole display, run:
  ''display.scrollright($00, $0F) 
  Ssd1306Command(SSD1306_SET_VERT_SCROLL_AREA)      
  Ssd1306Command($00)
  Ssd1306Command(displayHeight)
  Ssd1306Command(SSD1306_VERTLEFTHORIZSCROLL)
  Ssd1306Command($00)
  Ssd1306Command(scrollStart)
  Ssd1306Command($00)
  Ssd1306Command(scrollStop)
  Ssd1306Command($01)
  Ssd1306Command(SSD1306_ACTIVATE_SCROLL)

PUB StopScroll
  ''Stop the scroll
  
  Ssd1306Command(SSD1306_DEACTIVATE_SCROLL)

PUB ClearDisplay
  ''Clearing the display means just writing zeroes to the screen buffer.
  
  bytefill(@buffer, 0, ((displayWidth * displayHeight) / 8))
  UpdateDisplay 'Clearing the display ALWAYS updates the display

PUB PlotPoint(x, y, color) | pp
  ''Plot a point x,y on the screen. color is really just on or off (1 or 0)
  
  x &= $7F
  if y > 0 and y < displayHeight
    if color == WHITE
      buffer[x + ((y >> 3) * 128)] |= |< (y // 8)
    else  'Clear the bit and it's off (black)
      buffer[x + ((y >> 3) * 128)] &= !(|< (y // 8))
   
PUB UpdateDisplay | i, tmp
  ''Writes the screen buffer to the memory of the display
  
  Ssd1306Command(SSD1306_SETLOWCOLUMN)  ' low col = 0
  Ssd1306Command(SSD1306_SETHIGHCOLUMN) ' hi col = 0
  Ssd1306Command(SSD1306_SETSTARTLINE)  ' line #0

  'SpinHigh595(Header#DC_OLED_595) 
  High(Header#DC_OLED_PIN)
  WriteBuff(@buffer)    

PRI Swap(a, b) | t
  ''Needed by Line function below
  
  t := long[a]
  long[a] := long[b]
  long[b] := t 

PUB Line(x0, y0, x1, y1, c) | steep, deltax, deltay, error, ystep, yy, xx
  ''Draws a line on the screen
  ''Adapted/converted from psuedo-code found on Wikipedia:
  ''http://en.wikipedia.org/wiki/Bresenham's_line_algorithm      
  steep := ||(y1 - y0) > ||(x1 - x0)
  if steep
    swap(@x0, @y0)
    swap(@x1, @y1)
  if x0 > x1 
    swap(@x0, @x1)
    swap(@y0, @y1)
  deltax := x1 - x0
  deltay := ||(y1 - y0)
  error := deltax << 1
  yy := y0
  if y0 < y1
    ystep := 1
  else
    ystep := -1
  repeat xx from x0 to x1
    if steep
      plotPoint(yy, xx, c)
    else
      plotPoint(xx, yy, c)
    error := error - deltay
    if error < 0
      yy := yy + ystep
      error := error + deltax
  if autoUpdate
    UpdateDisplay
  
PUB Box(x0, y0, x1, y1, c)
  ''Draw a box formed by the coordinates of a diagonal line
  
  Line(x0, y0, x1, y0, c)
  Line(x1, y0, x1, y1, c)
  Line(x1, y1, x0, y1, c)
  Line(x0, y1, x0, y0, c)

PUB Write1x8String(str, len) | i
  ''Write a string on the display starting at position zero (left)
  
  repeat i from 0 to (len <# SSD1306_LCDCHARMAX) - 1
    write16x32Char(byte[str][i], i, 0) 

PUB Write2x8String(str, len, row) | i

  row &= $1 'Force in bounds
  if displayType == TYPE_128X64
    repeat i from 0 to (len <# SSD1306_LCDCHARMAX) - 1
      write16x32Char(byte[str][i], i, row) 
     
PUB Write16x32Char(ch, col, row) | h, i, j, k, q, r, s, mask, cbase, cset, bset

  if row == 0 or row == 1 and (col => 0 and col < 8)
    ''Write a 16x32 character to the screen at position 0-7 (left to right)
    cbase := $8000 + ((ch & $FE) << 6)  ' Compute the base of the interleaved character 
      
    repeat j from 0 to 31       ' For all the rows in the font
      bset := |< (j // 8)       ' For setting bits in the OLED buffer.
                                ' The mask is always a byte and has to wrap
      if ch & $01
        mask := $00000002       ' For the extraction of the bits interleaved in the font
      else
        mask := $00000001       ' For the extraction of the bits interleaved in the font
      r := long[cbase][j]       ' Row is the font data with which to perform bit extraction
      s := 0                    ' Just for printing the font  to the serial terminal (DEBUG)
      h := @buffer + row * 512  ' Get the base address of the OLED buffer
      h += ((j >> 3) * 128) + (col * 16)  ' Compute the offset to the column of data and add to the base...
                                ' ...then add the offset to the character position
      repeat k from 0 to 15     ' For all 16 bits we need from the interlaced font...
        if r & mask             ' If the bit is set...
          byte[h][k] |= bset    ' Set the column bit
        else
          byte[h][k] &= !bset   ' Clear the column bit
        mask := mask << 2       ' The mask shifts two places because the fonts are interlaced
    if autoUpdate
      updateDisplay             ' Update the display
     
{PUB Write4x16String(str, len, col, row) | i, j
  ''Write a string of 5x7 characters to the display @ column and row
  
  repeat j from 0 to len - 1
    Write5x7Char(byte[str][j], col, row)  
    col++
    if(col > 15)
      col := 0
      row++
  if autoUpdate
    updateDisplay               ' Update the display
}
PUB Write5x7Char(ch, col, row) | i    
  ''Write a 5x7 character to the display @ row and column

  ch -= " " ' offset so first printable character is zero
  {Pst.Str(string(11, 13, "@buffer = "))
  Pst.Dec(@buffer)
  Pst.Str(string(", ch # = "))
  'Pst.Char(ch)
  Pst.Dec(ch)
  Pst.Str(string(", ch = "))
  'Pst.Char(ch)
  SafeTx(ch + " ")
  Pst.Str(string(11, 13, "@buffer + "))
  Pst.Dec(row)
  Pst.Str(string(" * 128 + "))
  Pst.Dec(col)
  Pst.Str(string(" * 8 = "))
  Pst.Dec(@buffer + row * 128 + col * 8)
  }
  col &= $F
  if displayType == TYPE_128X32
    row &= $3
    repeat i from 0 to 7
      buffer[row * 128 + col * 8 + i] := byte[@font5x7 + 8 * ch + i]
  else
    row &= $7
    repeat i from 0 to 7
      buffer[row * 128 + col * 8 + i] := byte[@font5x7 + 8 * ch + i]
      
  
  if autoUpdate
    UpdateDisplay               ' Update the display
            
PUB AutoUpdateOn                'With autoUpdate On the display is updated for you

  autoUpdate := TRUE

PUB AutoUpdateOff               'With autoUpdate Off the system is faster.
                                'Update the display when you want

  autoUpdate := FALSE

PUB GetDisplayHeight            'For things that need it

  return displayHeight

PUB GetDisplayWidth             'For things that need it

  return displayWidth

PUB GetDisplayType              'For things that need it

  return displayType

PUB High(pin)
  ''Make a pin an output and drives it high
  
  dira[pin] := 1
  outa[pin] := 1
         
PUB Low(pin)
  ''Make a pin an output and drives it low
  
  dira[pin] := 1
  outa[pin] := 0
  
{PUB SpinHigh595(chan)
  
  {if chan == Header#RESET_DRV8711_X_595
    dira[2] := 1
    outa[2] := 1
  elseif chan == Header#SLEEP_DRV8711_X_595
    dira[0] := 1
    outa[0] := 1  }
  shiftRegisterOutputSpin |= 1 << chan
  SetCommand(Header#SPIN_595_SPI)
         
PUB SpinLow595(chan)

  {if chan == Header#RESET_DRV8711_X_595
    dira[2] := 1
    outa[2] := 0
  elseif chan == Header#SLEEP_DRV8711_X_595
    dira[0] := 1
    outa[0] := 0  }
  shiftRegisterOutputSpin &= !(1 << chan)
  SetCommand(Header#SPIN_595_SPI)
    }
PUB Ssd1306Command(localCommand) 'Send a byte as a command to the display
  ''Write SPI command to the OLED
  
  'SpinLow595(Header#DC_OLED_595)
  Low(Header#DC_OLED_PIN)
  ShiftOut(localCommand)   

PUB Ssd1306Data(localData)   'Send a byte as data to the display
  ''Write SPI data to the OLED
  
  'SpinHigh595(Header#DC_OLED_595)
  High(Header#DC_OLED_PIN)
  ShiftOut(localData)   

PUB GetBuffer                   'Get the address of the buffer for the display

  result := @buffer

'PUB GetSplash                   'Get the address of the Adafruit Splash Screen

  'result := @splash

PUB GetObjectName

  result := @objectName
  
{PUB SetAdcChannels(firstChan, numberOfChans)

  adcChannelsInUse := 1 #> numberOfChans <# 8
  firstAdcChannelInUse := 0 #> firstChan <# (8 - adcChannelsInUse) 

  SetCommand(Header#SET_ADC_CHANNELS_SPI)
    
PUB ReadAdc

  SetCommand(Header#ADC_SPI) 
  
PUB GetAdcPtr

  result := @adcChannelsInUse
         }
'PUB GetRefreshCount

  'result := refreshCount
    
PUB GetPasmArea

  result := @entry 


PUB ReleaseIo

  dira[Header#RESET_OLED_PIN] := 0
  outa[Header#RESET_OLED_PIN] := 0
  dira[Header#DC_OLED_PIN] := 0
  outa[Header#DC_OLED_PIN] := 0

DAT                     org
'------------------------------------------------------------------------------
entry                   or      dira, clockMask
                        or      dira, mosiMask
'dataOut                 or      dira, shiftMosiMask
'byteCount               or      dira, shiftClockMask                        
                        
                        or      dira, csOledMask
                        or      outa, csOledMask
                                     

                        
                       ' wrlong  con111, debugAddressF                        

' Pass through only on start up.                        
'------------------------------------------------------------------------------
loopSpi                 wrlong  zero, par  ' used to indicate command complete
                        
smallLoop              ' call    #maintenanceRounds
                        rdlong  commandCog, par 'wz 
              'if_z      jmp     #smallLoop
                        add     commandCog, #jumpTable
                       
                        jmp     commandCog
jumpTable               jmp     #smallLoop
                        
                        jmp     #shiftOne
                        jmp     #writeBuff_
                        {jmp     #spin595
                        jmp     #setAdc
                        jmp     #readAdcPasm
                        jmp     #writeDrv8711Pasm
                        jmp     #readDrv8711Pasm  }
                      
{ #0, IDLE_SPI, OLED_WRITE_ONE_SPI, OLED_WRITE_BUFFER_SPI}                                  

'------------------------------------------------------------------------------
'Single OLED SPI shift routine
shiftOne                andn    outa, csOledMask
                        rdlong  dataValue, mailboxAddr
                        ror     dataValue, #8
                        mov     bitCount, #8
                        
:msbShift               shl     dataValue, #1   wc
                        muxc    outa, mosiMask
                        andn    outa, clockMask
                        or      outa, clockMask                        
                        djnz    bitCount, #:msbShift
                        or      outa, csOledMask
          
                        
                        or      outa, mosiMask
                        jmp     #loopSpi 'preLoop                        
            
'------------------------------------------------------------------------------
writeBuff_              rdlong  bufferAddress, mailboxAddr                        
                        mov     byteCount, bufferSize

readByte                andn    outa, csOledMask
                        rdbyte  dataValue, bufferAddress
                        ror     dataValue, #8
                        mov     bitCount, #8 
                        add     bufferAddress, #1
:msbShift               shl     dataValue, #1   wc
                        muxc    outa, mosiMask
                        andn    outa, clockMask
                        or      outa, clockMask                        
                        djnz    bitCount, #:msbShift
                        or      outa, csOledMask
                                               
                        djnz    byteCount, #readByte
                        or      outa, mosiMask
                        'add     refreshCountCog, #1
                        'wrlong  refreshCountCog, refreshCountPtr
                        jmp     #loopSpi 'preLoop                                                         

'------------------------------------------------------------------------------
'' The variables "outputData", "bitCount" and "bitDelay" should be set
'' prior to calling spiBits

spiBits                 ror     outputData, bitCount
                        'wrlong  outputData, debugAddress6
                        'wrlong  con777, debugAddressF
                        mov     wait, cnt
                        add     wait, cogDelay
:loop
                        rcl     outputData, #1  wc
                        waitcnt wait, cogDelay
                        andn    outa, clockMask
                        muxc    outa, mosiMask
                        waitcnt wait, cogDelay
                        or      outa, clockMask
                        test    misoMask, ina  wc
                        rcl     inputData, #1
                        djnz    bitCount, #:loop
spiBits_ret             ret
'------------------------------------------------------------------------------

zero                    long 0                  '' Constant
bufferSize              long OLED_BUFFER_SIZE
                                              
'csMask                  long %10000                  '' Used for Chip Select mask
mailboxAddr             long 0                    
bufferAddress           long 0                  '' Used for buffer address

DAT ' PASM Variables

negativeOne             long -1
twelveBits              long $F_FF
bitDelay                long 80
{con111                  long 111
con222                  long 222
con333                  long 333
con444                  long 444
con555                  long 555
con666                  long 666
con777                  long 777
con888                  long 888
con999                  long 999  }
                                             
clockMask               long 1 << Header#SPI_CLOCK '' Used for ClockPin mask
mosiMask                long 1 << Header#SPI_MOSI
misoMask                long 1 << Header#SPI_MISO
'shiftClockMask          long 1 << Header#SHIFT_CLOCK '' Used for ClockPin mask
'shiftMosiMask           long 1 << Header#SHIFT_MOSI
'shiftMisoMask           long 1 << Header#SHIFT_MISO
'latch595Mask            long 1 << Header#LATCH_595_PIN
'latch165Mask            long 1 << Header#LATCH_165_PIN           
'dataAdcMask             long 1 << Header#ADC_DATA        
'dataAdcMask             long 1 << Header#SPI_MOSI      
{csChanMaskX             long 1 << Header#CS_DRV8711_X_595 ' active high
csChanMaskY             long 1 << Header#CS_DRV8711_Y_595 ' active high
csChanMaskZ             long 1 << Header#CS_DRV8711_Z_595 ' active high
resetChanMaskX          long 1 << Header#RESET_DRV8711_X_595
resetChanMaskY          long 1 << Header#RESET_DRV8711_Y_595
resetChanMaskZ          long 1 << Header#RESET_DRV8711_Z_595
sleepChanMaskX          long 1 << Header#SLEEP_DRV8711_X_595
sleepChanMaskY          long 1 << Header#SLEEP_DRV8711_Y_595
sleepChanMaskZ          long 1 << Header#SLEEP_DRV8711_Z_595   }
'csOledChanMask          long 1 << Header#CS_OLED_595 ' active low
csOledMask              long 1 << Header#CS_OLED_PIN ' active low

'csAdcChanMask           long 1 << Header#CS_ADC_595  ' active low

'p4Cs                    long 1 << 4 
'p2Reset                 long 1 << 2
'p0Sleep                 long 1
        
'shiftRegisterInputCog   long 0-0
'shiftRegisterOutputCog  long 0-0
'adcPtr                  long 0-0
'bitsFromSpinPtr         long 0-0
'adcInUsePtr             long 0-0
'firstAdcPtr             long 0-0
'refreshCountCog         long 0
'refreshCountPtr         long 0-0
'oledBufferPtr           long 0-0
{ebugAddress0           long 0-0
debugAddress1           long 0-0
debugAddress2           long 0-0
debugAddress3           long 0-0
debugAddress4           long 0-0
debugAddress5           long 0-0
debugAddress6           long 0-0
debugAddress7           long 0-0
debugAddress8           long 0-0
debugAddress9           long 0-0
debugAddressA           long 0-0
debugAddressB           long 0-0
debugAddressC           long 0-0
debugAddressD           long 0-0
debugAddressE           long 0-0
debugAddressF           long 0-0   }

cogDelay                res 1
wait                    res 1
adcRequest              res 1
activeAdcPtr            res 1
resultPtr               res 1
inputData               res 1
outputData              res 1
commandCog              res 1
{bitsFromPasmCog         res 1 
bitsFromSpinCog         res 1}
temp                    res 1
readErrors              res 1
{shiftRegisterInput      res 1
shiftOutputChange       res 1 }

dataValue               res 1                 
{dataOut                 res 1  }
byteCount               res 1                      
bitCount                res 1
debugPtrCog             res 1
'dataValue1              res 1
                        fit

extraBuffer             byte 0[1024 - (@csOledMask - @entry)]

''
'' A 5x7 font snagged off of the internet by a student of mine
''
'' 128 characters * 8 bytes per character == 1024 bytes (1K)
''                  Font        Char
font5x7      { byte %11111111   '$00
              byte %11111111   '$00
              byte %11111111   '$00
              byte %11111111   '$00
              byte %11111111   '$00
              byte %00000000   '$00
              byte %00000000   '$00
              byte %00000000   '$00

              byte %11111111   '$01
              byte %11111100   '$01
              byte %11111000   '$01
              byte %11100000   '$01
              byte %11000000   '$01
              byte %10000000   '$01
              byte %00000000   '$01
              byte %00000000   '$01
              
              byte %11111111   '$02
              byte %10100101   '$02
              byte %10011001   '$02
              byte %10100101   '$02
              byte %11111111   '$02
              byte %00000000   '$02
              byte %00000000   '$02
              byte %00000000   '$02
              
              byte %00000001   '$03
              byte %00000111   '$03
              byte %00001111   '$03
              byte %00111111   '$03
              byte %11111111   '$03
              byte %00000000   '$03
              byte %00000000   '$03
              byte %00000000   '$03
              
              byte %10000001   '$04
              byte %01000010   '$04
              byte %00100100   '$04
              byte %00011000   '$04
              byte %00011000   '$04
              byte %00000000   '$04
              byte %00000000   '$04
              byte %00000000   '$04
              
              byte %00011000   '$05
              byte %00011000   '$05
              byte %00011000   '$05
              byte %00011000   '$05
              byte %00011000   '$05
              byte %00000000   '$05
              byte %00000000   '$05
              byte %00000000   '$05
              
              byte %00000000   '$06
              byte %00000000   '$06
              byte %11111111   '$06
              byte %00000000   '$06
              byte %00000000   '$06
              byte %00000000   '$06
              byte %00000000   '$06
              byte %00000000   '$06
              
              byte %11111111   '$07
              byte %10000001   '$07
              byte %10000001   '$07
              byte %10000001   '$07
              byte %11111111   '$07
              byte %00000000   '$07
              byte %00000000   '$07
              byte %00000000   '$07
              
              byte %10101010   '$08
              byte %01010101   '$08
              byte %10101010   '$08
              byte %01010101   '$08
              byte %10101010   '$08
              byte %00000000   '$08
              byte %00000000   '$08
              byte %00000000   '$08
              
              byte %10101010   '$09
              byte %01010101   '$09
              byte %10101010   '$09
              byte %01010101   '$09
              byte %10101010   '$09
              byte %00000000   '$09
              byte %00000000   '$09
              byte %00000000   '$09
              
              byte %10101010   '$0A
              byte %01010101   '$0A
              byte %10101010   '$0A
              byte %01010101   '$0A
              byte %10101010   '$0A
              byte %00000000   '$0A
              byte %00000000   '$0A
              byte %00000000   '$0A
              
              byte %10101010   '$0B
              byte %01010101   '$0B
              byte %10101010   '$0B
              byte %01010101   '$0B
              byte %10101010   '$0B
              byte %00000000   '$0B
              byte %00000000   '$0B
              byte %00000000   '$0B
              
              byte %10101010   '$0C
              byte %01010101   '$0C
              byte %10101010   '$0C
              byte %01010101   '$0C
              byte %10101010   '$0C
              byte %00000000   '$0C
              byte %00000000   '$0C
              byte %00000000   '$0C
              
              byte %10101010   '$0D
              byte %01010101   '$0D
              byte %10101010   '$0D
              byte %01010101   '$0D
              byte %10101010   '$0D
              byte %00000000   '$0D
              byte %00000000   '$0D
              byte %00000000   '$0D
              
              byte %10101010   '$0E
              byte %01010101   '$0E
              byte %10101010   '$0E
              byte %01010101   '$0E
              byte %10101010   '$0E
              byte %00000000   '$0E
              byte %00000000   '$0E
              byte %00000000   '$0E
              
              byte %10101010   '$0F
              byte %01010101   '$0F
              byte %10101010   '$0F
              byte %01010101   '$0F
              byte %10101010   '$0F
              byte %00000000   '$0F
              byte %00000000   '$0F
              byte %00000000   '$0F
              
              byte %11111111   '$10
              byte %11111111   '$10
              byte %11111111   '$10
              byte %11111111   '$10
              byte %11111111   '$10
              byte %00000000   '$10
              byte %00000000   '$10
              byte %00000000   '$10
              
              byte %01111110   '$11
              byte %10111101   '$11
              byte %11011011   '$11
              byte %11100111   '$11
              byte %11100111   '$11
              byte %00000000   '$11
              byte %00000000   '$11
              byte %00000000   '$11
              
              byte %11000011   '$12
              byte %11000011   '$12
              byte %11000011   '$12
              byte %11000011   '$12
              byte %11000011   '$12
              byte %00000000   '$12
              byte %00000000   '$12
              byte %00000000   '$12
              
              byte %11111111   '$13
              byte %00000000   '$13
              byte %00000000   '$13
              byte %00000000   '$13
              byte %11111111   '$13
              byte %00000000   '$13
              byte %00000000   '$13
              byte %00000000   '$13
              
              byte %11111111   '$14
              byte %11100111   '$14
              byte %10011001   '$14
              byte %11100111   '$14
              byte %11111111   '$14
              byte %00000000   '$14
              byte %00000000   '$14
              byte %00000000   '$14
              
              byte %11111111   '$15
              byte %11111111   '$15
              byte %10000001   '$15
              byte %10000001   '$15
              byte %11111111   '$15
              byte %00000000   '$15
              byte %00000000   '$15
              byte %00000000   '$15
              
              byte %11111111   '$16
              byte %10000001   '$16
              byte %10000001   '$16
              byte %11111111   '$16
              byte %11111111   '$16
              byte %00000000   '$16
              byte %00000000   '$16
              byte %00000000   '$16
              
              byte %11111111   '$17
              byte %10000001   '$17
              byte %10000001   '$17
              byte %10000001   '$17
              byte %11111111   '$17
              byte %00000000   '$17
              byte %00000000   '$17
              byte %00000000   '$17
              
              byte %11111111   '$18
              byte %10000001   '$18
              byte %10000001   '$18
              byte %10000001   '$18
              byte %11111111   '$18
              byte %00000000   '$18
              byte %00000000   '$18
              byte %00000000   '$18
              
              byte %11111111   '$19
              byte %10000001   '$19
              byte %10000001   '$19
              byte %10000001   '$19
              byte %11111111   '$19
              byte %00000000   '$19
              byte %00000000   '$19
              byte %00000000   '$19
              
              byte %11111111   '$1A
              byte %10000001   '$1A
              byte %10000001   '$1A
              byte %10000001   '$1A
              byte %11111111   '$1A
              byte %00000000   '$1A
              byte %00000000   '$1A
              byte %00000000   '$1A
              
              byte %11111111   '$1B
              byte %10000001   '$1B
              byte %10000001   '$1B
              byte %10000001   '$1B
              byte %11111111   '$1B
              byte %00000000   '$1B
              byte %00000000   '$1B
              byte %00000000   '$1B
              
              byte %11111111   '$1C
              byte %10000001   '$1C
              byte %10000001   '$1C
              byte %10000001   '$1C
              byte %11111111   '$1C
              byte %00000000   '$1C
              byte %00000000   '$1C
              byte %00000000   '$1C
              
              byte %11111111   '$1D
              byte %10000001   '$1D
              byte %10000001   '$1D
              byte %10000001   '$1D
              byte %11111111   '$1D
              byte %00000000   '$1D
              byte %00000000   '$1D
              byte %00000000   '$1D
              
              byte %11111111   '$1E
              byte %10000001   '$1E
              byte %10000001   '$1E
              byte %10000001   '$1E
              byte %11111111   '$1E
              byte %00000000   '$1E
              byte %00000000   '$1E
              byte %00000000   '$1E
              
              byte %11111111   '$1F
              byte %10000001   '$1F
              byte %10000001   '$1F
              byte %10000001   '$1F
              byte %11111111   '$1F
              byte %00000000   '$1F
              byte %00000000   '$1F
              byte %00000000   '$1F }
              
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              byte %00000000   '$20
              
              byte %01011111   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              byte %00000000   '$21
              
              byte %00000011   '$22
              byte %00000101   '$22
              byte %00000000   '$22
              byte %00000011   '$22
              byte %00000101   '$22
              byte %00000000   '$22
              byte %00000000   '$22
              byte %00000000   '$22
              
              byte %00010100   '$23
              byte %00111110   '$23
              byte %00010100   '$23
              byte %00111110   '$23
              byte %00010100   '$23
              byte %00000000   '$23
              byte %00000000   '$23
              byte %00000000   '$23
              
              byte %00100100   '$24
              byte %00101010   '$24
              byte %01111111   '$24
              byte %00101010   '$24
              byte %00010010   '$24
              byte %00000000   '$24
              byte %00000000   '$24
              byte %00000000   '$24
              
              byte %01100011   '$25
              byte %00010000   '$25
              byte %00001000   '$25
              byte %00000100   '$25
              byte %01100011   '$25
              byte %00000000   '$25
              byte %00000000   '$25
              byte %00000000   '$25
              
              byte %00110110   '$26
              byte %01001001   '$26
              byte %01010110   '$26
              byte %00100000   '$26
              byte %01010000   '$26
              byte %00000000   '$26
              byte %00000000   '$26
              byte %00000000   '$26
              
              byte %00000000   '$27
              byte %00000000   '$27
              byte %00000101   '$27
              byte %00000011   '$27
              byte %00000000   '$27
              byte %00000000   '$27
              byte %00000000   '$27
              byte %00000000   '$27
              
              byte %00000000   '$28
              byte %00000000   '$28
              byte %00011100   '$28
              byte %00100010   '$28
              byte %01000001   '$28
              byte %00000000   '$28
              byte %00000000   '$28
              byte %00000000   '$28
              
              byte %01000001   '$29
              byte %00100010   '$29
              byte %00011100   '$29
              byte %00000000   '$29
              byte %00000000   '$29
              byte %00000000   '$29
              byte %00000000   '$29
              byte %00000000   '$29
              
              byte %00100100   '$2A
              byte %00011000   '$2A
              byte %01111110   '$2A
              byte %00011000   '$2A
              byte %00100100   '$2A
              byte %00000000   '$2A
              byte %00000000   '$2A
              byte %00000000   '$2A
              
              byte %00001000   '$2B
              byte %00001000   '$2B
              byte %00111110   '$2B
              byte %00001000   '$2B
              byte %00001000   '$2B
              byte %00000000   '$2B
              byte %00000000   '$2B
              byte %00000000   '$2B
              
              byte %10100000   '$2C
              byte %01100000   '$2C
              byte %00000000   '$2C
              byte %00000000   '$2C
              byte %00000000   '$2C
              byte %00000000   '$2C
              byte %00000000   '$2C
              byte %00000000   '$2C
              
              byte %00001000   '$2D
              byte %00001000   '$2D
              byte %00001000   '$2D
              byte %00001000   '$2D
              byte %00001000   '$2D
              byte %00000000   '$2D
              byte %00000000   '$2D
              byte %00000000   '$2D
              
              byte %01100000   '$2E
              byte %01100000   '$2E
              byte %00000000   '$2E
              byte %00000000   '$2E
              byte %00000000   '$2E
              byte %00000000   '$2E
              byte %00000000   '$2E
              byte %00000000   '$2E
              
              byte %01100000   '$2F
              byte %00010000   '$2F
              byte %00001000   '$2F
              byte %00000100   '$2F
              byte %00000011   '$2F
              byte %00000000   '$2F
              byte %00000000   '$2F
              byte %00000000   '$2F
              
              byte %00111110   '$30
              byte %01010001   '$30
              byte %01001001   '$30
              byte %01000101   '$30
              byte %00111110   '$30
              byte %00000000   '$30
              byte %00000000   '$30
              byte %00000000   '$30
              
              byte %00000000   '$31
              byte %01000010   '$31
              byte %01111111   '$31
              byte %01000000   '$31
              byte %00000000   '$31
              byte %00000000   '$31
              byte %00000000   '$31
              byte %00000000   '$31
              
              byte %01100010   '$32
              byte %01010001   '$32
              byte %01010001   '$32
              byte %01001001   '$32
              byte %01000110   '$32
              byte %00000000   '$32
              byte %00000000   '$32
              byte %00000000   '$32
              
              byte %00100010   '$33
              byte %01001001   '$33
              byte %01001001   '$33
              byte %01001001   '$33
              byte %00110110   '$33
              byte %00000000   '$33
              byte %00000000   '$33
              byte %00000000   '$33
              
              byte %00011000   '$34
              byte %00010100   '$34
              byte %00010010   '$34
              byte %01111111   '$34
              byte %00010000   '$34
              byte %00000000   '$34
              byte %00000000   '$34
              byte %00000000   '$34
              
              byte %00100111   '$35
              byte %01000101   '$35
              byte %01000101   '$35
              byte %01000101   '$35
              byte %00111001   '$35
              byte %00000000   '$35
              byte %00000000   '$35
              byte %00000000   '$35
              
              byte %00111100   '$36
              byte %01001010   '$36
              byte %01001001   '$36
              byte %01001001   '$36
              byte %00110000   '$36
              byte %00000000   '$36
              byte %00000000   '$36
              byte %00000000   '$36
              
              byte %00000001   '$37
              byte %01110001   '$37
              byte %00001001   '$37
              byte %00000101   '$37
              byte %00000011   '$37
              byte %00000000   '$37
              byte %00000000   '$37
              byte %00000000   '$37
              
              byte %00110110   '$38
              byte %01001001   '$38
              byte %01001001   '$38
              byte %01001001   '$38
              byte %00110110   '$38
              byte %00000000   '$38
              byte %00000000   '$38
              byte %00000000   '$38
              
              byte %00000110   '$39
              byte %01001001   '$39
              byte %01001001   '$39
              byte %00101001   '$39
              byte %00011110   '$39
              byte %00000000   '$39
              byte %00000000   '$39
              byte %00000000   '$39
              
              byte %00110110   '$3A
              byte %00110110   '$3A
              byte %00000000   '$3A
              byte %00000000   '$3A
              byte %00000000   '$3A
              byte %00000000   '$3A
              byte %00000000   '$3A
              byte %00000000   '$3A
              
              byte %10110110   '$3B
              byte %01110110   '$3B
              byte %00000000   '$3B
              byte %00000000   '$3B
              byte %00000000   '$3B
              byte %00000000   '$3B
              byte %00000000   '$3B
              byte %00000000   '$3B
              
              byte %00000000   '$3C
              byte %00001000   '$3C
              byte %00010100   '$3C
              byte %00100010   '$3C
              byte %01000001   '$3C
              byte %00000000   '$3C
              byte %00000000   '$3C
              byte %00000000   '$3C
              
              byte %00010100   '$3D
              byte %00010100   '$3D
              byte %00010100   '$3D
              byte %00010100   '$3D
              byte %00010100   '$3D
              byte %00000000   '$3D
              byte %00000000   '$3D
              byte %00000000   '$3D
              
              byte %01000001   '$3E
              byte %00100010   '$3E
              byte %00010100   '$3E
              byte %00001000   '$3E
              byte %00000000   '$3E
              byte %00000000   '$3E
              byte %00000000   '$3E
              byte %00000000   '$3E
              
              byte %00000010   '$3F
              byte %00000001   '$3F
              byte %01010001   '$3F
              byte %00001001   '$3F
              byte %00000110   '$3F
              byte %00000000   '$3F
              byte %00000000   '$3F
              byte %00000000   '$3F
              
              byte %00111110   '$40
              byte %01000001   '$40
              byte %01011101   '$40
              byte %01010001   '$40
              byte %01001110   '$40
              byte %00000000   '$40
              byte %00000000   '$40
              byte %00000000   '$40
              
              byte %01111100   '$41
              byte %00010010   '$41
              byte %00010001   '$41
              byte %00010010   '$41
              byte %01111100   '$41
              byte %00000000   '$41
              byte %00000000   '$41
              byte %00000000   '$41
              
              byte %01111111   '$42
              byte %01001001   '$42
              byte %01001001   '$42
              byte %01001001   '$42
              byte %00110110   '$42
              byte %00000000   '$42
              byte %00000000   '$42
              byte %00000000   '$42
              
              byte %00011100   '$43
              byte %00100010   '$43
              byte %01000001   '$43
              byte %01000001   '$43
              byte %00100010   '$43
              byte %00000000   '$43
              byte %00000000   '$43
              byte %00000000   '$43
              
              byte %01111111   '$44
              byte %01000001   '$44
              byte %01000001   '$44
              byte %00100010   '$44
              byte %00011100   '$44
              byte %00000000   '$44
              byte %00000000   '$44
              byte %00000000   '$44
              
              byte %01111111   '$45
              byte %01001001   '$45
              byte %01001001   '$45
              byte %01001001   '$45
              byte %01000001   '$45
              byte %00000000   '$45
              byte %00000000   '$45
              byte %00000000   '$45
              
              byte %01111111   '$46
              byte %00001001   '$46
              byte %00001001   '$46
              byte %00001001   '$46
              byte %00000001   '$46
              byte %00000000   '$46
              byte %00000000   '$46
              byte %00000000   '$46
              
              byte %00111110   '$47
              byte %01000001   '$47
              byte %01000001   '$47
              byte %01010001   '$47
              byte %00110010   '$47
              byte %00000000   '$47
              byte %00000000   '$47
              byte %00000000   '$47
              
              byte %01111111   '$48
              byte %00001000   '$48
              byte %00001000   '$48
              byte %00001000   '$48
              byte %01111111   '$48
              byte %00000000   '$48
              byte %00000000   '$48
              byte %00000000   '$48
              
              byte %01000001   '$49
              byte %01000001   '$49
              byte %01111111   '$49
              byte %01000001   '$49
              byte %01000001   '$49
              byte %00000000   '$49
              byte %00000000   '$49
              byte %00000000   '$49
              
              byte %00100000   '$4A
              byte %01000000   '$4A
              byte %01000000   '$4A
              byte %01000000   '$4A
              byte %00111111   '$4A
              byte %00000000   '$4A
              byte %00000000   '$4A
              byte %00000000   '$4A
              
              byte %01111111   '$4B
              byte %00001000   '$4B
              byte %00010100   '$4B
              byte %00100010   '$4B
              byte %01000001   '$4B
              byte %00000000   '$4B
              byte %00000000   '$4B
              byte %00000000   '$4B
              
              byte %01111111   '$4C
              byte %01000000   '$4C
              byte %01000000   '$4C
              byte %01000000   '$4C
              byte %01000000   '$4C
              byte %00000000   '$4C
              byte %00000000   '$4C
              byte %00000000   '$4C
              
              byte %01111111   '$4D
              byte %00000010   '$4D
              byte %00001100   '$4D
              byte %00000010   '$4D
              byte %01111111   '$4D
              byte %00000000   '$4D
              byte %00000000   '$4D
              byte %00000000   '$4D
              
              byte %01111111   '$4E
              byte %00000100   '$4E
              byte %00001000   '$4E
              byte %00010000   '$4E
              byte %01111111   '$4E
              byte %00000000   '$4E
              byte %00000000   '$4E
              byte %00000000   '$4E
              
              byte %00111110   '$4F
              byte %01000001   '$4F
              byte %01000001   '$4F
              byte %01000001   '$4F
              byte %00111110   '$4F
              byte %00000000   '$4F
              byte %00000000   '$4F
              byte %00000000   '$4F
              
              byte %01111111   '$50
              byte %00001001   '$50
              byte %00001001   '$50
              byte %00001001   '$50
              byte %00000110   '$50
              byte %00000000   '$50
              byte %00000000   '$50
              byte %00000000   '$50
              
              byte %00111110   '$51
              byte %01000001   '$51
              byte %01010001   '$51
              byte %00100001   '$51
              byte %01011110   '$51
              byte %00000000   '$51
              byte %00000000   '$51
              byte %00000000   '$51
              
              byte %01111111   '$52
              byte %00001001   '$52
              byte %00011001   '$52
              byte %00101001   '$52
              byte %01000110   '$52
              byte %00000000   '$52
              byte %00000000   '$52
              byte %00000000   '$52
              
              byte %00100110   '$53
              byte %01001001   '$53
              byte %01001001   '$53
              byte %01001001   '$53
              byte %00110010   '$53
              byte %00000000   '$53
              byte %00000000   '$53
              byte %00000000   '$53
              
              byte %00000001   '$54
              byte %00000001   '$54
              byte %01111111   '$54
              byte %00000001   '$54
              byte %00000001   '$54
              byte %00000000   '$54
              byte %00000000   '$54
              byte %00000000   '$54
              
              byte %00111111   '$55
              byte %01000000   '$55
              byte %01000000   '$55
              byte %01000000   '$55
              byte %00111111   '$55
              byte %00000000   '$55
              byte %00000000   '$55
              byte %00000000   '$55
              
              byte %00000111   '$56
              byte %00011000   '$56
              byte %01100000   '$56
              byte %00011000   '$56
              byte %00000111   '$56
              byte %00000000   '$56
              byte %00000000   '$56
              byte %00000000   '$56
              
              byte %00111111   '$57
              byte %01000000   '$57
              byte %00111000   '$57
              byte %01000000   '$57
              byte %00111111   '$57
              byte %00000000   '$57
              byte %00000000   '$57
              byte %00000000   '$57
              
              byte %01100011   '$58
              byte %00010100   '$58
              byte %00001000   '$58
              byte %00010100   '$58
              byte %01100011   '$58
              byte %00000000   '$58
              byte %00000000   '$58
              byte %00000000   '$58
              
              byte %00000011   '$59
              byte %00000100   '$59
              byte %01111000   '$59
              byte %00000100   '$59
              byte %00000011   '$59
              byte %00000000   '$59
              byte %00000000   '$59
              byte %00000000   '$59
              
              byte %01100001   '$5A
              byte %01010001   '$5A
              byte %01001001   '$5A
              byte %01000101   '$5A
              byte %01000011   '$5A
              byte %00000000   '$5A
              byte %00000000   '$5A
              byte %00000000   '$5A
              
              byte %01111111   '$5B
              byte %01111111   '$5B
              byte %01000001   '$5B
              byte %01000001   '$5B
              byte %01000001   '$5B
              byte %00000000   '$5B
              byte %00000000   '$5B
              byte %00000000   '$5B
              
              byte %00000011   '$5C
              byte %00000100   '$5C
              byte %00001000   '$5C
              byte %00010000   '$5C
              byte %01100000   '$5C
              byte %00000000   '$5C
              byte %00000000   '$5C
              byte %00000000   '$5C
              
              byte %01000001   '$5D
              byte %01000001   '$5D
              byte %01000001   '$5D
              byte %01111111   '$5D
              byte %01111111   '$5D
              byte %00000000   '$5D
              byte %00000000   '$5D
              byte %00000000   '$5D
              
              byte %00010000   '$5E
              byte %00001000   '$5E
              byte %00000100   '$5E
              byte %00001000   '$5E
              byte %00010000   '$5E
              byte %00000000   '$5E
              byte %00000000   '$5E
              byte %00000000   '$5E
              
              byte %10000000   '$5F
              byte %10000000   '$5F
              byte %10000000   '$5F
              byte %10000000   '$5F
              byte %10000000   '$5F
              byte %00000000   '$5F
              byte %00000000   '$5F
              byte %00000000   '$5F
              
              byte %00000000   '$60
              byte %00000000   '$60
              byte %00000110   '$60
              byte %00000101   '$60
              byte %00000000   '$60
              byte %00000000   '$60
              byte %00000000   '$60
              byte %00000000   '$60
              
              byte %00100000   '$61
              byte %01010100   '$61
              byte %01010100   '$61
              byte %01010100   '$61
              byte %01111000   '$61
              byte %00000000   '$61
              byte %00000000   '$61
              byte %00000000   '$61
              
              byte %01111111   '$62
              byte %01000100   '$62
              byte %01000100   '$62
              byte %01000100   '$62
              byte %00111000   '$62
              byte %00000000   '$62
              byte %00000000   '$62
              byte %00000000   '$62
              
              byte %00111000   '$63
              byte %01000100   '$63
              byte %01000100   '$63
              byte %01000100   '$63
              byte %01000100   '$63
              byte %00000000   '$63
              byte %00000000   '$63
              byte %00000000   '$63
              
              byte %00111000   '$64
              byte %01000100   '$64
              byte %01000100   '$64
              byte %01000100   '$64
              byte %01111111   '$64
              byte %00000000   '$64
              byte %00000000   '$64
              byte %00000000   '$64
              
              byte %00111000   '$65
              byte %01010100   '$65
              byte %01010100   '$65
              byte %01010100   '$65
              byte %01011000   '$65
              byte %00000000   '$65
              byte %00000000   '$65
              byte %00000000   '$65
              
              byte %00001000   '$66
              byte %01111110   '$66
              byte %00001001   '$66
              byte %00001001   '$66
              byte %00000010   '$66
              byte %00000000   '$66
              byte %00000000   '$66
              byte %00000000   '$66
              
              byte %00011000   '$67
              byte %10100100   '$67
              byte %10100100   '$67
              byte %10100100   '$67
              byte %01111000   '$67
              byte %00000000   '$67
              byte %00000000   '$67
              byte %00000000   '$67
              
              byte %01111111   '$68
              byte %00000100   '$68
              byte %00000100   '$68
              byte %00000100   '$68
              byte %01111000   '$68
              byte %00000000   '$68
              byte %00000000   '$68
              byte %00000000   '$68
              
              byte %00000000   '$69
              byte %01000100   '$69
              byte %01111101   '$69
              byte %01000000   '$69
              byte %00000000   '$69
              byte %00000000   '$69
              byte %00000000   '$69
              byte %00000000   '$69
              
              byte %01000000   '$6A
              byte %10000000   '$6A
              byte %10000100   '$6A
              byte %01111101   '$6A
              byte %00000000   '$6A
              byte %00000000   '$6A
              byte %00000000   '$6A
              byte %00000000   '$6A
              
              byte %01101111   '$6B
              byte %00010000   '$6B
              byte %00010000   '$6B
              byte %00101000   '$6B
              byte %01000100   '$6B
              byte %00000000   '$6B
              byte %00000000   '$6B
              byte %00000000   '$6B
              
              byte %00000000   '$6C
              byte %01000001   '$6C
              byte %01111111   '$6C
              byte %01000000   '$6C
              byte %00000000   '$6C
              byte %00000000   '$6C
              byte %00000000   '$6C
              byte %00000000   '$6C
              
              byte %01111100   '$6D
              byte %00000100   '$6D
              byte %00111000   '$6D
              byte %00000100   '$6D
              byte %01111100   '$6D
              byte %00000000   '$6D
              byte %00000000   '$6D
              byte %00000000   '$6D
              
              byte %01111100   '$6E
              byte %00000100   '$6E
              byte %00000100   '$6E
              byte %00000100   '$6E
              byte %01111000   '$6E
              byte %00000000   '$6E
              byte %00000000   '$6E
              byte %00000000   '$6E
              
              byte %00111000   '$6F
              byte %01000100   '$6F
              byte %01000100   '$6F
              byte %01000100   '$6F
              byte %00111000   '$6F
              byte %00000000   '$6F
              byte %00000000   '$6F
              byte %00000000   '$6F
              
              byte %11111100   '$70
              byte %00100100   '$70
              byte %00100100   '$70
              byte %00100100   '$70
              byte %00011000   '$70
              byte %00000000   '$70
              byte %00000000   '$70
              byte %00000000   '$70
              
              byte %00011000   '$71
              byte %00100100   '$71
              byte %00100100   '$71
              byte %00100100   '$71
              byte %11111100   '$71
              byte %00000000   '$71
              byte %00000000   '$71
              byte %00000000   '$71
              
              byte %01111100   '$72
              byte %00001000   '$72
              byte %00000100   '$72
              byte %00000100   '$72
              byte %00000100   '$72
              byte %00000000   '$72
              byte %00000000   '$72
              byte %00000000   '$72
              
              byte %01001000   '$73
              byte %01010100   '$73
              byte %01010100   '$73
              byte %01010100   '$73
              byte %00100100   '$73
              byte %00000000   '$73
              byte %00000000   '$73
              byte %00000000   '$73
              
              byte %00000100   '$74
              byte %00111111   '$74
              byte %01000100   '$74
              byte %01000100   '$74
              byte %00100000   '$74
              byte %00000000   '$74
              byte %00000000   '$74
              byte %00000000   '$74
              
              byte %00111100   '$75
              byte %01000000   '$75
              byte %01000000   '$75
              byte %00100000   '$75
              byte %01111100   '$75
              byte %00000000   '$75
              byte %00000000   '$75
              byte %00000000   '$75
              
              byte %00011100   '$76
              byte %00100000   '$76
              byte %01000000   '$76
              byte %00100000   '$76
              byte %00011100   '$76
              byte %00000000   '$76
              byte %00000000   '$76
              byte %00000000   '$76
              
              byte %01111100   '$77
              byte %01000000   '$77
              byte %00110000   '$77
              byte %01000000   '$77
              byte %01111100   '$77
              byte %00000000   '$77
              byte %00000000   '$77
              byte %00000000   '$77
              
              byte %01000100   '$78
              byte %00101000   '$78
              byte %00010000   '$78
              byte %00101000   '$78
              byte %01000100   '$78
              byte %00000000   '$78
              byte %00000000   '$78
              byte %00000000   '$78
              
              byte %00011100   '$79
              byte %10100000   '$79
              byte %10100000   '$79
              byte %10100000   '$79
              byte %01111100   '$79
              byte %00000000   '$79
              byte %00000000   '$79
              byte %00000000   '$79
              
              byte %01000100   '$7A
              byte %01100100   '$7A
              byte %01010100   '$7A
              byte %01001100   '$7A
              byte %01000100   '$7A
              byte %00000000   '$7A
              byte %00000000   '$7A
              byte %00000000   '$7A
              
              byte %00001000   '$7B
              byte %00111110   '$7B
              byte %01110111   '$7B
              byte %01000001   '$7B
              byte %01000001   '$7B
              byte %00000000   '$7B
              byte %00000000   '$7B
              byte %00000000   '$7B
              
              byte %00000000   '$7C
              byte %00000000   '$7C
              byte %11111111   '$7C
              byte %00000000   '$7C
              byte %00000000   '$7C
              byte %00000000   '$7C
              byte %00000000   '$7C
              byte %00000000   '$7C
              
              byte %01000001   '$7D
              byte %01000001   '$7D
              byte %01110111   '$7D
              byte %00111110   '$7D
              byte %00001000   '$7D
              byte %00000000   '$7D
              byte %00000000   '$7D
              byte %00000000   '$7D
              
              byte %00000100   '$7E
              byte %00000010   '$7E
              byte %00000110   '$7E
              byte %00000100   '$7E
              byte %00000010   '$7E
              byte %00000000   '$7E
              byte %00000000   '$7E
              byte %00000000   '$7E
              
              byte %11111111   '$7F
              byte %11111111   '$7F
              byte %11111111   '$7F
              byte %11111111   '$7F
              byte %11111111   '$7F
              byte %00000000   '$7F
              byte %00000000   '$7F
              byte %00000000   '$7F
                                      