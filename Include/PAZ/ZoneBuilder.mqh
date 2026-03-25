#ifndef PAZ_ZONEBUILDER_MQH
#define PAZ_ZONEBUILDER_MQH

#include "Structures.mqh"
#include "Inputs.mqh"

//=============================================================================
// CalcATR
// Manual ATR: average of (high-low) over the last `period` bars ending at barIndex.
//=============================================================================
double CalcATR(const MqlRates &rates[], int period, int barIndex)
  {
   if(barIndex < period)
      return 0.0;

   double sum = 0.0;
   for(int i = barIndex - period + 1; i <= barIndex; i++)
      sum += rates[i].high - rates[i].low;

   return sum / (double)period;
  }

//=============================================================================
// ImpulseStrength
// Return abs(close - open) / atr.
//=============================================================================
double ImpulseStrength(const MqlRates &bar, double atr)
  {
   if(atr <= 0.0)
      return 0.0;
   return MathAbs(bar.close - bar.open) / atr;
  }

//=============================================================================
// DetectDemandZone
// Demand: price drops in, forms a base (1-3 small-body candles), then strong
// bullish impulse departs upward.
//=============================================================================
bool DetectDemandZone(const MqlRates &rates[], int total, int barIndex,
                      double atr, PriceZone &zone, ENUM_TIMEFRAMES tf)
  {
   if(atr <= 0.0)
      return false;

   // Scan base lengths 1-3
   for(int baseLen = 1; baseLen <= 3; baseLen++)
     {
      int impulseIdx = barIndex + baseLen;
      if(impulseIdx >= total - 1)  // don't use the still-forming bar
         continue;

      // Check impulse bar: bullish and body/atr >= 1.0
      if(rates[impulseIdx].close <= rates[impulseIdx].open)
         continue;
      double impulseBody = MathAbs(rates[impulseIdx].close - rates[impulseIdx].open);
      if(impulseBody / atr < 1.0)
         continue;

      // Check all base candles are small-bodied (body/atr < 0.8)
      bool validBase = true;
      double lowestLow = rates[barIndex].low;
      double highestBodyTop = MathMax(rates[barIndex].close, rates[barIndex].open);

      for(int j = 0; j < baseLen; j++)
        {
         int idx = barIndex + j;
         double body = MathAbs(rates[idx].close - rates[idx].open);
         if(body / atr >= 0.8)
           {
            validBase = false;
            break;
           }
         if(rates[idx].low < lowestLow)
            lowestLow = rates[idx].low;
         double bodyTop = MathMax(rates[idx].close, rates[idx].open);
         if(bodyTop > highestBodyTop)
            highestBodyTop = bodyTop;
        }

      if(!validBase)
         continue;

      // Build the zone
      zone.lower              = lowestLow;
      zone.upper              = highestBodyTop;
      zone.timeCreated        = rates[barIndex].time;
      zone.timeMitigated      = 0;
      zone.barCreated         = barIndex;
      zone.tf                 = tf;
      zone.zoneType           = ZONE_DEMAND;
      zone.state              = ZONE_ACTIVE;
      zone.touchCount         = 0;
      zone.quality            = 0.0;
      zone.causedBOS          = false;
      zone.departureStrength  = ImpulseStrength(rates[impulseIdx], atr);
      zone.baseCandleCount    = baseLen;
      zone.hasHTFConfluence   = false;
      zone.refinedUpper       = 0.0;
      zone.refinedLower       = 0.0;
      zone.objName            = "";
      return true;
     }

   return false;
  }

//=============================================================================
// DetectSupplyZone
// Supply: price rallies in, forms a base (1-3 small-body candles), then strong
// bearish impulse departs downward.
//=============================================================================
bool DetectSupplyZone(const MqlRates &rates[], int total, int barIndex,
                      double atr, PriceZone &zone, ENUM_TIMEFRAMES tf)
  {
   if(atr <= 0.0)
      return false;

   for(int baseLen = 1; baseLen <= 3; baseLen++)
     {
      int impulseIdx = barIndex + baseLen;
      if(impulseIdx >= total - 1)
         continue;

      // Check impulse bar: bearish and body/atr >= 1.0
      if(rates[impulseIdx].close >= rates[impulseIdx].open)
         continue;
      double impulseBody = MathAbs(rates[impulseIdx].close - rates[impulseIdx].open);
      if(impulseBody / atr < 1.0)
         continue;

      // Check all base candles are small-bodied
      bool validBase = true;
      double highestHigh = rates[barIndex].high;
      double lowestBodyBottom = MathMin(rates[barIndex].close, rates[barIndex].open);

      for(int j = 0; j < baseLen; j++)
        {
         int idx = barIndex + j;
         double body = MathAbs(rates[idx].close - rates[idx].open);
         if(body / atr >= 0.8)
           {
            validBase = false;
            break;
           }
         if(rates[idx].high > highestHigh)
            highestHigh = rates[idx].high;
         double bodyBot = MathMin(rates[idx].close, rates[idx].open);
         if(bodyBot < lowestBodyBottom)
            lowestBodyBottom = bodyBot;
        }

      if(!validBase)
         continue;

      zone.upper              = highestHigh;
      zone.lower              = lowestBodyBottom;
      zone.timeCreated        = rates[barIndex].time;
      zone.timeMitigated      = 0;
      zone.barCreated         = barIndex;
      zone.tf                 = tf;
      zone.zoneType           = ZONE_SUPPLY;
      zone.state              = ZONE_ACTIVE;
      zone.touchCount         = 0;
      zone.quality            = 0.0;
      zone.causedBOS          = false;
      zone.departureStrength  = ImpulseStrength(rates[impulseIdx], atr);
      zone.baseCandleCount    = baseLen;
      zone.hasHTFConfluence   = false;
      zone.refinedUpper       = 0.0;
      zone.refinedLower       = 0.0;
      zone.objName            = "";
      return true;
     }

   return false;
  }

//=============================================================================
// ScoreZone
// Score a zone 0-10 based on multiple quality factors.
//=============================================================================
int ScoreZone(const PriceZone &zone, bool causedBOS, bool hasHTFConfluence)
  {
   int score = 0;

   // Departure strength
   if(zone.departureStrength >= 1.5)
      score += 3;
   else if(zone.departureStrength >= 1.0)
      score += 2;
   else if(zone.departureStrength >= 0.5)
      score += 1;

   // Freshness
   if(zone.touchCount == 0)
      score += 2;
   else if(zone.touchCount == 1)
      score += 1;

   // Caused BOS
   if(causedBOS)
      score += 2;

   // Tight base
   if(zone.baseCandleCount <= 2)
      score += 1;

   // HTF confluence
   if(hasHTFConfluence)
      score += 2;

   return score;
  }

//=============================================================================
// HasHTFConfluence
// Check if zone overlaps with any active zone from a higher timeframe.
//=============================================================================
bool HasHTFConfluence(const PriceZone &zone, const PriceZone &zones[], int zoneCount)
  {
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].state != ZONE_ACTIVE)
         continue;
      // Must be a higher timeframe
      if(PeriodSeconds(zones[i].tf) <= PeriodSeconds(zone.tf))
         continue;
      // Check overlap: zone.lower < htf.upper AND zone.upper > htf.lower
      if(zone.lower < zones[i].upper && zone.upper > zones[i].lower)
         return true;
     }
   return false;
  }

//=============================================================================
// UpdateZoneMitigation
// On last closed bar: demand mitigated if close < lower, supply if close > upper.
// Track touches when price enters zone but doesn't break through.
//=============================================================================
void UpdateZoneMitigation(PriceZone &zones[], int &zoneCount,
                          const MqlRates &rates[], int ratesCount,
                          ENUM_TIMEFRAMES tf)
  {
   if(ratesCount < 2)
      return;

   // Last closed bar
   int barIdx = ratesCount - 2;
   double barClose = rates[barIdx].close;
   double barLow   = rates[barIdx].low;
   double barHigh  = rates[barIdx].high;

   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].tf != tf || zones[i].state != ZONE_ACTIVE)
         continue;

      if(zones[i].zoneType == ZONE_DEMAND)
        {
         // Mitigated: close below zone lower
         if(barClose < zones[i].lower)
           {
            zones[i].state         = ZONE_MITIGATED;
            zones[i].timeMitigated = rates[barIdx].time;
           }
         // Touch: low entered the zone but close stayed above lower
         else if(barLow <= zones[i].upper && barClose >= zones[i].lower)
           {
            zones[i].touchCount++;
           }
        }
      else // ZONE_SUPPLY
        {
         // Mitigated: close above zone upper
         if(barClose > zones[i].upper)
           {
            zones[i].state         = ZONE_MITIGATED;
            zones[i].timeMitigated = rates[barIdx].time;
           }
         // Touch: high entered the zone but close stayed below upper
         else if(barHigh >= zones[i].lower && barClose <= zones[i].upper)
           {
            zones[i].touchCount++;
           }
        }
     }
  }

//=============================================================================
// UpdateZoneFading
// Active zones older than InpZoneFadeBars are set to ZONE_FADED.
//=============================================================================
void UpdateZoneFading(PriceZone &zones[], int zoneCount, int currentBarIndex)
  {
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].state != ZONE_ACTIVE)
         continue;
      if((currentBarIndex - zones[i].barCreated) > InpZoneFadeBars)
         zones[i].state = ZONE_FADED;
     }
  }

//=============================================================================
// CleanupMitigatedZones
// Remove mitigated zones older than InpMitigatedKeepBars.
//=============================================================================
void CleanupMitigatedZones(PriceZone &zones[], int &zoneCount,
                           const MqlRates &rates[], int ratesCount,
                           ENUM_TIMEFRAMES tf)
  {
   if(ratesCount < 2)
      return;

   int currentBarIdx = ratesCount - 2;

   for(int i = zoneCount - 1; i >= 0; i--)
     {
      if(zones[i].tf != tf)
         continue;
      if(zones[i].state != ZONE_MITIGATED && zones[i].state != ZONE_FADED)
         continue;

      // Find how many bars since mitigation/fade
      int ageBars = currentBarIdx - zones[i].barCreated;
      if(ageBars > InpMitigatedKeepBars)
        {
         // Shift remaining elements left
         for(int j = i; j < zoneCount - 1; j++)
            zones[j] = zones[j + 1];
         zoneCount--;
        }
     }
  }

//=============================================================================
// EnforceZoneCap
// Keep at most maxPerTF active zones for a given TF; remove lowest-scoring.
//=============================================================================
void EnforceZoneCap(PriceZone &zones[], int &zoneCount,
                    ENUM_TIMEFRAMES tf, int maxPerTF)
  {
   while(true)
     {
      // Count active zones for this TF
      int activeCount = 0;
      for(int i = 0; i < zoneCount; i++)
        {
         if(zones[i].tf == tf && zones[i].state == ZONE_ACTIVE)
            activeCount++;
        }

      if(activeCount <= maxPerTF)
         break;

      // Find the lowest-scoring active zone for this TF
      int worstIdx   = -1;
      double worstQ  = 999.0;
      for(int i = 0; i < zoneCount; i++)
        {
         if(zones[i].tf == tf && zones[i].state == ZONE_ACTIVE)
           {
            if(zones[i].quality < worstQ)
              {
               worstQ   = zones[i].quality;
               worstIdx = i;
              }
           }
        }

      if(worstIdx < 0)
         break;

      // Remove by shifting
      for(int j = worstIdx; j < zoneCount - 1; j++)
         zones[j] = zones[j + 1];
      zoneCount--;
     }
  }

//=============================================================================
// ZoneAlreadyExists
// Check if a similar zone (same TF, type, similar upper/lower) already exists.
//=============================================================================
bool ZoneAlreadyExists(const PriceZone &zones[], int zoneCount,
                       const PriceZone &candidate, double tolerance)
  {
   for(int i = 0; i < zoneCount; i++)
     {
      if(zones[i].tf != candidate.tf)
         continue;
      if(zones[i].zoneType != candidate.zoneType)
         continue;
      if(MathAbs(zones[i].upper - candidate.upper) < tolerance &&
         MathAbs(zones[i].lower - candidate.lower) < tolerance)
         return true;
     }
   return false;
  }

//=============================================================================
// RefineZone
// Refine H1 active zones using M15 data. Only zones with refinedUpper == 0.
//=============================================================================
void RefineZone(PriceZone &zone, const MqlRates &m15Rates[], int m15Count)
  {
   if(zone.state != ZONE_ACTIVE)
      return;
   if(zone.refinedUpper != 0.0)
      return;

   // Time window: zone creation +/- 4 hours
   datetime tStart = zone.timeCreated - 4 * 3600;
   datetime tEnd   = zone.timeCreated + 4 * 3600;

   if(zone.zoneType == ZONE_DEMAND)
     {
      double bestLow   = 0.0;
      double bestBodyTop = 0.0;
      bool   found     = false;

      for(int i = 0; i < m15Count; i++)
        {
         if(m15Rates[i].time < tStart || m15Rates[i].time > tEnd)
            continue;
         // Only M15 candles whose low is inside the zone
         if(m15Rates[i].low < zone.lower || m15Rates[i].low > zone.upper)
            continue;

         if(!found || m15Rates[i].low < bestLow)
           {
            bestLow    = m15Rates[i].low;
            bestBodyTop = MathMax(m15Rates[i].close, m15Rates[i].open);
            found      = true;
           }
        }

      if(found)
        {
         zone.refinedLower = bestLow;
         zone.refinedUpper = bestBodyTop;
        }
     }
   else // ZONE_SUPPLY
     {
      double bestHigh    = 0.0;
      double bestBodyBot = 0.0;
      bool   found       = false;

      for(int i = 0; i < m15Count; i++)
        {
         if(m15Rates[i].time < tStart || m15Rates[i].time > tEnd)
            continue;
         // Only M15 candles whose high is inside the zone
         if(m15Rates[i].high < zone.lower || m15Rates[i].high > zone.upper)
            continue;

         if(!found || m15Rates[i].high > bestHigh)
           {
            bestHigh    = m15Rates[i].high;
            bestBodyBot = MathMin(m15Rates[i].close, m15Rates[i].open);
            found       = true;
           }
        }

      if(found)
        {
         zone.refinedUpper = bestHigh;
         zone.refinedLower = bestBodyBot;
        }
     }
  }

//=============================================================================
// DetectZones
// Scan last 100 bars on a given TF for demand and supply zones.
//=============================================================================
void DetectZones(const MTFRates &ratesCache, PriceZone &zones[], int &zoneCount,
                 const StructureBreak &breaks[], int breakCount,
                 ENUM_TIMEFRAMES tf)
  {
   int total = ratesCache.count;
   if(total < 20)
      return;

   // ATR(14) from the last closed bar
   int lastBar = total - 2;
   double atr  = CalcATR(ratesCache.rates, 14, lastBar);
   if(atr <= 0.0)
      return;

   double tolerance = atr * 0.3;

   // Scan last 100 bars (avoid the still-forming bar and leave room for impulse)
   int scanStart = MathMax(14, lastBar - 100);

   for(int i = scanStart; i <= lastBar - 1; i++)
     {
      PriceZone candidate;

      // Try demand zone
      if(DetectDemandZone(ratesCache.rates, total, i, atr, candidate, tf))
        {
         if(!ZoneAlreadyExists(zones, zoneCount, candidate, tolerance))
           {
            // Check if zone caused a BOS
            bool causedBOS = false;
            for(int b = 0; b < breakCount; b++)
              {
               if(breaks[b].tf == tf &&
                  MathAbs((double)(breaks[b].time - candidate.timeCreated)) <
                  PeriodSeconds(tf) * 5)
                 {
                  causedBOS = true;
                  break;
                 }
              }

            bool htfConf = HasHTFConfluence(candidate, zones, zoneCount);
            candidate.causedBOS       = causedBOS;
            candidate.hasHTFConfluence = htfConf;

            int score = ScoreZone(candidate, causedBOS, htfConf);
            candidate.quality = (double)score;

            if(candidate.quality >= InpZoneMinQuality)
              {
               ArrayResize(zones, zoneCount + 1);
               zones[zoneCount] = candidate;
               zoneCount++;
              }
           }
        }

      // Try supply zone
      if(DetectSupplyZone(ratesCache.rates, total, i, atr, candidate, tf))
        {
         if(!ZoneAlreadyExists(zones, zoneCount, candidate, tolerance))
           {
            bool causedBOS = false;
            for(int b = 0; b < breakCount; b++)
              {
               if(breaks[b].tf == tf &&
                  MathAbs((double)(breaks[b].time - candidate.timeCreated)) <
                  PeriodSeconds(tf) * 5)
                 {
                  causedBOS = true;
                  break;
                 }
              }

            bool htfConf = HasHTFConfluence(candidate, zones, zoneCount);
            candidate.causedBOS       = causedBOS;
            candidate.hasHTFConfluence = htfConf;

            int score = ScoreZone(candidate, causedBOS, htfConf);
            candidate.quality = (double)score;

            if(candidate.quality >= InpZoneMinQuality)
              {
               ArrayResize(zones, zoneCount + 1);
               zones[zoneCount] = candidate;
               zoneCount++;
              }
           }
        }
     }
  }

//=============================================================================
// UpdateAllZones
// Master function: detect, mitigate, fade, cleanup, cap, and refine zones.
//=============================================================================
void UpdateAllZones(const MTFRates &rates[], PriceZone &zones[], int &zoneCount,
                    const StructureBreak &breaks[], int breakCount,
                    const StructureState &structure[])
  {
   //--- Detect zones on D1, H4, H1 (skip M15; respect visibility toggles)
   // TF_LIST: 0=D1, 1=H4, 2=H1, 3=M15
   if(InpShowD1Zones && rates[0].count > 20)
      DetectZones(rates[0], zones, zoneCount, breaks, breakCount, PERIOD_D1);

   if(InpShowH4Zones && rates[1].count > 20)
      DetectZones(rates[1], zones, zoneCount, breaks, breakCount, PERIOD_H4);

   if(InpShowH1Zones && rates[2].count > 20)
      DetectZones(rates[2], zones, zoneCount, breaks, breakCount, PERIOD_H1);

   //--- Update mitigation for all active TFs
   for(int i = 0; i < 3; i++) // D1, H4, H1
     {
      if(rates[i].count > 2)
        {
         UpdateZoneMitigation(zones, zoneCount, rates[i].rates, rates[i].count,
                              TF_LIST[i]);
        }
     }

   //--- Update fading for all zones
   // Use H1 bar index as a reasonable reference for bar age
   if(rates[2].count > 2)
     {
      int currentBar = rates[2].count - 2;
      UpdateZoneFading(zones, zoneCount, currentBar);
     }

   //--- Cleanup mitigated/faded zones for each TF
   for(int i = 0; i < 3; i++)
     {
      if(rates[i].count > 2)
         CleanupMitigatedZones(zones, zoneCount, rates[i].rates, rates[i].count,
                               TF_LIST[i]);
     }

   //--- Enforce zone cap per TF
   EnforceZoneCap(zones, zoneCount, PERIOD_D1, InpMaxZonesPerTF);
   EnforceZoneCap(zones, zoneCount, PERIOD_H4, InpMaxZonesPerTF);
   EnforceZoneCap(zones, zoneCount, PERIOD_H1, InpMaxZonesPerTF);

   //--- Refine H1 zones using M15 data (index 3 in rates[])
   if(rates[3].count > 0)
     {
      for(int i = 0; i < zoneCount; i++)
        {
         if(zones[i].tf == PERIOD_H1)
            RefineZone(zones[i], rates[3].rates, rates[3].count);
        }
     }
  }

#endif // PAZ_ZONEBUILDER_MQH
