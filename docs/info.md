<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

An SPI controller writes to registers that control 16 output pins and each can be set to 3kHz PWM signal.

It uses SPI mode 0 with write only. The registers update when nCS rises. Reads, invalid addresses, and packets that are not 16 bits are ignored.

| Bits | Field |
|---|---|
| 15 | R/W bit (1 = write; reads are ignored) |
| 14:8 | Register address |
| 7:0 | Data |

**Register map:**

| Address | Description | Reset value |
|---|---|---|
| 0x00 | Enable output on `uo_out[7:0]` | 0x00 |
| 0x01 | Enable output on `uio_out[7:0]` | 0x00 |
| 0x02 | Enable PWM mode on `uo_out[7:0]` | 0x00 |
| 0x03 | Enable PWM mode on `uio_out[7:0]` | 0x00 |
| 0x04 | PWM duty cycle (0-255) | 0x00 |

**PWM:** For each pin, if its output enable bit is 0 the output is 0. If the enable bit is 1 and its PWM mode bit is 1, the output follows the PWM signal.

**Pins:**

| Pin | Function |
|---|---|
| `ui[0]` | SCLK |
| `ui[1]` | COPI |
| `ui[2]` | nCS |
| `uo[7:0]`, `uio[7:0]` | Outputs 0 to 15 |

## How to test

Using the tests written with cocotb in the test folder, run

    make -B
