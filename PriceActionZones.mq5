//+------------------------------------------------------------------+
//|                                          PriceActionZones.mq5   |
//|                    Pure price action multi-timeframe indicator   |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
#property version           "1.00"

#include "Include/PAZ/Constants.mqh"
#include "Include/PAZ/Structures.mqh"
#include "Include/PAZ/Inputs.mqh"
#include "Include/PAZ/MTFData.mqh"
#include "Include/PAZ/SwingPoints.mqh"

//=============================================================================
// Global state
//=============================================================================

// Per-timeframe market structure (indexed by TF_LIST position)
StructureState  g_structure[4];

// Per-timeframe cached OHLCV data
MTFRates        g_rates[4];

// Zone pool
PriceZone       g_zones[];
int             g_zoneCount = 0;

// Structure break events
StructureBreak  g_breaks[];
int             g_breakCount = 0;

// Trendlines
TrendLine       g_trendlines[];
int             g_trendlineCount = 0;

// Key levels
KeyLevel        g_keyLevels[];
int             g_keyLevelCount = 0;

// Entry signals
EntrySignal     g_entries[];
int             g_entryCount = 0;

// Candle signals
CandleSignal    g_candleSignals[];
int             g_candleSignalCount = 0;

// Liquidity events
LiquidityEvent  g_liqEvents[];
int             g_liqEventCount = 0;

// Equal highs/lows levels
EqualLevel      g_eqLevels[];
int             g_eqLevelCount = 0;

// Active trade state
TradeState      g_trade;

// Dashboard snapshot
DashboardData   g_dashboard;

//=============================================================================
// OnInit
//=============================================================================
int OnInit()
  {
   //--- Validate inputs
   if(InpSwingLookbackD1 < 1 || InpSwingLookbackH4 < 1 ||
      InpSwingLookbackH1 < 1 || InpSwingLookbackM15 < 1)
     {
      Print("PAZ ERROR: Swing lookback values must be >= 1.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpMaxZonesPerTF < 1)
     {
      Print("PAZ ERROR: MaxZonesPerTF must be >= 1.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpZoneMinQuality < 0.0 || InpZoneMinQuality > 10.0)
     {
      Print("PAZ ERROR: ZoneMinQuality must be between 0 and 10.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpMinRR < 0.1)
     {
      Print("PAZ ERROR: MinRR must be >= 0.1.");
      return INIT_PARAMETERS_INCORRECT;
     }

   //--- Initialise per-timeframe structure states
   for(int i = 0; i < TF_COUNT; i++)
     {
      g_structure[i].trend      = TREND_RANGING;
      g_structure[i].swingCount = 0;
      ArrayResize(g_structure[i].swings, 0);

      g_rates[i].count      = 0;
      g_rates[i].tf         = TF_LIST[i];
      g_rates[i].lastUpdate = 0;
      ArrayResize(g_rates[i].rates, 0);
     }

   //--- Initialise trade state
   g_trade.isActive      = false;
   g_trade.isBreakeven   = false;
   g_trade.trailingSwings = false;

   //--- Initialise dashboard
   g_dashboard.d1Bias         = TREND_RANGING;
   g_dashboard.h4Bias         = TREND_RANGING;
   g_dashboard.h1Bias         = TREND_RANGING;
   g_dashboard.activeZoneCount = 0;
   g_dashboard.pendingSetups  = 0;
   g_dashboard.lastBOS        = "—";
   g_dashboard.lastCHoCH      = "—";
   g_dashboard.tradeStatus    = "Flat";

   Print("PAZ: PriceActionZones v1.00 initialised on ", Symbol(), " ", EnumToString(Period()));
   return INIT_SUCCEEDED;
  }

//=============================================================================
// OnDeinit
//=============================================================================
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, OBJ_PREFIX);
  }

//=============================================================================
// OnCalculate
//=============================================================================
int OnCalculate(const int      rates_total,
                const int      prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
  {
   if(rates_total < 100)
      return 0;

   // 1. Load MTF data
   if(!MTFLoadAll(g_rates, 100))
      return prev_calculated; // wait for data
   // 2. Detect swing points (all TFs)
   DetectAllSwingPoints(g_rates, g_structure);
   // TODO Task 4: detect BOS / CHoCH, populate g_breaks[]
   // TODO Task 5: identify and score supply/demand zones (g_zones[])
   // TODO Task 6: detect trendlines (g_trendlines[])
   // TODO Task 7: detect key levels and equal highs/lows
   // TODO Task 8: scan for candle patterns (g_candleSignals[])
   // TODO Task 9: detect liquidity sweeps (g_liqEvents[])
   // TODO Task 10: build entry signals (g_entries[])
   // TODO Task 11: draw all chart objects
   // TODO Task 12: update dashboard
   // TODO Task 13: fire alerts

   return rates_total;
  }
//+------------------------------------------------------------------+
