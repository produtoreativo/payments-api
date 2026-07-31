#!/usr/bin/env python3
"""
Cross-player conformance comparison for prodops_emit_event.
Reads results/claude-results.csv, codex-results.csv, copilot-results.csv
and produces a conformance report.
"""

import csv
import json
import os
import sys
from pathlib import Path

RESULTS_DIR = Path(__file__).parent / "results"
PLAYERS = ["claude", "codex", "copilot"]

# Checks that are allowed to be skipped (manual-only, not automated)
MANUAL_CHECKS = set()

# Checks where difference is ALLOWED between players
ALLOWED_TO_DIFFER = {
    "skill-discovery",   # path differs per player
}


def load_results(player: str) -> dict[str, dict]:
    """Load CSV results for a player. Returns {check_name: {result, actual, expected}}."""
    path = RESULTS_DIR / f"{player}-results.csv"
    if not path.exists():
        return {}
    results = {}
    with open(path) as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for row in reader:
            if len(row) < 3:
                continue
            result, check, actual = row[0], row[1], row[2]
            expected = row[3] if len(row) > 3 else ""
            results[check] = {"result": result, "actual": actual, "expected": expected}
    return results


def main():
    all_results: dict[str, dict[str, dict]] = {}
    available_players = []

    for player in PLAYERS:
        r = load_results(player)
        if r:
            all_results[player] = r
            available_players.append(player)
        else:
            print(f"WARNING: No results for {player} (run run-{player}.sh first)")

    if not available_players:
        print("ERROR: No results found. Run player scripts first.")
        sys.exit(1)

    # Collect all check names
    all_checks = set()
    for r in all_results.values():
        all_checks.update(r.keys())

    print()
    print("=" * 60)
    print("Cross-Player Conformance Report — prodops_emit_event")
    print("=" * 60)
    print(f"Players with results: {', '.join(available_players)}")
    print()

    semantic_failures = 0
    conformance_failures = 0
    total_checks = 0

    report_rows = []

    for check in sorted(all_checks):
        total_checks += 1
        player_results = {}
        for player in available_players:
            r = all_results.get(player, {}).get(check)
            if r:
                player_results[player] = r
            else:
                player_results[player] = {"result": "MISSING", "actual": "—", "expected": ""}

        # Individual failures
        failures = [p for p, r in player_results.items() if r["result"] != "PASS"]
        if failures:
            semantic_failures += 1

        # Cross-player conformance (only for semantic checks, not path checks)
        if check not in ALLOWED_TO_DIFFER and len(available_players) > 1:
            actuals = {r["actual"] for r in player_results.values() if r["result"] == "PASS"}
            if len(actuals) > 1:
                conformance_failures += 1

        # Build row
        row = {"check": check}
        all_pass = True
        conformant = True
        player_cols = {}
        for player in available_players:
            r = player_results[player]
            player_cols[player] = r["result"]
            if r["result"] != "PASS":
                all_pass = False

        if check not in ALLOWED_TO_DIFFER and len(available_players) > 1:
            actuals = {r["actual"] for r in player_results.values() if r["result"] == "PASS"}
            conformant = len(actuals) <= 1

        row["players"] = player_cols
        row["all_pass"] = all_pass
        row["conformant"] = conformant if check not in ALLOWED_TO_DIFFER else True
        report_rows.append(row)

    # Print matrix
    header = f"{'Check':<45}" + "".join(f"{p:>12}" for p in available_players) + "  Conformant"
    print(header)
    print("-" * len(header))

    for row in report_rows:
        check_col = row["check"][:44]
        player_cols = "".join(f"{row['players'].get(p, 'MISSING'):>12}" for p in available_players)
        conf_col = "✓" if row["conformant"] else "✗ DIVERGE"
        status_icon = "✓" if row["all_pass"] else "✗"
        print(f"{check_col:<45}{player_cols}  {conf_col}")

    print()
    print(f"Total checks:          {total_checks}")
    print(f"Semantic failures:     {semantic_failures}")
    print(f"Conformance failures:  {conformance_failures}")
    print()

    if semantic_failures == 0 and conformance_failures == 0:
        print("RESULT: ALL CHECKS PASS — players are conformant")
        gate_met = True
    elif len(available_players) < len(PLAYERS):
        print(f"RESULT: PARTIAL — {len(PLAYERS) - len(available_players)} player(s) pending")
        gate_met = False
    else:
        print(f"RESULT: FAILED — {semantic_failures} semantic + {conformance_failures} conformance failures")
        gate_met = False

    # Write JSON summary
    summary = {
        "players": available_players,
        "total_checks": total_checks,
        "semantic_failures": semantic_failures,
        "conformance_failures": conformance_failures,
        "gate_met": gate_met,
        "checks": report_rows,
    }
    out = RESULTS_DIR / "conformance-summary.json"
    with open(out, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"Summary: {out}")

    sys.exit(0 if gate_met else 1)


if __name__ == "__main__":
    main()
