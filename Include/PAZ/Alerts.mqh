#ifndef PAZ_ALERTS_MQH
#define PAZ_ALERTS_MQH

#include "Structures.mqh"
#include "Inputs.mqh"

// Alert dedup arrays
string g_alertedStage1[];
int    g_alertedStage1Count = 0;
string g_alertedStage2[];
int    g_alertedStage2Count = 0;

//+------------------------------------------------------------------+
bool AlreadyAlerted(const string &list[], int count, string id)
  {
   for(int i = 0; i < count; i++)
      if(list[i] == id) return true;
   return false;
  }

//+------------------------------------------------------------------+
void SendAllChannels(string msg)
  {
   Print("PAZ ALERT: ", msg);
   if(InpAlertSound) Alert(msg);
   if(InpAlertPush)  SendNotification(msg);
  }

//+------------------------------------------------------------------+
void FireStage1Alert(string symbol, string dir, double zoneLower,
                     double zoneUpper, int digits)
  {
   string zoneId = DoubleToString(zoneLower, digits) + "_" + dir;
   if(AlreadyAlerted(g_alertedStage1, g_alertedStage1Count, zoneId))
      return;

   string msg = StringFormat("PAZ %s %s ZONE READY 5/5 | Zone %s-%s",
                 symbol, dir,
                 DoubleToString(zoneLower, digits),
                 DoubleToString(zoneUpper, digits));
   SendAllChannels(msg);

   ArrayResize(g_alertedStage1, g_alertedStage1Count + 1);
   g_alertedStage1[g_alertedStage1Count] = zoneId;
   g_alertedStage1Count++;
  }

//+------------------------------------------------------------------+
void FireStage2Alerts(const EntrySignal &entries[], int entryCount)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   for(int i = 0; i < entryCount; i++)
     {
      string entryId = IntegerToString((long)entries[i].signalTime) + "_" +
                       IntegerToString(entries[i].direction);
      if(AlreadyAlerted(g_alertedStage2, g_alertedStage2Count, entryId))
         continue;

      string dir = (entries[i].direction == ENTRY_BUY) ? "BUY" : "SELL";
      string slStr = DoubleToString(entries[i].slPrice, digits);
      string tpStr = (entries[i].tpPrice > 0) ? DoubleToString(entries[i].tpPrice, digits) : "---";

      string msg = StringFormat("PAZ %s %s @ %s | SL %s | TP %s",
                    _Symbol, dir,
                    DoubleToString(entries[i].entryPrice, digits),
                    slStr, tpStr);
      SendAllChannels(msg);

      ArrayResize(g_alertedStage2, g_alertedStage2Count + 1);
      g_alertedStage2[g_alertedStage2Count] = entryId;
      g_alertedStage2Count++;
     }
  }

#endif
