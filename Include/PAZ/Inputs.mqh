#ifndef PAZ_INPUTS_MQH
#define PAZ_INPUTS_MQH

//=============================================================================
// Swing Points
//=============================================================================
input group "=== Swing Points ==="
input int    InpSwingLookbackD1  = 5;    // D1 swing lookback (bars)
input int    InpSwingLookbackH4  = 3;    // H4 swing lookback (bars)
input int    InpSwingLookbackH1  = 3;    // H1 swing lookback (bars)
input int    InpSwingLookbackM15 = 2;    // M15 swing lookback (bars)

//=============================================================================
// Zones
//=============================================================================
input group "=== Zones ==="
input int    InpMaxZonesPerTF      = 5;      // Max active zones per timeframe
input int    InpZoneFadeBars       = 200;    // Bars before untouched zone fades
input int    InpMitigatedKeepBars  = 100;    // Bars to keep mitigated zones visible
input double InpZoneMinQuality     = 5.0;    // Minimum zone quality score (0-10)

//=============================================================================
// Market Structure
//=============================================================================
input group "=== Market Structure ==="
input bool   InpShowBOS   = true;    // Draw Break-of-Structure lines
input bool   InpShowCHoCH = true;    // Draw Change-of-Character lines

//=============================================================================
// Trendlines
//=============================================================================
input group "=== Trendlines ==="
input int    InpTrendlineSteepAngle = 80;    // Angle (degrees) above which a trendline is "steep"

//=============================================================================
// Entry Signals
//=============================================================================
input group "=== Entry Signals ==="
input double InpMinRR = 2.0;    // Minimum reward-to-risk ratio for a valid setup

//=============================================================================
// Alerts
//=============================================================================
input group "=== Alerts ==="
input bool   InpAlertPush   = true;    // Send push notifications
input bool   InpAlertSound  = true;    // Play alert sound
input bool   InpAlertVisual = true;    // Show visual alert pop-up

//=============================================================================
// Timeframe Display
//=============================================================================
input group "=== Timeframe Display ==="
input bool   InpShowD1Zones  = true;    // Show D1 supply/demand zones
input bool   InpShowH4Zones  = true;    // Show H4 supply/demand zones
input bool   InpShowH1Zones  = true;    // Show H1 supply/demand zones
input bool   InpShowM15BOS   = true;    // Show M15 BOS/CHoCH markers

//=============================================================================
// Visual Layers (clean chart by default, toggle ON for detail)
//=============================================================================
input group "=== Visual Layers ==="
input bool   InpShowTrendlines    = false;   // Show trendlines
input bool   InpShowCandleLabels  = false;   // Show candlestick pattern labels
input bool   InpShowEqualHL       = false;   // Show equal highs/lows
input bool   InpShowKeyLevels     = false;   // Show key levels
input bool   InpShowSweepMarkers  = false;   // Show liquidity sweep markers
input int    InpNearestZones      = 3;       // Max zones to show above+below price (0=all)

//=============================================================================
// Dashboard
//=============================================================================
input group "=== Dashboard ==="
input bool               InpShowDashboard = true;                  // Display on-chart dashboard
input ENUM_BASE_CORNER   InpDashCorner    = CORNER_RIGHT_UPPER;    // Dashboard anchor corner

#endif // PAZ_INPUTS_MQH
