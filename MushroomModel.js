// Evaluates mushroom foraging suitability score (0 - 100)
function evaluateConditions(data) {
  if (!data || !data.current || (!data.hourly && !data.daily)) {
    return { score: 0, level: "Unknown", label: "🍄 ?", alert: false, rain3d: 0, temp: 0, rh: 0, dew: 0 };
  }

  var cur = data.current;
  var hourly = data.hourly;
  var daily = data.daily;

  // Rainfall in true past 72 hours (hourly precipitation with past_hours=72, forecast_hours=0)
  var rain3d = 0;
  if (hourly && Array.isArray(hourly.precipitation)) {
    for (var i = 0; i < hourly.precipitation.length; i++) {
      rain3d += (parseFloat(hourly.precipitation[i]) || 0);
    }
  } else if (daily && Array.isArray(daily.precipitation_sum)) {
    // Fallback if daily data is passed
    var count = Math.min(3, daily.precipitation_sum.length);
    for (var i = 0; i < count; i++) {
      rain3d += (parseFloat(daily.precipitation_sum[i]) || 0);
    }
  }
  rain3d = Math.round(rain3d * 10) / 10;

  var temp = parseFloat(cur.temperature_2m) || 0;
  var rh = parseFloat(cur.relative_humidity_2m) || 0;
  var dew = (cur.dew_point_2m !== undefined && cur.dew_point_2m !== null) ? parseFloat(cur.dew_point_2m) : (temp - ((100 - rh) / 5));

  // Seasonal factor (Northern Europe / Norway: Peak in Aug-Oct, moderate in Jul/Nov)
  var month = new Date().getMonth(); // 0-indexed: 6=Jul, 7=Aug, 8=Sep, 9=Oct, 10=Nov
  var seasonFactor = 0.3;
  if (month >= 7 && month <= 9) seasonFactor = 1.0; // Aug - Oct (Peak)
  else if (month === 6 || month === 10) seasonFactor = 0.7; // Jul / Nov

  // Rain Score (0 - 45 points)
  var rainScore = 0;
  if (rain3d >= 20) rainScore = 45;
  else if (rain3d >= 10) rainScore = 38;
  else if (rain3d >= 5) rainScore = 28;
  else if (rain3d >= 2) rainScore = 18;
  else if (rain3d >= 0.5) rainScore = 8;

  // Temperature Score (0 - 30 points, ideal 10°C - 18°C)
  var tempScore = 0;
  if (temp >= 10 && temp <= 18) tempScore = 30;
  else if (temp >= 7 && temp <= 22) tempScore = 20;
  else if (temp >= 4 && temp <= 25) tempScore = 10;

  // Humidity Score (0 - 25 points, ideal > 75%)
  var rhScore = 0;
  if (rh >= 80) rhScore = 25;
  else if (rh >= 70) rhScore = 18;
  else if (rh >= 60) rhScore = 10;

  var rawScore = (rainScore + tempScore + rhScore) * seasonFactor;
  var finalScore = Math.min(100, Math.round(rawScore));

  var level = "Dry";
  var label = "🍄 Low";
  var alert = false;

  if (finalScore >= 65) {
    level = "Prime";
    label = "🍄 Prime";
    alert = true;
  } else if (finalScore >= 45) {
    level = "Good";
    label = "🍄 Good";
    alert = true;
  } else if (finalScore >= 30) {
    level = "Fair";
    label = "🍄 Fair";
  }

  return {
    score: finalScore,
    level: level,
    label: label,
    alert: alert,
    rain3d: rain3d,
    temp: Math.round(temp),
    rh: Math.round(rh),
    dew: Math.round(dew)
  };
}

if (typeof module !== "undefined") {
  module.exports = {
    evaluateConditions: evaluateConditions
  };
}
