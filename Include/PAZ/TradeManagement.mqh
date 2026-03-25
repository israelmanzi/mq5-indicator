#ifndef PAZ_TRADEMANAGEMENT_MQH
#define PAZ_TRADEMANAGEMENT_MQH

#include "Structures.mqh"

//-----------------------------------------------------------------------------
// InitTrade
// Initialise a TradeState from a confirmed EntrySignal.
//-----------------------------------------------------------------------------
void InitTrade(TradeState &trade, const EntrySignal &entry)
  {
   trade.isActive       = true;
   trade.direction      = entry.direction;
   trade.entryPrice     = entry.entryPrice;
   trade.currentSL      = entry.slPrice;
   trade.currentTP      = entry.tpPrice;
   trade.initialSL      = entry.slPrice;
   trade.initialTP      = entry.tpPrice;
   trade.isBreakeven    = false;
   trade.trailingSwings = 0;
   trade.entryTime      = entry.signalTime;
   trade.objNameSL      = entry.objNameSL;
   trade.objNameTP      = entry.objNameTP;
  }

//-----------------------------------------------------------------------------
// CheckTradeExit
// Returns true and deactivates the trade if price has hit SL or TP.
//-----------------------------------------------------------------------------
bool CheckTradeExit(TradeState &trade, double currentPrice)
  {
   if(!trade.isActive)
      return false;

   if(trade.direction == ENTRY_BUY)
     {
      if(currentPrice <= trade.currentSL || currentPrice >= trade.currentTP)
        {
         trade.isActive = false;
         return true;
        }
     }
   else // ENTRY_SELL
     {
      if(currentPrice >= trade.currentSL || currentPrice <= trade.currentTP)
        {
         trade.isActive = false;
         return true;
        }
     }

   return false;
  }

//-----------------------------------------------------------------------------
// CheckBreakeven
// Moves currentSL to entryPrice once price achieves a 1:1 risk/reward.
//-----------------------------------------------------------------------------
void CheckBreakeven(TradeState &trade, double currentPrice)
  {
   if(!trade.isActive || trade.isBreakeven)
      return;

   double risk = MathAbs(trade.entryPrice - trade.initialSL);

   double profit;
   if(trade.direction == ENTRY_BUY)
      profit = currentPrice - trade.entryPrice;
   else // ENTRY_SELL
      profit = trade.entryPrice - currentPrice;

   if(profit >= risk)
     {
      trade.currentSL  = trade.entryPrice;
      trade.isBreakeven = true;
     }
  }

//-----------------------------------------------------------------------------
// TrailSLToSwings
// Trails the stop loss to the most recent swing low (BUY) or swing high (SELL)
// that formed after trade entry, once breakeven is already achieved.
//-----------------------------------------------------------------------------
void TrailSLToSwings(TradeState &trade, const StructureState &m15State, double buffer)
  {
   if(!trade.isActive || !trade.isBreakeven)
      return;

   int count = m15State.swingCount;

   if(trade.direction == ENTRY_BUY)
     {
      // Find the most recent swing low after entryTime
      double bestPrice  = -1.0;
      datetime bestTime = 0;

      for(int i = 0; i < count; i++)
        {
         const SwingPoint &sp = m15State.swings[i];
         if(sp.type == SWING_LOW && sp.time > trade.entryTime)
           {
            if(bestTime == 0 || sp.time > bestTime)
              {
               bestTime  = sp.time;
               bestPrice = sp.price;
              }
           }
        }

      if(bestPrice > 0.0)
        {
         double newSL = bestPrice - buffer;
         if(newSL > trade.currentSL)
           {
            trade.currentSL = newSL;
            trade.trailingSwings++;
           }
        }
     }
   else // ENTRY_SELL
     {
      // Find the most recent swing high after entryTime
      double bestPrice  = -1.0;
      datetime bestTime = 0;

      for(int i = 0; i < count; i++)
        {
         const SwingPoint &sp = m15State.swings[i];
         if(sp.type == SWING_HIGH && sp.time > trade.entryTime)
           {
            if(bestTime == 0 || sp.time > bestTime)
              {
               bestTime  = sp.time;
               bestPrice = sp.price;
              }
           }
        }

      if(bestPrice > 0.0)
        {
         double newSL = bestPrice + buffer;
         if(newSL < trade.currentSL)
           {
            trade.currentSL = newSL;
            trade.trailingSwings++;
           }
        }
     }
  }

//-----------------------------------------------------------------------------
// UpdateTradeManagement
// Top-level per-tick update: initialise from latest signal if flat, then
// check exit → breakeven → trailing stop.
//-----------------------------------------------------------------------------
void UpdateTradeManagement(TradeState        &trade,
                           double             currentPrice,
                           const StructureState &m15State,
                           const EntrySignal  &entries[],
                           int                entryCount,
                           double             buffer)
  {
   // Initialise from the most recent entry signal when no trade is active
   if(!trade.isActive && entryCount > 0)
     {
      InitTrade(trade, entries[entryCount - 1]);
     }

   if(trade.isActive)
     {
      if(CheckTradeExit(trade, currentPrice))
         return; // trade closed; nothing more to do this tick

      CheckBreakeven(trade, currentPrice);
      TrailSLToSwings(trade, m15State, buffer);
     }
  }

#endif // PAZ_TRADEMANAGEMENT_MQH
