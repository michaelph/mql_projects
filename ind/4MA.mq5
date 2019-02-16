//+------------------------------------------------------------------+
//|                                        4 Moving Average.mq5 |
//|                   Copyright 2019, Cub@Invest. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2019, Cub@Invest."
#property link      "http://www.mql5.com"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_label1 "Fastest period 4"
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_color2  Orange
#property indicator_label2 "Fast period 10"
#property indicator_width2  2

#property indicator_type3   DRAW_LINE
#property indicator_color3  Blue
#property indicator_label3 "Slow period 17"
#property indicator_width3  2

#property indicator_type4   DRAW_LINE
#property indicator_color4  Green
#property indicator_label4 "Slowest period 44"
#property indicator_width4  2

//--- input parameters
input int            InpMAPeriod1=1;         // Period 1
input int            InpMAShift1=0;           // Shift 1
input ENUM_MA_METHOD InpMAMethod1=MODE_SMA;  // Method 1

input int            InpMAPeriod2=30;         // Period 2
input int            InpMAShift2=0;           // Shift 2
input ENUM_MA_METHOD InpMAMethod2=MODE_SMA;  // Method 2

input int            InpMAPeriod3=60;         // Period 3
input int            InpMAShift3=0;           // Shift 3
input ENUM_MA_METHOD InpMAMethod3=MODE_SMA;  // Method 3

input int            InpMAPeriod4=200;         // Period 4
input int            InpMAShift4=0;           // Shift 4
input ENUM_MA_METHOD InpMAMethod4=MODE_SMA;  // Method 4

//--- indicator buffers
double               ExtLineBuffer1[];
double               ExtLineBuffer2[];
double               ExtLineBuffer3[];
double               ExtLineBuffer4[];
//+------------------------------------------------------------------+
//|   simple moving average                                          |
//+------------------------------------------------------------------+
void CalculateSimpleMA(double &ExtLineBuffer[],int InpMAPeriod ,int rates_total,int prev_calculated,int begin,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)// first calculation
     {
      limit=InpMAPeriod+begin;
      //--- set empty value for first limit bars
      for(i=0;i<limit-1;i++) ExtLineBuffer[i]=0.0;
      //--- calculate first visible value
      double firstValue=0;
      for(i=begin;i<limit;i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else limit=prev_calculated-1;
//--- main loop
   for(i=limit;i<rates_total && !IsStopped();i++)
      ExtLineBuffer[i]=ExtLineBuffer[i-1]+(price[i]-price[i-InpMAPeriod])/InpMAPeriod;
//---
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer4,INDICATOR_DATA);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod1);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpMAPeriod2);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpMAPeriod3);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpMAPeriod4);
//---- line shifts when drawing
   PlotIndexSetInteger(0,PLOT_SHIFT,InpMAShift1);
   PlotIndexSetInteger(1,PLOT_SHIFT,InpMAShift2);
   PlotIndexSetInteger(1,PLOT_SHIFT,InpMAShift3);
   PlotIndexSetInteger(1,PLOT_SHIFT,InpMAShift4);
//--- name for DataWindow
   string short_name1="unknown ma 1";
   string short_name2="unknown ma 2";
   string short_name3="unknown ma 3";
   string short_name4="unknown ma 4";
   switch(InpMAMethod1)
     {
      //case MODE_EMA :  short_name="EMA";  break;
      //case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name1="SMA1";  break;
      //case MODE_SMMA : short_name="SMMA"; break;
     }
    switch(InpMAMethod2)
     {
      //case MODE_EMA :  short_name="EMA";  break;
      //case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name2="SMA2";  break;
      //case MODE_SMMA : short_name="SMMA"; break;
     }
     
     switch(InpMAMethod3)
     {
      //case MODE_EMA :  short_name="EMA";  break;
      //case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name3="SMA3";  break;
      //case MODE_SMMA : short_name="SMMA"; break;
     }
     
     switch(InpMAMethod4)
     {
      //case MODE_EMA :  short_name="EMA";  break;
      //case MODE_LWMA : short_name="LWMA"; break;
      case MODE_SMA :  short_name4="SMA4";  break;
      //case MODE_SMMA : short_name="SMMA"; break;
     }
   //IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(InpMAPeriod)+")");
//---- sets drawing line empty value--
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
//---- initialization done
  }
//+------------------------------------------------------------------+
//|  Moving Average                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- check for bars count
   if(rates_total<InpMAPeriod1-1+begin)
      return(0);// not enough bars for calculation
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
      ArrayInitialize(ExtLineBuffer1,0);
//--- sets first bar from what index will be draw
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod1-1+begin);

//--- calculation
   switch(InpMAMethod1)
     {
      //case MODE_EMA:  CalculateEMA(rates_total,prev_calculated,begin,price);        break;
      //case MODE_LWMA: CalculateLWMA(rates_total,prev_calculated,begin,price);       break;
      //case MODE_SMMA: CalculateSmoothedMA(rates_total,prev_calculated,begin,price); break;
      case MODE_SMA:  CalculateSimpleMA(ExtLineBuffer1,InpMAPeriod1,rates_total,prev_calculated,begin,price);   break;
     }
     
   switch(InpMAMethod2)
     {
      //case MODE_EMA:  CalculateEMA(rates_total,prev_calculated,begin,price);        break;
      //case MODE_LWMA: CalculateLWMA(rates_total,prev_calculated,begin,price);       break;
      //case MODE_SMMA: CalculateSmoothedMA(rates_total,prev_calculated,begin,price); break;
      case MODE_SMA:  CalculateSimpleMA(ExtLineBuffer2,InpMAPeriod2,rates_total,prev_calculated,begin,price);   break;
     }
   switch(InpMAMethod3)
     {
      //case MODE_EMA:  CalculateEMA(rates_total,prev_calculated,begin,price);        break;
      //case MODE_LWMA: CalculateLWMA(rates_total,prev_calculated,begin,price);       break;
      //case MODE_SMMA: CalculateSmoothedMA(rates_total,prev_calculated,begin,price); break;
      case MODE_SMA:  CalculateSimpleMA(ExtLineBuffer3,InpMAPeriod3,rates_total,prev_calculated,begin,price);   break;
     }
   switch(InpMAMethod4)
     {
      //case MODE_EMA:  CalculateEMA(rates_total,prev_calculated,begin,price);        break;
      //case MODE_LWMA: CalculateLWMA(rates_total,prev_calculated,begin,price);       break;
      //case MODE_SMMA: CalculateSmoothedMA(rates_total,prev_calculated,begin,price); break;
      case MODE_SMA:  CalculateSimpleMA(ExtLineBuffer4,InpMAPeriod4,rates_total,prev_calculated,begin,price);   break;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
