#!/usr/bin/env python3
"""Buoyancy for the rows cylinder-buoyancy.py does not cover, from weight and volume.

Same physics and basis as cylinder-buoyancy.py (sea water 1.025 kg/L, standard
brass valve, real-gas air at 15 C), imported from it. Each row's weight and water
volume come from the source named in SOURCES; only the buoyancy is computed.

Two rows need more than a lookup:
- lp72, the classic steel 72: no sheet prints its water volume, so it is derived
  from the rated 71.55 cu ft at 2475 psi (real-gas air at 70 F, the US-chart
  isotherm). The one published weight (26 lb) contradicts the published empty
  buoyancy (0 lb with valve) by about 1.7 kg at that volume, so the weight is the
  one that gives the published empty buoyancy.
- ccr2_7l: no maker lists a 2.7 L bottle; its weight stays unsourced.

Usage: python3 scripts/cylinder-buoyancy-other.py [--write]
  prints every value and the sheet checks; --write updates datasets/cylinders.json.
"""

import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("cylinder_buoyancy", HERE / "cylinder-buoyancy.py")
cb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cb)
empty_kg, gas_kg, LB, PSI, RHO, RHO_SEA = cb.empty_kg, cb.gas_kg, cb.LB, cb.PSI, cb.RHO, cb.RHO_SEA
VALVE_NET = cb.VALVE_KG - RHO_SEA * cb.VALVE_KG / cb.RHO_BRASS

FDB = "Faber cylinder database (drawings.faber-italy.com, eng-product-scuba1.asp), EN 1964-1 build"
WORTH = "Worthington steel cylinder sheet (XS Scuba copy)"

# id: (weight kg without valve, water volume L or None to keep, source)
SOURCES = {
    "al12-200": (16.5, 12.0, "Luxfer P3080V, Luxfer scuba spec sheet 2022"),
    "steel12-232": (14.1, 12.0, FDB + ", 171 mm"),
    "steel12-300": (18.0, 12.0, FDB + ", 171 mm"),
    "steel15-232": (18.2, 15.0, FDB + ", 203 mm"),
    "steel10-232": (12.2, 10.0, FDB + ", 171 mm"),
    "steel10_5-232": (12.9, 10.5, FDB + ", 178 mm"),
    "steel7-232": (8.5, 7.0, FDB + ", 140 mm"),
    "steel3-300": (4.8, 3.0, FDB + ", 100 mm"),
    "steel12-200": (12.0, 12.0, FDB + ", 171 mm"),
    "steel8.5-232": (11.0, 8.5, "ECS 8.5 L 232 bar 140 mm, retailer listing (Faber makes no 8.5 L)"),
    "ccr2l": (2.6, 2.0, FDB + ", 100 mm"),
    "ccr3l": (3.6, 3.0, FDB + ", 100 mm"),
    "ccr2l-232": (2.8, 2.0, FDB + ", 100 mm"),
    "ccr3l-232": (3.8, 3.0, FDB + ", 100 mm"),
    "ccr2_7l": (None, None, "weight unsourced"),
    "hp120": (18.0, 15.3, WORTH + ", X7-120"),
    "hp119": (19.3, 14.8, WORTH + ", X8-119"),
    "hp130": (20.3, 16.0, WORTH + ", X8-130"),
    "lp50": (8.6, 7.8, "Faber LP spec sheet, LP50"),
    "lp72": ("steel72", "steel72", "steel 72, see module docstring"),
}

# Core's us70F compressibility tables (real-gas.ts), for the steel 72 rating.
Z70_N2 = [0.9998, 0.9944, 1.0015, 1.0214, 1.0527, 1.0776, 1.0931, 1.1405]
Z70_O2 = [0.9993, 0.9693, 0.9476, 0.9377, 0.9408, 0.9493, 0.9561, 0.9817]
CUFT_L = 28.316846592


def steel72():
    """Water volume from the 71.55 cu ft rating, and the weight that gives 0 lb empty."""
    p = 2475 * PSI
    z = 0.21 * cb.interp(Z70_O2, p) + 0.79 * cb.interp(Z70_N2, p)
    volume = 71.55 * CUFT_L * cb.SURFACE_BAR * z / p
    # 0 = rho*(V + m/rho_steel + V_valve) - m - m_valve, solved for m
    v_valve = cb.VALVE_KG / cb.RHO_BRASS
    weight = (RHO_SEA * (volume + v_valve) - cb.VALVE_KG) / (1 - RHO_SEA / RHO["steel"])
    return round(weight, 1), round(volume, 1)


def checks(rows):
    """Print physics against the buoyancy the sources publish (information only)."""
    print("Faber, no valve, second row read as empty (kg; physics - sheet)")
    for name, v, m, wp, full_lb, empty_lb in (
        ("LP50", 7.8, 8.6, 182.02, -2.4, 1.2),        # Faber LP sheet
        ("FX-15", 2.0, 3.0, 237.32, -2.42, -1.21),    # Paragon listing
        ("FX-23", 3.0, 3.9, 237.32, -2.64, -0.66),    # Paragon listing
    ):
        e = empty_kg(v, m, "steel") + VALVE_NET
        f = e - gas_kg(v, wp)
        print(f"  {name:6} full {f:6.2f} vs {full_lb * LB:6.2f} ({f - full_lb * LB:+.2f})"
              f"  empty {e:6.2f} vs {empty_lb * LB:6.2f} ({e - empty_lb * LB:+.2f})")
    print("Worthington sheet, with valve (kg; physics - sheet), its own weight and volume")
    for name, v, m, full, empty in (("X7-120", 15.3, 18.0, -5.0, -0.9), ("X8-119", 14.8, 19.3, -4.9, -0.9),
                                    ("X8-130", 16.0, 20.3, -5.3, -0.9)):
        e = empty_kg(v, m, "steel")
        f = e - gas_kg(v, 237.32)
        print(f"  {name:6} full {f:6.2f} vs {full:6.2f} ({f - full:+.2f})  empty {e:6.2f} vs {empty:6.2f} ({e - empty:+.2f})")


def main():
    path = HERE.parent / "datasets" / "cylinders.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = {c["id"]: c for c in data["cylinders"]}
    checks(rows)

    print("\nDataset values, sea water with valve (kg)")
    print(f"{'id':14}{'L':>6}{'kg':>6}{'empty':>7}{'at50':>7}{'full':>7}   was L/kg, e/50/f")
    for cid, (m, v, source) in SOURCES.items():
        c = rows[cid]
        if m == "steel72":
            m, v = steel72()
        m = c["emptyWeightKg"] if m is None else m
        v = c["waterVolumeL"] if v is None else v
        e = empty_kg(v, m, c["material"])
        wp = c["workingPressureBar"]
        old = c["buoyancyKg"]
        print(f"{cid:14}{v:6.1f}{m:6.1f}{e:7.2f}{e - gas_kg(v, 50):7.2f}{e - gas_kg(v, wp):7.2f}"
              f"   {c['waterVolumeL']}/{c['emptyWeightKg']}, {old['empty']}/{old['at50bar']}/{old['full']}"
              f"  [{source}]")
        c["waterVolumeL"], c["emptyWeightKg"] = v, m
        c["buoyancyKg"] = {"full": round(e - gas_kg(v, wp), 1) + 0.0,
                           "at50bar": round(e - gas_kg(v, 50), 1) + 0.0,
                           "empty": round(e, 1) + 0.0}  # + 0.0 drops a -0.0

    if "--write" in sys.argv:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nwrote {path}")


if __name__ == "__main__":
    main()
