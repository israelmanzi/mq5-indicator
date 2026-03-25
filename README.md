# PriceActionZones — MT5 Indicator

A pure price action indicator for MetaTrader 5 that identifies high-probability trading zones, market structure, and entry signals across multiple timeframes. No lagging indicators — only raw price data.

## What This Indicator Does

PriceActionZones performs **top-down multi-timeframe analysis** from Daily down to M15, automatically identifying:

### Market Structure
- **Swing highs and lows** with labels (HH, HL, LH, LL) on all timeframes
- **Trend direction** derived from swing point sequences — not moving averages
- **Break of Structure (BOS)** and **Change of Character (CHoCH)** on M15 for precise entry confirmation

### Supply and Demand Zones
- Automatically detects valid **demand zones** (buy areas) and **supply zones** (sell areas) on D1, H4, and H1
- Each zone is **scored 0-10** based on departure strength, freshness, whether it caused a BOS, base candle count, and higher-timeframe confluence
- Only zones scoring above your threshold are displayed — no clutter
- **Zone refinement**: H1 zones are automatically refined using M15 data for tighter entries
- Zones are tracked as they age: fresh zones are highlighted, mitigated zones fade to muted colors

### Candlestick Patterns
- Detects key reversal patterns: **engulfing, pin bar (hammer/shooting star), morning/evening star**
- Continuation patterns: **inside bar, three white soldiers / three black crows**
- Context patterns: **doji at key levels, tweezer tops/bottoms**
- Patterns are **only displayed when they occur at a key level** (zone, trendline, or structure level) — not random noise in the middle of a range

### Liquidity Analysis
- Identifies **equal highs and equal lows** — these are liquidity pools where stop losses cluster
- Detects **liquidity sweeps** — when price spikes beyond a key level and reverses, signaling that stops were hunted before the real move

### Trendlines
- Auto-drawn by connecting swing points (higher lows for uptrend, lower highs for downtrend)
- Tracks **breaks and retests** — when a trendline breaks and price returns to test the other side, the indicator flags it
- Steep trendlines (>80 degrees) are marked as unreliable

### Key Levels
- Horizontal levels where price has reacted **3 or more times** across multiple timeframes
- Psychological round numbers are automatically detected
- These serve as TP targets and confluence points

### Entry Signals
The indicator only marks an entry when **all conditions align**:

1. D1 trend bias is clear (bullish or bearish)
2. Price is at an H4/H1 supply or demand zone aligned with the bias
3. A liquidity sweep has occurred (stops were grabbed)
4. M15 shows a BOS in the trade direction
5. A candlestick pattern confirms at the key level
6. A confirmation candle closes beyond the signal candle
7. Risk-to-reward meets your minimum threshold (default 1:2)

Entry types include **zone taps**, **breakout and retest**, **double tops**, and **double bottoms**.

### Trade Management
- **SL** placed behind the trigger zone with a spread buffer
- **TP** targets the next opposing zone or key level
- **Breakeven**: SL moves to entry price when 1:1 R:R is reached
- **Trailing SL**: automatically trails to each new swing point as price moves in your favor

### Dashboard
An on-chart panel displays:
- Current D1, H4, and H1 bias
- Number of active zones
- Last BOS and CHoCH events
- Current trade status and R:R

## Color Guide

| Element | Color |
|---------|-------|
| Demand zones (buy areas) | Steel Blue |
| Supply zones (sell areas) | Indian Red |
| Refined zones | Brighter blue / salmon |
| Mitigated zones | Dark muted colors, dashed |
| BOS (bullish) | Dodger Blue |
| BOS (bearish) | Coral |
| CHoCH | Gold |
| Trendlines | Silver |
| Stop Loss | Tomato |
| Take Profit | Sea Green |
| Liquidity sweep | Magenta |
| Equal highs/lows | Orange dotted |
| Buy entry | Lime arrow |
| Sell entry | Red arrow |

## Settings

All parameters are configurable from the indicator settings panel:

**Swing Points** — Lookback period per timeframe (D1, H4, H1, M15). Higher = fewer but more significant swings.

**Zones** — Max active zones per timeframe (default 5), minimum quality score (default 5/10), fade timing, mitigated zone visibility duration.

**Entry Signals** — Minimum reward-to-risk ratio (default 1:2, set to 0 to disable filtering).

**Alerts** — Toggle push notifications, sound alerts, and visual markers independently.

**Timeframe Display** — Toggle D1, H4, H1 zones and M15 BOS/CHoCH on or off.

**Dashboard** — Toggle the info panel and choose which corner it appears in.

## Installation

1. Copy `PriceActionZones.mq5` and the `Include/PAZ/` folder into your MetaTrader 5 data directory
2. Open MetaEditor, navigate to the file, and compile (F7)
3. Attach the indicator to any chart
4. Configure your preferred settings

See the **Compilation Guide** section below for detailed setup.

## Compilation Guide

### Option 1: Compile from MetaEditor (Recommended)

1. Open MetaTrader 5
2. Press **F4** to open MetaEditor
3. In MetaEditor, go to **File > Open** and navigate to `PriceActionZones.mq5`
4. Press **F7** (or click the Compile button) to compile
5. If successful, you'll see "0 errors, 0 warnings" in the output panel
6. Switch back to MetaTrader 5 — the indicator appears under **Insert > Indicators > Custom**

### Option 2: Compile from MetaEditor Command Line

```
MetaEditor64.exe /compile:"C:\path\to\PriceActionZones.mq5" /log
```

Check the MetaEditor log file for results.

### File Placement

For MetaEditor to resolve the `Include/PAZ/` directory correctly, place the files so that the structure looks like this inside your MT5 data folder:

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

To find your MT5 data folder: in MetaTrader 5, go to **File > Open Data Folder**.

## Recommended Usage

- **Attach to H1 chart** as your primary working timeframe
- The indicator reads D1, H4, H1, and M15 data automatically regardless of which chart you're viewing
- Switch to M15 to see BOS/CHoCH confirmation details
- Wait for the full checklist to pass before entering — the indicator does the discipline for you
- Use the dashboard to stay aware of the higher-timeframe bias at all times

## Disclaimer

This indicator is a tool for analysis, not a trading system guarantee. Always apply your own judgment, manage your risk, and never risk more than you can afford to lose. Past price patterns do not guarantee future results.

## License

MIT
