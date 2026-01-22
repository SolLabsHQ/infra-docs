

## **FIXLOG**

\# Fix Log — Muse Overlay \+ Starlight

\#\# Decisions

\- Starlight state is semantic (idle/pending/flash), triggered by 202 but not named 202\.

\- Muse overlay is top-left, ZStack overlay (no layout push).

\- Only the Muse handle is swipeable (avoid accidental scroll conflicts).

\- Dismiss is recoverable via a thin, translucent, leading-aligned pill (3–5s).

\- Saved memories: receipt window (3s/5s) \+ glow then evaporate in place.

\- Manual entry persists until action; typing hides it and shows recovery pill.

\- Assistant arrival haptics: soft if fast, heartbeat if slow with mild scaling capped \+20%.

\- 👻 is locked as v0.1 Muse symbol with spectral styling \+ echo pulse.

\- Assistant arrival hook: latest assistant message appended in ThreadDetailView.

\#\# Open items

\- Confirm heartbeat scaling curve for slow arrivals (linear 1.2s → +20% over 4s ok?).

---
