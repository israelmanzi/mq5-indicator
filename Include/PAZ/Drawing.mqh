#ifndef PAZ_DRAWING_MQH
#define PAZ_DRAWING_MQH

#include "Constants.mqh"
#include "Structures.mqh"
#include "CandlePatterns.mqh"
#include "Inputs.mqh"

//=============================================================================
// Helper: timeframe short name for labels
//=============================================================================
string TFShortName(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_D1:  return "D1";
      case PERIOD_H4:  return "H4";
      case PERIOD_H1:  return "H1";
      case PERIOD_M15: return "M15";
      default:         return EnumToString(tf);
     }
  }

//=============================================================================
// Helper: check if TF visibility is enabled
//=============================================================================
bool IsTFVisible(ENUM_TIMEFRAMES tf)
  {
   // User toggle overrides
   if(tf == PERIOD_D1  && !InpShowD1Zones) return false;
   if(tf == PERIOD_H4  && !InpShowH4Zones) return false;
   if(tf == PERIOD_H1  && !InpShowH1Zones) return false;

   // Auto-filter by current chart timeframe using seconds (enum values are unreliable for comparison)
   int chartSec = PeriodSeconds(Period());
   int d1Sec    = PeriodSeconds(PERIOD_D1);   // 86400
   int h4Sec    = PeriodSeconds(PERIOD_H4);   // 14400
   int h1Sec    = PeriodSeconds(PERIOD_H1);   // 3600
   int m15Sec   = PeriodSeconds(PERIOD_M15);  // 900

   if(chartSec >= d1Sec)
     {
      // D1+ chart: D1 zones only
      return (tf == PERIOD_D1);
     }
   if(chartSec >= h4Sec)
     {
      // H4 chart: D1 + H4 zones
      return (tf == PERIOD_D1 || tf == PERIOD_H4);
     }
   if(chartSec >= h1Sec)
     {
      // H1 chart: H4 + H1 zones
      return (tf == PERIOD_H4 || tf == PERIOD_H1);
     }
   // M15 and below: H1 zones only
   return (tf == PERIOD_H1);
  }

//=============================================================================
// 1. DrawRectangle
//=============================================================================
void DrawRectangle(string name, datetime time1, double price1,
                   datetime time2, double price2, color clr,
                   int width, ENUM_LINE_STYLE style, bool fill)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_FILL, fill);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//=============================================================================
// 2. DrawHLine
//=============================================================================
void DrawHLine(string name, double price, color clr,
               int width, ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   else
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//=============================================================================
// 3. DrawTLine
//=============================================================================
void DrawTLine(string name, datetime time1, double price1,
               datetime time2, double price2, color clr,
               int width, ENUM_LINE_STYLE style, bool rayRight)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, rayRight);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//=============================================================================
// 4. DrawText
//=============================================================================
void DrawText(string name, datetime time, double price,
              string text, color clr, int fontSize,
              ENUM_ANCHOR_POINT anchor)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
     }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//=============================================================================
// 5. DrawArrow
//=============================================================================
void DrawArrow(string name, datetime time, double price,
               int arrowCode, color clr, int width)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   else
     {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
     }
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//=============================================================================
// Cleanup helper: delete stale objects with indices >= currentCount
//=============================================================================
void DeleteObjectAndSubs(string name)
  {
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   string subs[] = {"_lbl","_ref","_steep","_sl","_tp","_big","_top","_bot","_reflbl"};
   for(int s = 0; s < ArraySize(subs); s++)
     {
      string sub = name + subs[s];
      if(ObjectFind(0, sub) >= 0) ObjectDelete(0, sub);
     }
  }

// Stable name tracking: names drawn last cycle vs this cycle
string g_prevZoneNames[];
int    g_prevZoneNameCount = 0;

//+------------------------------------------------------------------+
//| Build a stable object name from zone identity                     |
//| Format: PAZ_Zone_DM_H1_1711382400                                |
//+------------------------------------------------------------------+
string ZoneObjName(const PriceZone &zone)
  {
   string typeStr = (zone.zoneType == ZONE_DEMAND) ? "DM" : "SP";
   string tfStr   = TFShortName(zone.tf);
   return OBJ_PREFIX + "Zone_" + typeStr + "_" + tfStr + "_" +
          IntegerToString((long)zone.timeCreated);
  }

//+------------------------------------------------------------------+
//| Remove zone objects that were drawn last cycle but not this one   |
//+------------------------------------------------------------------+
void CleanupStaleZones(const string &currentNames[], int currentCount)
  {
   for(int p = 0; p < g_prevZoneNameCount; p++)
     {
      bool stillExists = false;
      for(int c = 0; c < currentCount; c++)
        {
         if(g_prevZoneNames[p] == currentNames[c])
           { stillExists = true; break; }
        }
      if(!stillExists)
         DeleteObjectAndSubs(g_prevZoneNames[p]);
     }
   // Store current as previous for next cycle
   ArrayResize(g_prevZoneNames, currentCount);
   g_prevZoneNameCount = currentCount;
   for(int i = 0; i < currentCount; i++)
      g_prevZoneNames[i] = currentNames[i];
  }

// Index-based cleanup for non-zone objects (still used by other draw functions)
int g_prevBreakDrawn   = 0;
int g_prevTLDrawn      = 0;
int g_prevCPDrawn      = 0;
int g_prevLiqDrawn     = 0;
int g_prevEqDrawn      = 0;
int g_prevKLDrawn      = 0;
int g_prevEntDrawn     = 0;

void CleanupStaleObjects(string prefix, int currentCount, int &prevCount)
  {
   if(currentCount < prevCount)
     {
      for(int i = currentCount; i < prevCount; i++)
        {
         string name = StringFormat("%s%d", prefix, i);
         DeleteObjectAndSubs(name);
        }
     }
   prevCount = currentCount;
  }

//=============================================================================
// 6. DrawZones
//=============================================================================
void DrawZones(PriceZone &zones[], int zoneCount, double currentPrice)
  {
   datetime rightEdge = TimeCurrent() + 5 * PeriodSeconds(PERIOD_D1);

   // Collect names drawn this cycle for stale cleanup
   string drawnNames[];
   int    drawnCount = 0;

   // If InpNearestZones > 0, only show N nearest zones above and below price
   int drawnAbove = 0, drawnBelow = 0;
   int maxPerSide = (InpNearestZones > 0) ? InpNearestZones : 9999;

   // Sort indices by distance to current price
   int order[];
   ArrayResize(order, zoneCount);
   for(int i = 0; i < zoneCount; i++) order[i] = i;
   for(int i = 0; i < zoneCount - 1; i++)
     {
      for(int j = i + 1; j < zoneCount; j++)
        {
         double distI = MathMin(MathAbs(currentPrice - zones[order[i]].upper),
                                MathAbs(currentPrice - zones[order[i]].lower));
         double distJ = MathMin(MathAbs(currentPrice - zones[order[j]].upper),
                                MathAbs(currentPrice - zones[order[j]].lower));
         if(distJ < distI)
           { int tmp = order[i]; order[i] = order[j]; order[j] = tmp; }
        }
     }

   for(int idx = 0; idx < zoneCount; idx++)
     {
      int i = order[idx];

      if(!IsTFVisible(zones[i].tf))        continue;
      if(zones[i].state == ZONE_MITIGATED) continue; // skip broken zones

      // Nearest-zone filter
      if(InpNearestZones > 0)
        {
         double zoneMid = (zones[i].upper + zones[i].lower) / 2.0;
         if(zoneMid > currentPrice)
           { if(drawnAbove >= maxPerSide) continue; drawnAbove++; }
         else
           { if(drawnBelow >= maxPerSide) continue; drawnBelow++; }
        }

      bool isDemand = (zones[i].zoneType == ZONE_DEMAND);
      bool isFaded  = (zones[i].state == ZONE_FADED);
      string baseName = ZoneObjName(zones[i]);
      zones[i].objName = baseName;

      // Track this name
      ArrayResize(drawnNames, drawnCount + 1);
      drawnNames[drawnCount] = baseName;
      drawnCount++;

      // --- Style: active = dotted border, faded = thinner + muted color ---
      color borderClr;
      int   fontSize;
      if(isFaded)
        {
         borderClr = isDemand ? C'50,90,120' : C'140,65,65';  // muted versions
         fontSize  = 8;
        }
      else
        {
         borderClr = isDemand ? CLR_DEMAND_ACTIVE : CLR_SUPPLY_ACTIVE;
         fontSize  = 10;
        }

      DrawRectangle(baseName, zones[i].timeCreated, zones[i].upper,
                    rightEdge, zones[i].lower, borderClr, 1, STYLE_DOT, false);

      // --- Label ---
      string zoneLabel = isDemand ? "BUY ZONE" : "SELL ZONE";
      string fullLabel = zoneLabel + "  " + TFShortName(zones[i].tf);
      string bigLblName = baseName + "_big";
      double zoneMidPrice = (zones[i].upper + zones[i].lower) / 2.0;
      DrawText(bigLblName, zones[i].timeCreated, zoneMidPrice,
               fullLabel, borderClr, fontSize, ANCHOR_LEFT);

      // --- Refined zone: filled entry area (active zones only, not faded) ---
      if(!isFaded && zones[i].refinedUpper != 0.0 && zones[i].refinedLower != 0.0)
        {
         color refClr = isDemand ? CLR_DEMAND_REFINED : CLR_SUPPLY_REFINED;
         string refName = baseName + "_ref";
         DrawRectangle(refName, zones[i].timeCreated, zones[i].refinedUpper,
                       rightEdge, zones[i].refinedLower, refClr, 1, STYLE_SOLID, true);

         string refLblName = baseName + "_reflbl";
         double refMid = (zones[i].refinedUpper + zones[i].refinedLower) / 2.0;
         DrawText(refLblName, zones[i].timeCreated, refMid,
                  "ENTRY", refClr, 7, ANCHOR_LEFT);
        }
     }

   // Remove zones that were drawn last cycle but not this one
   CleanupStaleZones(drawnNames, drawnCount);
  }

//=============================================================================
// 7. DrawStructureBreaks
//=============================================================================
void DrawStructureBreaks(const StructureBreak &breaks[], int breakCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "BRK_", breakCount, g_prevBreakDrawn);

   if(!InpShowM15BOS)
      return;

   for(int i = 0; i < breakCount; i++)
     {
      // Only draw M15 breaks
      if(breaks[i].tf != PERIOD_M15)
         continue;

      color  clr = CLR_DASH_TEXT;
      string typeStr = "";

      switch(breaks[i].breakType)
        {
         case BREAK_BOS_BULL:
            clr     = CLR_BOS_BULL;
            typeStr = "BOS";
            break;
         case BREAK_BOS_BEAR:
            clr     = CLR_BOS_BEAR;
            typeStr = "BOS";
            break;
         case BREAK_CHOCH_BULL:
         case BREAK_CHOCH_BEAR:
            clr     = CLR_CHOCH;
            typeStr = "CHoCH";
            break;
         default:
            continue;
        }

      string baseName = OBJ_PREFIX + "BRK_" + IntegerToString(i);

      // Dashed horizontal line at break level
      DrawHLine(baseName, breaks[i].level, clr, 1, STYLE_DASH);

      // Text label
      string lblName = baseName + "_lbl";
      string label = typeStr + " " + DoubleToString(breaks[i].level, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
      DrawText(lblName, breaks[i].time, breaks[i].level, label, clr, 7, ANCHOR_LEFT_LOWER);
     }
  }

//=============================================================================
// 8. DrawTrendlines
//=============================================================================
void DrawTrendlines(TrendLine &lines[], int lineCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "TL_", lineCount, g_prevTLDrawn);

   if(!InpShowTrendlines)
      return;

   for(int i = 0; i < lineCount; i++)
     {
      // Color by steepness
      color clr = lines[i].isSteep ? CLR_TRENDLINE_STEEP : CLR_TRENDLINE;

      // Style by state
      ENUM_LINE_STYLE style;
      int width = 1;
      switch(lines[i].state)
        {
         case TL_ACTIVE:
            style = STYLE_SOLID;
            break;
         case TL_BROKEN:
            style = STYLE_DOT;
            break;
         case TL_RETESTING:
            style = STYLE_DASHDOT;
            width = 2;
            break;
         default:
            style = STYLE_SOLID;
            break;
        }

      string baseName = OBJ_PREFIX + "TL_" + IntegerToString(i);
      lines[i].objName = baseName;

      DrawTLine(baseName, lines[i].startTime, lines[i].startPrice,
                lines[i].endTime, lines[i].endPrice, clr, width, style, true);

      // Label steep trendlines
      if(lines[i].isSteep)
        {
         string lblName = baseName + "_lbl";
         double midPrice = (lines[i].startPrice + lines[i].endPrice) * 0.5;
         datetime midTime = (datetime)((long)lines[i].startTime +
                            ((long)lines[i].endTime - (long)lines[i].startTime) / 2);
         DrawText(lblName, midTime, midPrice, "STEEP", CLR_TRENDLINE_STEEP, 7, ANCHOR_LEFT_LOWER);
        }
     }
  }

//=============================================================================
// 9. DrawCandlePatterns
//=============================================================================
void DrawCandlePatterns(const CandleSignal &signals[], int signalCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "CP_", signalCount, g_prevCPDrawn);

   if(!InpShowCandleLabels)
      return;

   for(int i = 0; i < signalCount; i++)
     {
      // Only draw signals at key levels
      if(!signals[i].atKeyLevel)
         continue;

      bool   isBull = IsPatternBullish(signals[i].pattern);
      color  clr    = isBull ? CLR_PATTERN_BULL : CLR_PATTERN_BEAR;
      string label  = PatternName(signals[i].pattern);

      // Anchor: below for bullish, above for bearish
      ENUM_ANCHOR_POINT anchor = isBull ? ANCHOR_UPPER : ANCHOR_LOWER;

      string name = OBJ_PREFIX + "CP_" + IntegerToString(i);
      DrawText(name, signals[i].time, signals[i].price, label, clr, 7, anchor);
     }
  }

//=============================================================================
// 10. DrawLiquidityEvents
//=============================================================================
void DrawLiquidityEvents(const LiquidityEvent &events[], int eventCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "LIQ_", eventCount, g_prevLiqDrawn);

   if(!InpShowSweepMarkers)
      return;

   for(int i = 0; i < eventCount; i++)
     {
      string baseName = OBJ_PREFIX + "LIQ_" + IntegerToString(i);

      // Arrow: 233 up for bullish sweep, 234 down for bearish sweep
      int arrowCode = events[i].isBullish ? 233 : 234;
      DrawArrow(baseName, events[i].time, events[i].level, arrowCode, CLR_LIQUIDITY_SWEEP, 2);

      // "SWEEP" text label
      string lblName = baseName + "_lbl";
      ENUM_ANCHOR_POINT anchor = events[i].isBullish ? ANCHOR_UPPER : ANCHOR_LOWER;
      DrawText(lblName, events[i].time, events[i].level, "SWEEP", CLR_LIQUIDITY_SWEEP, 7, anchor);
     }
  }

//=============================================================================
// 11. DrawEqualLevels
//=============================================================================
void DrawEqualLevels(const EqualLevel &levels[], int levelCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "EQ_", levelCount, g_prevEqDrawn);

   if(!InpShowEqualHL)
      return;

   for(int i = 0; i < levelCount; i++)
     {
      string baseName = OBJ_PREFIX + "EQ_" + IntegerToString(i);

      // Dotted horizontal line
      DrawHLine(baseName, levels[i].price, CLR_EQUAL_HL, 1, STYLE_DOT);

      // Label: "EQH x2" or "EQL x3"
      string lblName = baseName + "_lbl";
      string typeStr = levels[i].isHighs ? "EQH" : "EQL";
      string label = typeStr + " x" + IntegerToString(levels[i].touchCount);
      DrawText(lblName, levels[i].lastTime, levels[i].price, label, CLR_EQUAL_HL, 7, ANCHOR_LEFT_LOWER);
     }
  }

//=============================================================================
// 12. DrawKeyLevels
//=============================================================================
void DrawKeyLevels(const KeyLevel &levels[], int levelCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "KL_", levelCount, g_prevKLDrawn);

   if(!InpShowKeyLevels)
      return;

   for(int i = 0; i < levelCount; i++)
     {
      string name = OBJ_PREFIX + "KL_" + IntegerToString(i);
      DrawHLine(name, levels[i].price, CLR_KEY_LEVEL, 1, STYLE_DOT);
     }
  }

//=============================================================================
// 13. DrawEntrySignals
//=============================================================================
void DrawEntrySignals(EntrySignal &entries[], int entryCount)
  {
   CleanupStaleObjects(OBJ_PREFIX + "ENT_", entryCount, g_prevEntDrawn);

   if(!InpAlertVisual)
      return;

   for(int i = 0; i < entryCount; i++)
     {
      bool   isBuy = (entries[i].direction == ENTRY_BUY);
      color  clr   = isBuy ? CLR_ENTRY_BUY : CLR_ENTRY_SELL;
      int    arrow = isBuy ? 233 : 234;
      string dir   = isBuy ? "BUY" : "SELL";

      string baseName = OBJ_PREFIX + "ENT_" + IntegerToString(i);
      entries[i].objNameEntry = baseName;

      // Entry arrow, width 3
      DrawArrow(baseName, entries[i].signalTime, entries[i].entryPrice, arrow, clr, 3);

      // Entry label: "BUY R:R 1:2.3" or "SELL R:R 1:1.5"
      string lblName = baseName + "_lbl";
      string label = dir + " R:R 1:" + DoubleToString(entries[i].rrRatio, 1);
      ENUM_ANCHOR_POINT anchor = isBuy ? ANCHOR_UPPER : ANCHOR_LOWER;
      DrawText(lblName, entries[i].signalTime, entries[i].entryPrice, label, clr, 8, anchor);

      // SL dashed line
      string slName = baseName + "_sl";
      entries[i].objNameSL = slName;
      DrawHLine(slName, entries[i].slPrice, CLR_SL, 1, STYLE_DASH);

      // TP dashed line
      string tpName = baseName + "_tp";
      entries[i].objNameTP = tpName;
      DrawHLine(tpName, entries[i].tpPrice, CLR_TP, 1, STYLE_DASH);
     }
  }

//=============================================================================
// 14. DrawTradeState
//=============================================================================
void DrawTradeState(const TradeState &trade)
  {
   if(!trade.isActive)
      return;

   string slName = OBJ_PREFIX + "Trade_SL";
   string tpName = OBJ_PREFIX + "Trade_TP";

   // SL line: width 2, DASHDOT if breakeven
   ENUM_LINE_STYLE slStyle = trade.isBreakeven ? STYLE_DASHDOT : STYLE_SOLID;
   DrawHLine(slName, trade.currentSL, CLR_SL, 2, slStyle);

   // TP line: width 2
   DrawHLine(tpName, trade.currentTP, CLR_TP, 2, STYLE_SOLID);

   // SL label
   string slLblName = slName + "_lbl";
   string slLabel;
   if(trade.isBreakeven && trade.trailingSwings > 0)
      slLabel = "SL (Trail x" + IntegerToString(trade.trailingSwings) + ")";
   else if(trade.isBreakeven)
      slLabel = "SL (BE)";
   else
      slLabel = "SL";
   DrawText(slLblName, TimeCurrent(), trade.currentSL, slLabel, CLR_SL, 7, ANCHOR_LEFT_LOWER);

   // TP label
   string tpLblName = tpName + "_lbl";
   DrawText(tpLblName, TimeCurrent(), trade.currentTP, "TP", CLR_TP, 7, ANCHOR_LEFT_LOWER);
  }

//=============================================================================
// 15. DrawAll
//=============================================================================
void DrawAll(PriceZone          &zones[],         int zoneCount,
             const StructureBreak &breaks[],      int breakCount,
             TrendLine           &lines[],         int lineCount,
             const CandleSignal  &candleSignals[], int candleSignalCount,
             const LiquidityEvent &liqEvents[],    int liqEventCount,
             const EqualLevel    &eqLevels[],      int eqLevelCount,
             const KeyLevel      &keyLevels[],     int keyLevelCount,
             EntrySignal         &entries[],        int entryCount,
             const TradeState    &trade,
             double              currentPrice)
  {
   // DEBUG: zones only — enable layers one by one for validation
   DrawZones(zones, zoneCount, currentPrice);
   //DrawStructureBreaks(breaks, breakCount);
   //DrawTrendlines(lines, lineCount);
   //DrawCandlePatterns(candleSignals, candleSignalCount);
   //DrawLiquidityEvents(liqEvents, liqEventCount);
   //DrawEqualLevels(eqLevels, eqLevelCount);
   //DrawKeyLevels(keyLevels, keyLevelCount);
   //DrawEntrySignals(entries, entryCount);
   //DrawTradeState(trade);

   ChartRedraw(0);
  }

#endif // PAZ_DRAWING_MQH
