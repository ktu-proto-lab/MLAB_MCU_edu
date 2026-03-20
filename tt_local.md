# Hardening Tiny Tapeout Projects Locally on Ubuntu (172.31.86.242) server

## Unset enviroment variables (just in case)
```bash
unset PDK_ROOT && unset PDK
```
## Installing python 3.14.3 for local user only

```bash
cd /tmp
wget https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tgz
tar -xf Python-3.14.3.tgz
cd Python-3.14.3/
./configure --prefix=$HOME/opt/python314 --enable-optimizations
make -j4
make install
cd ~
echo 'export PATH="$HOME/opt/python314/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Creating Python virtual enviroment
(dont know if its really needed if python was installed locally, but whatever)

```bash
mkdir ~/ttsetup
python3 -m venv ~/ttsetup/venv
source ~/ttsetup/venv/bin/activate
```

---

## Clone tt example project factory-test (or your project)

```bash
git clone https://github.com/TinyTapeout/ttsky25b-factory-test ~/factory-test
cd ~/factory-test
```
---

## Download `tt-support-tools`
```bash
git clone https://github.com/TinyTapeout/tt-support-tools tt
pip install -r ~/factory-test/tt/requirements.txt
```
---

## Installing librelane

```bash
export LIBRELANE_TAG=3.0.0rc1
pip install librelane==$LIBRELANE_TAG
```

## Setting PDK

```bash
export PDK_ROOT=~/ttsetup/pdk
```
SKY130:
```bash
export PDK=sky130A
```
IHP:
```bash
export PDK=ihp-sg13g2
```
---

Remove `--ihp` for sky130 pdk
## Hardening

```bash
cd ~/factory-test
./tt/tt_tool.py --create-user-config --ihp
```

Requires docker (ask Manfredas)
```bash
./tt/tt_tool.py --harden --ihp
```

---

## Rehardening

```bash
source ~/ttsetup/venv/bin/activate
export PDK_ROOT=~/ttsetup/pdk
export PDK=ihp-sg13g2
cd ~/factory-test
./tt/tt_tool.py --create-user-config --ihp
./tt/tt_tool.py --harden --ihp
```
