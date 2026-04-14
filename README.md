# PriceActionZones — MT5 Indicator

A pure price action indicator for MetaTrader 5. No lagging indicators, no moving averages — only raw price structure and supply/demand zones across multiple timeframes.

> **Status:** Early development. Zone detection and display is live. Entry signals, BOS/CHoCH, trendlines, and other layers are built but not yet enabled — being validated one layer at a time.

## What You See on the Chart

### Buy Zones

Dotted blue rectangle outline labeled **"BUY ZONE H1"** (or H4, D1 depending on context). This is where price previously dropped, paused, and reversed upward. Expect buyers to step in here again.

If a bright filled blue box labeled **"ENTRY"** appears inside the zone, that's the M15-refined precision area — your tighter entry point.

### Sell Zones

Dotted red rectangle outline labeled **"SELL ZONE H4"**. This is where price previously rallied, stalled, and reversed downward. Expect sellers to push price down here.

Bright salmon filled box labeled **"ENTRY"** inside = the refined entry area.

### Faded Zones

Same as above but with muted colors and smaller text. These zones are old but price never broke through them. They may still hold, but carry less conviction than fresh zones.

Mitigated zones (price already closed through them) are hidden entirely.

### Smart Timeframe Filtering

Zones auto-filter based on the chart you're viewing:

| Chart Timeframe | Zones Shown |
|---|---|
| D1 | D1 only |
| H4 | D1 + H4 |
| H1 | H4 + H1 |
| M15 | H1 only |

Switch timeframes and the relevant zones appear automatically.

### Nearest Zone Filter

By default, only the 3 nearest zones above and below current price are shown. Configurable in settings (set to 0 for all zones).

## What's Built But Not Yet Enabled

The following modules are fully implemented in the codebase but commented out while we validate each layer:

- **BOS/CHoCH** — Break of Structure and Change of Character detection on M15
- **Trendlines** — Auto-drawn from swing points on H4/H1 with break and retest tracking
- **Candlestick Patterns** — Engulfing, pin bars, morning/evening star, inside bars, and more — only at key levels
- **Liquidity Sweeps** — Detects stop hunts before reversals
- **Equal Highs/Lows** — Liquidity pool detection
- **Key Levels** — Multi-touch horizontal levels across timeframes
- **Entry Signals** — 7-step checklist combining all modules (D1 bias, zone alignment, liquidity sweep, M15 BOS, candle pattern, confirmation, R:R filter)
- **Trade Management** — SL/TP placement, breakeven at 1:1, trailing SL to swing points
- **Dashboard** — Compact bias + status panel
- **Alerts** — Push, sound, and visual notifications on entry signals

These will be enabled progressively as zone display is validated.

## Settings

Configurable from the indicator properties panel:

**Swing Points** — Lookback bars per timeframe (D1=5, H4=3, H1=3, M15=2).

**Zones** — Max active zones per TF (default 5), minimum quality score (default 5/10), fade timing.

**Timeframe Display** — Toggle D1, H4, H1 zones and M15 BOS/CHoCH.

**Visual Layers** — Toggle trendlines, candle labels, liquidity markers, equal highs/lows, key levels. All OFF by default.

**Nearest Zones** — Zones shown above + below price (default 3, 0 = all).

**Dashboard** — Toggle on/off, choose corner.

## Installation

1. Copy `PriceActionZones.mq5` and the `Include/PAZ/` folder into your MT5 indicators directory
2. Open MetaEditor (F4), open the file, compile (F7)
3. Attach to any chart

### File Placement

Place inside your MT5 data folder (**File > Open Data Folder** in MT5):

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

Run `./deploy.sh` from the project directory to copy files to the MT5 indicators folder, then compile in MetaEditor.

## Disclaimer

This is an analysis tool, not financial advice. Always manage your risk. Past price patterns do not guarantee future results.

## License

MIT
