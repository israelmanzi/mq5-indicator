#!/bin/bash
MT5_IND="/home/zozin/.var/app/com.usebottles.bottles/data/bottles/bottles/mt5/drive_c/Program Files/MetaTrader 5 Terminal/MQL5/Indicators"

cp PriceActionZones.mq5 "$MT5_IND/"
mkdir -p "$MT5_IND/Include/PAZ"
cp Include/PAZ/*.mqh "$MT5_IND/Include/PAZ/"

echo "Deployed to MT5 Indicators folder"
