#ifndef PAZ_CONSTANTS_MQH
#define PAZ_CONSTANTS_MQH

//--- Zone type
enum ENUM_ZONE_TYPE
  {
   ZONE_DEMAND,
   ZONE_SUPPLY
  };

//--- Zone state
enum ENUM_ZONE_STATE
  {
   ZONE_ACTIVE,
   ZONE_MITIGATED,
   ZONE_FADED
  };

//--- Trend direction
enum ENUM_TREND_DIR
  {
   TREND_BULLISH,
   TREND_BEARISH,
   TREND_RANGING
  };

//--- Swing type
enum ENUM_SWING_TYPE
  {
   SWING_HIGH,
   SWING_LOW
  };

//--- Swing label
enum ENUM_SWING_LABEL
  {
   SWING_HH,
   SWING_HL,
   SWING_LH,
   SWING_LL,
   SWING_NONE
  };

//--- Structure break
enum ENUM_STRUCTURE_BREAK
  {
   BREAK_NONE,
   BREAK_BOS_BULL,
   BREAK_BOS_BEAR,
   BREAK_CHOCH_BULL,
   BREAK_CHOCH_BEAR
  };

//--- Candle pattern
enum ENUM_CANDLE_PATTERN
  {
   PATTERN_NONE,
   PATTERN_BULLISH_ENGULFING,
   PATTERN_BEARISH_ENGULFING,
   PATTERN_HAMMER,
   PATTERN_SHOOTING_STAR,
   PATTERN_MORNING_STAR,
   PATTERN_EVENING_STAR,
   PATTERN_BULLISH_INSIDE_BAR,
   PATTERN_BEARISH_INSIDE_BAR,
   PATTERN_THREE_WHITE_SOLDIERS,
   PATTERN_THREE_BLACK_CROWS,
   PATTERN_DOJI_AT_LEVEL,
   PATTERN_TWEEZER_TOP,
   PATTERN_TWEEZER_BOTTOM
  };

//--- Entry type
enum ENUM_ENTRY_TYPE
  {
   ENTRY_NONE,
   ENTRY_ZONE_TAP,
   ENTRY_BREAKOUT_RETEST,
   ENTRY_DOUBLE_TOP,
   ENTRY_DOUBLE_BOTTOM
  };

//--- Entry direction
enum ENUM_ENTRY_DIR
  {
   ENTRY_BUY,
   ENTRY_SELL
  };

//--- Trendline state
enum ENUM_TRENDLINE_STATE
  {
   TL_ACTIVE,
   TL_BROKEN,
   TL_RETESTING
  };

//--- Color constants
const color CLR_DEMAND_ACTIVE    = C'70,130,180';
const color CLR_SUPPLY_ACTIVE    = C'205,92,92';
const color CLR_DEMAND_MITIGATED = C'47,79,79';
const color CLR_SUPPLY_MITIGATED = C'139,0,0';
const color CLR_DEMAND_REFINED   = C'0,191,255';
const color CLR_SUPPLY_REFINED   = C'250,128,114';
const color CLR_BOS_BULL         = C'30,144,255';
const color CLR_BOS_BEAR         = C'255,127,80';
const color CLR_CHOCH            = C'255,215,0';
const color CLR_TRENDLINE        = C'192,192,192';
const color CLR_TRENDLINE_STEEP  = C'105,105,105';
const color CLR_SL               = C'255,99,71';
const color CLR_TP               = C'60,179,113';
const color CLR_LIQUIDITY_SWEEP  = C'255,0,255';
const color CLR_EQUAL_HL         = C'255,165,0';
const color CLR_PATTERN_BULL     = C'0,191,255';
const color CLR_PATTERN_BEAR     = C'250,128,114';
const color CLR_CONFIRMATION     = C'50,205,50';
const color CLR_KEY_LEVEL        = C'255,255,255';
const color CLR_ENTRY_BUY        = C'0,255,0';
const color CLR_ENTRY_SELL       = C'255,0,0';
const color CLR_DASH_BG          = C'26,26,26';
const color CLR_DASH_TEXT        = C'211,211,211';

//--- Timeframe list
const ENUM_TIMEFRAMES TF_LIST[] = {PERIOD_D1, PERIOD_H4, PERIOD_H1, PERIOD_M15};
const int             TF_COUNT  = 4;

//--- Object name prefix
const string OBJ_PREFIX = "PAZ_";

#endif // PAZ_CONSTANTS_MQH
