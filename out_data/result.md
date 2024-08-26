# Recording Data

## Scenario 1

| Algorithm/Scenario  | FFRMT | HDP in SDN |
| -------- | --- | --- |
| Phase 1  | 4  | 4  |
| Phase 2  | 7  | 7  |
| Phase 3  | 5  | 7  |
| Phase 4  | 4  | 4  |

## Scenario 2

| Algorithm/Scenario  | FFRMT | HDP in SDN |
| -------- | --- | --- |
| Phase 1  | 4  | 4  |
| Phase 2  | 9  | 9  |
| Phase 3  | 5  | 9  |
| Phase 4  | 4  | 4  |

## Scenario 3

| Algorithm/Scenario  | FFRMT | HDP in SDN |
| -------- | --- | --- |
| Phase 1  | 3  | 3  |
| Phase 2  | 7  | 7  |
| Phase 3  | 5  | $\infty$  |
| Phase 4  | 4  | 4  |

The main difference between FFRMT and HDP is that FFRMT is **flow-awared**. This feature fix the packet loop issue caused by using cyclic-port order.
