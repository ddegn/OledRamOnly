DAT objectName          byte "OledAsm140828a", 0
CON
{{      
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
  LCD_BUFFER_SIZE_BOTH_TYPES    = 1024

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
  
VAR

  long  cog, command, mailbox
  long  csPin, dataCommandPin, dataPin, clockPin, resetPin, vccState
  long  displayWidth, displayHeight, displayType
  long  autoUpdate
  
  byte  buffer[LCD_BUFFER_SIZE_BOTH_TYPES]
  
'------------------------------------------------------------------------------------------------------------------------------
PUB Start(csPin_, dataCommandPin_, dataPin_, clockPin_, resetPin_, vccState_, type_)
'' Start SPI Engine - starts a cog
'' returns false if no cog available

  Stop

  ''Initialize variables 
  longmove(@csPin, @csPin_, 6)

  displayType := type_
 
  command := @csPin
  result := cog := cognew(@entry, @command) + 1

  repeat while command
   
  Init
    
PUB Stop
'' Stop SPI Engine - frees a cog

  if cog
     cogstop(cog~ - 1)
  command~

PRI Setcommand(cmd)

  command := cmd                '' Write command 
  repeat while command          '' Wait for command to be cleared, signifying receipt
   
PRI Init

  if displayType == TYPE_128X32
    displayWidth := SSD1306_LCDWIDTH
    displayHeight := SSD1306_LCDHEIGHT32
  else
    displayWidth := SSD1306_LCDWIDTH
    displayHeight := SSD1306_LCDHEIGHT64

  ''Setup reset and pin direction  
  High(resetPin)
  ''VDD (3.3V) goes high at start; wait for a ms
  waitcnt(clkfreq / 100000 + cnt)
  ''force reset low
  Low(resetPin)
  ''wait 10ms
  waitcnt(clkfreq / 100000 + cnt)
  ''remove reset
  High(resetPin)

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
  Setcommand(SHIFT_OUT_BYTE)

PUB WriteBuff(addr)

  mailbox := addr           
  Setcommand(SHIFT_OUT_BUFFER)

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

  High(dataCommandPin)
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
    write16x32Char(byte[str][i], 0, i) 

PUB Write2x8String(str, len, row) | i

  row &= $1 'Force in bounds
  if displayType == TYPE_128X64
    repeat i from 0 to (len <# SSD1306_LCDCHARMAX) - 1
      write16x32Char(byte[str][i], row, i) 
     
PUB Write16x32Char(ch, row, col) | h, i, j, k, q, r, s, mask, cbase, cset, bset

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
     
PUB Write4x16String(str, len, row, col) | i, j
  ''Write a string of 5x7 characters to the display @ row and column
  
  repeat j from 0 to len - 1
    Write5x7Char(byte[str][j], row, col)  
    col++
    if(col > 15)
      col := 0
      row++
  if autoUpdate
    updateDisplay               ' Update the display

PUB Write5x7Char(ch, row, col) | i    
  ''Write a 5x7 character to the display @ row and column
  
  col &= $F
  if displayType == TYPE_128X32
    row &= $3
    repeat i from 0 to 7
      buffer[row * 128 + col * 8 + i] := byte[@Font5x7 + 8 * ch + i]
  else
    row &= $7
    repeat i from 0 to 7
      buffer[row * 128 + col * 8 + i] := byte[@Font5x7 + 8 * ch + i]
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

PUB Ssd1306Command(localCommand) 'Send a byte as a command to the display
  ''Write SPI command to the OLED
  
  Low(dataCommandPin)
  ShiftOut(localCommand)   

PUB Ssd1306Data(localData)   'Send a byte as data to the display
  ''Write SPI data to the OLED
  
  High(dataCommandPin)
  ShiftOut(localData)   

PUB GetBuffer                   'Get the address of the buffer for the display

  return @buffer

PUB GetSplash                   'Get the address of the Adafruit Splash Screen

  return @splash

PUB GetObjectName

  return @objectName
  
DAT     'Adafruit Splash Screen (1Kbytes)

splash  byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80
        byte $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $80, $80, $C0, $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $80, $C0, $E0, $F0, $F8, $FC, $F8, $E0, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80
        byte $80, $80, $00, $80, $80, $00, $00, $00, $00, $80, $80, $80, $80, $80, $00, $FF
        byte $FF, $FF, $00, $00, $00, $00, $80, $80, $80, $80, $00, $00, $80, $80, $00, $00
        byte $80, $FF, $FF, $80, $80, $00, $80, $80, $00, $80, $80, $80, $80, $00, $80, $80
        byte $00, $00, $00, $00, $00, $80, $80, $00, $00, $8C, $8E, $84, $00, $00, $80, $F8
        byte $F8, $F8, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $E0, $E0, $C0, $80
        byte $00, $E0, $FC, $FE, $FF, $FF, $FF, $7F, $FF, $FF, $FF, $FF, $FF, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FE, $FF, $C7, $01, $01
        byte $01, $01, $83, $FF, $FF, $00, $00, $7C, $FE, $C7, $01, $01, $01, $01, $83, $FF
        byte $FF, $FF, $00, $38, $FE, $C7, $83, $01, $01, $01, $83, $C7, $FF, $FF, $00, $00
        byte $01, $FF, $FF, $01, $01, $00, $FF, $FF, $07, $01, $01, $01, $00, $00, $7F, $FF
        byte $80, $00, $00, $00, $FF, $FF, $7F, $00, $00, $FF, $FF, $FF, $00, $00, $01, $FF
        byte $FF, $FF, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $03, $0F, $3F, $7F, $7F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $E7, $C7, $C7, $8F
        byte $8F, $9F, $BF, $FF, $FF, $C3, $C0, $F0, $FF, $FF, $FF, $FF, $FF, $FC, $FC, $FC
        byte $FC, $FC, $FC, $FC, $FC, $F8, $F8, $F0, $F0, $E0, $C0, $00, $01, $03, $03, $03
        byte $03, $03, $01, $03, $03, $00, $00, $00, $00, $01, $03, $03, $03, $03, $01, $01
        byte $03, $01, $00, $00, $00, $01, $03, $03, $03, $03, $01, $01, $03, $03, $00, $00
        byte $00, $03, $03, $00, $00, $00, $03, $03, $00, $00, $00, $00, $00, $00, $00, $01
        byte $03, $03, $03, $03, $03, $01, $00, $00, $00, $01, $03, $01, $00, $00, $00, $03
        byte $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $80, $C0, $E0, $F0, $F9, $FF, $FF, $FF, $FF, $FF, $3F, $1F, $0F
        byte $87, $C7, $F7, $FF, $FF, $1F, $1F, $3D, $FC, $F8, $F8, $F8, $F8, $7C, $7D, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7F, $3F, $0F, $07, $00, $30, $30, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $FE, $FE, $FC, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E0, $C0, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30, $30, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $C0, $FE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7F, $7F, $3F, $1F
        byte $0F, $07, $1F, $7F, $FF, $FF, $F8, $F8, $FF, $FF, $FF, $FF, $FF, $FE, $F8, $E0
        byte $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $FE, $FE, $00, $00
        byte $00, $FC, $FE, $FC, $0C, $06, $06, $0E, $FC, $F8, $00, $00, $F0, $F8, $1C, $0E
        byte $06, $06, $06, $0C, $FF, $FF, $FF, $00, $00, $FE, $FE, $00, $00, $00, $00, $FC
        byte $FE, $FC, $00, $18, $3C, $7E, $66, $E6, $CE, $84, $00, $00, $06, $FF, $FF, $06
        byte $06, $FC, $FE, $FC, $0C, $06, $06, $06, $00, $00, $FE, $FE, $00, $00, $C0, $F8
        byte $FC, $4E, $46, $46, $46, $4E, $7C, $78, $40, $18, $3C, $76, $E6, $CE, $CC, $80
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $01, $07, $0F, $1F, $1F, $3F, $3F, $3F, $3F, $1F, $0F, $03
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F, $0F, $00, $00
        byte $00, $0F, $0F, $0F, $00, $00, $00, $00, $0F, $0F, $00, $00, $03, $07, $0E, $0C
        byte $18, $18, $0C, $06, $0F, $0F, $0F, $00, $00, $01, $0F, $0E, $0C, $18, $0C, $0F
        byte $07, $01, $00, $04, $0E, $0C, $18, $0C, $0F, $07, $00, $00, $00, $0F, $0F, $00
        byte $00, $0F, $0F, $0F, $00, $00, $00, $00, $00, $00, $0F, $0F, $00, $00, $00, $07
        byte $07, $0C, $0C, $18, $1C, $0C, $06, $06, $00, $04, $0E, $0C, $18, $0C, $0F, $07
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

'**********************************************************************************************************
'**  Assembly language driver
'**********************************************************************************************************
DAT           org
''****************************** 
'' SPI Engine - Command dispatch
''******************************

entry                   rdlong  bufferAddress, par     ' bufferAddress points to csPin  
                        mov     mailboxAddr, par
                        add     mailboxAddr, #4
                        rdlong  dataValue, bufferAddress
                        shl     csMask, dataValue
                        add     bufferAddress, #8
                        rdlong  dataValue, bufferAddress
                        shl     dataMask, dataValue
                        add     bufferAddress, #4
                        rdlong  dataValue, bufferAddress
                        shl     clockMask, dataValue
                        or      outa, csMask
                        or      outa, dataMask
                        or      outa, clockMask
                        or      dira, csMask
                        or      dira, dataMask
                        or      dira, clockMask
                        
preLoop                 wrlong  zero, par               '' Clear command
                      
loop                    rdlong  dataValue, par  wz      '' Wait for command via par
              if_z      jmp     #loop                   '' No command (0), keep looking

                        cmp     dataValue, #SHIFT_OUT_BYTE wz '' Jump to the single SPI shift routine
              if_z      jmp     #shiftOne             
                        cmp     dataValue, #SHIFT_OUT_BUFFER wz '' Jump to the write buffer routine
              if_z      jmp     #writeBuff_             

                        wrlong  zero,par                ''     Zero command to signify command received
                        jmp     #loop
                                               
'################################################################################################################
'Single OLED SPI shift routine
shiftOne                andn    outa, csMask
                        rdlong  dataValue, mailboxAddr
                        ror     dataValue, #8
                        mov     bitCount, #8
:msbShift               shl     dataValue, #1   wc
                        muxc    outa, dataMask
                        andn    outa, clockMask
                        or      outa, clockMask                        
                        djnz    bitCount, #:msbShift
                        or      outa, csMask
                        
                        or      outa, dataMask
                        jmp     #preLoop                        
            
'------------------------------------------------------------------------------------------------------------------------------
writeBuff_              rdlong  bufferAddress, mailboxAddr                        
                        mov     byteCount, bufferSize

readByte                andn    outa, csMask
                        rdbyte  dataValue, bufferAddress
                        ror     dataValue, #8
                        mov     bitCount, #8 
                        add     bufferAddress, #1
:msbShift               shl     dataValue, #1   wc
                        muxc    outa, dataMask
                        andn    outa, clockMask
                        or      outa, clockMask                        
                        djnz    bitCount, #:msbShift
                        or      outa, csMask
                        
                        djnz    byteCount, #readByte
                        or      outa, dataMask
                        jmp     #preLoop                                                         
            
'------------------------------------------------------------------------------------------------------------------------------
{
########################### Assembly variables ###########################
}
zero                    long 0                  '' Constant
bufferSize              long 1024               '' Buffer size
                                              
clockMask               long 1                  '' Used for ClockPin mask
dataMask                long 1                  '' Used for temporary data mask
csMask                  long 1                  '' Used for Chip Select mask
dataValue               res 1                   '' Used to hold dataValueue
bufferAddress           res 1                   '' Used for buffer address                     
byteCount               res 1                      
bitCount                res 1
mailboxAddr             res 1                    
                        fit
''
'' A 5x7 font snagged off of the internet by a student of mine
''
'' 128 characters * 8 bytes per character == 1024 bytes (1K)
''                  Font        Char
Font5x7       byte %11111111   '$00
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
              byte %00000000   '$1F
              
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

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}