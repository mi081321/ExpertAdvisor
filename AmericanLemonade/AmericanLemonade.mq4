//+------------------------------------------------------------------+
//|                                             AmericanLemonade.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict


int		g_nPreOrderTime				= 0;
int		g_nArrayOrderIndex[300]		= {-1};
double	g_dArrayOpenPriceList[300]	= {0};
double	g_dArrayPrePriceList[300]	= {0};

double	g_dFirstPriceDiffBorder		= 0.0;
double	g_dPriceDiffBorder			= 0.0;
double	g_dSLSeed					= 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
	for (int i = 0; i < ArrayRange(g_nArrayOrderIndex, 0); i++){
		g_nArrayOrderIndex[i]		= -1;
		g_dArrayOpenPriceList[i]	= 0.0;
		g_dArrayPrePriceList[i]		= 0.0;
	}
    g_nPreOrderTime = Seconds();
    
    InitializeCurrency();
    
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
	OrderJudge();
	SetStopLoss();
    
}

// こいつがループで回される
void OrderJudge()
{
	// オーダーのトータルが98以下ですか
	if ( OrdersTotal() <= 98 )
	{
		// 証拠金維持率が 200% 以上ですか
		if ( ( AccountFreeMargin() * 1.3 ) > AccountBalance() )
		{
			// 前の取引から5秒以上経ちましたか
			if ( ( Seconds() + 60 - g_nPreOrderTime ) % 60 >= 10 )
			{
				if ( OpenBuy() )
				{
					OpenSell();
				}
			}
		}
	}
    
	g_nPreOrderTime = Seconds();
}

// こいつがループで回される
void SetStopLoss()
{
	for ( int i = 0; i < ArrayRange( g_nArrayOrderIndex, 0 ); i++ )
	{
		if ( g_nArrayOrderIndex[i] != -1 )
		{
			if ( !OrderSelect( g_nArrayOrderIndex[i], SELECT_BY_POS, MODE_TRADES ) )
			{
				g_nArrayOrderIndex[i]		= -1;
				g_dArrayOpenPriceList[i]	= 0.0;
				g_dArrayPrePriceList[i]		= 0.0;
			}
			else
			{
				bool bIsFirst = false;
				if ( !( g_dArrayPrePriceList[i] >= 0.1 ) )
				{
					bIsFirst = true;
				}
				
				double dFirstPriceDiff;
				double dPriceDiff;
				double dNewSLPrice;
				
				RefreshRates();
				switch ( OrderType() )
				{
				case OP_BUY:
				case OP_BUYLIMIT:
				case OP_BUYSTOP:
					dFirstPriceDiff	= Bid - g_dArrayOpenPriceList[i];
					dPriceDiff		= Bid - g_dArrayPrePriceList[i];
					dNewSLPrice		= Bid - g_dSLSeed;
					
		            break;
		            
				case OP_SELL:
				case OP_SELLLIMIT:
				case OP_SELLSTOP:
					dFirstPriceDiff	= g_dArrayOpenPriceList[i] - Ask;
					dPriceDiff		= g_dArrayPrePriceList[i] - Ask;
					dNewSLPrice		= Ask + g_dSLSeed;
					
		            break;
				}
				
				if ( !bIsFirst )
				{
		         	if ( dFirstPriceDiff >= g_dPriceDiffBorder )
					{
						if ( OrderStopLoss() >= 0.1 )
						{
							OrderModify( OrderTicket(), OrderOpenPrice(), dNewSLPrice, 0, 0, Blue );
							g_dArrayPrePriceList[i]	= OrderType() == Ask ? Ask : Bid;
						}
					}
				}
				else if ( dFirstPriceDiff >= g_dFirstPriceDiffBorder )
				{
					OrderModify( OrderTicket(), OrderOpenPrice(), dNewSLPrice, 0, 0, Blue );
					g_dArrayPrePriceList[i]	= OrderType() == Ask ? Ask : Bid;
				}
			}
		}
	}
}

bool OpenBuy( void )
{
	bool bResult = false;
	
	for ( int i = 0; i < ArrayRange( g_nArrayOrderIndex, 0 ); i++ )
	{
		if ( g_nArrayOrderIndex[i] == -1 )
		{
			if ( OrderSend( Symbol(), OP_BUY,  0.01, Ask, 3, 0, 0, "Buy",  i, 0, Blue ) )
			{
				//OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES );
				//OrderModify( OrderTicket(), OrderOpenPrice(), 0, OrderOpenPrice() + g_dFirstPriceDiffBorder, 0, Blue );
				g_dArrayOpenPriceList[i] = Ask;
				g_nArrayOrderIndex[i] = OrdersTotal() - 1;
				
				bResult = true;
			}
			
			break;
		}
	}
	
	return bResult;
}

bool OpenSell( void )
{
	bool bResult = false;
	
	for ( int i = 0; i < ArrayRange( g_nArrayOrderIndex, 0 ); i++ )
	{
		if ( g_nArrayOrderIndex[i] == -1 )
		{
			if ( OrderSend( Symbol(), OP_SELL,  0.01, Bid, 3, 0, 0, "Sell",  i, 0, Red ) )
			{
				//OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES );
				//OrderModify( OrderTicket(), OrderOpenPrice(), 0, OrderOpenPrice() - g_dFirstPriceDiffBorder, 0, Red );
				g_dArrayOpenPriceList[i] = Bid;
				g_nArrayOrderIndex[i] = OrdersTotal() - 1;
				
				bResult = true;
			}
			
			break;
		}
	}
	
	return bResult;
}

void InitializeCurrency()
{
	
	if(Symbol()=="AUDJPY")
	{
		g_dFirstPriceDiffBorder	= 0.013;
		g_dPriceDiffBorder		= 0.001;
		g_dSLSeed				= 0.010;
	}
	if(Symbol()=="CADJPY")
	{
		g_dFirstPriceDiffBorder	= 0.013;
		g_dPriceDiffBorder		= 0.001;
		g_dSLSeed				= 0.010;
	}
	if(Symbol()=="GBPJPY")
	{
		g_dFirstPriceDiffBorder	= 0.013;
		g_dPriceDiffBorder		= 0.001;
		g_dSLSeed				= 0.010;
	}
	if(Symbol()=="USDJPY")
	{
		g_dFirstPriceDiffBorder	= 0.013;
		g_dPriceDiffBorder		= 0.001;
		g_dSLSeed				= 0.010;
	}
	if(Symbol()=="EURGBP")
	{
		g_dFirstPriceDiffBorder	= 0.00013;
		g_dPriceDiffBorder		= 0.00001;
		g_dSLSeed				= 0.00010;
	}
	if(Symbol()=="EURTRY")
	{
		g_dFirstPriceDiffBorder	= 0.00013;
		g_dPriceDiffBorder		= 0.00001;
		g_dSLSeed				= 0.00010;
	}
	if(Symbol()=="EURUSD")
	{
		g_dFirstPriceDiffBorder	= 0.00013;
		g_dPriceDiffBorder		= 0.00001;
		g_dSLSeed				= 0.00010;
	}

	
}

//+------------------------------------------------------------------+
