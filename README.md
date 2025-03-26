# FIFO_Design
Implementation of an asynchronous FIFO with clock domain crossing (CDC) safety using Gray code pointers and dual-clock synchronization. Includes self-checking testbench with metastability verification.

## Theory of Operation

An asynchronous FIFO (First-In-First-Out) buffer is a fundamental component in digital systems that enables reliable data transfer between subsystems operating in different clock domains. This implementation addresses the critical challenges of metastability and data corruption during clock domain crossing (CDC) through several key architectural features:

### Core Principles
1. **Dual-Clock Architecture**: Implements independent write (producer) and read (consumer) clock domains
2. **Gray Code Pointer Management**: Ensures single-bit transitions during CDC for metastability prevention
3. **Double-Flop Synchronization**: Provides robust clock domain crossing for control signals
4. **Binary-to-Gray Conversion**: Safe pointer transfer between clock domains

## Architectural Components

### 1. Memory Subsystem
- **Register File Storage**: Dual-port memory array with configurable:
  - `DATA_WIDTH` (default: 8-bit)
  - `ADDR_WIDTH` (default: 4-bit → 16-entry depth)
- Simultaneous read/write capability with collision prevention

### 2. Pointer Management System
| Component | Function |
|-----------|----------|
| Binary Counters | Track absolute read/write positions |
| Gray Converters (B2G/G2B) | Enable safe CDC transitions |
| Synchronization Chains | 2-stage flip-flop synchronizers |

### 3. Control Logic
- Full/Empty flag generation:
  - **Full**: wr_ptr_gray == ~rd_ptr_gray_sync[MSB:0]
  - **Empty**: rd_ptr_gray == wr_ptr_gray_sync
- Flow control signaling between domains

## CDC Safety Mechanisms

The design employs two critical synchronization techniques:

1. **Binary-to-Gray Conversion**: A mathematical operation that ensures only one bit changes between successive pointer values, implemented through bitwise operations that combine shift and XOR functions.

2. **Double-Flop Synchronization**: A two-stage register chain in the destination clock domain that reduces metastability probability by allowing a full clock cycle for signal stabilization between synchronization stages.

## Verification Methodology

### Testbench Architecture
- **Independent Clock Generation**:
  - Write clock: 100MHz (10ns period)
  - Read clock: ~71.4MHz (14ns period)
  
- **Self-Checking Tasks**: The testbench implements automated verification tasks that:
  1. Maintain reference data structures for expected values
  2. Compare actual FIFO outputs against golden references
  3. Automatically flag discrepancies with timestamp information

### Verification Cases
1. **Normal Operation**:
   - Concurrent read/write stress testing
   - Random interval operations

2. **Boundary Conditions**:
   - Full flag assertion testing
   - Empty flag assertion testing
   - Metastability injection

3. **Error Cases**:
   - Write-when-full detection
   - Read-when-empty detection

## Simulation Results

| Test Case | Result | Timestamp |
|-----------|--------|-----------|
| Initial Write Burst | 16 writes completed | 0-160ns |
| Full Condition Trigger | Assertion caught | 165ns |
| Read Drain | 16 reads verified | 200-424ns |
| Empty Condition | Assertion caught | 430ns |

## Implementation Requirements

### Toolchain Compatibility
- Supports all major Verilog simulators (Icarus Verilog, ModelSim, VCS)
- Waveform viewing capability recommended (GTKWave or equivalent)

### Parameterization
The design is fully parameterized through:
- DATA_WIDTH: Configurable data bus width
- ADDR_WIDTH: Determines FIFO depth as 2^ADDR_WIDTH

## Acknowledgments
This implementation is part of the course work for EE5530 Principles of SoC Functional Verification
