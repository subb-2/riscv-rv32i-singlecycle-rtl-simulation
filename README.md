# RISC-V RV32I CPU (Single-Cycle)

> - **Architecture:** Harvard Architecture (Instruction / Data Memory 분리)
> - **ISA:** RISC-V RV32I (공식 표준 문서 규격 준수)
> - **Language:** SystemVerilog

---

## 📌 프로젝트 개요

RISC-V는 RV32I ISA의 6가지 명령어 타입(R / I / S / B / U / J)을 모두 지원하는 **단일 사이클 CPU**입니다.  
Control Unit과 Datapath를 모듈로 분리하여 설계하였으며, Vivado 시뮬레이션을 통해 각 명령어 타입별 동작을 검증하였습니다.  
C 코드를 RISC-V 어셈블리로 컴파일한 `.mem` 파일을 ROM에 로드하여 실제 프로그램 실행까지 확인합니다.

---

## 🎯 지원 명령어

| 타입 | 명령어 |
|------|--------|
| **R-Type** | Register-Register | 레지스터 간 산술/논리 연산 수행 | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| **I-Type** | Register-Immediate / Load | 상숫값과의 연산 및 메모리 데이터 로드 | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| **Load / IL-Type** | LB, LH, LW, LBU, LHU |
| **S-Type** | Store | 메모리에 데이터 저장 | SB, SH, SW |
| **B-Type** | Branch | 조건에 따른 프로그램 카운터(PC) 분기 | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| **U-Type** | Upper Immediate | 상위 20비트 즉시값(Immediate) 처리 | LUI, AUIPC |
| **J-Type** | Jump | 무조건 분기 및 복귀 주소 저장(Link) | JAL, JALR |

---

## 🏗️ 시스템 구조

```
                    ┌──────────────────────────────────────────┐
                    │               RV32I_top                  │
  clk ─────────────►│                                          │
  rst ─────────────►│  ┌──────────────┐     ┌───────────────┐ │
                    │  │ instruction  │     │   data_mem    │ │
                    │  │    _mem      │     │    (RAM)      │ │
                    │  │   (ROM)      │     │ byte-addressable│
                    │  └──────┬───────┘     └───────▲───────┘ │
                    │   instr_data│               drdata│      │
                    │             ▼                     │      │
                    │  ┌──────────────────────────────────┐   │
                    │  │            RV32I_cpu             │   │
                    │  │  ┌──────────────┐ ┌──────────┐  │   │
                    │  │  │ control_unit │ │ datapath │  │   │
                    │  │  └──────────────┘ └──────────┘  │   │
                    │  └──────────────────────────────────┘   │
                    └──────────────────────────────────────────┘
```

---

## 📁 파일 구성

```
├── define.vh                   # opcode · ALU 연산 매크로 정의
├── RV32I_top.sv                # 최상위 모듈 — 세 모듈 연결 + LED 출력
├── RV32I_cpu.sv                # CPU 코어 (control_unit + datapath 인스턴스화)
├── rv32i_datapath.sv           # Datapath 전체 (레지스터파일, ALU, PC 등 포함)
├── instruction_mem.sv          # 명령어 ROM (32-bit word 단위, byte 주소 변환)
├── data_mem.sv                 # 데이터 RAM (byte-addressable, SB/SH/SW/LB/LH/LW 지원)
└── riscv_ru32i_rom_data.mem    # 명령어 초기화 데이터 (hex, $readmemh 용)
```

---

## 🔧 설계 세부 사항

### Control Unit

opcode / funct3 / funct7\[5\]를 조합하여 Datapath 제어 신호를 생성하는 조합 논리 블록입니다.

| 신호 | 역할 |
|------|------|
| `rf_we` | 레지스터 파일 쓰기 인에이블 |
| `alu_src` | ALU 두 번째 입력 선택 (rs2 / imm) |
| `alu_control[3:0]` | ALU 연산 종류 (`{funct7[5], funct3}`) |
| `rfwd_src[2:0]` | Write-back 소스 선택 (0~4) |
| `branch` | B-type 분기 인에이블 |
| `jal` | JAL / JALR 점프 인에이블 |
| `jalr` | JALR 여부 (PC = rs1 + imm) |
| `dwe` | 데이터 메모리 쓰기 인에이블 |
| `o_funct3` | 메모리 접근 크기 전달 (SB/SH/SW/LB/LH/LW 구분) |

**명령어 타입별 제어 신호 요약**

| Type | rf_we | alu_src | rfwd_src | branch | jal | jalr | dwe |
|------|-------|---------|----------|--------|-----|------|-----|
| R    | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| I    | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| Load | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| S    | 0 | 1 | — | 0 | 0 | 0 | 1 |
| B    | 0 | 0 | — | 1 | 0 | 0 | 0 |
| LUI  | 1 | 0 | 2 | 0 | 0 | 0 | 0 |
| AUIPC| 1 | 0 | 3 | 0 | 0 | 0 | 0 |
| JAL  | 1 | 0 | 4 | 0 | 1 | 0 | 0 |
| JALR | 1 | 0 | 4 | 0 | 1 | 1 | 0 |

### Datapath

내부 서브모듈 구성은 다음과 같습니다.

| 모듈 | 역할 |
|------|------|
| `register_file` | 32개 범용 레지스터 (x0 = 0 하드와이어) |
| `imm_extender` | 명령어 타입별 부호 확장 (I / S / B / U / J) |
| `alu` | 산술·논리 연산 + B-type 분기 비교 (`b_taken`) |
| `program_counter` | PC 업데이트 (PC+4 / PC+imm / rs1+imm) |
| `mux_2x1` | ALU 입력 소스 선택, PC 소스 선택 등 |
| `mux_5x1` | Write-back 소스 5-to-1 선택 |
| `pc_alu` | PC 전용 덧셈기 (PC+4, PC+imm 분리 계산) |
| `register` | 32-bit D 플립플롭 (PC 레지스터) |

**Write-back 소스 (`rfwd_src`)**

| 값 | 소스 | 사용 명령어 |
|----|------|------------|
| 0 | ALU 결과 | R-type, I-type |
| 1 | 데이터 메모리 | Load (LB/LH/LW 등) |
| 2 | Immediate | LUI |
| 3 | PC + Immediate | AUIPC |
| 4 | PC + 4 | JAL, JALR (리턴 주소) |

### PC 업데이트 로직

```
pc_next_sel = jal | (b_taken & branch)

if (pc_next_sel == 0):  PC ← PC + 4
else if (jalr == 1):    PC ← rs1 + imm   // JALR
else:                   PC ← PC + imm    // JAL / Branch taken
```

### Instruction Memory (ROM)

`instr_addr[31:2]`로 word 단위 접근합니다 (byte 주소 → `/4` 변환).  
초기화 방식은 두 가지를 지원합니다.

```systemverilog
// 방법 1 — .mem 파일로 읽기
$readmemh("riscv_ru32i_rom_data.mem", rom);

// 방법 2 — initial 블록 직접 설정
rom[0] = 32'hffc18213;  // ADDI x4, x3, -4
rom[1] = 32'hffe62293;  // SLTI x5, x12, -2
```

### Data Memory (RAM)

byte-addressable 구조로, `i_funct3`에 따라 접근 크기를 제어합니다.

| funct3 | Store | Load |
|--------|-------|------|
| 3'b000 | SB (1 byte) | LB (부호 확장) |
| 3'b001 | SH (2 bytes) | LH (부호 확장) |
| 3'b010 | SW (4 bytes) | LW |
| 3'b100 | — | LBU (0 확장) |
| 3'b101 | — | LHU (0 확장) |

---

## 🖥️ 개발 환경

| 항목 | 내용 |
|------|------|
| HDL | SystemVerilog |
| EDA Tool | Xilinx Vivado |
| 타겟 보드 | Xilinx FPGA (Zynq 계열) |
| 시뮬레이터 | Vivado Simulator (XSim) |
| 아키텍처 | Harvard Architecture (단일 사이클) |

---

## ✅ 시뮬레이션 검증 항목

- **R-Type** — ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND 전 연산 결과 확인
- **R-Type 엣지 케이스** — SLL shift amount 5-bit masking (rs2=33 → 실제 1bit shift), SLT signed vs SLTU unsigned 비교, SRL/SRA 부호 처리
- **I-Type** — ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI 결과 확인
- **S-Type & Load** — SB/SH/SW 저장 후 LB/LH/LW/LBU/LHU 로드, 부호 확장 검증
- **B-Type** — BEQ/BNE/BLT/BGE/BLTU/BGEU 분기 조건 및 PC 점프 주소 확인
- **U-Type & J-Type** — LUI/AUIPC 상위 20비트 처리, JAL/JALR 점프 및 리턴 주소 저장
- **C → ASM 실행** — `while` 루프 + 함수 호출 (`adder`) + 스택 프레임 생성/복구 + halt(`j .L4`) 전체 시나리오 동작 확인

---

## ⚙️ 타이밍 결과 (Vivado Implementation)

| 항목 | 값 |
|------|----|
| Worst Negative Slack (WNS) | 8.123 ns |
| Total Negative Slack (TNS) | 0 ns |
| Worst Hold Slack (WHS) | 0.263 ns |
| Failing Endpoints | 0 |

모든 사용자 지정 타이밍 제약 조건을 만족합니다.

---

## 🐛 Trouble Shooting

### 1. `pc_rs1_mux_out` X 상태 문제

**문제**: `program_counter` 내부 `pc_rs1_mux_out` 신호가 시뮬레이션에서 X(부정)로 유지되어 PC 값이 전파되지 않는 현상.

**원인**: `logic [31:0] pc_next_out, pc_rs1_mux_out;`으로 선언 시 비트 폭이 묵시적으로 축소되는 케이스 발생.

**해결**: 신호 비트 폭을 `[31:0]`으로 명시적 재선언하고, 연결 포트 방향을 재확인하여 해결.

### 2. ROM 명령어 포맷 오해석

**문제**: IL-Type(Load) 명령어에서 `imm[11:0]_rs1_funct3_rd_opcode` 필드 배치를 잘못 계산하여 생성한 ROM 값이 의도한 명령어와 불일치.

**원인**: 발표 자료 기준 LH/LW 명령어의 `funct3` 필드와 `rd` 필드 위치를 혼동.

**해결**: RISC-V 표준 스펙 문서를 재참조하여 각 필드 비트 범위를 재계산 후 ROM 값 재생성, 이후 시뮬레이션으로 `drdata` 출력 검증.

---

## 📄 알려진 제한 사항

- `data_mem` 크기가 33 바이트로 선언되어 있어 실제 운용 시 크기 조정 필요
- 파이프라인 미적용 (단일 사이클) — 클럭 주파수는 크리티컬 패스 지연에 의해 결정
- 인터럽트 및 CSR 레지스터 미구현
