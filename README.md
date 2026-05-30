# SystemVerilog Design — RISC-V RV32I Single-Cycle CPU

📅 프로젝트 정보

* 진행 기간: 2026.03 (3학년 2학기)
* 설계 대상: RV32I Single-Cycle CPU (R / I / S / B / U / J 전 타입 지원)
* 기술 스택: `SystemVerilog`, `Vivado XSim`, `Harvard Architecture (ROM/RAM 분리)`

---

## 📝 프로젝트 개요

RISC-V 공식 표준 문서(RV32I)를 기반으로 6가지 명령어 타입을 모두 지원하는 **단일 사이클 CPU**를 설계한 프로젝트입니다.  
단순 명령어 동작 구현을 넘어, **표준 스펙을 직접 해석하여 Control Signal 테이블을 도출**하고 각 명령어 타입별 엣지 케이스(Shift Masking, Signed/Unsigned 비교, 부호 확장 등)를 정량적으로 검증하는 데 집중했습니다.  
최종적으로 C 코드를 RISC-V 어셈블리로 컴파일한 `.mem` 파일을 ROM에 로드하여, 반복문·서브루틴·스택 제어를 포함한 실제 프로그램 실행까지 확인하였습니다.

---

## 🔑 주요 구현 내용

### 1. 계층형 모듈 구조 (Control Unit / Datapath 분리)

* **Architecture**: Harvard Architecture — 명령어 메모리(ROM)와 데이터 메모리(RAM)를 물리적으로 분리하여 단일 사이클에서 명령어 Fetch와 데이터 접근을 동시에 수행.
* **Control Unit**: Opcode를 해석하여 Datapath 내 각 모듈로 제어 신호를 생성. 신호는 아래 표 참조.
* **Datapath**: ALU, Register File, Immediate Extender, Program Counter, Write-Back MUX를 서브모듈로 분리 구현.

| 제어 신호 | 역할 |
|-----------|------|
| `rf_we` | 레지스터 파일 Write Enable |
| `alu_src` | ALU 두 번째 입력 선택 (rs2 / imm) |
| `alu_control[3:0]` | ALU 연산 종류 지정 |
| `rfwd_src[2:0]` | Write-back 소스 5-to-1 선택 (ALU / MEM / IMM / PC+IMM / PC+4) |
| `branch` / `jal` / `jalr` | 분기 및 점프 제어 |
| `dwe` | 데이터 메모리 Write Enable |
| `o_funct3` | 메모리 접근 크기 전달 (SB/SH/SW/LB/LH/LW 구분) |

### 2. RV32I 전 명령어 타입 구현

RV32I 공식 스펙을 기준으로 6가지 타입(R / I / S / B / U / J) 전체를 구현하였으며,
각 타입별 엣지 케이스(Shift Masking, Signed/Unsigned 경계값, 부호 확장)를
시뮬레이션으로 검증하였습니다.

### 3. C → ASM 통합 실행 검증

* **Scenario**: `while`문 반복 누적 연산, 함수 호출(`jal`), 스택 프레임 생성·복원(`sw`/`lw`/`addi sp`)을 포함한 복합 시나리오.
* **Method**: C 코드를 RISC-V 어셈블리로 컴파일 후 `.mem` 파일로 변환 → ROM에 로드 → Vivado 시뮬레이션으로 레지스터 및 메모리 값 전수 확인.
* **Result**: `0xfedcba98 + 0x12345678 = 0x11111110` 연산 포함 전 시나리오 PASS.

---

## 🚀 문제 해결 (Troubleshooting)

### 1. `pc_rs1_mux_out` X 상태 문제

* **문제**: 시뮬레이션에서 PC 값이 X 상태로 유지되어 Datapath 전체에 전파되는 현상.
* **원인**: 신호 선언 시 버스 폭 `[31:0]` 누락 → 1비트(Implicit Net)로 처리되어 상위 31비트가 Floating 상태.
* **해결**: 신호 비트 폭을 명시적으로 재선언하고 포트 방향 재확인.

### 2. ROM 명령어 포맷 오해석

* **문제**: I-Type 명령어 필드 배치 오계산으로 ROM에 저장된 값이 의도한 명령어와 불일치.
* **원인**: `funct3`와 `rd` 필드의 비트 범위 혼동.
* **해결**: RISC-V 공식 스펙 문서 재참조 → 필드 비트 범위 재계산 후 ROM 값 재생성.

---

## ✅ 검증 결과

| 명령어 타입 | 검증 항목 | 결과 |
|-------------|-----------|------|
| R-Type | 전 연산 + Shift Masking, Signed/Unsigned 경계값 | ✅ PASS |
| I-Type | 즉치 연산 전 항목 | ✅ PASS |
| S-Type & Load | SB/SH/SW 저장 후 LB/LH/LW/LBU/LHU 부호 확장 | ✅ PASS |
| B-Type | 분기 조건 및 PC 점프 주소 | ✅ PASS |
| U-Type & J-Type | LUI/AUIPC 상위 20비트, JAL/JALR 리턴 주소 저장 | ✅ PASS |
| C → ASM 통합 | 반복문, 서브루틴, 스택 제어 복합 시나리오 | ✅ PASS |

---

## 📚 배운 점

* **표준 문서 기반 설계**: ISA 스펙을 직접 읽고 필드 배치와 제어 신호를 도출하는 과정에서, 문서 오해석 하나가 명령어 전체를 망가뜨릴 수 있다는 것을 직접 경험. 설계 전 필드 비트 범위를 명시적으로 정리하는 습관의 중요성을 체감.
* **명시적 비트 폭 선언**: Implicit Net으로 인한 X 전파는 원인을 찾기 어렵고 디버깅 비용이 큼. SystemVerilog에서 모든 신호의 비트 폭을 명시적으로 선언하는 것이 단순한 코딩 스타일이 아니라 오류 예방의 핵심임을 이해.
* **단일 사이클 구조의 한계**: 클럭 주파수가 크리티컬 패스(가장 느린 명령어)에 의해 결정되는 구조적 제약을 직접 확인. 파이프라인 적용 시 동일 시간 내 처리량을 크게 향상시킬 수 있음을 설계를 통해 이해.

---

## 🖥️ 개발 환경

| 항목 | 내용 |
|------|------|
| HDL | SystemVerilog (IEEE 1800) |
| EDA Tool | Xilinx Vivado |
| 시뮬레이터 | Vivado Simulator (XSim) |
| 아키텍처 | Harvard Architecture (ROM / RAM 분리) |
| ISA | RISC-V RV32I (공식 표준 문서 규격 준수) |

---

## 📌 향후 개선 방향

* **파이프라인 구조 적용** — 단일 사이클 구조의 클럭 제약을 해소하고 처리량 향상
* **데이터 메모리 크기 확장** — 현재 33바이트 제한으로 실운용 시 크기 조정 필요
* **Hazard Detection Unit 추가** — 파이프라인 전환 시 Data Hazard / Control Hazard 처리 로직 설계

---

## 📂 포트폴리오 목차

* [📂 Source Code](#) : RTL 전체 소스 (Control Unit, Datapath 및 서브모듈)
* [📂 Report](#) : 최종 설계 보고서
