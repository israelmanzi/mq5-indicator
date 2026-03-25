#ifndef PAZ_LIQUIDITY_MQH
#define PAZ_LIQUIDITY_MQH

#include "Structures.mqh"

//=============================================================================
// DetectEqualLevels
// Groups swing points at similar prices (within tolerance) into EqualLevel
// clusters. A level is only kept when it has at least 2 touches.
//=============================================================================
void DetectEqualLevels(const SwingPoint &swings[], int swingCount,
                       ENUM_TIMEFRAMES tf, double tolerance,
                       EqualLevel &levels[], int &levelCount)
  {
   //--- First pass: build / merge clusters from swing points
   for(int i = 0; i < swingCount; i++)
     {
      if(swings[i].tf != tf)
         continue;

      bool isHighs = (swings[i].type == SWING_HIGH);
      double price = swings[i].price;

      //--- Search for an existing matching cluster
      int matchIdx = -1;
      for(int j = 0; j < levelCount; j++)
        {
         if(levels[j].tf != tf)
            continue;
         if(levels[j].isHighs != isHighs)
            continue;
         if(MathAbs(levels[j].price - price) <= tolerance)
           {
            matchIdx = j;
            break;
           }
        }

      if(matchIdx >= 0)
        {
         //--- Merge into existing cluster: running average of price
         double totalTouches = (double)levels[matchIdx].touchCount;
         levels[matchIdx].price = (levels[matchIdx].price * totalTouches + price)
                                  / (totalTouches + 1.0);
         levels[matchIdx].touchCount++;
         if(swings[i].time > levels[matchIdx].lastTime)
            levels[matchIdx].lastTime = swings[i].time;
        }
      else
        {
         //--- Create new cluster entry
         int newIdx = levelCount;
         ArrayResize(levels, newIdx + 1);
         levels[newIdx].price      = price;
         levels[newIdx].touchCount = 1;
         levels[newIdx].firstTime  = swings[i].time;
         levels[newIdx].lastTime   = swings[i].time;
         levels[newIdx].isHighs    = isHighs;
         levels[newIdx].tf         = tf;
         levelCount++;
        }
     }

   //--- Second pass: remove single-touch entries (not "equal" levels)
   int writeIdx = 0;
   for(int i = 0; i < levelCount; i++)
     {
      //--- Only keep entries that belong to this tf and have >= 2 touches
      if(levels[i].tf == tf && levels[i].touchCount < 2)
         continue;
      if(writeIdx != i)
         levels[writeIdx] = levels[i];
      writeIdx++;
     }
   levelCount = writeIdx;
   ArrayResize(levels, levelCount);
  }

//=============================================================================
// DetectLiquiditySweeps
// Checks the last closed bar for liquidity sweeps of recent swing levels and
// equal highs/lows levels. A sweep requires price to wick past the level and
// then close back on the opposite side, with the wick >= 30% of bar range.
//=============================================================================
void DetectLiquiditySweeps(const MqlRates &rates[], int total,
                           const SwingPoint &swings[], int swingCount,
                           const EqualLevel &eqLevels[], int eqCount,
                           ENUM_TIMEFRAMES tf, double tolerance,
                           LiquidityEvent &events[], int &eventCount)
  {
   if(total < 2)
      return;

   int barIdx = total - 2; // last closed bar
   MqlRates bar = rates[barIdx];
   double range = bar.high - bar.low;
   if(range <= 0)
      return;

   //--- Collect candidate levels (price, isHigh) from recent swings (last 20)
   //    and from equal levels
   double levelPrices[];
   bool   levelIsHigh[];
   int    levelCount = 0;

   //--- Gather up to 20 recent swings
   int swingStart = MathMax(0, swingCount - 20);
   for(int i = swingStart; i < swingCount; i++)
     {
      if(swings[i].tf != tf)
         continue;
      ArrayResize(levelPrices, levelCount + 1);
      ArrayResize(levelIsHigh, levelCount + 1);
      levelPrices[levelCount] = swings[i].price;
      levelIsHigh[levelCount] = (swings[i].type == SWING_HIGH);
      levelCount++;
     }

   //--- Gather equal levels for this tf
   for(int i = 0; i < eqCount; i++)
     {
      if(eqLevels[i].tf != tf)
         continue;
      ArrayResize(levelPrices, levelCount + 1);
      ArrayResize(levelIsHigh, levelCount + 1);
      levelPrices[levelCount] = eqLevels[i].price;
      levelIsHigh[levelCount] = eqLevels[i].isHighs;
      levelCount++;
     }

   //--- Evaluate each candidate level
   for(int i = 0; i < levelCount; i++)
     {
      double level = levelPrices[i];

      //--- Bullish sweep: wick pierced below, close recovered above
      //    bar.low < level - tolerance  AND  bar.close > level
      //    lower wick = close - low; wick must be >= 30% of range
      if(bar.low < level - tolerance && bar.close > level)
        {
         double lowerWick = bar.close - bar.low;
         if(lowerWick >= 0.3 * range)
           {
            int newIdx = eventCount;
            ArrayResize(events, newIdx + 1);
            events[newIdx].level     = level;
            events[newIdx].sweepHigh = bar.high;
            events[newIdx].sweepLow  = bar.low;
            events[newIdx].time      = bar.time;
            events[newIdx].barIndex  = barIdx;
            events[newIdx].isBullish = true;
            events[newIdx].tf        = tf;
            eventCount++;
           }
        }

      //--- Bearish sweep: wick pierced above, close recovered below
      //    bar.high > level + tolerance  AND  bar.close < level
      //    upper wick = high - close; wick must be >= 30% of range
      else if(bar.high > level + tolerance && bar.close < level)
        {
         double upperWick = bar.high - bar.close;
         if(upperWick >= 0.3 * range)
           {
            int newIdx = eventCount;
            ArrayResize(events, newIdx + 1);
            events[newIdx].level     = level;
            events[newIdx].sweepHigh = bar.high;
            events[newIdx].sweepLow  = bar.low;
            events[newIdx].time      = bar.time;
            events[newIdx].barIndex  = barIdx;
            events[newIdx].isBullish = false;
            events[newIdx].tf        = tf;
            eventCount++;
           }
        }
     }
  }

//=============================================================================
// UpdateLiquidity
// Detects equal levels and liquidity sweeps on H1 (index 2) and M15 (index 3).
//=============================================================================
void UpdateLiquidity(const MTFRates &rates[], const StructureState &structure[],
                     EqualLevel &eqLevels[], int &eqLevelCount,
                     LiquidityEvent &events[], int &eventCount,
                     double tolerance)
  {
   //--- Reset outputs for a fresh scan each tick
   eqLevelCount = 0;
   ArrayResize(eqLevels, 0);
   eventCount = 0;
   ArrayResize(events, 0);

   //--- H1  (TF_LIST index 2)
   DetectEqualLevels(structure[2].swings, structure[2].swingCount,
                     PERIOD_H1, tolerance,
                     eqLevels, eqLevelCount);
   DetectLiquiditySweeps(rates[2].rates, rates[2].count,
                         structure[2].swings, structure[2].swingCount,
                         eqLevels, eqLevelCount,
                         PERIOD_H1, tolerance,
                         events, eventCount);

   //--- M15 (TF_LIST index 3)
   DetectEqualLevels(structure[3].swings, structure[3].swingCount,
                     PERIOD_M15, tolerance,
                     eqLevels, eqLevelCount);
   DetectLiquiditySweeps(rates[3].rates, rates[3].count,
                         structure[3].swings, structure[3].swingCount,
                         eqLevels, eqLevelCount,
                         PERIOD_M15, tolerance,
                         events, eventCount);
  }

#endif // PAZ_LIQUIDITY_MQH
