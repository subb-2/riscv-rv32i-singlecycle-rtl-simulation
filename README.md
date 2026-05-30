# RISC-V RV32I CPU (Single-Cycle)

> - **Architecture:** Harvard Architecture (Instruction / Data Memory 분리)
> - **ISA:** RISC-V RV32I (공식 표준 문서 규격 준수)
> - **Language:** SystemVerilog

---

## 📌 프로젝트 개요

RV32I ISA의 6가지 명령어 타입(R / I / S / B / U / J)을 모두 지원하는 **단일 사이클 CPU**입니다.  
Control Unit과 Datapath를 모듈로 분리하여 설계하였으며, Vivado 시뮬레이션을 통해 각 명령어 타입별 동작을 검증하였습니다.  
C 코드를 RISC-V 어셈블리로 컴파일한 `.mem` 파일을 ROM에 로드하여 실제 프로그램 실행까지 확인하였습니다.

---

## 🏗️ 시스템 구조

명령어 메모리(ROM)와 데이터 메모리(RAM)를 분리한 Harvard Architecture로 구현하였습니다.  
CPU 내부는 명령어 흐름을 제어하는 **Control Unit**과 실제 연산 및 데이터 이동을 담당하는 **Datapath**로 구성됩니다.
<p align="center">
<img width="800" alt="System Block Diagram" src="https://github.com/user-attachments/assets/2d2afe77-4028-4400-bd35-bb8f8b120732" />
<img width="1000" alt="CPU Architecture" src="https://github.com/user-attachments/assets/f3c16ab6-3756-4ac7-9cc7-0966c163fda0" />
</p>
---

## 🎯 지원 명령어

| Format | Supported Instructions |
|--------|----------------------|
| R-Type | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-Type | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Load   | LB, LH, LW, LBU, LHU |
| S-Type | SB, SH, SW |
| B-Type | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| U-Type | LUI, AUIPC |
| J-Type | JAL, JALR |

---

## 🔧 설계 세부 사항

### Control Unit

Opcode를 해석하여 제어 신호를 생성하고 Datapath 내 각 모듈의 동작을 지시합니다.

| 신호 | 역할 |
|------|------|
| `rf_we` | 레지스터 파일 쓰기 enable |
| `alu_src` | ALU 두 번째 입력 선택 (rs2 / imm) |
| `alu_control[3:0]` | ALU 연산 종류 |
| `rfwd_src[2:0]` | Write-back 소스 선택 (ALU / MEM / IMM / PC+IMM / PC+4) |
| `branch` / `jal` / `jalr` | 분기 및 점프 제어 |
| `dwe` | 데이터 메모리 쓰기 enable |
| `o_funct3` | 메모리 접근 크기 전달 (SB/SH/SW/LB/LH/LW 구분) |

### Datapath 주요 서브모듈

| 모듈 | 역할 |
|------|------|
| `register_file` | 32개 범용 레지스터 (x0 = 0 Hardwired) |
| `imm_extender` | 명령어 타입별 부호 확장 (I / S / B / U / J) |
| `alu` | 산술·논리 연산 + B-type 분기 비교 (`b_taken`) |
| `program_counter` | PC 업데이트 (PC+4 / PC+imm / rs1+imm) |
| `mux_5x1` | Write-back 소스 5-to-1 선택 |

---

## ✅ 시뮬레이션 검증

- **R-Type** — 전 연산 결과 및 엣지 케이스 (shift masking, signed/unsigned 비교, SRL/SRA 부호 처리)
- **I-Type** — 즉치 연산 전 항목
- **S-Type & Load** — SB/SH/SW 저장 후 LB/LH/LW/LBU/LHU 부호 확장 검증
- **B-Type** — 분기 조건 및 PC 점프 주소 확인
- **U-Type & J-Type** — LUI/AUIPC 상위 20비트 처리, JAL/JALR 점프 및 리턴 주소 저장
- **C → ASM 통합 실행** — 반복문, 서브루틴, 스택 제어를 포함한 복합 시나리오 검증

---

## 🐛 Trouble Shooting

### 1. `pc_rs1_mux_out` X 상태 문제
**문제**: 시뮬레이션에서 PC 값이 X 상태로 유지되어 전달되지 않는 현상.  
**원인**: 버스 폭 `[31:0]` 선언 누락으로 신호가 1비트(Implicit Net)로 처리되어 상위 31비트가 Floating 상태.  
**해결**: 신호 비트 폭을 명시적으로 재선언하고 포트 방향 재확인.

### 2. ROM 명령어 포맷 오해석
**문제**: IL-Type 명령어 필드 배치 오계산으로 ROM 값이 의도한 명령어와 불일치.  
**원인**: `funct3`와 `rd` 필드 위치 혼동.  
**해결**: RISC-V 표준 스펙 문서 재참조하여 필드 비트 범위 재계산 후 ROM 값 재생성.

---

## 📄 알려진 제한 사항 및 향후 개선 방향

- 단일 사이클 구조상 클럭 주파수가 크리티컬 패스(가장 느린 명령어)에 의해 결정됨
- 파이프라인 적용 시 동일 시간 내 처리량 향상 가능
- `data_mem` 크기가 33바이트로 선언되어 있어 실운용 시 크기 조정 필요
