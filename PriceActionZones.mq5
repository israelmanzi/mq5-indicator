//+------------------------------------------------------------------+
//|                                          PriceActionZones.mq5    |
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
#include "Include/PAZ/MarketStructure.mqh"
#include "Include/PAZ/ZoneBuilder.mqh"
#include "Include/PAZ/CandlePatterns.mqh"
#include "Include/PAZ/Liquidity.mqh"
#include "Include/PAZ/Trendlines.mqh"
#include "Include/PAZ/KeyLevels.mqh"
#include "Include/PAZ/EntrySignals.mqh"
#include "Include/PAZ/TradeManagement.mqh"
#include "Include/PAZ/Drawing.mqh"
#include "Include/PAZ/Dashboard.mqh"

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
   g_trade.trailingSwings = 0;

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

   // Throttle: recalculate every 5 seconds to avoid performance issues
   static datetime lastCalc = 0;
   if(TimeCurrent() - lastCalc < 5 && prev_calculated > 0)
      return rates_total;
   lastCalc = TimeCurrent();

   // Full recalc: reset all accumulated arrays
   if(prev_calculated <= 0)
     {
      g_breakCount        = 0;
      g_zoneCount         = 0;
      g_candleSignalCount = 0;
      g_liqEventCount     = 0;
      g_eqLevelCount      = 0;
      g_trendlineCount    = 0;
      g_keyLevelCount     = 0;
      g_entryCount        = 0;
      ArrayResize(g_breaks, 0);
      ArrayResize(g_zones, 0);
      ArrayResize(g_candleSignals, 0);
      ArrayResize(g_liqEvents, 0);
      ArrayResize(g_eqLevels, 0);
      ArrayResize(g_trendlines, 0);
      ArrayResize(g_keyLevels, 0);
      ArrayResize(g_entries, 0);
      // Reset alert dedup
      g_alertedStage1Count = 0;
      g_alertedStage2Count = 0;
      ArrayResize(g_alertedStage1, 0);
      ArrayResize(g_alertedStage2, 0);
     }

   // 1. Load MTF data
   if(!MTFLoadAll(g_rates, 100))
      return prev_calculated; // wait for data
   // 2. Detect swing points (all TFs)
   DetectAllSwingPoints(g_rates, g_structure);
   // 3. Determine market structure + BOS/CHoCH (all TFs)
   UpdateAllStructure(g_rates, g_structure, g_breaks, g_breakCount);
   // 4-5. Build and refine zones (D1, H4, H1 -> M15 refinement)
   UpdateAllZones(g_rates, g_zones, g_zoneCount, g_breaks, g_breakCount, g_structure);
   // 6. Detect candlestick patterns (H1, M15)
   g_candleSignalCount = 0;
   ArrayResize(g_candleSignals, 0);
   double tolerance = _Point * 10;
   // H1 patterns (index 2 in TF_LIST)
   DetectCandlePatterns(g_rates[2].rates, g_rates[2].count, PERIOD_H1,
                        g_zones, g_zoneCount, g_structure[2],
                        g_candleSignals, g_candleSignalCount, tolerance);
   // M15 patterns (index 3)
   DetectCandlePatterns(g_rates[3].rates, g_rates[3].count, PERIOD_M15,
                        g_zones, g_zoneCount, g_structure[3],
                        g_candleSignals, g_candleSignalCount, tolerance);
   // 7. Detect liquidity events (H1, M15)
   UpdateLiquidity(g_rates, g_structure, g_eqLevels, g_eqLevelCount,
                   g_liqEvents, g_liqEventCount, tolerance);
   // 8. Build trendlines (H4, H1)
   UpdateAllTrendlines(g_structure, g_rates, g_trendlines, g_trendlineCount);
   // 9. Detect key levels (all TFs)
   DetectKeyLevels(g_structure, tolerance * 5, g_keyLevels, g_keyLevelCount);
   // 10. Generate entry signals (checklist)
   double currentPrice = close[rates_total - 1];
   double spread_val   = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   GenerateEntrySignals(g_structure, g_zones, g_zoneCount,
                        g_liqEvents, g_liqEventCount,
                        g_breaks, g_breakCount,
                        g_candleSignals, g_candleSignalCount,
                        g_keyLevels, g_keyLevelCount,
                        g_rates, g_entries, g_entryCount,
                        currentPrice, spread_val);

   // 10b. Generate pattern entries (double top/bottom, breakout+retest)
   GeneratePatternEntries(g_structure, g_zones, g_zoneCount,
                          g_trendlines, g_trendlineCount,
                          g_candleSignals, g_candleSignalCount,
                          g_keyLevels, g_keyLevelCount,
                          g_rates, g_breaks, g_breakCount,
                          g_liqEvents, g_liqEventCount,
                          g_entries, g_entryCount,
                          currentPrice, spread_val);

   // 11. Manage trades (SL/TP trailing)
   double trailBuffer = spread_val * _Point + _Point * 5;
   UpdateTradeManagement(g_trade, currentPrice, g_structure[3],
                         g_entries, g_entryCount, trailBuffer);

   // 12. Draw everything
   DrawAll(g_zones, g_zoneCount,
           g_breaks, g_breakCount,
           g_trendlines, g_trendlineCount,
           g_candleSignals, g_candleSignalCount,
           g_liqEvents, g_liqEventCount,
           g_eqLevels, g_eqLevelCount,
           g_keyLevels, g_keyLevelCount,
           g_entries, g_entryCount,
           g_trade,
           currentPrice,
           g_structure);
   // 13. Update dashboard (DEBUG: disabled)
   //BuildDashboardData(g_dashboard, g_structure, g_zones, g_zoneCount,
   //                   g_breaks, g_breakCount, g_entries, g_entryCount, g_trade);
   //DrawDashboard(g_dashboard);

   // 14. Stage 2 alerts (Stage 1 fires from DrawZones when 5/5)
   FireStage2Alerts(g_entries, g_entryCount);

   return rates_total;
  }
//+------------------------------------------------------------------+
