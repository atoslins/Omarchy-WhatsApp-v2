.pragma library

// Emoji data comes from Omarchy's own picker (shell/plugins/emojis/emojis.json,
// entries of { e: emoji, k: keywords }). A short list keeps the picker useful
// if that file is missing.
var FALLBACK = [
  { e: "\ud83d\ude00", k: "grinning face smile happy" },
  { e: "\ud83d\ude02", k: "face with tears of joy laugh" },
  { e: "\ud83d\ude0a", k: "smiling face blush happy" },
  { e: "\ud83d\ude0d", k: "heart eyes love" },
  { e: "\ud83d\ude09", k: "wink" },
  { e: "\ud83d\ude0e", k: "cool sunglasses" },
  { e: "\ud83e\udd14", k: "thinking" },
  { e: "\ud83d\ude22", k: "crying sad" },
  { e: "\ud83d\ude2e", k: "surprised open mouth wow" },
  { e: "\ud83d\ude4f", k: "folded hands please thanks pray" },
  { e: "\ud83d\udc4d", k: "thumbs up like yes" },
  { e: "\ud83d\udc4e", k: "thumbs down no" },
  { e: "\ud83d\udc4f", k: "clapping hands applause" },
  { e: "\ud83d\udcaa", k: "flexed biceps strong" },
  { e: "\u2764\ufe0f", k: "red heart love" },
  { e: "\ud83d\udd25", k: "fire hot lit" },
  { e: "\ud83c\udf89", k: "party popper celebrate" },
  { e: "\u2705", k: "check mark done yes" },
  { e: "\ud83d\ude4c", k: "raising hands hooray" },
  { e: "\ud83d\udc40", k: "eyes look" }
]

function parse(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    var values = Array.isArray(data) ? data.filter(function(item) {
      return item && typeof item.e === "string" && item.e !== ""
    }) : []
    return values.length > 0 ? values : FALLBACK
  } catch (error) {
    return FALLBACK
  }
}

function filter(emojis, query, limit) {
  var values = Array.isArray(emojis) && emojis.length > 0 ? emojis : FALLBACK
  var needle = String(query || "").trim().toLowerCase()
  var max = Math.max(0, Number(limit === undefined ? 400 : limit))
  var out = []
  for (var i = 0; i < values.length && out.length < max; i++) {
    var item = values[i]
    if (!needle || String(item.k || "").toLowerCase().indexOf(needle) >= 0) out.push(item)
  }
  return out
}

// Most recent first, without duplicates, bounded.
function remember(recent, emoji, limit) {
  var next = [emoji]
  var values = Array.isArray(recent) ? recent : []
  for (var i = 0; i < values.length && next.length < (limit || 16); i++)
    if (values[i] !== emoji) next.push(values[i])
  return next
}
