# PriceActionZones — MT5 Indicator

A pure price action indicator for MetaTrader 5. No lagging indicators, no moving averages — only raw price structure, supply/demand zones, and multi-timeframe analysis from Daily down to M15.

## What You See on the Chart

The indicator is designed for a **clean chart by default**. You see only what helps you make a decision right now. Additional layers can be toggled on when you need them.

### Default View (always on)

**Buy Zones** — Dotted blue rectangle outline with "BUY ZONE H1" label. This is where price previously dropped, paused, and shot upward. Expect buyers to step in here again.

**Sell Zones** — Dotted red rectangle outline with "SELL ZONE H4" label. This is where price previously rallied, stalled, and dropped. Expect sellers to push price down here.

**Entry Boxes** — Bright filled rectangle inside a zone labeled "ENTRY". This is the M15-refined precision area within the larger zone. Your actual entry point.

**Faded Zones** — Muted, smaller-font version of the above. These zones are old but still unmitigated (price never broke through). They may still hold, but treat with less conviction than fresh zones.

Mitigated zones (price already broke through) are hidden — they no longer matter.

### Smart Timeframe Filtering

Zones auto-filter based on the chart you're viewing:

| Chart Timeframe | Zones Shown |
|---|---|
| D1 | D1 only |
| H4 | D1 + H4 |
| H1 | H4 + H1 |
| M15 | H1 only |

No manual switching needed. Switch timeframes and the relevant zones appear.

### Optional Layers (toggle in settings)

These are OFF by default to keep the chart clean. Enable them under **Visual Layers** in the indicator settings:

| Layer | What it shows |
|---|---|
| BOS/CHoCH | Break of Structure and Change of Character lines on M15 — confirms trend continuation or reversal |
| Trendlines | Auto-drawn from swing points on H4/H1, with break and retest detection |
| Candle Pattern Labels | Text labels ("BullEng", "Hammer", etc.) at key levels only |
| Liquidity Sweep Markers | Arrows marking where stops were hunted before a reversal |
| Equal Highs/Lows | Dotted lines at liquidity pools where stop losses cluster |
| Key Levels | Multi-touch horizontal levels across timeframes |

### Entry Signals

When enabled, the indicator marks entries only when **all 7 conditions align**:

1. D1 trend bias is clear
2. Price is at an H4/H1 zone aligned with the trend
3. A liquidity sweep occurred (stops grabbed)
4. M15 confirms with a BOS in the trade direction
5. A candlestick pattern appears at the key level
6. A confirmation candle closes beyond the signal candle
7. Reward-to-risk meets the minimum threshold (default 1:2)

Entry types: zone taps, breakout and retest, double tops, double bottoms.

### Trade Management

After an entry signal fires:
- **SL** placed behind the trigger zone
- **TP** targets the next opposing zone or key level
- **Breakeven** at 1:1 — SL moves to entry price
- **Trailing SL** follows new M15 swing points as price moves in your favor

### Dashboard

A compact panel showing:
- D1/H4/H1 bias at a glance (+ bullish, - bearish, = ranging)
- Current trade status
- Active zone count

## How to Read It

1. **Check the bias** — are the higher timeframes aligned? D1+ H4+ means look for buys only
2. **Watch the zones** — is price approaching a BUY ZONE from above? That's your area of interest
3. **Drop to M15** — look for BOS confirmation and a candle pattern at the zone
4. **Wait for the arrow** — if entry signals are enabled, the green/red arrow means the checklist passed
5. **SL and TP are mapped** — the tomato line is your stop, the green line is your target

## Color Guide

| Element | Color |
|---|---|
| Buy zone outline | Steel Blue |
| Sell zone outline | Indian Red |
| Buy entry box (refined) | Bright Blue |
| Sell entry box (refined) | Salmon |
| Faded zone | Muted darker version |
| BOS (bullish) | Dodger Blue |
| BOS (bearish) | Coral |
| CHoCH | Gold |
| Trendlines | Silver |
| Stop Loss | Tomato |
| Take Profit | Sea Green |
| Liquidity sweep | Magenta |
| Equal highs/lows | Orange |
| Buy entry arrow | Lime |
| Sell entry arrow | Red |

## Settings

All configurable from the indicator properties panel:

**Swing Points** — Lookback bars per timeframe (D1=5, H4=3, H1=3, M15=2). Higher = fewer, more significant swings.

**Zones** — Max active zones per TF (default 5), minimum quality score (default 5/10), fade timing, mitigated zone visibility.

**Entry Signals** — Minimum R:R ratio (default 1:2).

**Alerts** — Toggle push notifications, sound alerts, and visual markers independently.

**Timeframe Display** — Toggle D1, H4, H1 zones and M15 BOS/CHoCH.

**Visual Layers** — Toggle trendlines, candle labels, liquidity markers, equal highs/lows, key levels. All OFF by default.

**Nearest Zones** — How many zones to show above and below current price (default 3). Set to 0 for all.

**Dashboard** — Toggle on/off, choose corner position.

## Installation

1. Copy `PriceActionZones.mq5` and the `Include/PAZ/` folder into your MT5 indicators directory
2. Open MetaEditor (F4), open the file, compile (F7)
3. Attach to any chart

### File Placement

Place files inside your MT5 data folder (find it via **File > Open Data Folder** in MT5):

```
MQL5/
  Indicators/
    PriceActionZones.mq5
    Include/
      PAZ/
        Constants.mqh
        Structures.mqh
        Inputs.mqh
        MTFData.mqh
        SwingPoints.mqh
        MarketStructure.mqh
        ZoneBuilder.mqh
        CandlePatterns.mqh
        Liquidity.mqh
        Trendlines.mqh
        KeyLevels.mqh
        EntrySignals.mqh
        TradeManagement.mqh
        Drawing.mqh
        Dashboard.mqh
```

### Linux (Bottles/Wine)

A `deploy.sh` script is included. Run `./deploy.sh` from the project directory to copy files to the MT5 indicators folder, then compile in MetaEditor.

## Disclaimer

This is an analysis tool, not financial advice. Always manage your risk. Past price patterns do not guarantee future results.

## License

MIT
