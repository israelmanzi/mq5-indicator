#ifndef PAZ_STRUCTURES_MQH
#define PAZ_STRUCTURES_MQH

#include "Constants.mqh"

//--- Single swing point
struct SwingPoint
  {
   double            price;
   datetime          time;
   int               barIndex;
   ENUM_SWING_TYPE   type;
   ENUM_SWING_LABEL  label;
   ENUM_TIMEFRAMES   tf;
  };

//--- Per-timeframe market structure state
struct StructureState
  {
   ENUM_TREND_DIR    trend;
   SwingPoint        lastSwingHigh;
   SwingPoint        lastSwingLow;
   SwingPoint        swings[];
   int               swingCount;
  };

//--- A single structure break event
struct StructureBreak
  {
   ENUM_STRUCTURE_BREAK breakType;
   double            level;
   datetime          time;
   int               barIndex;
   ENUM_TIMEFRAMES   tf;
  };

//--- Supply / demand zone
struct PriceZone
  {
   double            upper;
   double            lower;
   datetime          timeCreated;
   datetime          timeMitigated;
   int               barCreated;
   ENUM_TIMEFRAMES   tf;
   ENUM_ZONE_TYPE    zoneType;
   ENUM_ZONE_STATE   state;
   int               touchCount;
   double            quality;
   bool              causedBOS;
   double            departureStrength;
   int               baseCandleCount;
   bool              hasHTFConfluence;
   double            refinedUpper;
   double            refinedLower;
   string            objName;
  };

//--- Single candle signal
struct CandleSignal
  {
   ENUM_CANDLE_PATTERN pattern;
   double            strength;
   bool              atKeyLevel;
   double            price;
   datetime          time;
   int               barIndex;
   ENUM_TIMEFRAMES   tf;
  };

//--- Liquidity sweep event
struct LiquidityEvent
  {
   double            level;
   double            sweepHigh;
   double            sweepLow;
   datetime          time;
   int               barIndex;
   bool              isBullish;
   ENUM_TIMEFRAMES   tf;
  };

//--- Equal highs / lows level
struct EqualLevel
  {
   double            price;
   int               touchCount;
   datetime          firstTime;
   datetime          lastTime;
   bool              isHighs;
   ENUM_TIMEFRAMES   tf;
  };

//--- Trendline
struct TrendLine
  {
   double            startPrice;
   datetime          startTime;
   double            endPrice;
   datetime          endTime;
   int               touchCount;
   double            angleDegrees;
   bool              isSteep;
   bool              isAscending;
   ENUM_TRENDLINE_STATE state;
   datetime          breakTime;
   ENUM_TIMEFRAMES   tf;
   string            objName;
  };

//--- Key price level (multi-touch, multi-TF)
struct KeyLevel
  {
   double            price;
   int               touchCount;
   int               tfCount;
   bool              isRound;
   ENUM_TIMEFRAMES   primaryTF;
  };

//--- Entry signal
struct EntrySignal
  {
   ENUM_ENTRY_TYPE   entryType;
   ENUM_ENTRY_DIR    direction;
   double            entryPrice;
   double            slPrice;
   double            tpPrice;
   double            rrRatio;
   datetime          signalTime;
   datetime          confirmTime;
   bool              isConfirmed;
   ENUM_CANDLE_PATTERN confirmPattern;
   int               checklistScore;
   string            checklistDetail;
   ENUM_TIMEFRAMES   entryTF;
   int               triggerZoneIdx;   // -1 = none
   string            objNameEntry;
   string            objNameSL;
   string            objNameTP;
  };

//--- Active trade state
struct TradeState
  {
   bool              isActive;
   ENUM_ENTRY_DIR    direction;
   double            entryPrice;
   double            currentSL;
   double            currentTP;
   double            initialSL;
   double            initialTP;
   bool              isBreakeven;
   int               trailingSwings;
   datetime          entryTime;
   string            objNameSL;
   string            objNameTP;
  };

//--- Cached OHLCV data for one timeframe
struct MTFRates
  {
   MqlRates          rates[];
   int               count;
   ENUM_TIMEFRAMES   tf;
   datetime          lastUpdate;
  };

//--- Data snapshot for the on-chart dashboard
struct DashboardData
  {
   ENUM_TREND_DIR    d1Bias;
   ENUM_TREND_DIR    h4Bias;
   ENUM_TREND_DIR    h1Bias;
   int               activeZoneCount;
   int               pendingSetups;
   string            lastBOS;
   string            lastCHoCH;
   string            tradeStatus;
  };

#endif // PAZ_STRUCTURES_MQH
