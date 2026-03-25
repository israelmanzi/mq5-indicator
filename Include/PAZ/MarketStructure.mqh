#ifndef PAZ_MARKETSTRUCTURE_MQH
#define PAZ_MARKETSTRUCTURE_MQH

#include "Structures.mqh"

//=============================================================================
// DetermineTrend
// Inspect the last 4 swing labels to classify trend direction.
//=============================================================================
ENUM_TREND_DIR DetermineTrend(const StructureState &state)
  {
   if(state.swingCount < 4)
      return TREND_RANGING;

   int bullCount = 0;
   int bearCount = 0;

   // Examine the most recent 4 swings (highest indices)
   int start = state.swingCount - 4;
   for(int i = start; i < state.swingCount; i++)
     {
      ENUM_SWING_LABEL lbl = state.swings[i].label;
      if(lbl == SWING_HH || lbl == SWING_HL)
         bullCount++;
      if(lbl == SWING_LH || lbl == SWING_LL)
         bearCount++;
     }

   if(bullCount >= 3)
      return TREND_BULLISH;
   if(bearCount >= 3)
      return TREND_BEARISH;
   return TREND_RANGING;
  }

//=============================================================================
// DetectStructureBreaks
// Detect BOS and CHoCH on the last closed bar and append to breaks[].
//=============================================================================
void DetectStructureBreaks(const MqlRates      &rates[],
                           int                  ratesCount,
                           StructureState       &state,
                           ENUM_TIMEFRAMES       tf,
                           StructureBreak       &breaks[],
                           int                  &breakCount)
  {
   if(state.swingCount < 2 || ratesCount < 2)
      return;

   // Last CLOSED bar (skip the still-forming bar at ratesCount-1)
   int barIdx   = ratesCount - 2;
   double closePrice = rates[barIdx].close;
   datetime barTime  = rates[barIdx].time;

   // Dedup: skip if a break at this time+tf was already recorded
   for(int i = 0; i < breakCount; i++)
     {
      if(breaks[i].time == barTime && breaks[i].tf == tf)
         return;
     }

   // Resolve last swing high and last swing low
   SwingPoint lastHigh;
   SwingPoint lastLow;
   bool foundHigh = false;
   bool foundLow  = false;

   for(int i = state.swingCount - 1; i >= 0; i--)
     {
      if(!foundHigh && state.swings[i].type == SWING_HIGH)
        {
         lastHigh  = state.swings[i];
         foundHigh = true;
        }
      if(!foundLow && state.swings[i].type == SWING_LOW)
        {
         lastLow  = state.swings[i];
         foundLow = true;
        }
      if(foundHigh && foundLow)
         break;
     }

   if(!foundHigh || !foundLow)
      return;

   ENUM_STRUCTURE_BREAK breakType = BREAK_NONE;
   double               level     = 0.0;

   // BOS detection (trend-continuation, body close)
   if(state.trend == TREND_BULLISH && closePrice > lastHigh.price)
     {
      breakType = BREAK_BOS_BULL;
      level     = lastHigh.price;
     }
   else if(state.trend == TREND_BEARISH && closePrice < lastLow.price)
     {
      breakType = BREAK_BOS_BEAR;
      level     = lastLow.price;
     }
   // CHoCH detection (trend-reversal)
   else if(state.trend == TREND_BULLISH && closePrice < lastLow.price)
     {
      breakType = BREAK_CHOCH_BEAR;
      level     = lastLow.price;
     }
   else if(state.trend == TREND_BEARISH && closePrice > lastHigh.price)
     {
      breakType = BREAK_CHOCH_BULL;
      level     = lastHigh.price;
     }

   if(breakType == BREAK_NONE)
      return;

   // Append new break event
   ArrayResize(breaks, breakCount + 1);
   breaks[breakCount].breakType = breakType;
   breaks[breakCount].level     = level;
   breaks[breakCount].time      = barTime;
   breaks[breakCount].barIndex  = barIdx;
   breaks[breakCount].tf        = tf;
   breakCount++;
  }

//=============================================================================
// UpdateAllStructure
// Refresh trend, swing high/low references, and break detection for all TFs.
//=============================================================================
void UpdateAllStructure(const MTFRates   &rates[],
                        StructureState   &structure[],
                        StructureBreak   &breaks[],
                        int              &breakCount)
  {
   for(int i = 0; i < TF_COUNT; i++)
     {
      // 1. Update trend classification
      structure[i].trend = DetermineTrend(structure[i]);

      // 2. Update cached last swing high and last swing low
      bool foundHigh = false;
      bool foundLow  = false;
      for(int j = structure[i].swingCount - 1; j >= 0; j--)
        {
         if(!foundHigh && structure[i].swings[j].type == SWING_HIGH)
           {
            structure[i].lastSwingHigh = structure[i].swings[j];
            foundHigh = true;
           }
         if(!foundLow && structure[i].swings[j].type == SWING_LOW)
           {
            structure[i].lastSwingLow = structure[i].swings[j];
            foundLow = true;
           }
         if(foundHigh && foundLow)
            break;
        }

      // 3. Detect BOS / CHoCH for this timeframe
      DetectStructureBreaks(rates[i].rates, rates[i].count,
                            structure[i], TF_LIST[i],
                            breaks, breakCount);
     }
  }

#endif // PAZ_MARKETSTRUCTURE_MQH
