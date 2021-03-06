//# vim:set foldmethod=marker:
//+------------------------------------------------------------------+
//|                                                 PositionInfo.mq4 |
//|                                   Copyright 2015, SENAGA Yusuke. |
//|                                               mi081321@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, SENAGA Yusuke."
#property link      "mi081321@gmail.com"
#property library

// Standard Library
#include <Object.mqh>

// MyInclude
#include "..\_Include\Define.mqh"

// MyLib
#include "TimeStamp.mq4"
#include "TemplateArray.mq4"

// Note //{{{
/*
リリース判定用Stop Loss（Release Priceとでも呼ぶか）と、リスクヘッジ用のStop Lossを用意しておく
利確後、利益を伸ばすための反転判定はリリース判定用Stop Lossを利用
従来のStop Lossの役目はリスクヘッジ用のそれ

Take Profitは従来のやつのみ

*/

//}}}

class CPositionInfo : public CObject //{{{
{
protected:
	double m_dOrderPrice;
	double m_dSLPrice;
	double m_dTPPrice;
	
	double m_dOrderLots;

	int m_nMagicNumber;
	int m_nTicketNumber;

	string m_strOrderComment;

	CTimeStamp *m_cTimeStamp;

	bool m_bIsRelease;
	double m_dReleasePrice;
	double m_dReleaseBorderPips;

public:
	CPositionInfo()
	{
		Print("Constructor PositionInfo.");

		m_dOrderPrice		= 0.0;
		m_dSLPrice			= 0.0;
		m_dTPPrice			= 0.0;
		
		m_dOrderLots		= 0.0;

		m_nMagicNumber		= 0;
		m_nTicketNumber		= 0;

		m_strOrderComment	= "";
		
		m_cTimeStamp		= new CTimeStamp();
		
		m_bIsRelease 		= false;
		m_dReleasePrice		= 0.0;
		m_dReleaseBorderPips	= 0.0;
	}
	/*
	CPositionInfo(CPositionInfo& position)
	{
		this = GetPointer(position);
	}
	*/
	~CPositionInfo()
	{
		Print("Destructor PositionInfo.");
		//if (m_cTimeStamp != NULL)
		{
			delete m_cTimeStamp;
		}
		EraseStopLossLine();
		EraseTakeProfitLine();
	}

	// Open
	bool Open(int orderType, double lots, double stopLoss = 0.0, double takeProfit = 0.0, string comment = "", int slippage = 3, color arrowColor = Red)
	{
		bool bResult = false;
		if (GetOrderPrice() > 0){
			Print("Warning : Already ordered.");
		}
		else if (lots <= 0.0){
			Print("Warning : Request Lot = 0.0");
		}
		else {
			int nMagicNumber = 0;
			string strVarName = "";
			for (int i = 1; i < LONG_MAX_COUNT; i++){
				strVarName = DoubleToStr(i, 0);
				double nVarValue = GlobalVariableGet(strVarName);
				if (!nVarValue){
					nMagicNumber = i;
					break;
				}
			}

			RefreshRates();
			double dOrderPrice = 0;
			if (nMagicNumber){
				switch (orderType){
				case OP_BUY:
				case OP_BUYLIMIT:
				case OP_BUYSTOP:
					dOrderPrice = Ask;
					if (StringLen(comment) == 0){
						comment = "Buy";
					}
					break;

				case OP_SELL:
				case OP_SELLLIMIT:
				case OP_SELLSTOP:
					dOrderPrice = Bid;
					if (StringLen(comment) == 0){
						comment = "Sell";
					}
					break;

				default:
					break;
				}

				//Print("Symbol=", Symbol(), ", cmd=", orderType, ", volume=", lots, ", price=", dOrderPrice, ", slippage=", slippage, ", stoploss=", stopLoss, ", takeprofit=", takeProfit, ", magic=", nMagicNumber);
				bResult = OrderSend(Symbol(), orderType, lots, dOrderPrice, slippage, 0, 0, comment, nMagicNumber, 0, arrowColor);

				Print("Order send result : ", bResult);
				if (bResult){
					bResult = OrderSelect(OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES);
					if (bResult){
						SetOrderPrice(dOrderPrice);
						SetOrderLots(lots);
						SetOrderComment(comment);
						SetMagicNumber(nMagicNumber);
						SetTicketNumber(OrderTicket());
						GlobalVariableSet(DoubleToStr(GetMagicNumber()), GetMagicNumber());
	
						if (stopLoss > 0.0){
							SetStopLossPrice(stopLoss);
						}
						if (takeProfit > 0.0){
							SetTakeProfitPrice(takeProfit);
						}
	
						CTimeStamp time(TimeCurrent());
						SetOrderTime(time);
					}
				}
			}
		}

		return bResult;
	}

	// Close
	bool Close(color arrowColor = Blue)
	{
		bool bResult = false;

		bool nOrderResult = OrderSelect(GetTicketNumber(), SELECT_BY_TICKET, MODE_TRADES);
		if (!nOrderResult){
			Print("Error Order select failed : ", GetLastError());
		}
		else {
			double dClosePrice = 0.0;
			// GetOrderType から OrderType を取得
			int nOrderType = GetOrderType();
			switch (nOrderType){
			case OP_BUY:
			case OP_BUYLIMIT:
			case OP_BUYSTOP:
				dClosePrice = Bid;
				break;

			case OP_SELL:
			case OP_SELLLIMIT:
			case OP_SELLSTOP:
				dClosePrice = Ask;
				break;

			default:
				break;
			}

			bResult = OrderClose(GetTicketNumber(), GetOrderLots(), dClosePrice, 3, arrowColor);
			if (bResult){
				GlobalVariableDel(DoubleToStr(GetMagicNumber()));
			}
		}

		return bResult;
	}

	// Order Price
	void SetOrderPrice(double price)
	{
		m_dOrderPrice = price;
	}
	double GetOrderPrice()
	{
		return m_dOrderPrice;
	}

	// Magic Number
	void SetMagicNumber(int number)
	{
		m_nMagicNumber = number;
	}
	int GetMagicNumber()
	{
		return m_nMagicNumber;
	}

	// Ticket Number
	void SetTicketNumber(int number)
	{
		m_nTicketNumber = number;
	}
	int GetTicketNumber()
	{
		return m_nTicketNumber;
	}

	// Order Lots
	void SetOrderLots(double lots)
	{
		m_dOrderLots = lots;
	}
	double GetOrderLots()
	{
		return m_dOrderLots;
	}

	// Order Comment
	void SetOrderComment(string comment)
	{
		m_strOrderComment = comment;
	}
	string GetOrderComment()
	{
		return m_strOrderComment;
	}

	// Order Type
	int GetOrderType()
	{
		if (OrderSelect(GetTicketNumber(), SELECT_BY_TICKET, MODE_TRADES)){
			return OrderType();
		}
		return -1;
	}

	// OrderTime
	void SetOrderTime(CTimeStamp& time)
	{
		m_cTimeStamp.SetTime(time.GetTime());
	}
	CTimeStamp* GetOrderTime()
	{
		return m_cTimeStamp;
	}
	
	// Stop Loss 価格
	void SetStopLossPrice(double price)
	{
		m_dSLPrice = price;
		DrawStopLossLine(price);
		Print("Set Stop loss : ", price);
	}
	double GetStopLossPrice()
	{
		return m_dSLPrice;
	}
	void DrawStopLossLine(double price)
	{
		// マジックナンバーがユニークな値なのでそのままオブジェクト名として利用
		string strObjectName = DoubleToStr(GetMagicNumber());
		ObjectCreate(strObjectName,OBJ_HLINE, 0, 1, price);
		ObjectSet(strObjectName, OBJPROP_COLOR, Blue);
		ObjectSet(strObjectName, OBJPROP_STYLE, STYLE_DOT);
	}
	void EraseStopLossLine()
	{
		string strObjectName = DoubleToStr(GetMagicNumber());
		ObjectDelete(strObjectName);
	}
	// Stop Loss 監視
	bool OvserveStopLoss()
	{
		bool bResult = false;

		//Print("Stop Loss price : ", m_dSLPrice);
		if (m_dSLPrice > 0.0){
			// GetOrderType から OrderType を取得
			int nOrderType = GetOrderType();
			switch (nOrderType){
			case OP_BUY:
			case OP_BUYLIMIT:
			case OP_BUYSTOP:
				if (m_dSLPrice > Bid){
					bResult = true;
				}
				break;
			case OP_SELL:
			case OP_SELLLIMIT:
			case OP_SELLSTOP:
				if (m_dSLPrice < Ask){
					bResult = true;
				}
				break;
			}
		}

		return bResult;
	}

	// Take Profit 価格
	void SetTakeProfitPrice(double price)
	{
		m_dTPPrice = price;
		DrawTakeProfitLine(price);
		Print("Set Take profit : ", price);
	}
	double GetTakeProfitPrice()
	{
		return m_dTPPrice;
	}
	void DrawTakeProfitLine(double price)
	{
		// マジックナンバーがユニークな値なのでそのままオブジェクト名として利用
		string strObjectName = DoubleToStr(GetMagicNumber());
		ObjectCreate(strObjectName,OBJ_HLINE, 0, 1, price);
		ObjectSet(strObjectName, OBJPROP_COLOR, Red);
		ObjectSet(strObjectName, OBJPROP_STYLE, STYLE_DOT);
	}
	void EraseTakeProfitLine()
	{
		string strObjectName = DoubleToStr(GetMagicNumber());
		ObjectDelete(strObjectName);
	}
	// Take Profit 監視
	bool OvserveTakeProfit()
	{
		bool bResult = false;

		//Print("Take profit price : ", m_dTPPrice);
		if (m_dTPPrice > 0.0){
			// GetOrderType から OrderType を取得
			int nOrderType = GetOrderType();
			switch (nOrderType){
			case OP_BUY:
			case OP_BUYLIMIT:
			case OP_BUYSTOP:
				if (m_dTPPrice < Bid){
					bResult = true;
				}
				break;
			case OP_SELL:
			case OP_SELLLIMIT:
			case OP_SELLSTOP:
				if (m_dTPPrice > Ask){
					bResult = true;
				}
				break;
			}
		}

		return bResult;
	}

	void SetReleasePrice(double price)
	{
		m_dReleasePrice = price;
	}
	double GetReleasePrice()
	{
		return m_dReleasePrice;
	}
	void SetReleaseBorderPips(double pips)
	{
		m_dReleaseBorderPips = pips;
	}
	double GetReleaseBorderPips()
	{
		return m_dReleaseBorderPips;
	}
	// Release Price 監視
	bool OvserveReleasePrice()
	{
		bool bResult = false;

		if (m_dReleasePrice > 0.0 && m_dReleaseBorderPips > 0.0){
			double dNowPrice = 0;
			// GetOrderType から OrderType を取得
			int nOrderType = GetOrderType();
			switch (nOrderType){
			case OP_BUY:
			case OP_BUYLIMIT:
			case OP_BUYSTOP:
				dNowPrice = Bid;
				// 現在価格が リリース判定価格 + 更新幅pips より高い状態なら
				// 　→ 新しい Release Price をセット
				if (dNowPrice > m_dReleasePrice + m_dReleaseBorderPips){
					m_dReleasePrice = dNowPrice - m_dReleaseBorderPips;
				}
				// 現在価格が リリース判定価格より高い状態なら
				// 　→ リリースしても良いフラグを立てる
				if (dNowPrice > m_dReleasePrice){
					m_bIsRelease = true;
				}
				// フラグが立っている && 現在価格が リリース判定価格 を割っている
				// 　→ リリースしましょう
				if (m_bIsRelease && dNowPrice < m_dReleasePrice){
					// リリースする
					bResult = true;
				}
				break;

			case OP_SELL:
			case OP_SELLLIMIT:
			case OP_SELLSTOP:
				dNowPrice = Ask;
				// 現在価格が リリース判定価格 + 更新幅pips より低い状態なら
				// 　→ 新しい Release Price をセット
				if (dNowPrice < m_dReleasePrice - m_dReleaseBorderPips){
					m_dReleasePrice = dNowPrice + m_dReleaseBorderPips;
				}
				// 現在価格が リリース判定価格より低い状態なら
				// 　→ リリースしても良いフラグを立てる
				if (dNowPrice < m_dReleasePrice){
					m_bIsRelease = true;
				}
				// フラグが立っている && 現在価格が リリース判定価格 を超えている
				// 　→ リリースしましょう
				else if (m_bIsRelease && dNowPrice > m_dReleasePrice){
					// リリースする
					bResult = true;
				}
				break;

			default:
				break;
			}
		}

		return bResult;
	}
}; //}}}
