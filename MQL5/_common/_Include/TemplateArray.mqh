//# vim:set foldmethod=marker:
//+------------------------------------------------------------------+
//|                                                 PositionInfo.mq4 |
//|                                   Copyright 2015, SENAGA Yusuke. |
//|                                               mi081321@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, SENAGA Yusuke."
#property link      "mi081321@gmail.com"

#include "Define.mqh"

// Note //{{{
/*

*/

//}}}

template<typename T>
class CArrayT //{{{
{
private:
	T m_list[];

public:
	CArrayT()
	{
		resize(0);
	}
	~CArrayT()
	{
	}

	int length()
	{
		return ArrayRange(m_list, 0);
	}

	int resize(const int size)
	{
		return ArrayResize(m_list, size);
	}

	void insert( T& element, const int index)
	{
		resize(length() + 1);
		for (int i = length() - 1; i > index; i--){
			m_list[i] = m_list[i - 1];
		}

		m_list[index] = element;
	}

	void erase(const int index)
	{
		/*
		if (pBuffer != NULL){
			pBuffer.Close();
			delete pBuffer;
		}
		*/

		for (int i = index; i < length() - 1; i++){
			m_list[i] = m_list[i + 1];
		}

		resize(length() - 1);
	}

	void push_back(T element)
	{
		resize(length() + 1);
		m_list[length() - 1] = element;
	}

	T at(int index)
	{
		return m_list[index];
	}
}; //}}}
