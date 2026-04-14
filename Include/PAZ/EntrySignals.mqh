#ifndef PAZ_ENTRYSIGNALS_MQH
#define PAZ_ENTRYSIGNALS_MQH

#include "Structures.mqh"
#include "CandlePatterns.mqh"
#include "Trendlines.mqh"
#include "Inputs.mqh"

//=============================================================================
// 1. CheckD1Bias
//=============================================================================
bool CheckD1Bias(const StructureState &d1State, ENUM_ENTRY_DIR &dir)
  {
   if(d1State.trend == TREND_BULLISH)
     {
      dir = ENTRY_BUY;
      return true;
     }
   if(d1State.trend == TREND_BEARISH)
     {
      dir = ENTRY_SELL;
      return true;
     }
   return false;
  }

//=============================================================================
// 2. CheckZoneAlignment
//=============================================================================
bool CheckZoneAlignment(const PriceZone &zones[], int zoneCount,
                        ENUM_ENTRY_DIR dir, double currentPrice,
                        double tolerance, PriceZone &matchedZone)
  {
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].state != ZONE_ACTIVE)
         continue;

      // Only H4 and H1 zones
      if(zones[i].tf != PERIOD_H4 && zones[i].tf != PERIOD_H1)
         continue;

      // Direction check
      if(dir == ENTRY_BUY && zones[i].zoneType != ZONE_DEMAND)
         continue;
      if(dir == ENTRY_SELL && zones[i].zoneType != ZONE_SUPPLY)
         continue;

      // Determine zone bounds (use refined if available)
      double zUpper = (zones[i].refinedUpper > 0.0) ? zones[i].refinedUpper : zones[i].upper;
      double zLower = (zones[i].refinedLower > 0.0) ? zones[i].refinedLower : zones[i].lower;

      // Price within zone bounds
      if(currentPrice >= zLower - tolerance && currentPrice <= zUpper + tolerance)
        {
         matchedZone = zones[i];
         return true;
        }
     }
   return false;
  }

//=============================================================================
// 3. CheckLiquiditySweep
//=============================================================================
bool CheckLiquiditySweep(const LiquidityEvent &events[], int eventCount,
                         ENUM_ENTRY_DIR dir, datetime since)
  {
   for(int i = eventCount - 1; i >= 0; i--)
     {
      if(events[i].time < since)
         break;

      // Only H1 sweeps count for entry confirmation
      if(events[i].tf != PERIOD_H1)
         continue;

      if(dir == ENTRY_BUY && events[i].isBullish)
         return true;
      if(dir == ENTRY_SELL && !events[i].isBullish)
         return true;
     }
   return false;
  }

//=============================================================================
// 4. CheckM15BOS
//=============================================================================
bool CheckM15BOS(const StructureBreak &breaks[], int breakCount,
                 ENUM_ENTRY_DIR dir, datetime since)
  {
   for(int i = breakCount - 1; i >= 0; i--)
     {
      if(breaks[i].time < since)
         break;

      if(breaks[i].tf != PERIOD_M15)
         continue;

      if(dir == ENTRY_BUY &&
         (breaks[i].breakType == BREAK_BOS_BULL || breaks[i].breakType == BREAK_CHOCH_BULL))
         return true;

      if(dir == ENTRY_SELL &&
         (breaks[i].breakType == BREAK_BOS_BEAR || breaks[i].breakType == BREAK_CHOCH_BEAR))
         return true;
     }
   return false;
  }

//=============================================================================
// 5. CheckCandlePattern
//=============================================================================
bool CheckCandlePattern(const CandleSignal &signals[], int signalCount,
                        ENUM_ENTRY_DIR dir, datetime since,
                        ENUM_CANDLE_PATTERN &matched)
  {
   for(int i = signalCount - 1; i >= 0; i--)
     {
      if(signals[i].time < since)
         break;

      if(!signals[i].atKeyLevel)
         continue;

      bool isBull = IsPatternBullish(signals[i].pattern);

      if(dir == ENTRY_BUY && isBull)
        {
         matched = signals[i].pattern;
         return true;
        }
      if(dir == ENTRY_SELL && !isBull)
        {
         matched = signals[i].pattern;
         return true;
        }
     }
   return false;
  }

//=============================================================================
// 6. CheckConfirmation
//=============================================================================
bool CheckConfirmation(const MqlRates &rates[], int ratesCount,
                       ENUM_ENTRY_DIR dir, datetime patternTime,
                       ENUM_TIMEFRAMES tf)
  {
   // Find the bar at patternTime
   int patIdx = -1;
   for(int i = 0; i < ratesCount; i++)
     {
      if(rates[i].time == patternTime)
        {
         patIdx = i;
         break;
        }
     }

   if(patIdx < 0)
      return false;

   // Next bar must exist and be closed (not the forming bar = index 0 if newest-first,
   // but in MQL5 CopyRates with series ordering, index 0 is most recent).
   // Our rates arrays are oldest-first (standard CopyRates), so next bar = patIdx + 1
   // and the forming bar is at ratesCount - 1.
   int nextIdx = patIdx + 1;
   if(nextIdx >= ratesCount)
      return false;

   // Must be closed: not the last bar (which is still forming)
   if(nextIdx >= ratesCount - 1)
      return false;

   if(dir == ENTRY_BUY && rates[nextIdx].close > rates[patIdx].high)
      return true;
   if(dir == ENTRY_SELL && rates[nextIdx].close < rates[patIdx].low)
      return true;

   return false;
  }

//=============================================================================
// 7. CalcSL
//=============================================================================
double CalcSL(const PriceZone &zone, ENUM_ENTRY_DIR dir, double buffer)
  {
   if(dir == ENTRY_BUY)
     {
      double bottom = (zone.refinedLower > 0.0) ? zone.refinedLower : zone.lower;
      return bottom - buffer;
     }
   else
     {
      double top = (zone.refinedUpper > 0.0) ? zone.refinedUpper : zone.upper;
      return top + buffer;
     }
  }

//=============================================================================
// 8. CalcTP
//=============================================================================
double CalcTP(ENUM_ENTRY_DIR dir, double entryPrice,
              const PriceZone &zones[], int zoneCount,
              const KeyLevel &keyLevels[], int keyLevelCount)
  {
   double bestTP    = 0.0;
   double bestDist  = DBL_MAX;

   // Find nearest opposing zone
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].state != ZONE_ACTIVE)
         continue;

      if(dir == ENTRY_BUY && zones[i].zoneType == ZONE_SUPPLY)
        {
         double zLevel = (zones[i].refinedLower > 0.0) ? zones[i].refinedLower : zones[i].lower;
         if(zLevel > entryPrice)
           {
            double dist = zLevel - entryPrice;
            if(dist < bestDist)
              {
               bestDist = dist;
               bestTP   = zLevel;
              }
           }
        }
      else if(dir == ENTRY_SELL && zones[i].zoneType == ZONE_DEMAND)
        {
         double zLevel = (zones[i].refinedUpper > 0.0) ? zones[i].refinedUpper : zones[i].upper;
         if(zLevel < entryPrice)
           {
            double dist = entryPrice - zLevel;
            if(dist < bestDist)
              {
               bestDist = dist;
               bestTP   = zLevel;
              }
           }
        }
     }

   if(bestTP != 0.0)
      return bestTP;

   // Fallback: nearest key level in the right direction
   bestDist = DBL_MAX;
   for(int i = 0; i < keyLevelCount; i++)
     {
      if(dir == ENTRY_BUY && keyLevels[i].price > entryPrice)
        {
         double dist = keyLevels[i].price - entryPrice;
         if(dist < bestDist)
           {
            bestDist = dist;
            bestTP   = keyLevels[i].price;
           }
        }
      else if(dir == ENTRY_SELL && keyLevels[i].price < entryPrice)
        {
         double dist = entryPrice - keyLevels[i].price;
         if(dist < bestDist)
           {
            bestDist = dist;
            bestTP   = keyLevels[i].price;
           }
        }
     }

   return bestTP;
  }

//=============================================================================
// 9. GenerateEntrySignals (checklist-based zone tap entries)
//=============================================================================
void GenerateEntrySignals(const StructureState &structure[],
                          const PriceZone      &zones[],       int zoneCount,
                          const LiquidityEvent &liqEvents[],   int liqEventCount,
                          const StructureBreak &breaks[],      int breakCount,
                          const CandleSignal   &candleSignals[], int candleSignalCount,
                          const KeyLevel       &keyLevels[],   int keyLevelCount,
                          const MTFRates       &rates[],
                          EntrySignal          &entries[],      int &entryCount,
                          double currentPrice, double spreadVal)
  {
   datetime since = TimeCurrent() - 24 * 3600;

   //--- Cleanup: remove entries older than 24h
   for(int i = entryCount - 1; i >= 0; i--)
     {
      if(entries[i].signalTime < since)
        {
         for(int j = i; j < entryCount - 1; j++)
            entries[j] = entries[j + 1];
         entryCount--;
        }
     }
   ArrayResize(entries, entryCount);

   //--- Step 1: D1 bias
   ENUM_ENTRY_DIR dir;
   if(!CheckD1Bias(structure[0], dir))
      return;

   //--- Step 2: Zone alignment (tolerance = 50 pips for 5-digit, gives room for approach)
   double zoneTolerance = _Point * 50;
   PriceZone matchedZone;
   ZeroMemory(matchedZone);
   if(!CheckZoneAlignment(zones, zoneCount, dir, currentPrice, zoneTolerance, matchedZone))
      return;

   //--- Step 3: Liquidity sweep
   if(!CheckLiquiditySweep(liqEvents, liqEventCount, dir, since))
      return;

   //--- Step 4: M15 BOS
   if(!CheckM15BOS(breaks, breakCount, dir, since))
      return;

   //--- Step 5: Candle pattern
   ENUM_CANDLE_PATTERN matchedPattern = PATTERN_NONE;
   if(!CheckCandlePattern(candleSignals, candleSignalCount, dir, since, matchedPattern))
      return;

   //--- Step 6: Confirmation (use M15 rates, index 3)
   // Find the candle signal time for confirmation
   datetime patternTime = 0;
   for(int i = candleSignalCount - 1; i >= 0; i--)
     {
      if(candleSignals[i].time >= since && candleSignals[i].pattern == matchedPattern)
        {
         patternTime = candleSignals[i].time;
         break;
        }
     }
   if(patternTime == 0)
      return;

   if(!CheckConfirmation(rates[3].rates, rates[3].count, dir, patternTime, PERIOD_M15))
      return;

   //--- Calculate SL and TP
   double buffer = spreadVal * _Point + _Point * 5;
   double sl = CalcSL(matchedZone, dir, buffer);
   double tp = CalcTP(dir, currentPrice, zones, zoneCount, keyLevels, keyLevelCount);

   //--- Calculate R:R for display (no gate — always allow entry)
   double risk   = MathAbs(currentPrice - sl);
   double reward = (tp > 0.0) ? MathAbs(tp - currentPrice) : 0.0;
   double rr     = (risk > 0.0 && reward > 0.0) ? reward / risk : 0.0;

   //--- Dedup: skip if entry signaled within last H1
   datetime oneHourAgo = TimeCurrent() - 3600;
   for(int i = 0; i < entryCount; i++)
     {
      if(entries[i].signalTime >= oneHourAgo &&
         entries[i].direction == dir &&
         entries[i].entryType == ENTRY_ZONE_TAP)
         return;
     }

   //--- Find matched zone index in zones[]
   int triggerIdx = -1;
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].timeCreated == matchedZone.timeCreated &&
         zones[i].tf == matchedZone.tf &&
         zones[i].zoneType == matchedZone.zoneType)
        {
         triggerIdx = i;
         break;
        }
     }

   //--- Build checklist detail
   string detail = StringFormat("D1=%s | Zone=%s %s | Liq=Y | M15BOS=Y | Pattern=%s | Confirm=Y | RR=%.1f",
                                (dir == ENTRY_BUY) ? "Bull" : "Bear",
                                (matchedZone.zoneType == ZONE_DEMAND) ? "Demand" : "Supply",
                                EnumToString(matchedZone.tf),
                                PatternName(matchedPattern),
                                rr);

   //--- Append entry
   int idx = entryCount;
   ArrayResize(entries, idx + 1);

   entries[idx].entryType      = ENTRY_ZONE_TAP;
   entries[idx].direction      = dir;
   entries[idx].entryPrice     = currentPrice;
   entries[idx].slPrice        = sl;
   entries[idx].tpPrice        = tp;
   entries[idx].rrRatio        = rr;
   entries[idx].signalTime     = TimeCurrent();
   entries[idx].confirmTime    = TimeCurrent();
   entries[idx].isConfirmed    = true;
   entries[idx].confirmPattern = matchedPattern;
   entries[idx].checklistScore = 6;
   entries[idx].checklistDetail = detail;
   entries[idx].entryTF        = PERIOD_M15;
   entries[idx].triggerZoneIdx = triggerIdx;
   entries[idx].objNameEntry   = "";
   entries[idx].objNameSL      = "";
   entries[idx].objNameTP      = "";

   entryCount++;

   Print("PAZ ENTRY: ZoneTap ", (dir == ENTRY_BUY) ? "BUY" : "SELL",
         " @ ", DoubleToString(currentPrice, _Digits),
         " SL=", DoubleToString(sl, _Digits),
         " TP=", DoubleToString(tp, _Digits),
         " RR=", DoubleToString(rr, 1));
  }

//=============================================================================
// 10. DetectDoubleTop
//=============================================================================
bool DetectDoubleTop(const StructureState &h1State, const MqlRates &rates[],
                     int ratesCount, double tolerance,
                     double &neckline, double &peakPrice)
  {
   // Need at least 2 swing highs
   int highCount = 0;
   int highIdx1 = -1, highIdx2 = -1;

   // Find last 2 swing highs (scan from newest)
   for(int i = h1State.swingCount - 1; i >= 0; i--)
     {
      if(h1State.swings[i].type == SWING_HIGH)
        {
         if(highCount == 0)
            highIdx1 = i;   // most recent
         else if(highCount == 1)
           {
            highIdx2 = i;   // second most recent
            break;
           }
         highCount++;
        }
     }

   if(highIdx1 < 0 || highIdx2 < 0)
      return false;

   double peak1 = h1State.swings[highIdx1].price;
   double peak2 = h1State.swings[highIdx2].price;

   // Peaks must be at similar price
   if(MathAbs(peak1 - peak2) > tolerance)
      return false;

   peakPrice = MathMax(peak1, peak2);

   // Find neckline = lowest swing low between the two peaks
   datetime time1 = h1State.swings[highIdx2].time;
   datetime time2 = h1State.swings[highIdx1].time;
   neckline = DBL_MAX;

   for(int i = 0; i < h1State.swingCount; i++)
     {
      if(h1State.swings[i].type == SWING_LOW &&
         h1State.swings[i].time >= time1 &&
         h1State.swings[i].time <= time2)
        {
         if(h1State.swings[i].price < neckline)
            neckline = h1State.swings[i].price;
        }
     }

   if(neckline == DBL_MAX)
      return false;

   // Confirmed when last closed bar's close < neckline
   if(ratesCount < 2)
      return false;

   int lastClosed = ratesCount - 2;
   if(rates[lastClosed].close < neckline)
      return true;

   return false;
  }

//=============================================================================
// 11. DetectDoubleBottom
//=============================================================================
bool DetectDoubleBottom(const StructureState &h1State, const MqlRates &rates[],
                        int ratesCount, double tolerance,
                        double &neckline, double &troughPrice)
  {
   // Need at least 2 swing lows
   int lowCount = 0;
   int lowIdx1 = -1, lowIdx2 = -1;

   // Find last 2 swing lows (scan from newest)
   for(int i = h1State.swingCount - 1; i >= 0; i--)
     {
      if(h1State.swings[i].type == SWING_LOW)
        {
         if(lowCount == 0)
            lowIdx1 = i;   // most recent
         else if(lowCount == 1)
           {
            lowIdx2 = i;   // second most recent
            break;
           }
         lowCount++;
        }
     }

   if(lowIdx1 < 0 || lowIdx2 < 0)
      return false;

   double trough1 = h1State.swings[lowIdx1].price;
   double trough2 = h1State.swings[lowIdx2].price;

   // Troughs must be at similar price
   if(MathAbs(trough1 - trough2) > tolerance)
      return false;

   troughPrice = MathMin(trough1, trough2);

   // Find neckline = highest swing high between the two troughs
   datetime time1 = h1State.swings[lowIdx2].time;
   datetime time2 = h1State.swings[lowIdx1].time;
   neckline = 0.0;

   for(int i = 0; i < h1State.swingCount; i++)
     {
      if(h1State.swings[i].type == SWING_HIGH &&
         h1State.swings[i].time >= time1 &&
         h1State.swings[i].time <= time2)
        {
         if(h1State.swings[i].price > neckline)
            neckline = h1State.swings[i].price;
        }
     }

   if(neckline == 0.0)
      return false;

   // Confirmed when last closed bar's close > neckline
   if(ratesCount < 2)
      return false;

   int lastClosed = ratesCount - 2;
   if(rates[lastClosed].close > neckline)
      return true;

   return false;
  }

//=============================================================================
// 12. CheckBreakoutRetest
//=============================================================================
bool CheckBreakoutRetest(const TrendLine    &lines[],      int lineCount,
                         const CandleSignal &candleSignals[], int candleSignalCount,
                         ENUM_ENTRY_DIR dir, double currentPrice,
                         double tolerance, datetime since,
                         double &retestLevel)
  {
   for(int i = 0; i < lineCount; i++)
     {
      if(lines[i].state != TL_RETESTING)
         continue;

      if(lines[i].breakTime < since)
         continue;

      // Direction match: ascending broken = support broken = SELL retest
      //                  descending broken = resistance broken = BUY retest
      if(dir == ENTRY_BUY && lines[i].isAscending)
         continue;
      if(dir == ENTRY_SELL && !lines[i].isAscending)
         continue;

      // Price must be near projected trendline level
      double projected = TrendlinePriceAt(lines[i], TimeCurrent());
      if(MathAbs(currentPrice - projected) > tolerance)
         continue;

      // Must have a candle pattern near the retest level
      bool hasPattern = false;
      for(int j = candleSignalCount - 1; j >= 0; j--)
        {
         if(candleSignals[j].time < since)
            break;

         if(MathAbs(candleSignals[j].price - projected) <= tolerance)
           {
            hasPattern = true;
            break;
           }
        }

      if(!hasPattern)
         continue;

      retestLevel = projected;
      return true;
     }
   return false;
  }

//=============================================================================
// 13. GeneratePatternEntries
//=============================================================================
void GeneratePatternEntries(const StructureState  &structure[],
                            const PriceZone       &zones[],          int zoneCount,
                            const TrendLine       &trendlines[],     int trendlineCount,
                            const CandleSignal    &candleSignals[],  int candleSignalCount,
                            const KeyLevel        &keyLevels[],      int keyLevelCount,
                            const MTFRates        &rates[],
                            const StructureBreak  &breaks[],         int breakCount,
                            const LiquidityEvent  &liqEvents[],      int liqEventCount,
                            EntrySignal           &entries[],         int &entryCount,
                            double currentPrice, double spreadVal)
  {
   datetime since  = TimeCurrent() - 24 * 3600;
   double  buffer  = spreadVal * _Point + _Point * 5;
   double  tolerance = _Point * 50;  // wider tolerance for pattern matching

   //--- Dedup helper: check if same type entry within last H1
   datetime oneHourAgo = TimeCurrent() - 3600;

   //=========================================================================
   // Double Top (SELL)
   //=========================================================================
   {
      // Requires D1 bearish or ranging
      if(structure[0].trend == TREND_BEARISH || structure[0].trend == TREND_RANGING)
        {
         double neckline  = 0.0;
         double peakPrice = 0.0;

         // H1 state = index 2
         if(DetectDoubleTop(structure[2], rates[2].rates, rates[2].count,
                            tolerance, neckline, peakPrice))
           {
            // M15 BOS bear
            if(CheckM15BOS(breaks, breakCount, ENTRY_SELL, since))
              {
               // Liquidity sweep
               if(CheckLiquiditySweep(liqEvents, liqEventCount, ENTRY_SELL, since))
                 {
                  // SL above peaks + buffer
                  double sl = peakPrice + buffer;
                  // TP = neckline - measured move
                  double measuredMove = peakPrice - neckline;
                  double tp = neckline - measuredMove;

                  double risk   = MathAbs(sl - currentPrice);
                  double reward = MathAbs(currentPrice - tp);
                  if(risk > 0.0)
                    {
                     double rr = reward / risk;
                     if(InpMinRR <= 0.0 || rr >= InpMinRR)
                       {
                        // Dedup
                        bool dup = false;
                        for(int i = 0; i < entryCount; i++)
                          {
                           if(entries[i].signalTime >= oneHourAgo &&
                              entries[i].entryType == ENTRY_DOUBLE_TOP)
                             {
                              dup = true;
                              break;
                             }
                          }

                        if(!dup)
                          {
                           string detail = StringFormat("DblTop: peaks=%.5f neckline=%.5f RR=%.1f",
                                                        peakPrice, neckline, rr);

                           int idx = entryCount;
                           ArrayResize(entries, idx + 1);

                           entries[idx].entryType       = ENTRY_DOUBLE_TOP;
                           entries[idx].direction        = ENTRY_SELL;
                           entries[idx].entryPrice       = currentPrice;
                           entries[idx].slPrice          = sl;
                           entries[idx].tpPrice          = tp;
                           entries[idx].rrRatio          = rr;
                           entries[idx].signalTime       = TimeCurrent();
                           entries[idx].confirmTime      = TimeCurrent();
                           entries[idx].isConfirmed      = true;
                           entries[idx].confirmPattern   = PATTERN_NONE;
                           entries[idx].checklistScore   = 4;
                           entries[idx].checklistDetail  = detail;
                           entries[idx].entryTF          = PERIOD_H1;
                           entries[idx].triggerZoneIdx   = -1;
                           entries[idx].objNameEntry     = "";
                           entries[idx].objNameSL        = "";
                           entries[idx].objNameTP        = "";
                           entryCount++;

                           Print("PAZ ENTRY: DoubleTop SELL @ ",
                                 DoubleToString(currentPrice, _Digits),
                                 " SL=", DoubleToString(sl, _Digits),
                                 " TP=", DoubleToString(tp, _Digits),
                                 " RR=", DoubleToString(rr, 1));
                          }
                       }
                    }
                 }
              }
           }
        }
   }

   //=========================================================================
   // Double Bottom (BUY)
   //=========================================================================
   {
      // Requires D1 bullish or ranging
      if(structure[0].trend == TREND_BULLISH || structure[0].trend == TREND_RANGING)
        {
         double neckline    = 0.0;
         double troughPrice = 0.0;

         // H1 state = index 2
         if(DetectDoubleBottom(structure[2], rates[2].rates, rates[2].count,
                               tolerance, neckline, troughPrice))
           {
            // M15 BOS bull
            if(CheckM15BOS(breaks, breakCount, ENTRY_BUY, since))
              {
               // Liquidity sweep
               if(CheckLiquiditySweep(liqEvents, liqEventCount, ENTRY_BUY, since))
                 {
                  // SL below troughs - buffer
                  double sl = troughPrice - buffer;
                  // TP = neckline + measured move
                  double measuredMove = neckline - troughPrice;
                  double tp = neckline + measuredMove;

                  double risk   = MathAbs(currentPrice - sl);
                  double reward = MathAbs(tp - currentPrice);
                  if(risk > 0.0)
                    {
                     double rr = reward / risk;
                     if(InpMinRR <= 0.0 || rr >= InpMinRR)
                       {
                        // Dedup
                        bool dup = false;
                        for(int i = 0; i < entryCount; i++)
                          {
                           if(entries[i].signalTime >= oneHourAgo &&
                              entries[i].entryType == ENTRY_DOUBLE_BOTTOM)
                             {
                              dup = true;
                              break;
                             }
                          }

                        if(!dup)
                          {
                           string detail = StringFormat("DblBot: troughs=%.5f neckline=%.5f RR=%.1f",
                                                        troughPrice, neckline, rr);

                           int idx = entryCount;
                           ArrayResize(entries, idx + 1);

                           entries[idx].entryType       = ENTRY_DOUBLE_BOTTOM;
                           entries[idx].direction        = ENTRY_BUY;
                           entries[idx].entryPrice       = currentPrice;
                           entries[idx].slPrice          = sl;
                           entries[idx].tpPrice          = tp;
                           entries[idx].rrRatio          = rr;
                           entries[idx].signalTime       = TimeCurrent();
                           entries[idx].confirmTime      = TimeCurrent();
                           entries[idx].isConfirmed      = true;
                           entries[idx].confirmPattern   = PATTERN_NONE;
                           entries[idx].checklistScore   = 4;
                           entries[idx].checklistDetail  = detail;
                           entries[idx].entryTF          = PERIOD_H1;
                           entries[idx].triggerZoneIdx   = -1;
                           entries[idx].objNameEntry     = "";
                           entries[idx].objNameSL        = "";
                           entries[idx].objNameTP        = "";
                           entryCount++;

                           Print("PAZ ENTRY: DoubleBottom BUY @ ",
                                 DoubleToString(currentPrice, _Digits),
                                 " SL=", DoubleToString(sl, _Digits),
                                 " TP=", DoubleToString(tp, _Digits),
                                 " RR=", DoubleToString(rr, 1));
                          }
                       }
                    }
                 }
              }
           }
        }
   }

   //=========================================================================
   // Breakout + Retest
   //=========================================================================
   {
      ENUM_ENTRY_DIR dir;
      if(CheckD1Bias(structure[0], dir))
        {
         double retestLevel = 0.0;
         if(CheckBreakoutRetest(trendlines, trendlineCount,
                                candleSignals, candleSignalCount,
                                dir, currentPrice, tolerance, since, retestLevel))
           {
            // M15 BOS
            if(CheckM15BOS(breaks, breakCount, dir, since))
              {
               // Liquidity sweep
               if(CheckLiquiditySweep(liqEvents, liqEventCount, dir, since))
                 {
                  // SL behind retest level
                  double sl;
                  if(dir == ENTRY_BUY)
                     sl = retestLevel - buffer;
                  else
                     sl = retestLevel + buffer;

                  double tp = CalcTP(dir, currentPrice, zones, zoneCount, keyLevels, keyLevelCount);
                  if(tp != 0.0)
                    {
                     double risk   = MathAbs(currentPrice - sl);
                     double reward = MathAbs(tp - currentPrice);
                     if(risk > 0.0)
                       {
                        double rr = reward / risk;
                        if(InpMinRR <= 0.0 || rr >= InpMinRR)
                          {
                           // Dedup
                           bool dup = false;
                           for(int i = 0; i < entryCount; i++)
                             {
                              if(entries[i].signalTime >= oneHourAgo &&
                                 entries[i].entryType == ENTRY_BREAKOUT_RETEST &&
                                 entries[i].direction == dir)
                                {
                                 dup = true;
                                 break;
                                }
                             }

                           if(!dup)
                             {
                              string detail = StringFormat("BkRetest: %s retest=%.5f RR=%.1f",
                                                           (dir == ENTRY_BUY) ? "BUY" : "SELL",
                                                           retestLevel, rr);

                              int idx = entryCount;
                              ArrayResize(entries, idx + 1);

                              entries[idx].entryType       = ENTRY_BREAKOUT_RETEST;
                              entries[idx].direction        = dir;
                              entries[idx].entryPrice       = currentPrice;
                              entries[idx].slPrice          = sl;
                              entries[idx].tpPrice          = tp;
                              entries[idx].rrRatio          = rr;
                              entries[idx].signalTime       = TimeCurrent();
                              entries[idx].confirmTime      = TimeCurrent();
                              entries[idx].isConfirmed      = true;
                              entries[idx].confirmPattern   = PATTERN_NONE;
                              entries[idx].checklistScore   = 4;
                              entries[idx].checklistDetail  = detail;
                              entries[idx].entryTF          = PERIOD_M15;
                              entries[idx].triggerZoneIdx   = -1;
                              entries[idx].objNameEntry     = "";
                              entries[idx].objNameSL        = "";
                              entries[idx].objNameTP        = "";
                              entryCount++;

                              Print("PAZ ENTRY: BreakoutRetest ",
                                    (dir == ENTRY_BUY) ? "BUY" : "SELL",
                                    " @ ", DoubleToString(currentPrice, _Digits),
                                    " SL=", DoubleToString(sl, _Digits),
                                    " TP=", DoubleToString(tp, _Digits),
                                    " RR=", DoubleToString(rr, 1));
                             }
                          }
                       }
                    }
                 }
              }
           }
        }
   }
  }

#endif // PAZ_ENTRYSIGNALS_MQH
