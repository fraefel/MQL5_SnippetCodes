//+------------------------------------------------------------------+
//|                                                 openBuyOrder.mq5 |
//|                                    André Augusto Giannotti Scotá |
//|                              https://sites.google.com/view/a2gs/ |
//+------------------------------------------------------------------+
#property copyright "André Augusto Giannotti Scotá"
#property link      "https://sites.google.com/view/a2gs/"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade trade;

void OnTick()
{
   double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   MqlRates priceInfo[];

   ArraySetAsSeries(priceInfo, true);

   int priceData = CopyRates(_Symbol /*Symbol()*/, _Period /*Period()*/, 0, 3, priceInfo);

   // Buy when candle is bullish
   if(priceInfo[1].close > priceInfo[1].open){

      if(PositionsTotal() == 0){
         double volume  = 0.10;
         double price   = ask;
         double sl      = ask - 300 * _Point;
         double tp      = ask + 150 * _Point;
         string comment = "simple buy order";

         trade.Buy(volume, _Symbol, price, sl, tp, comment);

         uint ret = trade.ResultRetcode();

         if(ret != TRADE_RETCODE_PLACED && ret != TRADE_RETCODE_DONE){
            printf("Return [%s]", trade.ResultRetcodeDescription());
         }else{
            printf("Order [%lu] Deal [%lu] Return [%s]", trade.ResultOrder(), trade.ResultDeal(), trade.ResultRetcodeDescription());
         }
      }
   }
}