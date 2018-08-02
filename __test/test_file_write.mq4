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

// MyLib
#include "..\_common\_Lib\PositionInfo.mq4"
#include "..\_common\_Lib\TimeStamp.mq4"
//}}}

//CTimeStamp *tm;
	
int OnInit()//{{{
{
	Print("OnInit");
	//tm = new CTimeStamp();
	return(INIT_SUCCEEDED);
}//}}}

void OnDeinit(const int reason)//{{{
{
	Print("OnDeInit");
	//delete tm;
}//}}}

void OnTick()//{{{
{
	int fHandle;
	fHandle = FileOpen("test_file_write.csv", FILE_CSV|FILE_READ|FILE_WRITE, ',');
	if (fHandle > 0)
	{
		Print("File Open Success!!");
		
		// ファイル出力のデフォルトパスはカレントではなく以下のパスとなるらしい
		// F:\Program Files\FxPro - MetaTrader 4\tester\files
		FileSeek(fHandle, 0, SEEK_END);
		FileWrite(fHandle, Close[0], Open[0], High[0], Low[0]);
		FileClose(fHandle);
	}
	else
	{
		Print("File Open Failed...");
	}
}//}}}

