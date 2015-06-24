DAT programName         byte "TestOled", 0
CON
{  Test code to send bitmap data from SD to display.


  ******* Private Notes *******
 
  Change name from "TestMotor" to "TestOled."
 
}  
CON

  _clkmode = xtal1 + pll16x                           
  _xinfreq = 5_000_000

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

  SCALED_MULTIPLIER = 1000

  QUOTE = 34

  'executeState enumeration
  '#0, INIT_EXECUTE, SELECT_TO_EXECUTE, ACTIVE_EXECUTE, RETURN_FROM_EXECUTE
            
VAR

  'long stack[64]
  'long qq
  'long commandSpi
  'long debugSpi[16]
  'long shiftRegisterOutput, shiftRegisterInput ' read only from Spin
  'long adcData[8]

  'long lastRefreshTime, refreshInterval
  'long sdErrorNumber, sdErrorString, sdTryCount
  'long filePosition[Header#NUMBER_OF_AXES]
  'long globalMultiplier
  long timer
  'long topX, topY, topZ
  long oledPtr[Header#MAX_OLED_DATA_LINES]
  'long testData[Header#MAX_OLED_DATA_LINES]

  
  'long adcPtr
  'long buttonMask
  'long configPtr', filePosition[4]
  long globalMultiplier', fileNamePtr
  'long fileIdNumber[Header#MAX_DATA_FILES]
  'long dataFileCounter, highlightedFile
  long oledBufferPtr
  
  byte debugLock', spiLock
  'byte tstr[32]

  'byte sdMountFlag[Header#NUMBER_OF_SD_INSTANCES]
  byte endFlag
  'byte configData[Header#CONFIG_SIZE]
  'byte sdFlag, highlightedLine
  byte commentIndex, newCommentFlag
  byte codeType, codeValue, expectedChar
  byte sdProgramName[Header#MAX_NAME_SIZE + 1]
  byte downFlag, activeFile
  
DAT

designFileIndex         long -1
'lowerZAmount            long Header#DEFAULT_Z_DISTANCE
measuredStack           long 0
oledStackPtr            long 0
'microStepMultiplier     long 1
'machineState            byte Header#INIT_STATE
'stepPin                 byte Header#STEP_X_PIN, Header#STEP_Y_PIN, Header#STEP_Z_PIN
'directionPin            byte Header#DIR_X_PIN, Header#DIR_Y_PIN, Header#DIR_Z_PIN
'units                   byte Header#MILLIMETER_UNIT 
delimiter               byte 13, 10, ",", 9, 0
'executeState            byte INIT_EXECUTE

'programState            byte Header#FRESH_PROGRAM
'microsteps              byte Header#DEFAULT_MICROSTEPS
'machineState            byte Header#DEFAULT_MACHINE_STATE
'previousProgram         byte Header#INIT_MAIN
'homedFlag               byte Header#UNKNOWN_POSITION, 0[3]                          
'positionX               long 0 '$80_00_00_00
'ositionY               long 0 '$80_00_00_00
'positionZ               long 0 '$80_00_00_00
 
OBJ

  Header : "HeaderOled"
  Pst : "Parallax Serial TerminalDat" ' Allows child objects to share serial driver.
  Format : "StrFmt"
  Oled : "OledCommonMethods"
   
PUB Setup(parameter0, parameter1) '| cncCog

  Pst.Start(115_200) ' Only call Start method from top object.
 
  repeat
    result := Pst.RxCount
    Pst.str(string(11, 13, "Press any key to continue starting program."))
    waitcnt(clkfreq / 2 + cnt)
  until result
  Pst.RxFlush
        
  oledStackPtr := Oled.Start

  oledBufferPtr := Oled.GetOledBuffer

  D
  Pst.str(string(11, 13, "Helper object started."))
  C

  waitcnt(clkfreq * 2 + cnt)


  result := 0

  D
  Pst.str(string(11, 13, "Parent waiting for press."))
  Oled.PressToContinueC
   
  MainLoop


PUB MainLoop | localIndex, localBuffer[5]

  
  D
  Pst.str(string(11, 13, "Before PAUSE_MONITOR_OLED waiting for press."))
  Oled.PressToContinueC
  Oled.SetOled(Header#PAUSE_MONITOR_OLED, 0, 0, 0)
  
  repeat
    {D
    Pst.str(string(11, 13, "Before writing 255 to first byte in buffer waiting for press."))
    Oled.PressToContinueC
    byte[oledBufferPtr] := 255
    D
    Pst.str(string(11, 13, "Before UpdateDispaly waiting for press."))
    Oled.PressToContinueC
    Oled.UpdateDisplay
    D
    Pst.str(string(11, 13, "Top of loop waiting for press."))
    Oled.PressToContinueC
    
    Oled.StopScroll
    Oled.ResetVerticalScroll
    Oled.SetOled(Header#PAUSE_MONITOR_OLED, 0, 0, 0)
    repeat localIndex from 0 to 16
      D
      Pst.str(string(11, 13, "Before writing 255 to first byte in buffer waiting for press."))
      Oled.PressToContinueC
      byte[oledBufferPtr] := 255
      D
      Pst.str(string(11, 13, "Before UpdateDispaly waiting for press."))     
      Oled.PressToContinueC
      Oled.UpdateDisplay
      D
      Pst.str(string(11, 13, "Before horizontal line waiting for press."))
      Oled.PressToContinueC
      Oled.Line(10, localIndex * 8, 117, localIndex * 8, 1)
      D
      Pst.str(string(11, 13, "Before UpdateDispaly waiting for press."))     
      Oled.PressToContinueC
      Oled.UpdateDisplay
      D
      Pst.str(string(11, 13, "Before ScrollString waiting for press."))
      Oled.PressToContinueC
      result := Format.Str(@localBuffer, string("line # "))
      result := Format.Dec(result, localIndex)
      byte[result] := 0
      Oled.ScrollString(@localBuffer, 1)
      D
      Pst.str(string(11, 13, "Before writing 255 to first byte in buffer waiting for press."))
      Oled.PressToContinueC
      byte[oledBufferPtr] := 255
      D
      Pst.str(string(11, 13, "Before UpdateDispaly waiting for press."))     
      Oled.PressToContinueC
      Oled.UpdateDisplay
      D
      Pst.str(string(11, 13, "Before StopScroll waiting for press."))
      Oled.PressToContinueC
      Oled.StopScroll
      D
      Pst.str(string(11, 13, "Before vertical line waiting for press."))
      Oled.PressToContinueC
      Oled.Line(localIndex * 8, 10, localIndex * 8, 53, 1)
      D
      Pst.str(string(11, 13, "After vertical line waiting for press."))
      Oled.PressToContinueC    }
      
    'GenerateDemoNumbers
    'Oled.StopScroll
    Oled.SetOled(Header#PAUSE_MONITOR_OLED, 0, 0, 0)
    'Oled.InitDisplay
    D
    Pst.str(string(11, 13, "Before BuildN(32, 3, 3) waiting for press."))
    Oled.PressToContinueC 
    BuildN(32, 3, 3)
    D
    Pst.str(string(11, 13, "Before UpdateDisplay waiting for press."))
    Oled.PressToContinueC 
    Oled.UpdateDisplay

    D
    Pst.str(string(11, 13, "Before BuildN(32, 4, 4) waiting for press."))
    Oled.PressToContinueC 
    BuildN(32, 4, 4)
    D
    Pst.str(string(11, 13, "Before UpdateDisplay waiting for press."))
    Oled.PressToContinueC 
    Oled.UpdateDisplay

    D
    Pst.str(string(11, 13, "Before BuildN(64, 6, 6) waiting for press."))
    Oled.PressToContinueC 
    BuildN(64, 6, 6)
    D
    Pst.str(string(11, 13, "Before UpdateDisplay waiting for press."))
    Oled.PressToContinueC 
    Oled.UpdateDisplay

    'EnterData
    D
    Pst.str(string(11, 13, "Before MAIN_LOGO_OLED waiting for press."))
    Oled.PressToContinueC 

    Oled.ReleaseIo
    
    Oled.SetOled(Header#MAIN_LOGO_OLED, 0, 0, 0)
    Oled.PressToContinue
   
PRI DebugStack 


  Pst.Home
  Pst.ClearEnd
  Pst.NewLine
   
  measuredStack := CheckStack(oledStackPtr, Header#MONITOR_OLED_STACK_SIZE, measuredStack, Header#STACK_CHECK_LONG)
  Pst.Str(string(" The OLED cog has so far used "))
  Pst.Dec(measuredStack)
  Pst.Str(string(" of the "))
  Pst.Dec(Header#MONITOR_OLED_STACK_SIZE)
  Pst.Str(string(" longs originally set aside for it."))
  Pst.ClearEnd
  Pst.NewLine
         
  
PRI CheckStack(localPtr, localSize, previousSize, fillLong)
'' Find the highest none zero long in the section
'' of RAM "localSize" longs in size and starting
'' at "localPtr". The return value will be at
'' least the size of "previousSize" and will only
'' be larger if a non-zero long is found at a higher
'' memory location than in previous calls to
'' the method.

  localSize--
  previousSize--
  repeat result from 0 to localSize
    if long[localPtr][result] <> fillLong
      if result > previousSize
        previousSize := result
  result := ++previousSize

PUB GenerateDemoNumbers | localIndex, joyX, joyY, joyZ, pot1, pot2, pot3
  L
  Pst.Str(string(11, 13, "GenerateDemoNumbers Method"))
  C
 
  oledPtr[3] := 0 '$80_00_00_00
  oledPtr[4] := @pot1

  oledPtr[5] := @pot2
  oledPtr[6] := @pot3
  oledPtr[0] := @joyX
  oledPtr[1] := @joyY
  oledPtr[2] := @joyZ
  oledPtr[7] := @timer
                        
  timer := 9999
  Oled.SetOled(Header#AXES_READOUT_OLED, @joystickLabels, @oledPtr, 8)

  Oled.StopScroll
  
  repeat 200

    joyX := AddWithLimit(joyX, 1, -999, 9999)
    joyY := AddWithLimit(joyY, 2, -999, 9999)
    joyZ := AddWithLimit(joyZ, 3, -999, 9999)
    pot1 := AddWithLimit(pot1, -2, -999, 9999)
    pot2 := AddWithLimit(pot2, -3, -999, 9999)
    pot3 := AddWithLimit(pot3, -4, -999, 9999)
    timer := AddWithLimit(timer, -1, 0, 9999)
    'Oled.UpdateDisplay
   
  
      
    'temp := Oled.SetInvert(invertPos[0], invertPos[1], invertPos[0] + invertSize, invertPos[1] + invertSize)
    'temp := Oled.SetInvert(invertPos[0], invertPos[1], invertPos[0] + invertSize, invertPos[1] + invertSize)
               
    waitcnt(clkfreq / 10 + cnt)
  'while result

  L
  Pst.Str(string(11, 13, "End of GenerateDemoNumbers Method"))
  C
  
  Oled.InvertOff
  waitcnt(clkfreq / 10 + cnt)
  
  Oled.SetOled(Header#DEMO_OLED, @xyzLabels, @oledPtr, 4) 
  waitcnt(clkfreq * 2 + cnt)

PUB AddWithLimit(startValue, valueToAdd, lowerLimit, upperLimit)

  result := startValue + valueToAdd

  if result < lowerLimit
    result := upperLimit
  elseif result > upperLimit
    result := lowerLimit

PUB EnterData | localIndex, joyX, joyY, joyZ, pot1, pot2, pot3, localTime, highlightedLine, {
} temp, partialNumberFlag, negativeFlag, activePtr, buttonFlag
  L
  Pst.Str(string(11, 13, "EnterData Method"))
  C
  
  EnterDataHeading
  
  highlightedLine := 0
  partialNumberFlag := 0
  negativeFlag := 0
  buttonFlag := 0
  
  oledPtr[3] := 0 '$80_00_00_00
  oledPtr[4] := @pot1

  oledPtr[5] := @pot2
  oledPtr[6] := @pot3
  oledPtr[0] := @joyX
  oledPtr[1] := @joyY
  oledPtr[2] := @joyZ
  oledPtr[7] := @timer
                        
  timer := 0
  localTime := cnt
  
  Oled.SetOled(Header#AXES_READOUT_OLED, @joystickLabels, @oledPtr, 8)

  'Oled.StopScroll
  temp := Oled.SetInvert(0, highlightedLine * 8, 128, highlightedLine * 8 + 7)
  repeat 

    if cnt - localTime > clkfreq
      timer := AddWithLimit(timer, 1, 0, 9999)
      localTime += clkfreq
      
    
    'Oled.UpdateDisplay
      
    'temp := Oled.SetInvert(0, highlightedLine * 8, 128, highlightedLine * 8 + 7)
  
    result := Pst.RxCount
    if result
      result := Pst.CharIn
      case result
        "w":
          'temp := Oled.SetInvert(0, highlightedLine * 8, 128, highlightedLine * 8 + 7)
          highlightedLine := AddWithLimit(highlightedLine, -1, 0, 7)
          'temp := Oled.SetInvert(0, highlightedLine * 8, 128, highlightedLine * 8 + 7)
          if partialNumberFlag and negativeFlag
            -long[activePtr]
          partialNumberFlag := 0
          negativeFlag := 0
          
        "s":
          highlightedLine := AddWithLimit(highlightedLine, 1, 0, 7)
          if partialNumberFlag and negativeFlag
            -long[activePtr]
          partialNumberFlag := 0
          negativeFlag := 0
          
        "x":
          if partialNumberFlag and negativeFlag
            -long[activePtr]
          partialNumberFlag := 0
          negativeFlag := 0
          quit
          
        "0".."9", "-":
          if partialNumberFlag
            case result
              "-":
                negativeFlag := 1

          else
            case highlightedLine
              3:
                L
                Pst.Str(string(11, 13, "button is now o"))
                case buttonFlag
                  0:
                    buttonLabel[onOffPosition] := "n"  ' on
                    buttonLabel[onOffPosition + 1] := " "
                    Pst.Str(string("n "))
                  other:
                    buttonLabel[onOffPosition] := "f"  ' off
                    buttonLabel[onOffPosition + 1] := "f"
                    Pst.Str(string("ff"))
                !buttonFlag
              7:
                if result == "0"
                  timer := 0
                  localTime := cnt
                  Pst.Str(string(11, 13, "Timer zeroed."))
                else
                  Pst.Str(string(11, 13, "Press ", QUOTE, "0", QUOTE, " to zero timer."))  
              other:
              
                activePtr := oledPtr[highlightedLine]
                partialNumberFlag := 1

                case result
                  "-":
                    long[activePtr] := 0
                    negativeFlag := 1
                  other:
                    long[activePtr] := result - "0"

        other:
          Pst.Str(string(11, 13, "Not a valid input."))
          EnterDataHeading
      temp := Oled.SetInvert(0, highlightedLine * 8, 128, highlightedLine * 8 + 7)
          
PRI EnterDataHeading

  L
  Pst.Str(string(11, 13, "Use ", QUOTE, "s", QUOTE, " and ", QUOTE, "w", QUOTE, " to highlight value to change."))
  Pst.Str(string(11, 13, "Type a numbers followed by enter to change values of highlighted field."))
  Pst.Str(string(11, 13, "Press ", QUOTE, "x", QUOTE, " to exit."))
  C
          
PUB L

  Oled.L

PUB C

  Oled.C
  
PUB D 'ebugCog
'' display cog ID at the beginning of debug statements

  Oled.D

PUB DHome

  L
  Pst.Char(11)
  Pst.Char(13)
  Pst.Home
  Pst.Dec(cogid)
  Pst.Char(":")
  Pst.Char(32)

PUB BuildN(pixelsSide, fromCenterUp, fromCenterDown) | columnes, rows, maxIndex, row, {
} center, beforeCenter, afterCenter

  rows := (pixelsSide + 7) / 8
  maxIndex := pixelsSide - 1

  center := pixelsSide / 2
  beforeCenter := center - fromCenterUp
  afterCenter := center + fromCenterDown
  
  Oled.ClearDisplay
  D
  Pst.Str(string("BuildN Method"))

  
  repeat row from 0 to maxIndex
  
    Pst.Str(string(11, 13, "row = "))
    Pst.Dec(row)
   
    if row =< beforeCenter
      Pst.Str(string(", center band still starts on left edge, from 0 to "))
      Pst.Dec(beforeCenter + row)
      Oled.Line(0, row, beforeCenter + row, row, 1)
    elseif row > beforeCenter and row =< afterCenter
      Pst.Str(string(", gap in design on left edge, center band doesn't start until "))
      Pst.Dec(row - beforeCenter)
      Pst.Str(string(" and ends "))
      
      if beforeCenter + row =< maxIndex
        Oled.Line(row - beforeCenter, row, beforeCenter + row, row, 1)
        Pst.Str(string(" before far right at "))
        Pst.Dec(beforeCenter + row)
      else  
        Oled.Line(row - beforeCenter, row, maxIndex, row, 1)
        Pst.Str(string(" at far right edge"))
        
    else ' row > afterCenter
      Pst.Str(string(", bottom triangle area ends at"))
      Pst.Dec(row - afterCenter)
      Pst.Str(string(" center stripe begins at "))
      Pst.Dec(row - beforeCenter)
      Pst.Str(string(" and ends "))
      Oled.Line(0, row, row - afterCenter, row, 1)
      if beforeCenter + row =< maxIndex ' middle stops early 
        Oled.Line(row - beforeCenter, row, beforeCenter + row, row, 1)
        Pst.Str(string(" before far right at "))
        Pst.Dec(beforeCenter + row)
      else    ' middle goes to end
        Oled.Line(row - beforeCenter, row, maxIndex, row, 1)
        Pst.Str(string(" at far right edge"))
    if afterCenter + row =< maxIndex
      Pst.Str(string(", top right triangle area begins at"))
      Pst.Dec(afterCenter + row)
      Oled.Line(afterCenter + row, row, maxIndex, row, 1)
   
  C  
PUB BuildNOld(pixelsSide, fromCenterUp, fromCenterDown) | columnes, rows, maxIndex, row

  rows := (pixelsSide + 7) / 8
  maxIndex := rows - 1
  D
  Pst.Str(string("BuildN Method oledBufferPtr = "))
  Pst.Dec(oledBufferPtr)
  C
  
  repeat row from 0 to maxIndex
    longfill(oledBufferPtr + (row * Header#OLED_WIDTH), $FF, rows * 8)
    
    
DAT

pauseInterval           long 40
minDelay                long 100 'US_001 * 1_000
maxDelay                long 10_000 'US_001 * 20_000
'cncName                 byte "CNA_0000.TXT", 0  ' Use all caps in file names or SD driver wont find them.


{programNames            byte "INIT_MAIN", 0
                        byte "DESIGN_INPUT_MAIN", 0
                        byte "DESIGN_REVIEW_MAIN", 0
                        byte "DESIGN_READ_MAIN", 0
                        byte "MANUAL_JOYSTICK_MAIN", 0
                        byte "MANUAL_NUNCHUCK_MAIN", 0
                        byte "MANUAL_POTS_MAIN", 0 } 
                          
DAT
{
unitsText               byte "steps", 0
                        byte "turns", 0
                        byte "inches", 0
                        byte "millimeters", 0

unitsTxt                byte "steps", 0
                        byte "turns", 0
                        byte "in", 0
                        byte "mm", 0

axesText                byte "X_AXIS", 0
                        byte "Y_AXIS", 0
                        byte "Z_AXIS", 0
                        byte "DESIGN_AXIS", 0   }

{machineStateTxt         byte "INIT_STATE", 0
                        byte "DESIGN_INPUT_STATE", 0
                        byte "DESIGN_REVIEW_STATE", 0
                        byte "DESIGN_READ_STATE", 0
                        byte "MANUAL_JOYSTICK_STATE", 0
                        byte "MANUAL_NUNCHUCK_STATE", 0
                        byte "MANUAL_POTS_STATE", 0   }


xyzLabels               byte "x = ", 0
yLabel                  byte "y = ", 0
zLabel                  byte "z = ", 0
                        byte "timer = ", 0

adcLabels               byte "ADC X = ", 0
                        byte "ADC Y = ", 0
                        byte "ADC Z = ", 0
                        byte "Timer = ", 0
                        
joystickLabels          byte "Joy X = ", 0
                        byte "Joy Y = ", 0
                        byte "Joy Z = ", 0
                             '012345678
buttonLabel             byte "Button off", 0
                        byte "Pot 1 = ", 0
                        byte "Pot 2 = ", 0
                        byte "Pot 3 = ", 0
                        byte "Timer = ", 0
                        
onOffPosition           byte 8
{                        
oledMenuLimit           byte 3
oledMenuHighlightRange  byte 1, 2                             
                         
                             '0123456789012345
oledMenu                byte "Highlight&Select", 0
                        byte " Select Design", 0
                        byte " Return to Top", 0

{oledMenu                byte "Highlight&Select", 0
                        byte "  enter design", 0
                        byte "display design", 0
                        byte "execute design", 0
                        byte "   joystick", 0
                        byte "   nunchuck", 0
                        byte " poteniometers", 0
                        byte " home machine", 0
}                       
                             '0123456789012345
selectFileTxt           byte "  Select File", 0
cncNumber               byte " CNC # ", 0
                        byte " CNC # ", 0
                        byte " CNC # ", 0
                        byte " CNC # ", 0
                        byte " CNC # ", 0
                        byte " CNC # ", 0
                        byte " CNC # ", 0
                        
homedText               byte "Machine Homed", 0
endText                 byte "End of Program", 0
                             '0123456789012345
errorButContinueText    byte "Error Continuing", 0
                        byte "  with Program", 0

expectedCharText        byte "CODE_TYPE_CHAR", 0
                        byte "CODE_VALUE_CHAR", 0
                        byte "PARAMETER_VALUE_CHAR", 0
                        byte "STRING_CHAR", 0
                        byte "COMMENT_CHAR", 0

gCodeText               byte "RAPID_POSITION_G", 0
                        byte "LINEAR_G", 0
                        byte "CIRCULAR_CW_G", 0
                        byte "CIRCULAR_CCW_G", 0
                        byte "DWELL_G", 0
                        byte "5", 0
                        byte "6", 0
                        byte "7", 0
                        byte "8", 0
                        byte "9", 0
                        byte "10", 0
                        byte "#11", 0
                        byte "FULL_CIRCLE_CW_G", 0
                        byte "FULL_CIRCLE_CCW_G", 0
                        byte "14", 0
                        byte "15", 0
                        byte "16", 0
                        byte "17", 0
                        byte "18", 0
                        byte "#19", 0
                        byte "INCHES_G", 0
                        byte "MILLIMETERS_G", 0
                        byte "22", 0
                        byte "23", 0
                        byte "24", 0
                        byte "25", 0
                        byte "26", 0
                        byte "#27", 0
                        byte "HOME_G", 0
                        byte "#29", 0
                        byte "SECONDARY_HOME_G", 0
                        byte "31", 0
                        byte "32", 0
                        byte "33", 0
                        byte "34", 0
                        byte "35", 0
                        byte "36", 0
                        byte "37", 0
                        byte "38", 0
                        byte "#39", 0
                        byte "TOOL_RADIUS_COMP_OFF_G", 0
                        byte "TOOL_RADIUS_COMP_LEFT_G", 0
                        byte "TOOL_RADIUS_COMP_RIGHT_G", 0
                        byte "TOOL_HEIGHT_COMP_NEGATIVE_G", 0
                        byte "TOOL_HEIGHT_COMP_POSITIVE_G", 0
                        byte "TOOL_HEIGHT_COMP_OFF_G", 0
                        byte "46", 0
                        byte "47", 0
                        byte "48", 0
                        byte "49", 0
                        byte "50", 0
                        byte "#51", 0
                        byte "LOCAL_SYSTEM_G", 0
                        byte "MACHINE_SYSTEM_G", 0
                        byte "WORK_SYSTEM_G", 0  

mCodeText               byte "COMPULSORY_STOP_M", 0
                        byte "OPTIONAL_STOP_M", 0
                        byte "END_OF_PROGRAM_M", 0
                        byte "SPINDLE_ON_CCW_M", 0
                        byte "04", 0
                        byte "SPINDLE_STOP_M", 0
  
dCodeText               byte "POINT_D", 0
                        byte "START_D", 0
                        byte "PART_VERSION_D", 0
                        byte "PART_NAME_D", 0
                        byte "PARTS_IN_FILE_D", 0
                        byte "DATE_CREATED_D", 0
                        byte "DATE_MODIFIED_D", 0
                        byte "PROGRAM_NAME_D", 0
                        byte "EXTERNALLY_CREATED_D", 0
                        byte "CREATED_USING_PROGRAM_D", 0
                        byte "AUTHOR_NAME_D", 0
                        byte "PROJECT_NAME_D", 0
                        byte "TOOL_RADIUS_UNITS_D", 0
                        
commentFromFile         byte 0[MAX_COMMENT_CHARACTERS + 1]    }
                                           
'                        long
{DAT accelerationTable   'long 0[MAX_ACCEL_TABLE]
'slowaccelTable          long 0[MAX_ACCEL_TABLE]

buffer0X                long 0[Header#HUB_BUFFER_SIZE]
buffer1X                long 0[Header#HUB_BUFFER_SIZE]
buffer0Y                long 0[Header#HUB_BUFFER_SIZE]
buffer1Y                long 0[Header#HUB_BUFFER_SIZE]
buffer0Z                long 0[Header#HUB_BUFFER_SIZE]
buffer1Z                long 0[Header#HUB_BUFFER_SIZE]
extra                   long 0[Header#MAX_ACCEL_TABLE - (6 * Header#HUB_BUFFER_SIZE)]
 }
DAT
{propBeanie    byte $04, $0E, $0E, $0E, $0E, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $04, $04, $04, $F4
              byte $F4, $04, $04, $04, $2, $06, $06, $06, $06, $06, $06, $07, $0F, $0E, $0E, $04
              byte $00, $00, $00, $80, $E0, $F0, $F8, $1C, $0E, $02, $01, $00, $00, $F8, $FF, $FF
              byte $FF, $FF, $FC, $00, $00, $01, $03, $06, $1C, $F8, $F0, $E0, $80, $00, $00, $00
              byte $00, $00, $7C, $5F, $9F, $9F, $80, $88, $88, $88, $08, $08, $0E, $0F, $0F, $0F
              byte $0F, $0F, $0F, $0F, $08, $08, $88, $88, $88, $80, $9F, $9F, $5F, $7C, $00, $00
              byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01
              byte $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    }