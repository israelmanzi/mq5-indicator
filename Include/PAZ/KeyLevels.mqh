#ifndef PAZ_KEYLEVELS_MQH
#define PAZ_KEYLEVELS_MQH

#include "Structures.mqh"

//+------------------------------------------------------------------+
//| Returns true if price is near a round psychological level        |
//+------------------------------------------------------------------+
bool IsRoundNumber(double price, int digits)
  {
   double rounded;
   if(digits <= 2)
      rounded = MathRound(price);
   else if(digits == 3)
      rounded = MathRound(price * 10.0) / 10.0;
   else
      rounded = MathRound(price * 100.0) / 100.0;

   return (MathAbs(price - rounded) < _Point * 5);
  }

//+------------------------------------------------------------------+
//| Detect key price levels from swing points across all timeframes  |
//+------------------------------------------------------------------+
void DetectKeyLevels(const StructureState &structure[], double tolerance,
                     KeyLevel &levels[], int &levelCount)
  {
   //--- Reset output
   ArrayResize(levels, 0);
   levelCount = 0;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   //--- Scan every TF and every swing point
   for(int tf = 0; tf < TF_COUNT; tf++)
     {
      ENUM_TIMEFRAMES curTF = TF_LIST[tf];

      for(int s = 0; s < structure[tf].swingCount; s++)
        {
         double swingPrice = structure[tf].swings[s].price;

         //--- Try to match an existing level
         bool matched = false;
         for(int k = 0; k < levelCount; k++)
           {
            if(MathAbs(levels[k].price - swingPrice) <= tolerance)
              {
               //--- Update running average price
               double totalTouches = (double)levels[k].touchCount;
               levels[k].price = (levels[k].price * totalTouches + swingPrice) /
                                  (totalTouches + 1.0);
               levels[k].touchCount++;

               //--- Count distinct TF if this is a new one
               if(curTF != levels[k].primaryTF)
                 {
                  levels[k].tfCount++;
                  //--- Promote primaryTF to higher timeframe (lower index = higher TF)
                  if(tf < ArrayBsearch(TF_LIST, levels[k].primaryTF))
                     levels[k].primaryTF = curTF;
                 }

               matched = true;
               break;
              }
           }

         if(!matched)
           {
            //--- Create a new entry
            ArrayResize(levels, levelCount + 1);
            levels[levelCount].price      = swingPrice;
            levels[levelCount].touchCount = 1;
            levels[levelCount].tfCount    = 1;
            levels[levelCount].primaryTF  = curTF;
            levels[levelCount].isRound    = IsRoundNumber(swingPrice, digits);
            levelCount++;
           }
        }
     }

   //--- Filter: keep if touchCount >= 3 OR tfCount >= 2 OR isRound
   int kept = 0;
   for(int k = 0; k < levelCount; k++)
     {
      if(levels[k].touchCount >= 3 || levels[k].tfCount >= 2 || levels[k].isRound)
        {
         if(k != kept)
            levels[kept] = levels[k];
         kept++;
        }
     }
   levelCount = kept;
   ArrayResize(levels, levelCount);

   //--- Bubble sort descending by touchCount
   for(int i = 0; i < levelCount - 1; i++)
     {
      for(int j = 0; j < levelCount - 1 - i; j++)
        {
         if(levels[j].touchCount < levels[j + 1].touchCount)
           {
            KeyLevel tmp   = levels[j];
            levels[j]      = levels[j + 1];
            levels[j + 1]  = tmp;
           }
        }
     }

   //--- Cap at 20
   if(levelCount > 20)
     {
      levelCount = 20;
      ArrayResize(levels, 20);
     }
  }

#endif // PAZ_KEYLEVELS_MQH
