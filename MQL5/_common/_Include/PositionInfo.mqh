//# vim:set foldmethod=marker:
//+------------------------------------------------------------------+
//|                                                 PositionInfo.mq4 |
//|                                   Copyright 2015, SENAGA Yusuke. |
//|                                               mi081321@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, SENAGA Yusuke."
#property link      "mi081321@gmail.com"

// Standard Library
#include <Object.mqh>

// MyInclude
#include "Define.mqh"
#include "initMQL4.mqh"
#include "ObjectMQL4.mqh"

// MyLib
#include "TimeStamp.mqh"
#include "TemplateArray.mqh"

extern double Ask;
extern double Bid;

// Note //{{{
/*
リリース判定用Stop Loss（Release Priceとでも呼ぶか）と、リスクヘッジ用のStop Lossを用意しておく
利確後、利益を伸ばすための反転判定はリリース判定用Stop Lossを利用
従来のStop Lossの役目はリスクヘッジ用のそれ

Take Profitは従来のやつのみ

*/

//}}}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPositionInfo : public CObject //{{{
{
protected:
    //double           m_dOrderPrice;
    //double           m_dOrderLots;
    //ulong              m_nMagicNumber;
    
    MqlTradeRequest m_stTradeRequestInfo;
    
    ulong              m_nTicketNumber;

    double           m_dSLPrice;
    double           m_dTPPrice;
    
    string           m_strOrderComment;

    CTimeStamp       *m_cTimeStamp;

    bool             m_bIsRelease;
    double           m_dReleasePrice;
    double           m_dReleaseBorderPips;

public:
    CPositionInfo()
    {
        Print("Constructor PositionInfo.");
        
        m_nTicketNumber		= 0;

        m_dSLPrice			= 0.0;
        m_dTPPrice			= 0.0;

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

    bool Open(MqlTradeRequest& tradeRequest)
    {
        bool bResult = false;
        bResult = Open(tradeRequest.type, tradeRequest.volume, tradeRequest.price, tradeRequest.sl, tradeRequest.tp, tradeRequest.comment, tradeRequest.deviation);
        
        return bResult;
    }
    // Open
    bool Open(ENUM_ORDER_TYPE orderType, double lots, double price, double stopLoss = 0.0, double takeProfit = 0.0, string comment = "", ulong slippage = 3, color arrowColor = Red)
    {
        bool bResult = false;
        if(GetOrderPrice() > 0)
        {
            Print("Warning : Already ordered.");
        }
        else
            if(lots <= 0.0)
            {
                Print("Warning : Request Lots = 0.0");
            }
            else
            {
                ulong ulMagicNumber = 0;
                for(int i = 1; i < LONG_MAX_COUNT; i++)
                {
                    string strVarName = IntegerToString(i, 0);
                    double dVarValue = GlobalVariableGet(strVarName);
                    if(!dVarValue)
                    {
                        ulMagicNumber = (ulong)i;
                        break;
                    }
                }

                if(ulMagicNumber)
                {
                    /*
                    switch(orderType)
                    {
                        case ORDER_TYPE_BUY:
                        case ORDER_TYPE_BUY_LIMIT:
                        case ORDER_TYPE_BUY_STOP:
                            dOrderPrice = Ask;
                            if(StringLen(comment) == 0)
                            {
                                comment = "Buy";
                            }
                            break;

                        case ORDER_TYPE_SELL:
                        case ORDER_TYPE_SELL_LIMIT:
                        case ORDER_TYPE_SELL_STOP:
                            dOrderPrice = Bid;
                            if(StringLen(comment) == 0)
                            {
                                comment = "Sell";
                            }
                            break;

                        default:
                            break;
                    }
                    */

                    MqlTradeRequest tradeRequest = {0};
                    tradeRequest.action = TRADE_ACTION_DEAL;
                    tradeRequest.symbol = _Symbol;
                    tradeRequest.type = orderType;
                    tradeRequest.volume = lots;
                    tradeRequest.price = price;
                    tradeRequest.sl = stopLoss;
                    tradeRequest.tp = takeProfit;
                    tradeRequest.comment = comment;
                    tradeRequest.deviation = slippage;
                    tradeRequest.magic = ulMagicNumber;
                    
                    MqlTradeResult tradeResult = {0};
                    
                    //Print("Symbol=", Symbol(), ", cmd=", orderType, ", volume=", lots, ", price=", dOrderPrice, ", slippage=", slippage, ", stoploss=", stopLoss, ", takeprofit=", takeProfit, ", magic=", nMagicNumber);
                    // ↓MQL4のコード
                    //bResult = OrderSend(Symbol(), orderType, lots, price, slippage, 0, 0, comment, nMagicNumber, 0, arrowColor);
                    bResult = OrderSend(tradeRequest, tradeResult);

                    Print("Order send result : ", bResult);
                    if(bResult)
                    {
                        ulong ulTicketNum = OrderGetTicket(OrdersTotal() - 1);
                        if(ulTicketNum > 0)
                        {
                            SetOrderType(orderType);
                            SetOrderLots(lots);
                            SetOrderPrice(price);
                            SetOrderComment(comment);
                            SetMagicNumber(ulMagicNumber);
                            SetTicketNumber(ulTicketNum);
                            GlobalVariableSet(DoubleToString(GetMagicNumber()), GetMagicNumber());

                            if(stopLoss > 0.0)
                            {
                                SetStopLossPrice(stopLoss);
                            }
                            if(takeProfit > 0.0)
                            {
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
    bool Close(string comment = "", color arrowColor = Blue)
    {
        bool bResult = false;

        bool nOrderResult = PositionSelectByTicket(GetTicketNumber());
        if(!nOrderResult)
        {
            Print("Error Order select failed : ", GetLastError());
        }
        else
        {
            double dClosePrice = 0.0;
            ENUM_ORDER_TYPE nCloseType = 0;
            // GetOrderType から OrderType を取得
            ENUM_ORDER_TYPE nOrderType = GetOrderType();
            switch(nOrderType)
            {
                case ORDER_TYPE_BUY:
                case ORDER_TYPE_BUY_LIMIT:
                case ORDER_TYPE_BUY_STOP:
                    dClosePrice = Bid;
                    nCloseType = ORDER_TYPE_SELL;
                    break;

                case ORDER_TYPE_SELL:
                case ORDER_TYPE_SELL_LIMIT:
                case ORDER_TYPE_SELL_STOP:
                    dClosePrice = Ask;
                    nCloseType = ORDER_TYPE_BUY;
                    break;

                default:
                    break;
            }


            MqlTradeRequest closeRequest = {0};
            closeRequest.action = TRADE_ACTION_DEAL;
            closeRequest.symbol = _Symbol;
            closeRequest.type = nCloseType;
            closeRequest.volume = GetOrderLots();
            closeRequest.price = dClosePrice;
            closeRequest.comment = comment;
            closeRequest.position = GetTicketNumber();
            
            MqlTradeResult closeResult = {0};
            
            // ↓MQL4のコード
            //bResult = OrderSend(GetTicketNumber(), GetOrderLots(), dClosePrice, 3, arrowColor);
            bResult = OrderSend(closeRequest, closeResult);
            if(bResult)
            {
                GlobalVariableDel(DoubleToString(GetMagicNumber()));
            }
        }

        return bResult;
    }

    // Order Price
    void SetOrderPrice(double price)
    {
        m_stTradeRequestInfo.price = price;
    }
    double GetOrderPrice()
    {
        return m_stTradeRequestInfo.price;
    }

    // Magic Number
    void SetMagicNumber(ulong number)
    {
        m_stTradeRequestInfo.magic = number;
    }
    ulong GetMagicNumber()
    {
        return m_stTradeRequestInfo.magic;
    }

    // Ticket Number
    void SetTicketNumber(ulong number)
    {
        m_stTradeRequestInfo.position = number;
    }
    ulong GetTicketNumber()
    {
        return m_stTradeRequestInfo.position;
    }

    // Order Lots
    void SetOrderLots(double lots)
    {
        m_stTradeRequestInfo.volume = lots;
    }
    double GetOrderLots()
    {
        return m_stTradeRequestInfo.volume;
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
    ulong SetOrderType(ENUM_ORDER_TYPE type)
    {
        return m_stTradeRequestInfo.type = (ENUM_ORDER_TYPE)type;
    }
    ENUM_ORDER_TYPE GetOrderType()
    {
        return m_stTradeRequestInfo.type;
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
    double           GetStopLossPrice()
    {
        return m_dSLPrice;
    }
    void             DrawStopLossLine(double price)
    {
        // マジックナンバーがユニークな値なのでそのままオブジェクト名として利用
        string strObjectName = DoubleToString(GetMagicNumber());
        ObjectCreate(strObjectName, OBJ_HLINE, 0, 1, price);
        //ObjectSet(strObjectName, OBJPROP_COLOR, Blue);
        ObjectSet(strObjectName, OBJPROP_COLOR, Blue);
        ObjectSet(strObjectName, OBJPROP_STYLE, STYLE_DOT);
    }
    void             EraseStopLossLine()
    {
        string strObjectName = DoubleToString(GetMagicNumber());
        ObjectDelete(strObjectName);
    }
    // Stop Loss 監視
    bool             OvserveStopLoss()
    {
        bool bResult = false;

        //Print("Stop Loss price : ", m_dSLPrice);
        if(m_dSLPrice > 0.0)
        {
            // GetOrderType から OrderType を取得
            ENUM_ORDER_TYPE nOrderType = GetOrderType();
            switch(nOrderType)
            {
                case ORDER_TYPE_BUY:
                case ORDER_TYPE_BUY_LIMIT:
                case ORDER_TYPE_BUY_STOP:
                    if(m_dSLPrice > Bid)
                    {
                        bResult = true;
                    }
                    break;
                case ORDER_TYPE_SELL:
                case ORDER_TYPE_SELL_LIMIT:
                case ORDER_TYPE_SELL_STOP:
                    if(m_dSLPrice < Ask)
                    {
                        bResult = true;
                    }
                    break;
            }
        }

        return bResult;
    }

    // Take Profit 価格
    void             SetTakeProfitPrice(double price)
    {
        m_dTPPrice = price;
        DrawTakeProfitLine(price);
        Print("Set Take profit : ", price);
    }
    double           GetTakeProfitPrice()
    {
        return m_dTPPrice;
    }
    void             DrawTakeProfitLine(double price)
    {
        // マジックナンバーがユニークな値なのでそのままオブジェクト名として利用
        string strObjectName = DoubleToString(GetMagicNumber());
        ObjectCreate(strObjectName, OBJ_HLINE, 0, 1, price);
        ObjectSet(strObjectName, OBJPROP_COLOR, Red);
        ObjectSet(strObjectName, OBJPROP_STYLE, STYLE_DOT);
    }
    void             EraseTakeProfitLine()
    {
        string strObjectName = DoubleToString(GetMagicNumber());
        ObjectDelete(strObjectName);
    }
    // Take Profit 監視
    bool             OvserveTakeProfit()
    {
        bool bResult = false;

        //Print("Take profit price : ", m_dTPPrice);
        if(m_dTPPrice > 0.0)
        {
            // GetOrderType から OrderType を取得
            ENUM_ORDER_TYPE nOrderType = GetOrderType();
            switch(nOrderType)
            {
                case ORDER_TYPE_BUY:
                case ORDER_TYPE_BUY_LIMIT:
                case ORDER_TYPE_BUY_STOP:
                    if(m_dTPPrice < Bid)
                    {
                        bResult = true;
                    }
                    break;
                case ORDER_TYPE_SELL:
                case ORDER_TYPE_SELL_LIMIT:
                case ORDER_TYPE_SELL_STOP:
                    if(m_dTPPrice > Ask)
                    {
                        bResult = true;
                    }
                    break;
            }
        }

        return bResult;
    }

    void             SetReleasePrice(double price)
    {
        m_dReleasePrice = price;
    }
    double           GetReleasePrice()
    {
        return m_dReleasePrice;
    }
    void             SetReleaseBorderPips(double pips)
    {
        m_dReleaseBorderPips = pips;
    }
    double           GetReleaseBorderPips()
    {
        return m_dReleaseBorderPips;
    }
    // Release Price 監視
    bool             OvserveReleasePrice()
    {
        bool bResult = false;

        if(m_dReleasePrice > 0.0 && m_dReleaseBorderPips > 0.0)
        {
            double dNowPrice = 0;
            // GetOrderType から OrderType を取得
            ENUM_ORDER_TYPE nOrderType = GetOrderType();
            switch(nOrderType)
            {
                case ORDER_TYPE_BUY:
                case ORDER_TYPE_BUY_LIMIT:
                case ORDER_TYPE_BUY_STOP:
                    dNowPrice = Bid;
                    // 現在価格が リリース判定価格 + 更新幅pips より高い状態なら
                    // 　→ 新しい Release Price をセット
                    if(dNowPrice > m_dReleasePrice + m_dReleaseBorderPips)
                    {
                        m_dReleasePrice = dNowPrice - m_dReleaseBorderPips;
                    }
                    // 現在価格が リリース判定価格より高い状態なら
                    // 　→ リリースしても良いフラグを立てる
                    if(dNowPrice > m_dReleasePrice)
                    {
                        m_bIsRelease = true;
                    }
                    // フラグが立っている && 現在価格が リリース判定価格 を割っている
                    // 　→ リリースしましょう
                    if(m_bIsRelease && dNowPrice < m_dReleasePrice)
                    {
                        // リリースする
                        bResult = true;
                    }
                    break;

                case ORDER_TYPE_SELL:
                case ORDER_TYPE_SELL_LIMIT:
                case ORDER_TYPE_SELL_STOP:
                    dNowPrice = Ask;
                    // 現在価格が リリース判定価格 + 更新幅pips より低い状態なら
                    // 　→ 新しい Release Price をセット
                    if(dNowPrice < m_dReleasePrice - m_dReleaseBorderPips)
                    {
                        m_dReleasePrice = dNowPrice + m_dReleaseBorderPips;
                    }
                    // 現在価格が リリース判定価格より低い状態なら
                    // 　→ リリースしても良いフラグを立てる
                    if(dNowPrice < m_dReleasePrice)
                    {
                        m_bIsRelease = true;
                    }
                    // フラグが立っている && 現在価格が リリース判定価格 を超えている
                    // 　→ リリースしましょう
                    else
                        if(m_bIsRelease && dNowPrice > m_dReleasePrice)
                        {
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
