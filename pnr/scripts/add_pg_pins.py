import re

# Define module types
targets_with_comma = {'ixc013_b16m', 'ixc013_i16x'}
all_targets = {'vddcore', 'vddpad', 'gndcore', 'gndpad',
               'filler1u', 'filler2u', 'filler4u', 'filler10u'} | targets_with_comma

# Define insertions for instances
insertion_comma = [
    ".VDDCORE(VDD),",
    ".VSSCORE(VSS),",
    ".VDDPAD(VDDPAD),",
    ".VSSPAD(VSSPAD),"
]

insertion_nocomma = [
    ".VDDCORE(VDD),",
    ".VSSCORE(VSS),",
    ".VDDPAD(VDDPAD),",
    ".VSSPAD(VSSPAD)"
]

# Read the original file
with open("../pnrOutData/pnr_netlist_LVS.v", "r") as f:
    lines = f.readlines()

new_lines = []
module_port_added = False
in_port_section = False

pattern = re.compile(rf"^\s*({'|'.join(re.escape(name) for name in all_targets)})\s+.*\(\s*$")

for i, line in enumerate(lines):
    stripped = line.strip()

    # Modify module port list
    if stripped.startswith("module ibex_simple_system") and not module_port_added:
        # Inject new ports after the opening parenthesis line
        open_paren_index = line.find('(')
        if open_paren_index != -1:
            # Insert new ports
            new_lines.append(line[:open_paren_index+1] + "\n")
            new_lines.append("   VDD, VSS, VDDPAD, VSSPAD,\n")
            new_lines.append(line[open_paren_index+1:])
            module_port_added = True
            in_port_section = True
            continue

    # Insert inout declarations after module port list
    if in_port_section and stripped.startswith("input "):
        new_lines.append("   inout VDD, VSS, VDDPAD, VSSPAD;\n")
        in_port_section = False

    # Regular module instance match
    match = pattern.match(line)
    if match:
        module_name = match.group(1)
        indent = re.match(r'^(\s*)', line).group(1) + "    "
        insertion = insertion_comma if module_name in targets_with_comma else insertion_nocomma
        new_lines.append(line)
        for l in insertion:
            new_lines.append(indent + l + "\n")
        continue

    new_lines.append(line)

# Save to modified file
with open("../pnrOutData/pnr_netlist_LVS_withPG.v", "w") as f:
    f.writelines(new_lines)