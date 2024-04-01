//Here's an updated version of the EA that includes a function to close all orders when a certain profit level is reached:

// Grid, Averaging, Trailing Stop, Magic Number, Last Order Open Time, and Close All Orders Function Expert Advisor (EA)

input int gridDistance = 50;           // Distance between grid orders
input int maxOrders = 5;               // Maximum number of grid orders
input double lotSize = 0.01;           // Lot size for each order
input int trailingStopDistance = 30;   // Trailing stop distance in points
input int magicNumber = 23343;         // Magic number for identifying orders
input double targetProfit = 10.0;     // Target profit level to close all orders

int orderCounter = 0;                  // Track the number of own orders opened
datetime lastOrderOpenTime;            // Store the open time of the last order
extern int MA1Period     = 12;       // Period 1
extern int MA2Period     = 44;       // Period 2
double delta;

double upl,lastbuyprice,lastsellprice,bupl,supl,lastpl,highestpl,nextbuylot,nextselllot;
int b,s;
int prevorders;
double todaypl, yesterdaypl, weekspl,AllTimePL,thismonthpl,lastmonthpl;

extern   string   IndiName       =  "super-trend";                                           // Indicator Name
extern   int      Nbr_Periods    =  10;                                                      // Nbr Periods
extern   double   Multiplier     =  3;
extern   double   MinimumVolume  =  1000; 
double lastbuypl, lastsellpl;
int lastbuyticket, lastsellticket;
double lastbuypriceopen, lastsellpriceopen; 

int canbuy=0, cansell=0; 
void OnTick()
  {
   double ma1=iMA(NULL,PERIOD_CURRENT,MA1Period,0,0,0,1);
   double ma2=iMA(NULL,PERIOD_CURRENT,MA2Period,0,0,0,1);
   delta=MathAbs(NormalizeDouble((Bid-ma1)/Point,0));
   double momentum=iMomentum(Symbol(),PERIOD_CURRENT,250,PRICE_MEDIAN,0);
    

   Comment(


      "  | Bpos: ",b,
      "  | Spos: ",s,
      "  | buysPL: ",bupl,
      "  | sellspl: ",supl,
      "  | last PL: ",lastpl,
      "  | HighestPl: ",highestpl,
      "  | EQUITY: ",AccountEquity(),
      "  | Bal: ",AccountBalance(),
      "  | DELTA: ",DoubleToString(delta,2),
      "\n  | AllTimePL: ",DoubleToString(AllTimePL,2),
      "  | Last Month PL: ",DoubleToString(lastmonthpl,2),
      "  | ThisMonthPL: ",DoubleToString(thismonthpl,2),
      "  | ThisWeekPL: ",DoubleToString(weekspl,2),
      "  | YesterdayPL: ",DoubleToString(yesterdaypl,2),
      "  | Momentum: ",DoubleToString(momentum,2),
      "  | TodayPL: ",DoubleToString(todaypl,2),
      " \n | TermialPath: ",TerminalInfoString(TERMINAL_DATA_PATH)
   );

   if(delta<1000)
     {
      b=0;
      s=0;
      bupl=0;
      supl=0;
      double lastbuylot=0,lastselllot=0;
      long volume = iVolume(Symbol(), PERIOD_CURRENT, 0);
      int spread = (int)MarketInfo(Symbol(), MODE_SPREAD);
   
   double STBuy1 = iCustom(Symbol(),0,IndiName,Nbr_Periods,Multiplier,0,1);
   double STSell1 = iCustom(Symbol(),0,IndiName,Nbr_Periods,Multiplier,1,1);
   
   if(STBuy1 != 0 && STBuy1 != EMPTY_VALUE && STSell1 == EMPTY_VALUE && volume > MinimumVolume){canbuy=1;} else {canbuy=0;}

   if( STSell1 != 0 && STSell1 != EMPTY_VALUE && STBuy1 == EMPTY_VALUE && volume > MinimumVolume) {cansell=1;} else {cansell=0;} 
   
      // Count the number of own orders opened by the EA
      int ownOrders = 0;
      int buystoday=0;
      int sellstoday=0;
      for(int i = 0; i < OrdersTotal(); i++)
        {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderMagicNumber() == magicNumber && OrderSymbol()==Symbol() && OrderStopLoss()<=0)
              {

               ownOrders++;
               upl+=OrderProfit();
               if(OrderType()==OP_BUY)
                 {
                  b++;
                  bupl+=OrderProfit()+OrderSwap()+OrderCommission();
                  if(OrderOpenTime()>TimeCurrent()-86400)
                     buystoday++;
                  if(OrderLots()>=lastbuylot)
                    {
                     lastbuylot=OrderLots();
                     lastbuypriceopen=OrderOpenPrice();

                     nextbuylot=NormalizeDouble(lastbuylot*1.3,2);
                    }
                    if(OrderLots()>=lastbuylot){
                     lastbuypl=OrderProfit();
                     lastbuyticket=OrderTicket();
                    } 
                 }
               if(OrderType()==OP_SELL)
                 {
                  s++;
                  supl+=OrderProfit()+OrderSwap()+OrderCommission();
                  if(OrderOpenTime()>TimeCurrent()-86400)
                     sellstoday++;
                  if(OrderLots()>=lastselllot)
                    {
                     lastselllot=OrderLots();
                     lastsellpriceopen=OrderOpenPrice();

                     nextselllot=NormalizeDouble(lastselllot*1.3,2);
                    }
                   if(OrderLots()>=lastselllot && OrderProfit()<0){
                     lastsellpl=OrderProfit();
                     lastsellticket=OrderTicket();
                   } 
                    
                 }
              }
           }
        }


      if(b==1)
         nextbuylot=lotSize*2;
      if(s==1)
         nextselllot=lotSize*2;

      if(b<1)
        {
        if ( OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, 0, 0, "GptDelta", magicNumber, 0, CLR_NONE)){
         lastbuyprice=Bid;}
        }

      if(s<1)
        {
         if (OrderSend(Symbol(), OP_SELL, lotSize, Bid, 0, 0, 0, "GptDelta", magicNumber, 0, CLR_NONE)){
         lastsellprice=Ask;}
        }


      if(momentum>97 && canbuy==1 && b>0 && Ask<lastbuyprice-((20+(b*50))*Point) && NewBar()==true && (buystoday<4 || (s>b && buystoday<6)))
        {
         if(OrderSend(Symbol(), OP_BUY, FindLastBuySize(), Ask, 0, 0, 0, "GptDelta", magicNumber, 0, CLR_NONE)){
         lastbuyprice=Bid;}
        }

      if(momentum<103 && cansell==1 && s>0 && Bid>lastsellprice+((20+(s*50))*Point) && NewBar()==true && (sellstoday<4 || (b>s && sellstoday<6)))
        {
         if (OrderSend(Symbol(), OP_SELL, FindLastSellSize(), Bid, 0, 0, 0, "GptDelta", magicNumber, 0, CLR_NONE)){
         lastsellprice=Ask;}
        }


      if(b+s!=prevorders)
        {todayProfitLoss(); yesterdayProfitLoss(); weekProfitLoss(); monthProfitLoss(); LastmonthProfitLoss(); AllTimeProfitLoss();}
     prevorders=b+s;

      // Perform averaging on existing orders (example: adding to losing positions)
      // You will need to define your specific averaging strategy here
      // This example does not include averaging logic

      // Check the last order open time
      if(ownOrders > 0 && TimeCurrent() - lastOrderOpenTime > PeriodSeconds() * 5)
        {
         // Execute additional actions or logic based on the last order open time
        }

      // Check if the target profit is reached and close all orders
      if(b>0 && bupl >= targetProfit+(MathAbs(lastsellpl)*1) && Bid<Open[0])
        {
         lastpl=bupl;
         if(bupl>highestpl)
            highestpl=bupl;
             TrailByPercentage();
            if (bupl>MathAbs(lastsellpl)*1) Closelastsell();
         CloseAllOrders(OP_BUY);
         lastsellprice=lastsellpriceopen;
       
        }


      if(s>0 && supl >= targetProfit+ (MathAbs(lastbuypl)*1) && Bid>Open[0])
        {
         lastpl=supl;
         if(supl>highestpl)
            highestpl=supl;
             TrailByPercentage();
         if (supl>MathAbs(lastbuypl)*1) Closelastbuy();
         CloseAllOrders(OP_SELL);
        lastbuyprice=lastbuypriceopen;
        }
     }
  }

// Function to close all own orders
void CloseAllOrders(int type)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber() == magicNumber && OrderType()==type && OrderStopLoss()<=0)
            int doclose=OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, CLR_NONE);
        }
     }
  }
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime dt = 0;

   if(Time[0] != dt)
     {
      dt = Time[0];
      return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//// Today's Profit loss

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double todayProfitLoss()
  {
   double sum;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            if(TimeToStr(TimeCurrent(),TIME_DATE)==TimeToString(OrderCloseTime(),TIME_DATE))
              {
               sum+=OrderProfit()+OrderCommission()+OrderSwap();
               todaypl=sum;
              }
           }
        }
     }
   return(sum);
  }
//+------------------------------------------------------------------+

//// yesterday Profit loss

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double yesterdayProfitLoss()
  {
   double sum;
   datetime yesterday =iTime(NULL, PERIOD_D1, 1);
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            if(TimeToStr(yesterday,TIME_DATE)==TimeToString(OrderCloseTime(),TIME_DATE))
              {
               //if(TimeToString(DayTimeBars[0]) ==TimeToString(OrderCloseTime(),TIME_DATE)){
               sum+=OrderProfit()+OrderCommission()+OrderSwap();
               yesterdaypl=sum;
              }
           }
        }
     }
   return(sum);
  }


//// This weeks Profit loss
double weekProfitLoss()
  {
   double sum;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            if(iTime(NULL,PERIOD_W1,0)<OrderCloseTime())
              {
               sum+=OrderProfit()+OrderCommission()+OrderSwap();
              }
           }
        }
     }
   weekspl=sum;
   return(sum);
  }
//+------------------------------------------------------------------+
//// This month Profit loss
double monthProfitLoss()
  {
   double sum;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            if(iTime(NULL,PERIOD_MN1,0)<OrderCloseTime())
              {
               sum+=OrderProfit()+OrderCommission()+OrderSwap();
              }
           }
        }
     }
   thismonthpl=sum;
   return(sum);
  }

//// last month Profit loss
double LastmonthProfitLoss()
  {
   double sum;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            if(iTime(NULL,PERIOD_MN1,1)<OrderCloseTime() && iTime(NULL,PERIOD_MN1,0)>OrderCloseTime())
              {
               sum+=OrderProfit()+OrderCommission()+OrderSwap();
              }
           }
        }
     }
   lastmonthpl=sum;
   return(sum);
  }

//// All time Profit loss
double AllTimeProfitLoss()
  {
   double sum;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==_Symbol && OrderMagicNumber()==magicNumber)
           {
            sum+=OrderProfit()+OrderCommission()+OrderSwap();
           }
        }
     }
   AllTimePL=sum;
   return(sum);
  }


//+------------------------------------------------------------------+
double FindLastBuySize()
{ 
 double oldorderopenprice = 0, orderprice,orderlotsize; 
 int cnt, oldticketnumber = 0, ticketnumber; 

 for(cnt=OrdersTotal()-1;cnt>=0;cnt--) 
 { 
  OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES); 
  if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=magicNumber) 
   continue; 
  if(OrderSymbol()==Symbol() && OrderMagicNumber()==magicNumber && OrderType()==OP_BUY)   
  { 
     ticketnumber = OrderTicket(); 
     if(ticketnumber>oldticketnumber) 
     { 
      orderprice=OrderOpenPrice(); 
      oldorderopenprice=orderprice; 
      oldticketnumber=ticketnumber; 
      orderlotsize=OrderLots();
      
     } 
  } 
 } 

  if (orderlotsize>lotSize) {return(NormalizeDouble(orderlotsize*1.3,2));} else  {return(orderlotsize*2);}
} 

double FindLastSellSize() 
{ 
 double oldorderopenprice = 0, orderprice, orderlotsize; 
 int cnt, oldticketnumber = 0, ticketnumber; 

 for(cnt=OrdersTotal()-1;cnt>=0;cnt--) 
 { 
  OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES); 
  if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=magicNumber) 
   continue; 
  if(OrderSymbol()==Symbol() && OrderMagicNumber()==magicNumber && OrderType()==OP_SELL)   
  { 
     ticketnumber = OrderTicket(); 
     if(ticketnumber>oldticketnumber) 
     { 
      orderprice=OrderOpenPrice(); 
      oldorderopenprice=orderprice; 
      oldticketnumber=ticketnumber; 
      orderlotsize=OrderLots();
     } 
  } 
 } 

  if (orderlotsize>lotSize) {return(NormalizeDouble(orderlotsize*1.3,2));} else  {return(orderlotsize*2);} 
} 
/////////////////////////////////////////////////////////////////////////////////////
// Trail / break Even
////////////////////////////////////////////////////////////////////////////////////
void trail_stop(int type) 
{ double new_sl=0; bool OrderMod=false; 
   for(int i=0;i<OrdersTotal();i++) 
   { 
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break; 
      if(OrderMagicNumber()==magicNumber && OrderSymbol()==Symbol() && OrderType()==type && OrderStopLoss()<=0) 
      { 
         RefreshRates();          
         if(OrderType()==OP_BUY) 
         {  new_sl=0;  int tries=0;
            if(MarketInfo(Symbol(),MODE_BID)-OrderOpenPrice()>trailingStopDistance*Point && OrderOpenPrice()>OrderStopLoss()) new_sl=OrderOpenPrice(); 
            if (MarketInfo(Symbol(),MODE_BID)-OrderStopLoss()>trailingStopDistance*Point+0*Point && OrderStopLoss()>=OrderOpenPrice()) 
            new_sl = MarketInfo(Symbol(),MODE_BID)-trailingStopDistance*Point; 
             OrderMod=false; 
             tries=0; 
              
             while(!OrderMod && tries<3 && new_sl>0) 
            {   
               OrderMod=OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,OrderTakeProfit(),0,White); 
               tries=tries+1; 
                
            } 
             
         } 
         if(OrderType()==OP_SELL) 
         {   new_sl=0; 
             if(OrderOpenPrice()-MarketInfo(Symbol(),MODE_ASK)>trailingStopDistance*Point && (OrderOpenPrice()<OrderStopLoss()||OrderStopLoss()==0)) new_sl=OrderOpenPrice(); 
             if(OrderStopLoss()-MarketInfo(Symbol(),MODE_ASK)>trailingStopDistance*Point+0*Point && OrderStopLoss()<=OrderOpenPrice()) 
             new_sl=MarketInfo(Symbol(),MODE_ASK)+trailingStopDistance*Point; 
             OrderMod=false; 
             tries=0; 
              
             while(!OrderMod && tries<3 && new_sl>0) 
            {   
               OrderMod=OrderModify(OrderTicket(),OrderOpenPrice(),new_sl,OrderTakeProfit(),0,White); 
               tries=tries+1; 
                
            } 
          
         } 
          
      } 
   } 
} 
// Function to last lossing order
void Closelastbuy()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(lastbuyticket, SELECT_BY_TICKET, MODE_TRADES))
        {
         if(OrderMagicNumber() == magicNumber)
            int doclose=OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, CLR_NONE);
        }
     }
  }
  
  // Function to last lossing order
void Closelastsell()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(lastsellticket, SELECT_BY_TICKET, MODE_TRADES))
        {
         if(OrderMagicNumber() == magicNumber)
            int doclose=OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, CLR_NONE);
        }
     }
  }
  
  //+------------------------------------------------------------------+
//|Function to trail orders by percentage of the profit              |
//+------------------------------------------------------------------+
void TrailByPercentage()
  {
   double newSellSl=0;
   double newbuySl=0;
   double buySl=0;
   double sellSl;


  

   for(int cnt=0; cnt<OrdersTotal(); cnt++)
     {
      if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderType()<=OP_SELL&& OrderSymbol()==Symbol() && OrderProfit()>OrderLots()*100) /*400 here represents trailin start*/
           {
            if(OrderType()==OP_BUY  && OrderMagicNumber()==magicNumber && OrderProfit()>0)
              {

               buySl=NormalizeDouble(OrderStopLoss(),Digits);
               newbuySl=NormalizeDouble(Bid-((Bid-OrderOpenPrice())/9),Digits);

               //if(NormalizeDouble(Ask,Digits)>NormalizeDouble(OrderOpenPrice()+100*Point,Digits) && Ask<High[0])  {//Not useful in our case
               if(buySl<newbuySl ||(OrderStopLoss()==0))
                 {
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),newbuySl,OrderTakeProfit(),0,Blue))
                     continue;
                  if(GetLastError()==0)
                    {
                     
                     Print(Symbol()+ ": Trailing Buy OrderModify ok ");
                    }

                 }

              }
            else
              {
               if(OrderType()==OP_SELL  && OrderMagicNumber()==magicNumber)
                 {

                  sellSl=NormalizeDouble(OrderStopLoss(),Digits);
                  newSellSl=NormalizeDouble(Ask+((OrderOpenPrice()-Ask)/9),Digits);

                  // if(NormalizeDouble(Bid,Digits)<NormalizeDouble(OrderOpenPrice()-100*Point,Digits) && Bid>Low[0])  { //low [0] && high[0] represent trailingstep
                  if(sellSl>newSellSl ||(OrderStopLoss()==0))
                    {
                     if(OrderModify(OrderTicket(),OrderOpenPrice(),newSellSl,OrderTakeProfit(),0,Red))
                        continue;
                     if(GetLastError()>0)
                       {
                        Print(Symbol()+ ": Error Trailing Sell " + IntegerToString(OrderTicket()) +"");
                       }
                     else
                       {
                        if(GetLastError()==0)
                          {
                          Print(Symbol()+ ": Trailing Sell OrderModify ok ");
                          }
                       }

                    }

                 }
              }
           }
        }
     }
  } 
