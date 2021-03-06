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

// MyInclude
#include "..\_common\_Include\Define.mqh"

// MyLib
#include "..\_common\_Lib\PositionInfo.mq4"
#include "..\_common\_Lib\TimeStamp.mq4"
//}}}

// Note //{{{
/*
CPositionInfoListにて、CPositionInfoの動的配列を保持するも、外部から配列操作するにはポインタクラスの配列としなければならないらしい。
上記とする場合、insert()などで要素を追加しても、insert()を呼び出した関数が終了するとクラスオブジェクトは破棄されてしまう。
insertした要素はクラスオブジェクトのポインタであるため、実体の破棄に伴い不正なポインタ扱いとなってしまう。

対処として、staticな変数（クラスオブジェクト）をinsertする実装を試してみたが、逆にプロセス生きてる間実体が残るので、新規要素を扱うことができなくなる。（想定通り）
*/
//}}}

// Global variable//{{{

CPositionInfoList *plist;

//}}}
	
int OnInit()//{{{
{
	Print("OnInit");
	plist = new CPositionInfoList();
	return(INIT_SUCCEEDED);
}//}}}

void OnDeinit(const int reason)//{{{
{
	Print("OnDeInit");
	delete plist;
}//}}}

void OnTick()//{{{
{
	OvservePosition();
	
	CTimeStamp tm(TimeCurrent());
	if (tm.GetYear() == 2018 && tm.GetMonth() == 6 && tm.GetDay() == 20 && tm.GetHour() == 18 && tm.GetMinute() == 30 && tm.GetSesond() % 10 == 0){
		CPositionInfo position;
		position.Open(OP_BUY, 0.01, Ask - 0.3, Ask + 0.01);
		plist.push_back(position);
	}
	if (tm.GetYear() == 2018 && tm.GetMonth() == 6 && tm.GetDay() == 20 && tm.GetHour() == 19 && tm.GetMinute() == 30 && tm.GetSesond() == 28){
		//position.Close();
	}
}//}}}

void OvservePosition()
{
	for (int i = 0; i < plist.length(); i++){
		CPositionInfo *pBuffer = plist.GetElement(i);
		if (pBuffer != NULL){
			if (pBuffer.OvserveStopLoss()){
				pBuffer.Close();
				delete pBuffer;
				plist.erase(i);
			}
			if (pBuffer.OvserveTakeProfit()){
				pBuffer.Close();
				delete pBuffer;
				plist.erase(i);
			}
		}
	}
}