#!/bin/bash
MT5_IND="/home/zozin/.var/app/com.usebottles.bottles/data/bottles/bottles/mt5/drive_c/Program Files/MetaTrader 5 Terminal/MQL5/Indicators"

# Deploy to MT5
cp PriceActionZones.mq5 "$MT5_IND/"
mkdir -p "$MT5_IND/Include/PAZ"
cp Include/PAZ/*.mqh "$MT5_IND/Include/PAZ/"

# Package as zip
rm -f out.zip
zip -r out.zip PriceActionZones.mq5 Include/PAZ/*.mqh

echo "Deployed to MT5 Indicators folder"
echo "Packaged to out.zip"
