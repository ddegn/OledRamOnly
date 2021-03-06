DAT objectName          byte "HeaderOled", 0
CON{
  ****** Private Notes ******

}
CON                  

  CLK_FREQ = 80_000_000
  MS_001 = CLK_FREQ / 1000

CON '' QuickStart CNC

  'SHIFT_CLOCK = 10'' Used for ClockPin mask
  'SHIFT_MOSI = 11
  'SHIFT_MISO = 0

  'ADC_DATA = 1 '12
  
  'LATCH_165_PIN = 13
  'LATCH_595_PIN = 14
  
  SPI_CLOCK = 23 '15

  SPI_MOSI = 22
  SPI_MISO = 15 '23
{  DOPIN = 24    ' SD Card Data OUT
  ClKPIN = 25    ' SD Card Clock
  DIPIN = 26    ' SD Card Data IN
  CSPIN = 27    ' SD Card Chip Select
  I2CBASE = 28    ' Wii Nunchuck      }

  CS_OLED_PIN = 20
  DC_OLED_PIN = 16
  RESET_OLED_PIN = 18
  
  DEBUG_TX_PIN = 30
  DEBUG_RX_PIN = 31


  DEFAULT_MAX_DIGITS = 4


CON ' CNC Pins

  TERMINAL_BAUD = 115_200

  DEBUG_SPI_VARIABLES = 16
  DEBUG_SPI_BYTES = DEBUG_PASM_VARIABLES * 4
  MAX_DEBUG_SPI_INDEX = DEBUG_SPI_VARIABLES - 1
  
  DEBUG_PASM_VARIABLES = 6
  DEBUG_PASM_BYTES = DEBUG_PASM_VARIABLES * 4

  COMMAND_VARIABLES = 3
  COMMAND_BYTES = COMMAND_VARIABLES * 4
  
  #0, IDLE_COMMAND, MOVE_COMMAND, HOLD_POSITION_COMMAND
      SPEED_COMMAND, SET_POSITION_COMMAND
      BRAKE_COMMAND, RELEASE_BRAKE_COMMAND
    
      
  #0, IDLE_SPI, OLED_WRITE_ONE_SPI, OLED_WRITE_BUFFER_SPI
   
  HUB_BUFFER_SIZE = 100
 

  NUMBER_OF_BUFFERS = 2
 
  NUMBER_OF_SD_INSTANCES = 2 'NUMBER_OF_AXES + 1

  ' SD instances
  #0, CNC_DATA_SD, OLED_DATA_SD

CON 'oledFileType enumeration
  #0, NO_ACTIVE_OLED_TYPE, FONT_OLED_TYPE, GRAPHICS_OLED_TYPE

  ' fontFile enumeration
  #0, _5_x_7_FONT', FREE_DESIGN_FONT, SIMPLYTROINICS_FONT

 #0, INIT_STATE, DESIGN_INPUT_STATE, DESIGN_REVIEW_STATE, DESIGN_READ_STATE
     MANUAL_JOYSTICK_STATE, MANUAL_NUNCHUCK_STATE, MANUAL_POTS_STATE
      
  DEFAULT_MACHINE_STATE = INIT_STATE

  MAX_NAME_SIZE = PROGRAM_NAME_LIMIT


  SCALED_MULTIPLIER = 1000


  MENU_DISPLAY_TIME = 10        ' in seconds

  PSEUDO_MULTIPLIER = 1000

  WP_SD_PIN = -1          
  CD_SD_PIN = -1           
  RTC_PIN_1 = -1                 ' Pins that would have been used by real time clock.
  RTC_PIN_2 = -1
  RTC_PIN_3 = -1
  
    ' sdFlag enumeration
  #0, NOT_FOUND_SD, IN_USE_SD, INITIALIZING_SD, NEW_LOG_CREATED_SD, DESIGN_FILE_FOUND_SD, NO_DESIGN_FILE_YET_SD, IN_USE_BY_OTHER_DEVICE_SD
                   
  #0, READ_FILE_SUCCESS, FILE_NOT_FOUND, READ_FILE_ERROR_OTHER
  
  MAX_FILE_NUMBER = 9999
  PROGRAM_VERSION_CHARACTERS = 7
  VERSION_CHARACTER_TO_USE = 3
  VERSION_LOC_IN_LOG_NAME = 1
  NUMBER_LOC_IN_FILE_NAME = 4     

  ' offset from command
  #0, COMMAND_OFFSET, STEPS_OR_SPEED_OFFSET, POSITION_FROM_PASM_OFFSET, POSITION_TO_PASM_OFFSET
      

  MAX_OFFSET_INDEX = POSITION_TO_PASM_OFFSET
  NUMBER_OF_OFFSETS = MAX_OFFSET_INDEX + 1
 
CON ' Shared Constants

  DEBUG_BAUD = 115_200
  PROGRAM_NAME_LIMIT = 16

  ' wait enumeration
  #0, NO_WAIT, YES_WAIT

CON ' Configuration Constants

  ' Main Program Settings
  #0, INIT_MAIN, DESIGN_INPUT_MAIN, DESIGN_REVIEW_MAIN, DESIGN_READ_MAIN
      MANUAL_JOYSTICK_MAIN, MANUAL_NUNCHUCK_MAIN, MANUAL_POTS_MAIN  

  ' Homed State
 ' #0, UNKNOWN_POSITION, HOMED_POSITION, SET_HOME_POSITION

  ' programState
  #0, FRESH_PROGRAM, ACTIVE_PROGRAM, TRANSITIONING_PROGRAM, SHUTDOWN_PROGRAM


  ' fileIndex enumeration
  #0, CNC_DATA_FILE, CONFIG_FILE, SERIAL_FILE, MOTOR_FILE
  
  ' bitmap enumeration
  #0, BEANIE_SMALL_BITMAP, BEANIE_LARGE_BITMAP, ADAFRUIT_BITMAP
      LMR_SMALL_BITMAP, LMR_LARGE_BITMAP

  MAX_BITMAP_INDEX = LMR_LARGE_BITMAP
  NUMBER_OF_BITMAPS = MAX_BITMAP_INDEX + 1

  ' sub program enumeration  update "stateToSubIndex" if this list is changed
  #0, DESIGN_ENTRY_SUB, INSPECT_DESIGN_SUB, MANUAL_CONTROL_SUB
      NUNCHUCK_CONTROL_SUB, TEST_LINE_SUB

  MAX_SUB_PROGRAM_INDEX = TEST_LINE_SUB
  NUMBER_OF_SUB_PROGRAMS = MAX_SUB_PROGRAM_INDEX + 1

  NO_SUB_PROGRAM = 255

  OLED_BUFFER_SIZE = 1024

  OLED_WIDTH = 128
  OLED_HEIGHT = 64
  OLED_LINES = 8
  
  ' oledState enumeration
  #0, DEMO_OLED, MAIN_LOGO_OLED, AXES_READOUT_OLED, BITMAP_OLED, GRAPH_OLED
      PAUSE_MONITOR_OLED, CLEAR_OLED

  MIN_OLED_X = 0
  MAX_OLED_X = OLED_WIDTH - 1
  MIN_OLED_Y = 0
  MAX_OLED_Y = OLED_HEIGHT - 1
  MIN_OLED_INVERTED_SIZE_X = 2
  MIN_OLED_INVERTED_SIZE_Y = 8

  MAX_OLED_DATA_LINES = OLED_LINES
  MAX_OLED_LINE_INDEX = MAX_OLED_DATA_LINES - 1
  MAX_OLED_CHAR_COL = OLED_WIDTH / 8
  MAX_OLED_CHAR_COL_INDEX = MAX_OLED_CHAR_COL
  
  MAX_DATA_FILES = 40
  PRE_ID_CHARACTERS = 4
  ID_CHARACTERS = 4
  POST_ID_CHARACTERS = 4
  
  DEFAULT_DEADBAND = 4095 / 20
  DEFAULT_CENTER = 4095 / 2

  STACK_CHECK_LONG = $55_AA_A5_5A
  MONITOR_OLED_STACK_SIZE = 140 ' really 126 '175

  SERIAL_PASM_IMAGE = 452
  MOTOR_PASM_IMAGE = 414   
  MAX_PASM_IMAGE = SERIAL_PASM_IMAGE 

  RX_BUFFER = 16
  TX_BUFFER = 64

  TOTAL_SERIAL_BUFFERS = RX_BUFFER + TX_BUFFER
  
CON 'DRV8711 Constants

 { CTRL_REG   = 0

  {DRV8711CTL_DEADTIME_400ns = $000
  DRV8711CTL_DEADTIME_450ns = $400
  DRV8711CTL_DEADTIME_650ns = $800
  DRV8711CTL_DEADTIME_850ns = $C00

  DRV8711CTL_IGAIN_5        = $000 }
  DRV8711CTL_IGAIN_10       = $100
 { DRV8711CTL_IGAIN_20       = $200
  DRV8711CTL_IGAIN_40       = $300}

  DRV8711CTL_STALL_INTERNAL = $000
 { DRV8711CTL_STALL_EXTERNAL = $080

  DRV8711CTL_STEPMODE_MASK  = $078

  DRV8711CTL_FORCESTEP      = $004
  DRV8711CTL_REV_DIRECTION  = $002}
  DRV8711CTL_ENABLE         = $001
  
  TORQUE_REG = 1
  
  DRV8711TRQ_BEMF_50us      = $000
  {DRV8711TRQ_BEMF_100us     = $100
  DRV8711TRQ_BEMF_200us     = $200
  DRV8711TRQ_BEMF_300us     = $300
  DRV8711TRQ_BEMF_400us     = $400
  DRV8711TRQ_BEMF_600us     = $500
  DRV8711TRQ_BEMF_800us     = $600
  DRV8711TRQ_BEMF_1ms       = $700
  }
  DRV8711TRQ_TORQUE_MASK    = $0FF

  OFF_REG    = 2
  
  DRV8711OFF_STEPMOTOR      = $000
  {DRV8711OFF_DUALMOTORS     = $100
  }
  DRV8711OFF_OFFTIME_MASK   = $0FF
  
  BLANK_REG  = 3
  
  DRV8711BLNK_ADAPTIVE_BLANK = $100
  DRV8711BLNK_BLANKTIME_MASK = $0FF
 
  DECAY_REG  = 4
  {
  DRV8711DEC_SLOW_DECAY     = $000
  DRV8711DEC_SLOW_MIXED     = $100
  DRV8711DEC_FAST_DECAY     = $200
  DRV8711DEC_MIXED_DECAY    = $300
  DRV8711DEC_SLOW_AUTOMIX   = $400
  DRV8711DEC_AUTOMIX        = $500 }
  DRV8711DEC_DECAYTIME_MASK = $0FF
  
  STALL_REG  = 5
  {
  DRV8711STL_DIVIDE_32      = $000
  DRV8711STL_DIVIDE_16      = $400 }
  DRV8711STL_DIVIDE_8       = $800
 { DRV8711STL_DIVIDE_4       = $C00 }
  DRV8711STL_STEPS_1        = $000
 { DRV8711STL_STEPS_2        = $100
  DRV8711STL_STEPS_4        = $200
  DRV8711STL_STEPS_8        = $300 }
  DRV8711STL_THRES_MASK     = $0FF
  
  DRIVE_REG  = 6
  {
  DRV8711DRV_HIGH_50mA      = $000
  DRV8711DRV_HIGH_100mA     = $400
  DRV8711DRV_HIGH_150mA     = $800
  DRV8711DRV_HIGH_200mA     = $C00

  DRV8711DRV_LOW_100mA      = $000
  DRV8711DRV_LOW_200mA      = $100
  DRV8711DRV_LOW_300mA      = $200
  DRV8711DRV_LOW_400mA      = $300

  DRV8711DRV_HIGH_250ns     = $000
  DRV8711DRV_HIGH_500ns     = $040
  DRV8711DRV_HIGH_1us       = $080
  DRV8711DRV_HIGH_2us       = $0C0

  DRV8711DRV_LOW_250ns      = $000
  DRV8711DRV_LOW_500ns      = $010
  DRV8711DRV_LOW_1us        = $020
  DRV8711DRV_LOW_2us        = $030}

  DRV8711DRV_OCP_1us        = $000
  {DRV8711DRV_OCP_2us        = $004
  DRV8711DRV_OCP_4us        = $008
  DRV8711DRV_OCP_8us        = $00C}

  DRV8711DRV_OCP_250mV      = $000
  {DRV8711DRV_OCP_500mV      = $001
  DRV8711DRV_OCP_750mV      = $002
  DRV8711DRV_OCP_1000mV     = $003
  }
  STATUS_REG = 7
 
  DRV8711STS_LATCHED_STALL  = $080
  DRV8711STS_STALL          = $040
  DRV8711STS_PREDRIVE_B     = $020
  DRV8711STS_PREDRIVE_A     = $010
  DRV8711STS_UNDERVOLT      = $008
  DRV8711STS_OVERCUR_B      = $004
  DRV8711STS_OVERCUR_A      = $002
  DRV8711STS_OVERTEMP       = $001 }

PUB GetObjectName

  result := @objectName

'PUB GetConfigName

  'result := @configFile   
  
{PUB GetFileName(fileIndex)

  'result := @dataFile
  result := FindString(@dataFile, fileIndex)
  
PUB GetBitmapWidth(bitmapIndex)

  result := bitmapWidth[bitmapIndex]
  
PUB GetBitmapHeight(bitmapIndex)

  result := bitmapHeight[bitmapIndex]
  
PUB GetBitmapName(bitmapIndex)

  result := FindString(@beanieSmallFile, bitmapIndex)
 }
PUB GetFontWidth(fontIndex)

  result := fontWidth[fontIndex]
  
PUB GetFontHeight(fontIndex)

  result := fontHeight[fontIndex]
  
PUB GetFontFirst(fontIndex)

  result := fontFirstChar[fontIndex]
  
PUB GetFontLast(fontIndex)

  result := fontLastChar[fontIndex]
  
{PUB GetFontName(fontIndex)

  result := FindString(@font5x7File, fontIndex)
  }
PUB FindString(firstStr, stringIndex)      
'' Finds start address of one string in a list
'' of string. "firstStr" is the address of 
'' string #0 in the list. "stringIndex"
'' indicates which of the strings in the list
'' the method is to find.

  result := firstStr 
  repeat while stringIndex    
    repeat while byte[result++]  
    stringIndex--
    
PUB TtaMethod(N, X, localD)   ' return X*N/D where all numbers and result are positive =<2^31
  return (N / localD * X) + (binNormal(N//localD, localD, 31) ** (X*2))

PUB BinNormal (y, x, b) : f                  ' calculate f = y/x * 2^b
' b is number of bits
' enter with y,x: {x > y, x < 2^31, y <= 2^31}
' exit with f: f/(2^b) =<  y/x =< (f+1) / (2^b)
' that is, f / 2^b is the closest appoximation to the original fraction for that b.
  repeat b
    y <<= 1
    f <<= 1
    if y => x    '
      y -= x
      f++
  if y << 1 => x    ' Round off. In some cases better without.
      f++

DAT
{
dataFile                byte "CNC_0000.TXT", 0
configFile              byte "CONFIG_0.DAT", 0
serialFile              byte "SERIAL_4.DAT", 0
motorFile               byte "MOTORCNC.DAT", 0

beanieSmallFile         byte "BEANIE_0.DAT", 0 
beanieLargeFile         byte "BEANIE_1.DAT", 0
adafruitSplashFile      byte "ADAFRUIT.DAT", 0
lmrSmallFile            byte "LMRSMALL.DAT", 0
lmrLargeFile            byte "LMR_BIG0.DAT", 0
}
bitmapWidth             byte 32, 64, 128, 32, 64
bitmapHeight            byte 32, 64, 64, 32, 64

{font5x7File             byte "FONT_5X7.DAT", 0
freeDesignFile          byte "FREEDESI.DAT", 0
simplyTronicsFile       byte "SIMPLYTR.DAT", 0 }

fontWidth               byte 8, 8, 8
fontHeight              byte 8, 8, 8
fontFirstChar           byte 0, 32, 32
fontLastChar            byte 126, 126, 126  