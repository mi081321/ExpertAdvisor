//# vim:set foldmethod=marker:
// Copylith//{{{
//+------------------------------------------------------------------+
//|                                                test_position.mq4 |
//|                                   Copyright 2018, SENAGA Yusuke. |
//|                                       aganesy.personal@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, SENAGA Yusuke."
#property link      "aganesy.personal@gmail.com"
#property version   "1.00"
#property strict

// 外部参照//{{{
// MyInclude
#include "..\_common\_Include\Define.mqh"
#include "..\_common\_Include\initMQL4.mqh"

// MyLib
#include "..\_common\_Include\PositionInfo.mqh"
#include "..\_common\_Include\TimeStamp.mqh"
//}}}

CPositionInfo *g_cPosition;
//CTimeStamp *tm;

extern double Ask;
extern double Bid;


// 構造体定義 //{{{
struct ChartInfomation
{
    double open;
    double close;
    double high;
    double low;
    double moving; // 終値 - 始値（ローソクの縦幅のこと）
};
//}}}

int OnInit()//{{{
{
	Print("OnInit");
	g_cPosition = new CPositionInfo();
	//tm = new CTimeStamp();
	return(INIT_SUCCEEDED);
}//}}}

void OnDeinit(const int reason)//{{{
{
	Print("OnDeInit");
	delete g_cPosition;
	//delete tm;
}//}}}

void OnTick()//{{{
{
    UpdateChartInfomation();
    ObserveClose();
    ObserveOpen();
    
}//}}}

void ObserveClose()//{{{
{
	if (g_cPosition != NULL){
		if (g_cPosition.OvserveStopLoss()){
			g_cPosition.Close();
			delete g_cPosition;
			g_cPosition = NULL;
		}
		else if (g_cPosition.OvserveTakeProfit()){
			g_cPosition.Close();
			delete g_cPosition;
			g_cPosition = NULL;
		}
	}
}//}}}

void ObserveOpen()//{{{
{
    //OpenTest();
    //OpenTrello();
}//}}}

void OpenTest()//{{{
{
	CTimeStamp tm(TimeCurrent());
	if (tm.GetSesond() % 30 == 0){
    	if (g_cPosition == NULL){
    	    g_cPosition = new CPositionInfo();
    	}
		//g_cPosition.Open(OP_BUY, 0.01, Ask, Ask - PIPS(300), Ask + PIPS(10));
		//g_cPosition.Open(OP_BUY, 0.01, Ask, 0, Ask + PIPS(5));
		g_cPosition.Open(OP_SELL, 0.01, Bid, Bid + PIPS(100), Bid - PIPS(15));
	}
}//}}}

void OpenTrello()//{{{
{
	// 直近5本のローソクの値を取得しておく。
	ChartInfomation stChartFive[5];
	for (int i = 0; i < 5; i++){
	    stChartFive[i].open = iOpen(Symbol(), Period(), i);
        stChartFive[i].close = iClose(Symbol(), Period(), i);
        stChartFive[i].high = iHigh(Symbol(), Period(), i);
        stChartFive[i].low = iLow(Symbol(), Period(), i);
        stChartFive[i].moving = stChartFive[i].close - stChartFive[i].open;
	}
	
	// Trelloのメモより
	// 直近5本の計算結果の合算が0に近いとき、折返しが近いと判定することも可能と推測。
	double moving_sum = 0.0;
	for (int i = 0; i < 5; i++){
	    moving_sum += stChartFive[i].moving;
	}
	
	// ToDo
	// 現在、どちらの向きでチャートが推移しているのか判定し、状態を変数に持っておく。
	// 折返し判定でtrueとなった場合には、チャートの反転（or停滞）を状態変数に保持する。
	// 同時に、ポジションをOpenする。（これはObserveOpenにて実装する。）
	// 同時に、ポジションをCloseする。（これはObserveCloseにて実装する。）
	
}//}}}

void OpenTrap()//{{{
{
    
}//}}}