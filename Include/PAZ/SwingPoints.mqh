#ifndef PAZ_SWINGPOINTS_MQH
#define PAZ_SWINGPOINTS_MQH

#include "Structures.mqh"
#include "MTFData.mqh"

//-----------------------------------------------------------------------------
// IsSwingHigh
// Returns true if rates[index].high is strictly greater than the high of every
// bar within lookback distance on both sides.
//-----------------------------------------------------------------------------
bool IsSwingHigh(const MqlRates &rates[], int index, int lookback, int total)
  {
   if(index < lookback || index >= total - lookback)
      return false;

   double pivot = rates[index].high;
   for(int i = index - lookback; i <= index + lookback; i++)
     {
      if(i == index)
         continue;
      if(rates[i].high >= pivot)
         return false;
     }
   return true;
  }

//-----------------------------------------------------------------------------
// IsSwingLow
// Returns true if rates[index].low is strictly lower than the low of every
// bar within lookback distance on both sides.
//-----------------------------------------------------------------------------
bool IsSwingLow(const MqlRates &rates[], int index, int lookback, int total)
  {
   if(index < lookback || index >= total - lookback)
      return false;

   double pivot = rates[index].low;
   for(int i = index - lookback; i <= index + lookback; i++)
     {
      if(i == index)
         continue;
      if(rates[i].low <= pivot)
         return false;
     }
   return true;
  }

//-----------------------------------------------------------------------------
// LabelSwing
// Compares current swing against the most recent prior swing of the same type
// and returns the appropriate HH / HL / LH / LL label.
// Returns SWING_NONE when no valid previous swing exists.
//-----------------------------------------------------------------------------
ENUM_SWING_LABEL LabelSwing(const SwingPoint &current, const SwingPoint &prevSameType)
  {
   if(prevSameType.time == 0)
      return SWING_NONE;

   if(current.type == SWING_HIGH)
      return (current.price > prevSameType.price) ? SWING_HH : SWING_LH;
   else
      return (current.price > prevSameType.price) ? SWING_HL : SWING_LL;
  }

//-----------------------------------------------------------------------------
// FindLastSwingOfType
// Scans swings[] backwards for the most recent entry whose type matches the
// requested type.  Populates result and returns true on success; zeroes result
// and returns false when no match is found.
//-----------------------------------------------------------------------------
bool FindLastSwingOfType(const SwingPoint &swings[], int count,
                         ENUM_SWING_TYPE type, SwingPoint &result)
  {
   for(int i = count - 1; i >= 0; i--)
     {
      if(swings[i].type == type)
        {
         result = swings[i];
         return true;
        }
     }
   ZeroMemory(result);
   return false;
  }

//-----------------------------------------------------------------------------
// DetectSwingPoints
// Scans the cached OHLCV data for one timeframe and populates state.swings[].
// The array is rebuilt from scratch on every call.
//-----------------------------------------------------------------------------
void DetectSwingPoints(const MTFRates &ratesCache, StructureState &state,
                       ENUM_TIMEFRAMES tf)
  {
   int lookback = MTFGetSwingLookback(tf);
   int total    = ratesCache.count;

   //--- Reset swing list
   ArrayResize(state.swings, 0);
   state.swingCount = 0;

   if(total < lookback * 2 + 1)
      return;

   //--- Scan oldest (0) to newest (total-1), skipping the guard bands
   for(int i = lookback; i < total - lookback; i++)
     {
      bool isHigh = IsSwingHigh(ratesCache.rates, i, lookback, total);
      bool isLow  = IsSwingLow (ratesCache.rates, i, lookback, total);

      if(!isHigh && !isLow)
         continue;

      //--- Build the new swing point (high takes precedence on exact equality)
      SwingPoint sp;
      ZeroMemory(sp);
      sp.barIndex = i;
      sp.time     = ratesCache.rates[i].time;
      sp.tf       = tf;

      if(isHigh)
        {
         sp.type  = SWING_HIGH;
         sp.price = ratesCache.rates[i].high;

         SwingPoint prevHigh;
         FindLastSwingOfType(state.swings, state.swingCount, SWING_HIGH, prevHigh);
         sp.label = LabelSwing(sp, prevHigh);
        }
      else
        {
         sp.type  = SWING_LOW;
         sp.price = ratesCache.rates[i].low;

         SwingPoint prevLow;
         FindLastSwingOfType(state.swings, state.swingCount, SWING_LOW, prevLow);
         sp.label = LabelSwing(sp, prevLow);
        }

      //--- Append to the dynamic array
      ArrayResize(state.swings, state.swingCount + 1);
      state.swings[state.swingCount] = sp;
      state.swingCount++;
     }
  }

//-----------------------------------------------------------------------------
// DetectAllSwingPoints
// Iterates over every timeframe in TF_LIST and calls DetectSwingPoints for
// each one that holds enough data.
//-----------------------------------------------------------------------------
void DetectAllSwingPoints(const MTFRates &rates[], StructureState &structure[])
  {
   for(int i = 0; i < TF_COUNT; i++)
     {
      int lookback = MTFGetSwingLookback(TF_LIST[i]);
      if(!MTFHasData(rates[i], lookback * 2 + 1))
         continue;

      DetectSwingPoints(rates[i], structure[i], TF_LIST[i]);
     }
  }

#endif // PAZ_SWINGPOINTS_MQH
