#!/usr/bin/env python3
"""Cylinder buoyancy from weight and volume (Archimedes), for the Faber rows and AL40.

    empty   = rho_sea * (V_water + m / rho_metal + V_valve) - (m + m_valve)
    at50bar = empty - gas_mass(50 bar)
    full    = empty - gas_mass(working pressure)

All in sea water (1.025 kg/L) with a standard valve fitted, the dataset's basis.
The weight and water volume are the manufacturer's (measured specs); only the
buoyancy is computed.

Two checks run first and print their residuals:
- Luxfer: physics must land within 0.2 kg of Luxfer's full rows (with valve)
  and its consistent 500 psi rows. AL40 and AL50's 500 psi rows are skipped:
  AL40's full-to-500 psi gap needs 7.24 L of gas against the rated 5.7 L.
- Faber: the same physics without the valve must reproduce Faber's full row and
  the row its sheet labels "500 psi", read as empty. That is the basis the
  Faber figures fit (no valve, second row empty); the dataset adds the valve.

Gas mass is air at 15 C with real-gas Z, the same model as Dive Kit core's
`calculateGasMass` (src/buoyancy/gas-mass.ts): gauge + 1.01325 bar absolute,
Z from the NIST 15 C tables in src/lib/diving/real-gas.ts (Amagat 21/79),
argon-free air at 1.2214 g/L (1 atm, 15 C).

Usage: python3 scripts/cylinder-buoyancy.py [--write]
  prints every value; --write puts the results into datasets/cylinders.json.
"""

import json
import sys
from pathlib import Path

LB = 0.45359237
PSI = 0.0689475729  # bar
RHO_SEA = 1.025  # kg/L
RHO = {"steel": 7.85, "aluminum": 2.70}  # chrome-moly steel, 6061 aluminium
VALVE_KG, RHO_BRASS = 0.7, 8.5  # standard brass valve
SURFACE_BAR = 1.01325

# Core's iso15C compressibility tables (real-gas.ts), per component.
Z_P = [1, 50, 100, 150, 200, 232, 250, 300]
Z_N2 = [0.9997, 0.9919, 0.9973, 1.0164, 1.0478, 1.0732, 1.0891, 1.1377]
Z_O2 = [0.9992, 0.9658, 0.9411, 0.929, 0.9311, 0.9396, 0.9466, 0.9732]
AIR_STP_G_L = 0.21 * 1.429 + 0.79 * 1.251  # 0 C, 1 atm (core's argon-free air)
TEMP_FACTOR = 273.15 / 288.15  # 0 C -> 15 C


def interp(table, p):
    """Linear interpolation on the Z grid; extrapolates past 300 bar like core."""
    if p <= Z_P[0]:
        return table[0]
    for i in range(1, len(Z_P)):
        if p <= Z_P[i]:
            t = (p - Z_P[i - 1]) / (Z_P[i] - Z_P[i - 1])
            return table[i - 1] + t * (table[i] - table[i - 1])
    return table[-1] + (table[-1] - table[-2]) / (Z_P[-1] - Z_P[-2]) * (p - Z_P[-1])


def gas_kg(volume_l, gauge_bar):
    """Mass of air in the cylinder at a gauge pressure (core's calculateGasMass)."""
    p_abs = gauge_bar + SURFACE_BAR
    z = 0.21 * interp(Z_O2, p_abs) + 0.79 * interp(Z_N2, p_abs)
    return volume_l * p_abs / z / SURFACE_BAR * AIR_STP_G_L * TEMP_FACTOR / 1000


def empty_kg(volume_l, weight_kg, material):
    """Empty buoyancy in sea water, valve fitted."""
    displaced = volume_l + weight_kg / RHO[material] + VALVE_KG / RHO_BRASS
    return RHO_SEA * displaced - weight_kg - VALVE_KG


# id: (weight kg, full lb, "500 psi" lb) from the Faber FXG HP and Faber LP sheets.
# The weight is the sheet's kg figure: its lb figures disagree with it (FX117
# 37.6 lb is 17.05 kg against 17.7 kg), and only the kg weights reproduce the
# sheet's own buoyancy rows on every cylinder.
FABER = {
    "hp80": (13.0, -8.05, -1.74),
    "hp100": (15.6, -8.41, -0.59),
    "hp117": (17.7, -9.12, 0.35),
    "hp133": (19.4, -9.08, 1.45),
    "lp85": (14.2, -3.80, 2.32),
    "lp108": (18.6, -5.0, 3.0),
}
# 500 psi rows that contradict their own full row (gas gap vs rated volume).
LUXFER_INCONSISTENT_500 = {"al40", "al50"}
# id: (full kg, 500 psi kg) from the Luxfer rev. 19A sheet; weight is the dataset's.
LUXFER = {
    "al13": (-0.80, -0.40),
    "al19": (-0.60, -0.05),
    "al30": (-0.68, 0.0),
    "al40": (-0.32, 1.13),
    "al50": (-1.13, 0.36),
    "al63": (-1.10, 0.77),
    "al80": (-0.80, 1.54),
    "al100": (-2.10, 0.86),
}


def main():
    path = Path(__file__).resolve().parent.parent / "datasets" / "cylinders.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = {c["id"]: c for c in data["cylinders"]}
    valve_net = VALVE_KG - RHO_SEA * VALVE_KG / RHO_BRASS
    worst = 0.0

    print("Luxfer check, with valve (kg; physics - sheet)")
    print(f"{'id':7}{'full':>7}{'sheet':>7}{'res':>7}{'500psi':>8}{'sheet':>7}{'res':>7}{'empty':>7}")
    for cid, (s_full, s_500) in LUXFER.items():
        c = rows[cid]
        v, wp, m = c["waterVolumeL"], c["workingPressureBar"], c["emptyWeightKg"]
        e = empty_kg(v, m, c["material"])
        full, at500 = e - gas_kg(v, wp), e - gas_kg(v, 500 * PSI)
        skip = cid in LUXFER_INCONSISTENT_500
        worst = max(worst, abs(full - s_full), 0 if skip else abs(at500 - s_500))
        print(f"{cid:7}{full:7.2f}{s_full:7.2f}{full - s_full:+7.2f}"
              f"{at500:8.2f}{s_500:7.2f}{at500 - s_500:+7.2f}{e:7.2f}"
              + ("  (500 psi row inconsistent, skipped)" if skip else ""))
    print(f"largest Luxfer residual: {worst:.2f} kg")
    if worst > 0.2:
        sys.exit("Method misses Luxfer by more than 0.2 kg; not writing.")

    print("\nFaber check, without valve (kg; physics - sheet; sheet's 500 psi row read as empty)")
    print(f"{'id':7}{'full':>7}{'sheet':>7}{'res':>7}{'empty':>8}{'sheet':>7}{'res':>7}")
    worst = 0.0
    for cid, (m, full_lb, row2_lb) in FABER.items():
        c = rows[cid]
        v, wp = c["waterVolumeL"], c["workingPressureBar"]
        e = empty_kg(v, m, c["material"]) + valve_net
        full = e - gas_kg(v, wp)
        worst = max(worst, abs(full - full_lb * LB), abs(e - row2_lb * LB))
        print(f"{cid:7}{full:7.2f}{full_lb * LB:7.2f}{full - full_lb * LB:+7.2f}"
              f"{e:8.2f}{row2_lb * LB:7.2f}{e - row2_lb * LB:+7.2f}")
    print(f"largest Faber residual: {worst:.2f} kg")
    if worst > 0.2:
        sys.exit("Faber sheet does not fit the no-valve basis; not writing.")

    print("\nDataset values, with valve (kg)")
    print(f"{'id':7}{'weight':>7}{'empty':>7}{'at50':>7}{'full':>7}{'was e/50/f':>18}")
    for cid in [*FABER, "al40"]:
        c = rows[cid]
        v, wp = c["waterVolumeL"], c["workingPressureBar"]
        m = FABER[cid][0] if cid in FABER else c["emptyWeightKg"]
        e = empty_kg(v, m, c["material"])
        new = {"full": round(e - gas_kg(v, wp), 1),
               "at50bar": round(e - gas_kg(v, 50), 1),
               "empty": round(e, 1)}
        if cid == "al40":
            new["full"] = round(LUXFER[cid][0], 1)  # Luxfer's full row; physics agrees within 0.12
        old = c["buoyancyKg"]
        print(f"{cid:7}{m:7.2f}{e:7.2f}{e - gas_kg(v, 50):7.2f}{e - gas_kg(v, wp):7.2f}"
              f"{old['empty']:8.1f}/{old['at50bar']:.1f}/{old['full']:.1f}"
              f"  -> {new['empty']}/{new['at50bar']}/{new['full']}")
        c["emptyWeightKg"], c["buoyancyKg"] = m, new

    if "--write" in sys.argv:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nwrote {path}")


if __name__ == "__main__":
    main()
