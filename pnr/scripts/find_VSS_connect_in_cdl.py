import re

def find_gate_connected_to_vss(cdl_path):
    """
    Finds all transistor instances in a CDL file whose gate is connected to VSS.
    """

    # Regex for MOSFET lines: M<name> <D> <G> <S> <B> <model> ...
    mos_regex = re.compile(
        r'^\s*(M\S*)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)', re.IGNORECASE)

    matches = []

    with open(cdl_path, 'r') as f:
        for line_num, line in enumerate(f, start=1):
            m = mos_regex.match(line)
            if m:
                name, drain, gate, source, bulk, model = m.groups()
                if (gate.upper() == 'VSSCORE' or gate.upper() == 'inh_VSS'):
                    matches.append({
                        'line': line_num,
                        'instance': name,
                        'drain': drain,
                        'gate': gate,
                        'source': source,
                        'bulk': bulk,
                        'model': model,
                        'raw_line': line.strip()
                    })

    if matches:
        print(f"\nFound {len(matches)} transistors with gate tied to VSS:\n")
        for m in matches:
            print(f"Line {m['line']}: {m['instance']} → gate={m['gate']} | line: {m['raw_line']}")
    else:
        print("No transistors found with gate connected to VSS.")


# Example usage:
find_gate_connected_to_vss("/eda/cad_run/sg13g2/cds/cds_mlabuser068076/PVS/lvs/mlabuser068076/Ibex/ibex_simple_system/ibex_simple_system.cdl")
# find_gate_connected_to_vss("/eda/cad_run/sg13g2/cds/cds_mlabuser068076/PVS/lvs/mlabuser068076/ixc013g2_iocell/padring_lvs/padring_lvs.cdl")
# find_gate_connected_to_vss("../cdl_explanation.txt")