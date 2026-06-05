<!---
docs/info.md — Variable Stiffness Gripper ASIC (VSG-ASIC)
Tiny Tapeout submission — SkyWater SKY130 130 nm
-->

## How it works

This project implements a digital control system for a two-axis robotic arm with a variable-stiffness gripper, written entirely in Verilog HDL and targeting the SkyWater SKY130 130 nm process via Tiny Tapeout.

The system drives three stepper motors (X axis, Y axis, and gripper) using **STEP/DIR** signals compatible with industry-standard drivers such as the **DRV8825** or **A4988**. All mechanical switch inputs are filtered through an internal **debouncer** (20 ms settling window) to eliminate contact bounce before reaching the control logic.

### Functional blocks

- **Debouncer (×5):** Each mechanical input — two buttons per axis plus the gripper limit switch — passes through a 2-stage synchronizer followed by a stable-time counter (1 000 000 cycles at 50 MHz = 20 ms). Only clean, settled signals reach the motor controllers.

- **NEMA Controller (×2):** One instance per axis (X and Y). Generates a STEP pulse train at ~4 kHz and a DIR signal based on which directional button is pressed. If both buttons are pressed simultaneously the motor stops — a hardware conflict guard. When no button is pressed the STEP output stays low, locking the motor in place.

- **Gripper Stepper Controller (FSM):** A three-state machine — `IDLE`, `CLOSING`, `HOLDING` — manages the gripper motor:
  - **IDLE:** `dip_switch = 0`. Motor stopped, DIR set to open direction.
  - **CLOSING:** `dip_switch = 1`. STEP pulses drive the gripper closed.
  - **HOLDING:** `rigidity_switch = 1` detected. STEP output freezes, holding the last position until `dip_switch` is released.

- **PWM Timing:** STEP pulse frequency is determined by `SPEED_DIV = 6 250` cycles per half-period, giving a step rate of `50 MHz / (2 × 6 250) = 4 000 Hz` (4 kHz).

## How to test

1. Apply clock (`clk`) at 50 MHz and assert reset low (`rst_n = 0`) for at least 10 clock cycles. Then release reset (`rst_n = 1`). All outputs will be `0x00`.

2. Drive `ui_in` with the desired command. All inputs are debounced internally — hold each input steady for at least **20 ms** (1 000 000 cycles at 50 MHz) before expecting the output to respond.

| `ui_in` bit | Signal | Action |
|---|---|---|
| `[0]` | `btn_x_cw` | Move X axis clockwise |
| `[1]` | `btn_x_ccw` | Move X axis counter-clockwise |
| `[2]` | `btn_y_cw` | Move Y axis clockwise |
| `[3]` | `btn_y_ccw` | Move Y axis counter-clockwise |
| `[4]` | `dip_grip` | Enable gripper close sequence |
| `[5]` | `sw_limit` | Rigidity/contact limit switch (active high) |
| `[6–7]` | — | Unused, tie to 0 |

3. Observe `uo_out`:

| `uo_out` bit | Signal | Description |
|---|---|---|
| `[0]` | `step_x` | X-axis STEP pulse train (~4 kHz when moving) |
| `[1]` | `dir_x` | X-axis direction (1 = CW, 0 = CCW) |
| `[2]` | `step_y` | Y-axis STEP pulse train |
| `[3]` | `dir_y` | Y-axis direction (1 = CW, 0 = CCW) |
| `[4]` | `step_grip` | Gripper STEP pulse train |
| `[5]` | `dir_grip` | Gripper direction (1 = closing, 0 = opening) |
| `[6–7]` | — | Tied to 0 |

4. **Gripper sequence test:**
   - Assert `ui_in[4]` (dip_grip). After debounce, `uo_out[4]` (step_grip) should begin toggling and `uo_out[5]` (dir_grip) should go high.
   - Assert `ui_in[5]` (sw_limit) while `ui_in[4]` remains high. After debounce, `step_grip` must freeze (HOLD state).
   - Release `ui_in[4]`. The gripper returns to IDLE and `step_grip` stops.

5. **Conflict test:** Assert both `ui_in[0]` and `ui_in[1]` simultaneously. `uo_out[0]` (step_x) must remain `0`.

> **Tip:** Use a logic analyzer on `uo_out[0]` and `uo_out[2]` to verify the STEP pulse frequency (~4 kHz = 250 µs period). Use `uo_out[1]` and `uo_out[3]` to confirm direction changes correctly.

## External hardware

| Component | Qty | Connection | Notes |
|---|---|---|---|
| Stepper motor driver (DRV8825 or A4988) | 3 | `uo_out[0–1]` (X), `uo_out[2–3]` (Y), `uo_out[4–5]` (gripper) | Connect STEP and DIR pins. Set microstepping via MS pins on driver board |
| NEMA 17 stepper motor | 2 | Via DRV8825 driver | X and Y axis |
| Stepper motor (gripper, e.g. NEMA 11 or NEMA 17) | 1 | Via DRV8825 driver | Gripper open/close |
| Mechanical push button (X axis) | 2 | `ui_in[0]`, `ui_in[1]` | Wire active-high with 10 kΩ pull-down to GND |
| Mechanical push button (Y axis) | 2 | `ui_in[2]`, `ui_in[3]` | Wire active-high with 10 kΩ pull-down to GND |
| DIP switch | 1 | `ui_in[4]` | Gripper enable, active high |
| Limit / contact switch | 1 | `ui_in[5]` | Rigidity detection, active high, 10 kΩ pull-down |
| External power supply (12–24 V) | 1 | DRV8825 VMOT | Do not power motors from the ASIC supply |
| Decoupling capacitor (100 µF) | 3 | Across each DRV8825 VMOT–GND | Protects driver from back-EMF spikes |