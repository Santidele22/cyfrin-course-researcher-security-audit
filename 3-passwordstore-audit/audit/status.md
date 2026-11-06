# PasswordStore Audit — Status

Estado de los contratos bajo auditoría, según la salida de `scc` del repositorio.

## Contratos en scope

| Contrato              | Ubicación                          | Estado                                |
| --------------------- | ---------------------------------- | ------------------------------------- |
| `PasswordStore`       | `src/PasswordStore.sol`            | Auditado                              |
| `DeployPasswordStore` | `script/DeployPasswordStore.s.sol` | Fuera de scope (script de despliegue) |
| `PasswordStoreTest`   | `test/PasswordStore.t.sol`         | Fuera de scope (suite de tests)       |

## Métricas (`scc --by-file`)

| Archivo                            | Líneas | Código | Comentarios | Blanks | Complejidad |
| ---------------------------------- | ------ | ------ | ----------- | ------ | ----------- |
| `src/PasswordStore.sol`            | 41     | 20     | 15          | 6      | 2           |
| `script/DeployPasswordStore.s.sol` | 15     | 12     | 1           | 2      | 0           |
| `test/PasswordStore.t.sol`         | 33     | 26     | 1           | 6      | 0           |
| **Total**                          | **89** | **58** | **17**      | **14** | **2**       |

> Nota: los `.sol` bajo `lib/chainlink-brownie-contracts/` son dependencias de terceros de Foundry y no forman parte del scope de la auditoría.
