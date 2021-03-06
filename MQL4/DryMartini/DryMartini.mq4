//# vim:set foldmethod=marker:
// Copylith {{{
//+------------------------------------------------------------------+
//|                                                   DryMartini.mq4 |
//|                                   Copyright 2015, SENAGA Yusuke. |
//|                                               mi081321@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, SENAGA Yusuke."
#property link      "mi081321@gmail.com"
#property version   "1.00"
#property strict
// }}}

// グローバル変数{{{
double	g_dTrapInterval		= 0.0;

//}}}

int OnInit()//{{{
{
	if (!InitializeCurrency())
	{
		Print("ERRER : This Currency is not supported : ",  Symbol());
		return (INIT_FAILED);
	}

	return(INIT_SUCCEEDED);
}//}}}

void OnDeinit(const int reason)//{{{
{

}//}}}

void OnTick()//{{{
{

}//}}}

bool InitializeCurrency()//{{{
{
	bool bResult = true;
	
	if(Symbol()=="AUDJPY")
	{
		g_dTrapInterval	= 0.010;
	}
	else if(Symbol()=="CADJPY")
	{
		g_dTrapInterval	= 0.010;
	}
	else if(Symbol()=="EURJPY")
	{
		g_dTrapInterval	= 0.010;
	}
	else if(Symbol()=="GBPJPY")
	{
		g_dTrapInterval	= 0.010;
	}
	else if(Symbol()=="USDJPY")
	{
		g_dTrapInterval	= 0.010;
	}
	else if(Symbol()=="EURGBP")
	{
		g_dTrapInterval	= 0.00010;
	}
	else if(Symbol()=="EURTRY")
	{
		g_dTrapInterval	= 0.00010;
	}
	else if(Symbol()=="EURUSD")
	{
		g_dTrapInterval	= 0.00010;
	}
	else
	{
		bResult = false;
	}
	
	return bResult;
}//}}}

