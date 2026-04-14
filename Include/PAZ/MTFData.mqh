#ifndef PAZ_MTFDATA_MQH
#define PAZ_MTFDATA_MQH

#include "Structures.mqh"
#include "Inputs.mqh"

//-----------------------------------------------------------------------------
// MTFLoadRates
// Loads OHLCV data for a single timeframe into cache.
// Returns false and prints an error if CopyRates fails.
//-----------------------------------------------------------------------------
bool MTFLoadRates(MTFRates &cache, ENUM_TIMEFRAMES tf, int barsNeeded)
  {
   int copied = CopyRates(_Symbol, tf, 0, barsNeeded, cache.rates);
   if(copied <= 0)
     {
      PrintFormat("PAZ ERROR: CopyRates failed for %s — returned %d (error %d)",
                  EnumToString(tf), copied, GetLastError());
      return false;
     }
   cache.count      = copied;
   cache.tf         = tf;
   cache.lastUpdate = TimeCurrent();
   return true;
  }

//-----------------------------------------------------------------------------
// MTFLoadAll
// Loads OHLCV data for all four timeframes (D1, H4, H1, M15).
// barsNeeded per TF: D1=200, H4=500, H1=1000, M15=2000 (each floored at minBars).
// Returns true only when every timeframe loads successfully.
//-----------------------------------------------------------------------------
bool MTFLoadAll(MTFRates &rates[], int minBars)
  {
   // Per-TF bar targets indexed to match TF_LIST: D1, H4, H1, M15
   int tfBars[4] = {200, 500, 1000, 2000};
   int loaded = 0;

   for(int i = 0; i < TF_COUNT; i++)
     {
      int barsNeeded = (int)MathMax(tfBars[i], minBars);
      if(MTFLoadRates(rates[i], TF_LIST[i], barsNeeded))
         loaded++;
      else
         rates[i].count = 0; // mark as unavailable, don't block others
     }
   // Need at least D1 + one lower TF to do anything useful
   return (loaded >= 2 && rates[0].count > 0);
  }

//-----------------------------------------------------------------------------
// MTFGetSwingLookback
// Returns the user-configured swing lookback for the given timeframe.
//-----------------------------------------------------------------------------
int MTFGetSwingLookback(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_D1:  return InpSwingLookbackD1;
      case PERIOD_H4:  return InpSwingLookbackH4;
      case PERIOD_H1:  return InpSwingLookbackH1;
      case PERIOD_M15: return InpSwingLookbackM15;
      default:         return 3;
     }
  }

//-----------------------------------------------------------------------------
// MTFHasData
// Returns true when the cache holds at least minRequired bars.
//-----------------------------------------------------------------------------
bool MTFHasData(const MTFRates &cache, int minRequired)
  {
   return cache.count >= minRequired;
  }

#endif // PAZ_MTFDATA_MQH
