# PriceActionZones — MT5 Indicator

A pure price action indicator for MetaTrader 5. No lagging indicators, no moving averages — only raw price structure and supply/demand zones across multiple timeframes from Daily down to M15.

> **Status:** Active development. Zone detection, entry checklist, BOS/CHoCH, and two-stage alerts are live. Trendlines, candle pattern labels, liquidity markers, key levels, and trade management are built but toggled off — being validated incrementally.

## What You See on Chart

### Zones

**Buy Zone** — Dotted blue rectangle outline labeled "BUY ZONE H1" (or H4). Price previously dropped here, paused, and reversed upward. Expect buyers to step in again when price returns.

**Sell Zone** — Dotted red rectangle outline labeled "SELL ZONE H4" (or H1). Price previously rallied here, stalled, and reversed downward. Expect sellers to push price down when price returns.

**Faded Zone** — Dashed border in muted dark color with smaller label. Old zone that price never broke through. Still valid but lower conviction than fresh zones.

Mitigated zones (price closed through them) are hidden — they're dead and won't reappear.

### Entry Box

A filled rectangle inside active H1 zones showing the M15-refined entry area with a 5-step checklist.

**Entry box color tells you readiness at a glance:**

| Color | Score | Meaning |
|---|---|---|
| Green | 5/5 | All conditions met — actionable |
| Gold | 3-4/5 | Getting close — watch this zone |
| Gray | 0-2/5 | Not ready |

**Checklist legend** printed below the entry label:

```
D1+ ZN+ SW- BOS+ CP-
```

| Code | What it checks | + means | - means |
|---|---|---|---|
| D1 | D1 trend bias | Clear bullish or bearish | Ranging, no direction |
| ZN | Zone aligns with bias | Buy zone + bull bias, or sell + bear | Zone conflicts with D1 direction |
| SW | H1 liquidity sweep | Stops grabbed on H1 in last 24h | No H1 sweep detected |
| BOS | M15 Break of Structure | M15 confirmed the trade direction | No M15 BOS yet |
| CP | Candle pattern at zone | Matching pattern at this zone's price | No pattern detected |

### BOS / CHoCH Labels

Text labels on the chart (no lines) marking M15 structure events:

- **Blue "BOS 1.08234"** — Bullish Break of Structure. Trend continuing up.
- **Coral "BOS 1.07890"** — Bearish Break of Structure. Trend continuing down.
- **Gold "CHoCH 1.08100"** — Change of Character. Trend may be reversing.

### Smart Timeframe Filtering

Zones auto-filter based on the chart you're viewing:

| Chart | Zones shown |
|---|---|
| D1 | D1 only |
| H4 | D1 + H4 |
| H1 | H4 + H1 |
| M15 | H1 only |

By default, only the 3 nearest zones above and below current price are displayed.

## Alerts

Two-stage notification system. All channels fire on both stages (Print, Alert pop-up, Push to phone).

**Stage 1 — Heads Up** (5/5 checklist conditions met):
```
PAZ EURUSD BUY ZONE READY 5/5 | Zone 1.08100-1.08234
```

**Stage 2 — Enter Now** (5/5 + confirmation candle closes):
```
PAZ EURUSD BUY @ 1.08234 | SL 1.08100 | TP 1.08650
```

Each zone only triggers each stage once — no repeated alerts for the same setup.

### Push Notifications Setup

To receive alerts on your phone:

1. Install MetaTrader 5 mobile app, log into your broker
2. In the mobile app: Settings → MetaQuotes ID — copy the ID
3. In desktop MT5: Tools → Options → Notifications — paste the ID, enable
4. Click Test to verify

The indicator must be running on your desktop for alerts to fire. MT5 mobile cannot run custom indicators — it only receives the push messages.

## How to Read It

1. **Check the zones** — is price approaching a BUY ZONE or SELL ZONE?
2. **Check the entry box color** — green means all conditions aligned
3. **Read the legend** — D1+ ZN+ SW+ BOS+ CP+ tells you exactly what's confirmed
4. **Look for BOS/CHoCH labels** — these confirm whether M15 structure supports the trade
5. **Wait for Stage 2 alert** — that's your signal with exact entry, SL, and TP prices

## What's Built But Not Yet Enabled

Togglable in indicator settings under "Visual Layers":

- Trendlines (auto-drawn from swing points, break and retest detection)
- Candlestick pattern labels at key levels
- Liquidity sweep markers
- Equal highs/lows (liquidity pools)
- Key levels (multi-touch horizontals)
- Trade management visuals (trailing SL, breakeven, TP)
- Dashboard panel

## Settings

All configurable from the indicator properties:

- **Swing Points** — Lookback bars per timeframe (D1=5, H4=3, H1=3, M15=2)
- **Zones** — Max per TF (default 5), minimum quality (default 5/10), fade timing
- **Alerts** — Push, sound, and pop-up (all ON by default)
- **Timeframe Display** — Toggle D1, H4, H1 zones and M15 BOS/CHoCH
- **Visual Layers** — Toggle trendlines, candle labels, sweep markers, equal highs/lows, key levels (all OFF by default)
- **Nearest Zones** — How many zones above/below price (default 3, 0 = all)
- **Dashboard** — Toggle on/off, choose corner

## Disclaimer

This is an analysis tool, not financial advice. Always manage your risk. Past price patterns do not guarantee future results.

## License

MIT
