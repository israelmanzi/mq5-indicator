#ifndef PAZ_CANDLEPATTERNS_MQH
#define PAZ_CANDLEPATTERNS_MQH

#include "Structures.mqh"

//=============================================================================
// Candle helpers
//=============================================================================

double CandleBody(const MqlRates &bar)
  {
   return MathAbs(bar.close - bar.open);
  }

bool IsBullish(const MqlRates &bar)
  {
   return bar.close > bar.open;
  }

bool IsBearish(const MqlRates &bar)
  {
   return bar.close < bar.open;
  }

double UpperWick(const MqlRates &bar)
  {
   return bar.high - MathMax(bar.open, bar.close);
  }

double LowerWick(const MqlRates &bar)
  {
   return MathMin(bar.open, bar.close) - bar.low;
  }

double CandleRange(const MqlRates &bar)
  {
   return bar.high - bar.low;
  }

double AvgBodySize(const MqlRates &rates[], int endIdx, int period)
  {
   if(endIdx < 0 || period <= 0)
      return 0.0;

   double sum   = 0.0;
   int    count = 0;
   int    start = endIdx - period + 1;
   if(start < 0)
      start = 0;

   for(int i = start; i <= endIdx; i++)
     {
      sum += CandleBody(rates[i]);
      count++;
     }

   if(count == 0)
      return 0.0;

   return sum / count;
  }

int PatternStrength(double bodySize, double avgBody)
  {
   if(avgBody <= 0.0)
      return 1;

   double ratio = bodySize / avgBody;
   if(ratio >= 1.5)
      return 3;
   if(ratio >= 1.0)
      return 2;
   return 1;
  }

//=============================================================================
// Key level check
//=============================================================================

bool IsAtKeyLevel(double price,
                  const PriceZone &zones[], int zoneCount,
                  const StructureState &structure,
                  double tolerance)
  {
   // Check against active zones (including refined zones)
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].state == ZONE_MITIGATED || zones[i].state == ZONE_FADED)
         continue;

      // Standard zone bounds
      if(price >= zones[i].lower - tolerance && price <= zones[i].upper + tolerance)
         return true;

      // Refined zone bounds (if defined: refinedUpper != 0)
      if(zones[i].refinedUpper != 0.0 &&
         price >= zones[i].refinedLower - tolerance &&
         price <= zones[i].refinedUpper + tolerance)
         return true;
     }

   // Check against last swing high
   if(structure.lastSwingHigh.price != 0.0 &&
      MathAbs(price - structure.lastSwingHigh.price) <= tolerance)
      return true;

   // Check against last swing low
   if(structure.lastSwingLow.price != 0.0 &&
      MathAbs(price - structure.lastSwingLow.price) <= tolerance)
      return true;

   return false;
  }

//=============================================================================
// Individual pattern detectors
//=============================================================================

bool IsBullishEngulfing(const MqlRates &prev, const MqlRates &curr)
  {
   if(!IsBearish(prev) || !IsBullish(curr))
      return false;
   // curr body must fully engulf prev body
   return curr.open <= prev.close && curr.close >= prev.open;
  }

bool IsBearishEngulfing(const MqlRates &prev, const MqlRates &curr)
  {
   if(!IsBullish(prev) || !IsBearish(curr))
      return false;
   // curr body must fully engulf prev body
   return curr.open >= prev.close && curr.close <= prev.open;
  }

bool IsHammer(const MqlRates &bar)
  {
   double body  = CandleBody(bar);
   double lower = LowerWick(bar);
   double upper = UpperWick(bar);

   if(body <= 0.0)
      return false;

   return lower >= 2.0 * body && upper <= 0.5 * body;
  }

bool IsShootingStar(const MqlRates &bar)
  {
   double body  = CandleBody(bar);
   double upper = UpperWick(bar);
   double lower = LowerWick(bar);

   if(body <= 0.0)
      return false;

   return upper >= 2.0 * body && lower <= 0.5 * body;
  }

bool IsMorningStar(const MqlRates &first,
                   const MqlRates &second,
                   const MqlRates &third,
                   double avgBody)
  {
   if(!IsBearish(first) || !IsBullish(third))
      return false;

   double smallThreshold = avgBody * 0.5;
   if(CandleBody(second) > smallThreshold)
      return false;

   double firstMid = (first.open + first.close) * 0.5;
   return third.close > firstMid;
  }

bool IsEveningStar(const MqlRates &first,
                   const MqlRates &second,
                   const MqlRates &third,
                   double avgBody)
  {
   if(!IsBullish(first) || !IsBearish(third))
      return false;

   double smallThreshold = avgBody * 0.5;
   if(CandleBody(second) > smallThreshold)
      return false;

   double firstMid = (first.open + first.close) * 0.5;
   return third.close < firstMid;
  }

bool IsInsideBar(const MqlRates &prev, const MqlRates &curr)
  {
   return curr.high < prev.high && curr.low > prev.low;
  }

bool IsThreeWhiteSoldiers(const MqlRates &r1,
                          const MqlRates &r2,
                          const MqlRates &r3,
                          double avgBody)
  {
   if(!IsBullish(r1) || !IsBullish(r2) || !IsBullish(r3))
      return false;
   if(r2.close <= r1.close || r3.close <= r2.close)
      return false;
   double halfAvg = avgBody * 0.5;
   return CandleBody(r1) > halfAvg &&
          CandleBody(r2) > halfAvg &&
          CandleBody(r3) > halfAvg;
  }

bool IsThreeBlackCrows(const MqlRates &r1,
                       const MqlRates &r2,
                       const MqlRates &r3,
                       double avgBody)
  {
   if(!IsBearish(r1) || !IsBearish(r2) || !IsBearish(r3))
      return false;
   if(r2.close >= r1.close || r3.close >= r2.close)
      return false;
   double halfAvg = avgBody * 0.5;
   return CandleBody(r1) > halfAvg &&
          CandleBody(r2) > halfAvg &&
          CandleBody(r3) > halfAvg;
  }

bool IsDoji(const MqlRates &bar, double avgBody)
  {
   double body  = CandleBody(bar);
   double range = CandleRange(bar);
   if(avgBody <= 0.0 || range <= 0.0)
      return false;
   return body < 0.1 * avgBody && range > 0.5 * avgBody;
  }

bool IsTweezerTop(const MqlRates &prev, const MqlRates &curr, double tolerance)
  {
   if(!IsBullish(prev) || !IsBearish(curr))
      return false;
   return MathAbs(prev.high - curr.high) <= tolerance;
  }

bool IsTweezerBottom(const MqlRates &prev, const MqlRates &curr, double tolerance)
  {
   if(!IsBearish(prev) || !IsBullish(curr))
      return false;
   return MathAbs(prev.low - curr.low) <= tolerance;
  }

//=============================================================================
// Main scanner
//=============================================================================

void DetectCandlePatterns(const MqlRates      &rates[],
                          int                  total,
                          ENUM_TIMEFRAMES       tf,
                          const PriceZone      &zones[],
                          int                  zoneCount,
                          const StructureState &structure,
                          CandleSignal         &signals[],
                          int                  &signalCount,
                          double               priceTolerance)
  {
   if(total < 4)
      return;

   // CopyRates returns index 0 = oldest, index total-1 = newest (forming bar).
   // Scan from total-2 (last closed bar) backwards to cover up to 50 bars.
   int scanStart = total - 2;
   int scanEnd   = MathMax(3, total - 51);

   for(int i = scanStart; i >= scanEnd; i--)
     {
      // "curr" = rates[i], "prev" = rates[i-1] (one bar older)
      // For 3-bar patterns: first=rates[i-2], second=rates[i-1], third=rates[i]

      // Ensure we have enough history for multi-candle patterns
      bool have2 = (i - 1 >= 0);
      bool have3 = (i - 2 >= 0);

      ENUM_CANDLE_PATTERN detected = PATTERN_NONE;
      double              signalPrice = rates[i].high; // default label at bar high

      // Average body using the 10 bars ending at this bar
      double avgBody = AvgBodySize(rates, i, 10);

      // ---- Tier 1: Multi-candle reversal patterns ----

      // Morning Star (3 candles: first=i-2, second=i-1, third=i)
      if(detected == PATTERN_NONE && have3)
        {
         if(IsMorningStar(rates[i - 2], rates[i - 1], rates[i], avgBody))
           {
            if(IsAtKeyLevel(rates[i].low, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_MORNING_STAR;
               signalPrice = rates[i].low;
              }
           }
        }

      // Evening Star (3 candles: first=i-2, second=i-1, third=i)
      if(detected == PATTERN_NONE && have3)
        {
         if(IsEveningStar(rates[i - 2], rates[i - 1], rates[i], avgBody))
           {
            if(IsAtKeyLevel(rates[i].high, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_EVENING_STAR;
               signalPrice = rates[i].high;
              }
           }
        }

      // Three White Soldiers
      if(detected == PATTERN_NONE && have3)
        {
         if(IsThreeWhiteSoldiers(rates[i - 2], rates[i - 1], rates[i], avgBody))
           {
            if(IsAtKeyLevel(rates[i].close, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_THREE_WHITE_SOLDIERS;
               signalPrice = rates[i].close;
              }
           }
        }

      // Three Black Crows
      if(detected == PATTERN_NONE && have3)
        {
         if(IsThreeBlackCrows(rates[i - 2], rates[i - 1], rates[i], avgBody))
           {
            if(IsAtKeyLevel(rates[i].close, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_THREE_BLACK_CROWS;
               signalPrice = rates[i].close;
              }
           }
        }

      // ---- Tier 2: Two-candle patterns ----

      // Bullish Engulfing
      if(detected == PATTERN_NONE && have2)
        {
         if(IsBullishEngulfing(rates[i - 1], rates[i]))
           {
            if(IsAtKeyLevel(rates[i].low, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_BULLISH_ENGULFING;
               signalPrice = rates[i].low;
              }
           }
        }

      // Bearish Engulfing
      if(detected == PATTERN_NONE && have2)
        {
         if(IsBearishEngulfing(rates[i - 1], rates[i]))
           {
            if(IsAtKeyLevel(rates[i].high, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_BEARISH_ENGULFING;
               signalPrice = rates[i].high;
              }
           }
        }

      // Tweezer Top
      if(detected == PATTERN_NONE && have2)
        {
         if(IsTweezerTop(rates[i - 1], rates[i], priceTolerance))
           {
            if(IsAtKeyLevel(rates[i].high, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_TWEEZER_TOP;
               signalPrice = rates[i].high;
              }
           }
        }

      // Tweezer Bottom
      if(detected == PATTERN_NONE && have2)
        {
         if(IsTweezerBottom(rates[i - 1], rates[i], priceTolerance))
           {
            if(IsAtKeyLevel(rates[i].low, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_TWEEZER_BOTTOM;
               signalPrice = rates[i].low;
              }
           }
        }

      // Inside Bar
      if(detected == PATTERN_NONE && have2)
        {
         if(IsInsideBar(rates[i - 1], rates[i]))
           {
            if(IsAtKeyLevel((rates[i].high + rates[i].low) * 0.5, zones, zoneCount, structure, priceTolerance))
              {
               detected = IsBullish(rates[i]) ? PATTERN_BULLISH_INSIDE_BAR
                                              : PATTERN_BEARISH_INSIDE_BAR;
               signalPrice = (rates[i].high + rates[i].low) * 0.5;
              }
           }
        }

      // ---- Tier 3: Single-candle patterns ----

      // Hammer
      if(detected == PATTERN_NONE)
        {
         if(IsHammer(rates[i]))
           {
            if(IsAtKeyLevel(rates[i].low, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_HAMMER;
               signalPrice = rates[i].low;
              }
           }
        }

      // Shooting Star
      if(detected == PATTERN_NONE)
        {
         if(IsShootingStar(rates[i]))
           {
            if(IsAtKeyLevel(rates[i].high, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_SHOOTING_STAR;
               signalPrice = rates[i].high;
              }
           }
        }

      // Doji
      if(detected == PATTERN_NONE)
        {
         if(IsDoji(rates[i], avgBody))
           {
            if(IsAtKeyLevel((rates[i].high + rates[i].low) * 0.5, zones, zoneCount, structure, priceTolerance))
              {
               detected    = PATTERN_DOJI_AT_LEVEL;
               signalPrice = (rates[i].high + rates[i].low) * 0.5;
              }
           }
        }

      // Nothing found at this bar
      if(detected == PATTERN_NONE)
         continue;

      // Record the signal
      int newSize = signalCount + 1;
      ArrayResize(signals, newSize);

      signals[signalCount].pattern    = detected;
      signals[signalCount].strength   = (double)PatternStrength(CandleBody(rates[i]), avgBody);
      signals[signalCount].atKeyLevel = true;
      signals[signalCount].price      = signalPrice;
      signals[signalCount].time       = rates[i].time;
      signals[signalCount].barIndex   = i;
      signals[signalCount].tf         = tf;

      signalCount++;
     }
  }

//=============================================================================
// Display helpers
//=============================================================================

string PatternName(ENUM_CANDLE_PATTERN pattern)
  {
   switch(pattern)
     {
      case PATTERN_BULLISH_ENGULFING:    return "BullEng";
      case PATTERN_BEARISH_ENGULFING:    return "BearEng";
      case PATTERN_HAMMER:               return "Hammer";
      case PATTERN_SHOOTING_STAR:        return "ShootStar";
      case PATTERN_MORNING_STAR:         return "MornStar";
      case PATTERN_EVENING_STAR:         return "EveStar";
      case PATTERN_BULLISH_INSIDE_BAR:   return "InsideBar+";
      case PATTERN_BEARISH_INSIDE_BAR:   return "InsideBar-";
      case PATTERN_THREE_WHITE_SOLDIERS: return "3Soldiers";
      case PATTERN_THREE_BLACK_CROWS:    return "3Crows";
      case PATTERN_DOJI_AT_LEVEL:        return "Doji";
      case PATTERN_TWEEZER_TOP:          return "TwzTop";
      case PATTERN_TWEEZER_BOTTOM:       return "TwzBot";
      default:                           return "None";
     }
  }

bool IsPatternBullish(ENUM_CANDLE_PATTERN pattern)
  {
   switch(pattern)
     {
      case PATTERN_BULLISH_ENGULFING:
      case PATTERN_HAMMER:
      case PATTERN_MORNING_STAR:
      case PATTERN_BULLISH_INSIDE_BAR:
      case PATTERN_THREE_WHITE_SOLDIERS:
      case PATTERN_TWEEZER_BOTTOM:
         return true;
      default:
         return false;
     }
  }

#endif // PAZ_CANDLEPATTERNS_MQH
