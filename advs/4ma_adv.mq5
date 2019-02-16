//+------------------------------------------------------------------+
//|                                           ma2_crossing_lines.mq5 |
//|                                         Copyright 2019, Michael. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Cub@Invest."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_color1  clrBlack

//////Code added by Peter///////////////////
MqlDateTime current_time;
MqlDateTime  start_ops;
MqlDateTime  end_ops;
int start_hour=9;
int start_min=40;
int end_hour=18;
double volume=1; // volumen de minicontratos
enum trend{rising=1,falling=2,undefined=3}; // debe ser muyúsculas
//////End code added by Peter///////////////////

int MA_handle=0;
int EA_Magic=987654;   // EA Magic Number

double initial_balance,current_balance;
double max_day_loss=80;

//+------------------------------------------------------------------+
//| Buy negotiation function                                         |
//+------------------------------------------------------------------+
bool Buy(double ask_price,MqlTradeRequest & mrequest,MqlTradeResult & mresult,double stop_loss,bool buyCondition)
  {
   mrequest.action=TRADE_ACTION_DEAL;                                // immediate order execution
   mrequest.price=NormalizeDouble(ask_price,_Digits);          // latest ask price
   mrequest.symbol=_Symbol;                                         // currency pair
   mrequest.volume=volume;                                            // number of lots to trade
   mrequest.magic=EA_Magic;                                        // Order Magic Number
   mrequest.type = ORDER_TYPE_BUY;                                     // Buy Order
   mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   mrequest.deviation=80;                                            // Deviation from current price

   if(buyCondition)
     {
      mrequest.sl=stop_loss; // Stop Loss
      mrequest.tp=(mrequest.price-stop_loss)*1+mrequest.price;
     }

//--- send order
   OrderSend(mrequest,mresult);

// get the result code
   if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
     {
      Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
      return true;
     }
   else
     {
      Alert("The Buy order request could not be completed -error:",GetLastError());
      ResetLastError();
      return false;
     }
  }
//+------------------------------------------------------------------+
//| Sell negotiation function                                   |
//+------------------------------------------------------------------+
bool Sell(double bid_price,MqlTradeRequest &mrequest,MqlTradeResult &mresult,double stop_loss,bool sellCondition)
  {
   mrequest.action=TRADE_ACTION_DEAL;                                 // immediate order execution
   mrequest.price=NormalizeDouble(bid_price,_Digits);          // latest Bid price
   mrequest.symbol=_Symbol;                                         // currency pair
   mrequest.volume=volume;                                            // number of lots to trade
   mrequest.magic=EA_Magic;                                        // Order Magic Number
   mrequest.type= ORDER_TYPE_SELL;                                     // Sell Order
   mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   mrequest.deviation=80;                                           // Deviation from current price
   if(sellCondition)
     {
      mrequest.sl=stop_loss; // Stop Loss
      mrequest.tp=mrequest.price-(stop_loss-mrequest.price)*1;
     }

//--- send order
   OrderSend(mrequest,mresult);
   if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
     {
      Alert("A Sell order has been successfully placed with Ticket#:",mresult.order,"!!");
      return true;
     }
   else
     {
      Alert("The Sell order request could not be completed -error:",GetLastError());
      ResetLastError();
      return false;
     }
  }
//+------------------------------------------------------------------+
//| Trailing Stop function                                   |
//+------------------------------------------------------------------+

bool Trailing_Stop(MqlTradeRequest &mrequest,MqlTradeResult &mresult,double stl)
  {
   bool order_send=false;
   double tkp=0;
   int total=PositionsTotal(); // número de posições abertas   
//--- iterar sobre todas as posições abertas
   for(int i=0; i<total; i++)
     {
      //--- parâmetros da posição
      ulong  position_ticket=PositionGetTicket(i);// bilhete da posição
      string position_symbol=PositionGetString(POSITION_SYMBOL); // símbolo 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // número de signos depois da coma
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber da posição
      double vol=PositionGetDouble(POSITION_VOLUME);    // volume da posição
      double sl=PositionGetDouble(POSITION_SL);  // Stop Loss da posição
      double tp=PositionGetDouble(POSITION_TP);  // Take-Profit da posição
      double profit=PositionGetDouble(POSITION_PROFIT);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // tipo da posição

      if(magic==EA_Magic)
        {
         if(type==POSITION_TYPE_BUY)
           {
            double ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            if(ask-sl<0.8*(tp-sl))
               return false;
            if(profit>=65)
              {
               stl=NormalizeDouble(ask,_Digits)-25;
               tkp=(NormalizeDouble(ask,_Digits)-stl)*1+NormalizeDouble(ask,_Digits);
              }else{
                tkp=(NormalizeDouble(ask,_Digits)-stl)*0.5+NormalizeDouble(ask,_Digits);                
              }
            tkp=round(tkp/5)*5;
            
           }

         if(type==POSITION_TYPE_SELL)
           {

            double bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            if(sl-bid<0.8*(sl-tp))
               return false;
            if(profit>=65)
              {
               stl=NormalizeDouble(bid,_Digits)+25;
               tkp=NormalizeDouble(bid,_Digits)-(stl-NormalizeDouble(bid,_Digits))*1;
              }else{
                   tkp=NormalizeDouble(bid,_Digits)-(stl-NormalizeDouble(bid,_Digits))*0.5;
              }           
            tkp=round(tkp/5)*5;              
           }
         //--- saída de informações sobre a posição
         PrintFormat("#%I64u %s  %s  %.2f  %s  sl: %s  tp: %s  [%I64d]",
                     position_ticket,
                     position_symbol,
                     EnumToString(type),
                     vol,
                     DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                     DoubleToString(sl,digits),
                     DoubleToString(tp,digits),
                     magic);

         ZeroMemory(mrequest);
         ZeroMemory(mresult);
         //--- definição dos parâmetros de operação
         mrequest.action  =TRADE_ACTION_SLTP; // tipo de operação de negociação
         mrequest.position=position_ticket;   // bilhete da posição
         mrequest.symbol=position_symbol;     // símbolo 
         mrequest.sl      =(NormalizeDouble(stl,_Digits));                // Stop Loss da posição
         mrequest.tp      =(NormalizeDouble(tkp,_Digits));                // Take Profit da posição
         mrequest.magic=EA_Magic;             // MagicNumber da posição
         //--- saída de informações sobre a modificação
         PrintFormat("Modify #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
         //--- envio do pedido
         order_send=OrderSend(mrequest,mresult);
         if(!order_send)
            PrintFormat("OrderSend error %d",GetLastError());  // se não for possível enviar o pedido, exibir o código de erro
         //--- informações sobre a operação   
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",mresult.retcode,mresult.deal,mresult.order);
        }

     }
   return order_send;
  }
//+------------------------------------------------------------------+
//| Close open positions function                                    |
//+------------------------------------------------------------------+
bool Close_Positions(MqlTradeRequest &mrequest,MqlTradeResult &mresult)
  {
   bool order_send=false;
   double price=0;

   int total=PositionsTotal(); // número de posições abertas
//--- iterar sobre todas as posições abertas
   for(int i=0; i<total; i++)
     {
      //--- parâmetros da ordem
      ulong  position_ticket=PositionGetTicket(i);// bilhete da posição
      string position_symbol=PositionGetString(POSITION_SYMBOL); // símbolo 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // número de signos depois da coma
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber da posição
      double vol=PositionGetDouble(POSITION_VOLUME);    // volume da posição
      double sl=PositionGetDouble(POSITION_SL);  // Stop Loss da posição
      double tp=PositionGetDouble(POSITION_TP);  // Take-Profit da posição
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // tipo da posição
      ENUM_ORDER_TYPE order_type=ORDER_TYPE_BUY;
      // Cheking signal for trailling stop
      if(magic==EA_Magic)
        {
         double ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
         double bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
         if(type==POSITION_TYPE_BUY)
           {
            order_type=ORDER_TYPE_SELL;
            price=NormalizeDouble(bid,_Digits);          // latest Bid price
           }

         if(type==POSITION_TYPE_SELL)
           {
            order_type=ORDER_TYPE_BUY;
            price=NormalizeDouble(ask,_Digits);          // latest Ask price
           }
         //--- saída de informações sobre a posição
         PrintFormat("#%I64u %s  %s  %.2f  %s  sl: %s  tp: %s  [%I64d]",
                     position_ticket,
                     position_symbol,
                     EnumToString(type),
                     vol,
                     DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                     DoubleToString(sl,digits),
                     DoubleToString(tp,digits),
                     magic);

         ZeroMemory(mrequest);
         ZeroMemory(mresult);
         //--- definição dos parâmetros de operação
         mrequest.action  =TRADE_ACTION_DEAL; // tipo de operação de negociação
         mrequest.symbol=position_symbol;     // símbolo 
         mrequest.type=order_type;
         mrequest.magic=EA_Magic;             // MagicNumber da posição
         mrequest.volume=vol;
         mrequest.price=price;
         mrequest.type_filling=ORDER_FILLING_FOK;                          // Order execution type
         mrequest.deviation=80;                                           // Deviation from current price
         //--- envio do pedido
         order_send=OrderSend(mrequest,mresult);
         if(!order_send)
            PrintFormat("OrderSend error %d",GetLastError());  // se não for possível enviar o pedido, exibir o código de erro
         //--- informações sobre a operação   
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",mresult.retcode,mresult.deal,mresult.order);
        }

     }
   return order_send;
  }

//+------------------------------------------------------------------+
//| Minimum identification function                                  |
//+------------------------------------------------------------------+
double Get_Minimum(int bars_to_analyze,ENUM_TIMEFRAMES timeframes)
  {
   double lowest=3e5;
   int bars=Bars(_Symbol,timeframes);
   for(int i=1; i<bars_to_analyze; i++)
     {
      if(iLow(_Symbol,timeframes,i)<lowest)
         lowest=iLow(_Symbol,timeframes,i);
     }
   return lowest;
  }

//+------------------------------------------------------------------+
//| Maximum identification function                                |
//+------------------------------------------------------------------+
double Get_Maximum(int bars_to_analyze,ENUM_TIMEFRAMES timeframes)
  {
   double highest=0;
   int bars=Bars(_Symbol,timeframes);
   for(int i=1; i<bars_to_analyze; i++)
     {
      if(iHigh(_Symbol,timeframes,i)>highest)
         highest=iHigh(_Symbol,timeframes,i);
     }
   return highest;
  }

//+------------------------------------------------------------------+
//| Trend identification function                                    |
//+------------------------------------------------------------------+
int Get_Trend(ENUM_TIMEFRAMES timeframes)
  {
   int bars_to_analyze=0;
   double high_1=0;
   double high_2=0;
   double low_1=3e5;
   double low_2=3e5;
   int bars=0;
   int index=0;
   switch(timeframes)
     {
      case PERIOD_M1:   
      bars_to_analyze=10;
      //Chequear iLowest()
      for(int i=0; i<bars_to_analyze/2; i++)
        {
         if(iLow(_Symbol,timeframes,i)<low_1)
            low_1=iLow(_Symbol,timeframes,i);

         if(iHigh(_Symbol,timeframes,i)>high_1)
            high_1=iHigh(_Symbol,timeframes,i);
        }
      for(int i=bars_to_analyze/2; i<bars_to_analyze; i++)
        {
         if(iLow(_Symbol,timeframes,i)<low_2)
            low_2=iLow(_Symbol,timeframes,i);

         if(iHigh(_Symbol,timeframes,i)>high_2)
            high_2=iHigh(_Symbol,timeframes,i);
        }
      break;
      case PERIOD_M5: bars_to_analyze=8;
      for(int i=0; i<bars_to_analyze/2; i++)
        {
         if(iLow(_Symbol,timeframes,i)<low_1)
            low_1=iLow(_Symbol,timeframes,i);

         if(iHigh(_Symbol,timeframes,i)>high_1)
            high_1=iHigh(_Symbol,timeframes,i);
        }
      for(int i=bars_to_analyze/2; i<bars_to_analyze; i++)
        {
         if(iLow(_Symbol,timeframes,i)<low_2)
            low_2=iLow(_Symbol,timeframes,i);

         if(iHigh(_Symbol,timeframes,i)>high_2)
            high_2=iHigh(_Symbol,timeframes,i);
        }
      break;
     }
   if((low_1>low_2) && (high_1>high_2))
      return 1; // rising
   if((low_1<low_2) && (high_1<high_2))
      return 2; // falling
   else return 3; //undefined
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Comienzo de la estrategia
   ObjectsDeleteAll(0);
   MA_handle=iCustom(NULL,0,"Examples\\4Moving Average");
   if(MA_handle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }

   initial_balance=AccountInfoDouble(ACCOUNT_BALANCE);
   printf("Initial day balance: %s",DoubleToString(initial_balance));

//--- ok
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//////Code added by Peter///////////////////
//ver si hay formas más adecuadas de trabajar con el tiempo
   TimeCurrent(current_time);
   TimeCurrent(start_ops);
   TimeCurrent(end_ops);
   start_ops.hour=start_hour;
   start_ops.min=start_min;
   start_ops.sec=0;
   end_ops.hour=end_hour;
   end_ops.min=0;
   end_ops.sec=0;

   current_balance=AccountInfoDouble(ACCOUNT_BALANCE)-initial_balance;

    //optimizar las flags
   if(current_time.hour==end_hour)
      initial_balance=AccountInfoDouble(ACCOUNT_BALANCE);

   bool available_to_op=(StructToTime(current_time)>StructToTime(start_ops)) && 
                        (StructToTime(current_time)<StructToTime(end_ops)) && 
                        (current_balance>-max_day_loss); //O último termo garante não perder mais de R$80 por dia.
   bool close_ops=(StructToTime(current_time)>StructToTime(end_ops));

//////End code added by Peter///////////////////
//---
   double maFastest[];
   double maFast[];
   double maSlow[];
   double maSlowest[];
   ArraySetAsSeries(maFastest,true);
   ArraySetAsSeries(maFast,true);
   ArraySetAsSeries(maSlow,true);
   ArraySetAsSeries(maSlowest,true);
   CopyBuffer(MA_handle,0,0,3,maFastest);
   CopyBuffer(MA_handle,1,0,3,maFast);
   CopyBuffer(MA_handle,2,0,3,maSlow);
   CopyBuffer(MA_handle,3,0,3,maSlowest);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

   bool buyOpened=false;
   bool sellOpened=false;

    //estamos posicionados? Que tipo de posición?
   if(PositionSelect(_Symbol)==true)
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         buyOpened=true;
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         sellOpened=true;
        }
     }

// MAs trends
   bool ma_rising=((maFast[1]<maFast[0]) && (maSlow[1]<maSlow[0]));
   int tendency=Get_Trend(PERIOD_M1);
   int primary_trend=Get_Trend(PERIOD_M5);
   bool ma_falling=((maFast[1]>maFast[0]) && (maSlow[1]>maSlow[0]));

//Conditions to open a position
   bool buyCondition=(maFastest[1]<maFast[1] && maFastest[0]>maFast[0]+10 && maSlow[0]<maFast[0] && tendency==rising && ma_rising && available_to_op)
                     || 
                     (maFast[1]<maSlowest[1] && maFast[0]>maSlowest[0] && maSlow[1]<maSlow[0] && maFast[1]<maFast[0] && available_to_op)
                     ||
                     (maFastest[2]>=maFast[2]+20 && maFastest[1]<=maFast[1]+20 && maFastest[2]>maFastest[1] && maFastest[0]>maFastest[1] && maFastest[0]>=maFast[0]+20 && ma_rising && maSlow[0]<maFast[0] && tendency==rising && primary_trend==rising && available_to_op);

   bool sellCondition=(maFastest[1]>maFast[1] && maFastest[0]<maFast[0]-10 && maSlow[0]>maFast[0] && tendency==falling && ma_falling && available_to_op)
                      || 
                      (maFast[1]>maSlowest[1] && maFast[0]<maSlowest[0] && maSlow[1]>maSlow[0] && maFast[1]>maFast[0] && available_to_op)
                      || 
                      (maFastest[2]<=maFast[2]-20 && maFastest[1]>=maFast[1]-20 && maFastest[2]<maFastest[1] && maFastest[0]<maFastest[1] && maFastest[0]<=maFast[0]-20 && ma_falling && maSlow[0]>maFast[0] && tendency==falling && primary_trend==falling && available_to_op);

   MqlTradeRequest mrequest;
   MqlTradeResult mresult;
   ZeroMemory(mrequest);
   double stop_loss=0;

   if(buyCondition && !buyOpened)
     {
      stop_loss=Get_Minimum(5,PERIOD_M1);
      if((NormalizeDouble(ask,_Digits)-stop_loss<225) && (NormalizeDouble(ask,_Digits)-stop_loss<5*(max_day_loss+current_balance)))
        {
         Buy(ask,mrequest,mresult,stop_loss,buyCondition);         //Opening buy operation

        }
     }

   if((close_ops && buyOpened))
     {
      Sell(bid,mrequest,mresult,0.0,sellCondition);      //Closing buy operation
      //Close_Positions(mrequest,mresult);
     }

   if(sellCondition && !sellOpened)
     {
      stop_loss=Get_Maximum(5,PERIOD_M1);
      if((stop_loss-NormalizeDouble(bid,_Digits)<225) && (stop_loss-NormalizeDouble(bid,_Digits)<5*max_day_loss+5*current_balance))
        {
         Sell(bid,mrequest,mresult,stop_loss,sellCondition);      //Opening sell operation
        }
     }

   if((close_ops && sellOpened))
     {
      Buy(ask,mrequest,mresult,0.0,buyCondition);       //Closing sell operation
      //Close_Positions(mrequest,mresult);
     }

   if(buyOpened)
     {
      stop_loss=Get_Minimum(5,PERIOD_M1);
      Trailing_Stop(mrequest,mresult,stop_loss);
     }

   if(sellOpened)
     {
      stop_loss=Get_Maximum(5,PERIOD_M1);
      Trailing_Stop(mrequest,mresult,stop_loss);
     }

  }
//+------------------------------------------------------------------+
