//# vim:set foldmethod=marker:
// Copylith//{{{
//+------------------------------------------------------------------+
//|                                           test_position_list.mq4 |
//|                                   Copyright 2018, SENAGA Yusuke. |
//|                                       aganesy.personal@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, SENAGA Yusuke."
#property link      "aganesy.personal@gmail.com"
#property version   "1.00"
#property strict

// 外部参照//{{{

//Standard Library
#include <Arrays\List.mqh>

// MyInclude
#include "..\_common\_Include\Define.mqh"

// MyLib
#include "..\_common\_Lib\PositionInfo.mq4"
#include "..\_common\_Lib\TimeStamp.mq4"
//}}}

// Note //{{{
/*
クラスオブジェクトの動的配列を利用するにはCObjectクラスを継承する必要があるとのことで、いろいろ試してみる。

https://metatradebysakata.blogspot.com/p/1.html
> 自分でクラスオブジェクトの動的配列を生成するとき、
> CObjectクラスを継承する必要があります。

https://www.mql5.com/ja/docs/standardlibrary/cobject
https://www.mql5.com/ja/articles/53
https://www.mql5.com/ja/articles/1334#c5
*/
//}}}

// Global variable//{{{

CList g_list;
	
//}}}

int OnInit()//{{{
{
	Print("OnInit");
	return(INIT_SUCCEEDED);
}//}}}

void OnDeinit(const int reason)//{{{
{
	Print("OnDeInit");
}//}}}

void OnTick()//{{{
{
	OvservePosition();
	
	CTimeStamp tm(TimeCurrent());
	//if (tm.GetYear() == 2018 && tm.GetMonth() == 6 && tm.GetDay() == 20 && tm.GetHour() == 18 && tm.GetMinute() == 30 && tm.GetSesond() % 10 == 0){
	if (tm.GetSesond() % 10 == 0){
		bool bOpenResult = false;

		CPositionInfo *positionbuy = new CPositionInfo();
		bOpenResult = positionbuy.Open(OP_BUY, 0.01, Ask - PIPS(300), Ask + PIPS(10));
		if (bOpenResult){
			g_list.Add(positionbuy);
		}
		else {
			delete positionbuy;
		}
		CPositionInfo *positionsell = new CPositionInfo();
		bOpenResult = positionsell.Open(OP_SELL, 0.01, Bid + PIPS(300), Bid - PIPS(10));
		if (bOpenResult){
			g_list.Add(positionsell);
		}
		else {
			delete positionsell;
		}
	}
	if (tm.GetYear() == 2018 && tm.GetMonth() == 6 && tm.GetDay() == 20 && tm.GetHour() == 19 && tm.GetMinute() == 30 && tm.GetSesond() == 28){
		//position.Close();
	}
}//}}}

void OvservePosition()
{
	CPositionInfo* node = g_list.GetFirstNode();
	while (node != NULL){
		bool bIsClose = false;
		if (node.OvserveStopLoss()){
			bIsClose = true;
		}
		if (node.OvserveTakeProfit()){
			bIsClose = true;
		}
		if (bIsClose){
			bool bCLoseResult = node.Close();
			if (bCLoseResult){
				g_list.DeleteCurrent();
			}
		}
		node = g_list.GetNextNode();
	}
}
