# 🍄 Mushroom Alert (`bk.mushroom`)

An Omarchy status bar widget that tracks local weather conditions and alerts you when rainfall, temperature, and humidity are prime for mushroom foraging (chanterelles, porcini, and autumn fungi).

## Features

- **Foraging Index (0–100):** Evaluates local weather conditions using:
  - 🌧️ **Precipitation:** Cumulative rainfall over the past 72 hours.
  - 🌡️ **Temperature:** Optimal fungal growth window (10°C–18°C).
  - 💧 **Moisture:** Relative humidity and dew point levels.
  - 🍂 **Seasonality:** Weighted for northern hemisphere peak season (August–October).
- **Status Bar Indicator:**
  - Dynamic status pills: `🍄 Prime`, `🍄 Good`, `🍄 Fair`, or `🍄 Low`.
  - Highlights active pill when conditions are favorable.
- **Interactive:**
  - **Left click:** Sends an Omarchy desktop notification with a breakdown of recent rainfall, temperature, humidity, and foraging advice.
  - **Right click:** Forces an immediate weather data refresh.
- **Location Aware:** Reads coordinates automatically from Omarchy weather settings (`~/.local/state/omarchy/settings/weather.json`), with fallback coordinates.
- **IPC Support:** Control from terminal or scripts:
  ```bash
  omarchy-shell emit bk.mushroom refresh
  omarchy-shell emit bk.mushroom notify
  ```

## Installation

Install and enable the widget in your Omarchy shell:

```bash
omarchy plugin add https://github.com/bkvingedal/omarchy-mushroom.git --enable
```

Or clone manually into your Omarchy plugins directory:

```bash
git clone https://github.com/bkvingedal/omarchy-mushroom.git ~/.config/omarchy/plugins/bk.mushroom
omarchy plugin enable bk.mushroom --section center
```

## License

MIT
