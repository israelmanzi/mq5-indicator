#ifndef PAZ_TRENDLINES_MQH
#define PAZ_TRENDLINES_MQH

#include "Structures.mqh"
#include "Inputs.mqh"

//=============================================================================
// CalcTrendAngle
// Returns the trendline angle in degrees, normalised against the average bar
// range so that angle is comparable across instruments/timeframes.
//
// pricePerBar   = |priceEnd - priceStart| / barsElapsed
// normalised    = pricePerBar / avgRange
// angle (deg)   = |atan(normalised)| * 180 / PI
//=============================================================================
double CalcTrendAngle(double   priceStart,
                      datetime timeStart,
                      double   priceEnd,
                      datetime timeEnd,
                      double   avgRange,
                      int      periodSeconds)
  {
   if(timeEnd <= timeStart || avgRange <= 0.0 || periodSeconds <= 0)
      return 0.0;

   int barsElapsed = (int)((timeEnd - timeStart) / periodSeconds);
   if(barsElapsed <= 0)
      return 0.0;

   double pricePerBar = MathAbs(priceEnd - priceStart) / (double)barsElapsed;
   double normalised  = pricePerBar / avgRange;
   return MathAbs(MathArctan(normalised) * 180.0 / M_PI);
  }

//=============================================================================
// BuildTrendlines
// Scans swings in StructureState (newest → oldest) to find:
//   - one ascending  trendline : two swing lows forming a higher-low sequence
//   - one descending trendline : two swing highs forming a lower-high sequence
// Skips duplicates (same tf + isAscending + start/end times already present).
//=============================================================================
void BuildTrendlines(const StructureState &state,
                     ENUM_TIMEFRAMES       tf,
                     double                avgRange,
                     TrendLine            &lines[],
                     int                  &lineCount)
  {
   if(state.swingCount < 4)
      return;

   int periodSeconds = PeriodSeconds(tf);

   //--------------------------------------------------------------------------
   // Ascending trendline: find two swing lows (newest first) where the older
   // swing low has a LOWER price than the newer one  → higher-low sequence.
   // newer swing:  swings[i]   (closer to present, higher price)
   // older swing:  swings[j]   (further in past,   lower  price)
   //--------------------------------------------------------------------------
   bool builtAsc = false;
   for(int i = state.swingCount - 1; i >= 1 && !builtAsc; i--)
     {
      if(state.swings[i].type != SWING_LOW)
         continue;

      for(int j = i - 1; j >= 0 && !builtAsc; j--)
        {
         if(state.swings[j].type != SWING_LOW)
            continue;

         // older low must be strictly lower (ascending structure)
         if(state.swings[j].price >= state.swings[i].price)
            continue;

         datetime ts = state.swings[j].time;
         datetime te = state.swings[i].time;

         // Duplicate check (MQL5 has no lambdas; expand inline)
         bool found = false;
         for(int k = 0; k < lineCount && !found; k++)
            if(lines[k].tf == tf && lines[k].isAscending == true &&
               lines[k].startTime == ts && lines[k].endTime == te)
               found = true;
         if(found)
           {
            builtAsc = true;
            break;
           }

         double angle = CalcTrendAngle(state.swings[j].price, ts,
                                       state.swings[i].price, te,
                                       avgRange, periodSeconds);

         int newIdx = lineCount;
         ArrayResize(lines, newIdx + 1);
         lines[newIdx].startPrice   = state.swings[j].price;
         lines[newIdx].startTime    = ts;
         lines[newIdx].endPrice     = state.swings[i].price;
         lines[newIdx].endTime      = te;
         lines[newIdx].touchCount   = 2;
         lines[newIdx].angleDegrees = angle;
         lines[newIdx].isSteep      = (angle > (double)InpTrendlineSteepAngle);
         lines[newIdx].isAscending  = true;
         lines[newIdx].state        = TL_ACTIVE;
         lines[newIdx].breakTime    = 0;
         lines[newIdx].tf           = tf;
         lines[newIdx].objName      = "";
         lineCount++;
         builtAsc = true;
        }
     }

   //--------------------------------------------------------------------------
   // Descending trendline: find two swing highs (newest first) where the older
   // swing high has a HIGHER price than the newer one → lower-high sequence.
   // newer swing:  swings[i]   (closer to present, lower  price)
   // older swing:  swings[j]   (further in past,   higher price)
   //--------------------------------------------------------------------------
   bool builtDesc = false;
   for(int i = state.swingCount - 1; i >= 1 && !builtDesc; i--)
     {
      if(state.swings[i].type != SWING_HIGH)
         continue;

      for(int j = i - 1; j >= 0 && !builtDesc; j--)
        {
         if(state.swings[j].type != SWING_HIGH)
            continue;

         // older high must be strictly higher (descending structure)
         if(state.swings[j].price <= state.swings[i].price)
            continue;

         datetime ts = state.swings[j].time;
         datetime te = state.swings[i].time;

         bool found = false;
         for(int k = 0; k < lineCount && !found; k++)
            if(lines[k].tf == tf && lines[k].isAscending == false &&
               lines[k].startTime == ts && lines[k].endTime == te)
               found = true;
         if(found)
           {
            builtDesc = true;
            break;
           }

         double angle = CalcTrendAngle(state.swings[j].price, ts,
                                       state.swings[i].price, te,
                                       avgRange, periodSeconds);

         int newIdx = lineCount;
         ArrayResize(lines, newIdx + 1);
         lines[newIdx].startPrice   = state.swings[j].price;
         lines[newIdx].startTime    = ts;
         lines[newIdx].endPrice     = state.swings[i].price;
         lines[newIdx].endTime      = te;
         lines[newIdx].touchCount   = 2;
         lines[newIdx].angleDegrees = angle;
         lines[newIdx].isSteep      = (angle > (double)InpTrendlineSteepAngle);
         lines[newIdx].isAscending  = false;
         lines[newIdx].state        = TL_ACTIVE;
         lines[newIdx].breakTime    = 0;
         lines[newIdx].tf           = tf;
         lines[newIdx].objName      = "";
         lineCount++;
         builtDesc = true;
        }
     }
  }

//=============================================================================
// TrendlinePriceAt
// Projects the trendline's price level at a given time by linear extrapolation
// from the start point using the slope defined by (start → end).
//=============================================================================
double TrendlinePriceAt(const TrendLine &line, datetime atTime)
  {
   if(line.endTime == line.startTime)
      return line.startPrice;

   double slope = (line.endPrice - line.startPrice) /
                  (double)(line.endTime - line.startTime);
   return line.startPrice + slope * (double)(atTime - line.startTime);
  }

//=============================================================================
// UpdateTrendlineStates
// Evaluates the last closed bar for each trendline belonging to `tf`:
//   ACTIVE   → TL_BROKEN  when close crosses through the projected level.
//   TL_BROKEN → TL_RETESTING when price returns within 0.5 × avgRange of the
//               projected level on a later bar.
//=============================================================================
void UpdateTrendlineStates(TrendLine        &lines[],
                           int               lineCount,
                           const MqlRates   &rates[],
                           int               ratesCount,
                           ENUM_TIMEFRAMES   tf)
  {
   if(ratesCount < 2 || lineCount <= 0)
      return;

   int barIdx = ratesCount - 2;          // last closed bar
   MqlRates bar = rates[barIdx];

   double range = bar.high - bar.low;
   if(range <= 0.0)
      range = _Point;                    // fallback: avoid division by zero

   for(int i = 0; i < lineCount; i++)
     {
      if(lines[i].tf != tf)
         continue;

      double projected = TrendlinePriceAt(lines[i], bar.time);

      if(lines[i].state == TL_ACTIVE)
        {
         // Ascending trendline acts as support → broken when close drops below
         if(lines[i].isAscending && bar.close < projected)
           {
            lines[i].state     = TL_BROKEN;
            lines[i].breakTime = bar.time;
           }
         // Descending trendline acts as resistance → broken when close rises above
         else if(!lines[i].isAscending && bar.close > projected)
           {
            lines[i].state     = TL_BROKEN;
            lines[i].breakTime = bar.time;
           }
        }
      else if(lines[i].state == TL_BROKEN)
        {
         // Retest: price returns close to the projected trendline level
         double distance = MathAbs(bar.close - projected);
         if(distance / range < 0.5)
            lines[i].state = TL_RETESTING;
        }
     }
  }

//=============================================================================
// CalcAvgRange
// Computes the average bar range (high - low) over the last `lookback` bars
// of the supplied rates array (excludes the still-forming current bar).
//=============================================================================
static double CalcAvgRange(const MqlRates &rates[], int count, int lookback)
  {
   if(count < 2)
      return _Point;

   int end   = count - 2;               // last closed bar
   int start = MathMax(0, end - lookback + 1);
   int n     = end - start + 1;

   double sum = 0.0;
   for(int i = start; i <= end; i++)
      sum += rates[i].high - rates[i].low;

   return (n > 0) ? sum / (double)n : _Point;
  }

//=============================================================================
// UpdateAllTrendlines
// Orchestrates trendline building and state updates for H4 (index 1 in
// TF_LIST) and H1 (index 2 in TF_LIST).
//=============================================================================
void UpdateAllTrendlines(const StructureState &structure[],
                         const MTFRates       &rates[],
                         TrendLine            &lines[],
                         int                  &lineCount)
  {
   //--- Reset the trendline pool on each call for a clean rebuild
   lineCount = 0;
   ArrayResize(lines, 0);

   //--- H4 (TF_LIST index 1 = PERIOD_H4)
   {
      double avgRange = CalcAvgRange(rates[1].rates, rates[1].count, 50);
      BuildTrendlines(structure[1], PERIOD_H4, avgRange, lines, lineCount);
      UpdateTrendlineStates(lines, lineCount,
                            rates[1].rates, rates[1].count, PERIOD_H4);
   }

   //--- H1 (TF_LIST index 2 = PERIOD_H1)
   {
      double avgRange = CalcAvgRange(rates[2].rates, rates[2].count, 50);
      BuildTrendlines(structure[2], PERIOD_H1, avgRange, lines, lineCount);
      UpdateTrendlineStates(lines, lineCount,
                            rates[2].rates, rates[2].count, PERIOD_H1);
   }
  }

#endif // PAZ_TRENDLINES_MQH
