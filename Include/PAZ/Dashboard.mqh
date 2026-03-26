#ifndef PAZ_DASHBOARD_MQH
#define PAZ_DASHBOARD_MQH

#include "Constants.mqh"
#include "Structures.mqh"
#include "Inputs.mqh"

//=============================================================================
// Internal helpers
//=============================================================================

string TrendStr(ENUM_TREND_DIR trend)
  {
   switch(trend)
     {
      case TREND_BULLISH: return "BULLISH";
      case TREND_BEARISH: return "BEARISH";
      default:            return "RANGING";
     }
  }

color TrendColor(ENUM_TREND_DIR trend)
  {
   switch(trend)
     {
      case TREND_BULLISH: return CLR_ENTRY_BUY;
      case TREND_BEARISH: return CLR_ENTRY_SELL;
      default:            return CLR_DASH_TEXT;
     }
  }

//=============================================================================
// DashLabel — create or update a single OBJ_LABEL on the chart
//=============================================================================
void DashLabel(string name, int x, int y, string text, color clr, int fontSize,
               ENUM_BASE_CORNER corner)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetString (0, name, OBJPROP_TEXT,        text);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    fontSize);
   ObjectSetString (0, name, OBJPROP_FONT,        "Consolas");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
  }

//=============================================================================
// BuildDashboardData — populate DashboardData from current indicator state
//=============================================================================
void BuildDashboardData(DashboardData        &dash,
                        const StructureState  &structure[],
                        const PriceZone       &zones[],
                        int                   zoneCount,
                        const StructureBreak  &breaks[],
                        int                   breakCount,
                        const EntrySignal     &entries[],
                        int                   entryCount,
                        const TradeState      &trade)
  {
   // Multi-timeframe bias (indices match TF_LIST: D1=0, H4=1, H1=2)
   dash.d1Bias = structure[0].trend;
   dash.h4Bias = structure[1].trend;
   dash.h1Bias = structure[2].trend;

   // Count active zones
   dash.activeZoneCount = 0;
   for(int i = 0; i < zoneCount; i++)
      if(zones[i].state == ZONE_ACTIVE)
         dash.activeZoneCount++;

   // Scan backwards through breaks for last M15 BOS and CHoCH
   dash.lastBOS   = "None";
   dash.lastCHoCH = "None";
   bool foundBOS = false, foundCHoCH = false;
   for(int i = breakCount - 1; i >= 0 && !(foundBOS && foundCHoCH); i--)
     {
      if(breaks[i].tf != PERIOD_M15) continue;

      if(!foundBOS &&
         (breaks[i].breakType == BREAK_BOS_BULL || breaks[i].breakType == BREAK_BOS_BEAR))
        {
         string side = (breaks[i].breakType == BREAK_BOS_BULL) ? "Bull" : "Bear";
         dash.lastBOS = StringFormat("%s @ %.5f", side, breaks[i].level);
         foundBOS = true;
        }

      if(!foundCHoCH &&
         (breaks[i].breakType == BREAK_CHOCH_BULL || breaks[i].breakType == BREAK_CHOCH_BEAR))
        {
         string side = (breaks[i].breakType == BREAK_CHOCH_BULL) ? "Bull" : "Bear";
         dash.lastCHoCH = StringFormat("%s @ %.5f", side, breaks[i].level);
         foundCHoCH = true;
        }
     }

   // Pending setups
   dash.pendingSetups = entryCount;

   // Trade status
   if(trade.isActive)
     {
      double rr = 0.0;
      if(MathAbs(trade.entryPrice - trade.initialSL) > 0.0)
         rr = MathAbs(trade.initialTP - trade.entryPrice) /
              MathAbs(trade.entryPrice - trade.initialSL);

      string dir = (trade.direction == ENTRY_BUY) ? "BUY" : "SELL";
      string be  = trade.isBreakeven ? " (BE)" : "";
      dash.tradeStatus = StringFormat("%s active R:R 1:%.1f%s", dir, rr, be);
     }
   else
      dash.tradeStatus = "Watching";
  }

//=============================================================================
// DrawDashboard — render the on-chart panel
//=============================================================================
void DrawDashboard(const DashboardData &dash)
  {
   if(!InpShowDashboard)
      return;

   const string PFX    = OBJ_PREFIX + "DASH_";
   const int    PW     = 180;
   const int    PH     = 80;
   const int    X0     = 10;
   const int    Y0     = 10;
   const int    ROWH   = 16;

   bool rightSide = (InpDashCorner == CORNER_RIGHT_UPPER ||
                     InpDashCorner == CORNER_RIGHT_LOWER);
   int labelX = rightSide ? (X0 + PW - 5) : (X0 + 6);

   // --- Background ---
   string bgName = PFX + "BG";
   if(ObjectFind(0, bgName) < 0)
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER,       InpDashCorner);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE,    X0);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE,    Y0);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE,        PW);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE,        PH);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR,      CLR_DASH_BG);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, C'60,60,60');
   ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, bgName, OBJPROP_HIDDEN,       true);

   int y = Y0 + 6;

   // Row 1: Bias — compact "D1 ▲  H4 ▲  H1 ▼"
   string biasRow = "";
   string tfs[] = {"D1", "H4", "H1"};
   ENUM_TREND_DIR biases[3];
   biases[0] = dash.d1Bias;
   biases[1] = dash.h4Bias;
   biases[2] = dash.h1Bias;

   // Draw each TF bias as a separate label for individual coloring
   int xOff = labelX;
   for(int i = 0; i < 3; i++)
     {
      string arrow = "";
      if(biases[i] == TREND_BULLISH) arrow = " +";
      else if(biases[i] == TREND_BEARISH) arrow = " -";
      else arrow = " =";

      string tfLabel = tfs[i] + arrow;
      string name = PFX + "B" + IntegerToString(i);

      if(rightSide)
        {
         DashLabel(name, X0 + PW - 6 - i * 58, y, tfLabel,
                   TrendColor(biases[i]), 9, InpDashCorner);
        }
      else
        {
         DashLabel(name, X0 + 6 + i * 58, y, tfLabel,
                   TrendColor(biases[i]), 9, InpDashCorner);
        }
     }
   y += ROWH + 2;

   // Row 2: Setup status
   DashLabel(PFX + "SETUP", labelX, y,
             dash.tradeStatus, CLR_DASH_TEXT, 8, InpDashCorner);
   y += ROWH;

   // Row 3: Zone count (subtle)
   DashLabel(PFX + "ZONES", labelX, y,
             StringFormat("%d zones active", dash.activeZoneCount),
             C'120,120,120', 7, InpDashCorner);
  }

#endif // PAZ_DASHBOARD_MQH
