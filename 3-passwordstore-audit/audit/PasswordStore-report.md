# PasswordStore Security Audit Report

## Initial Impressions Summary

The purpose of this report is to perform a security review of the PasswordStore smart contract. The review was conducted manually against the contract source at `src/PasswordStore.sol`.

### Summary

- Protocol: PasswordStore allows a designated owner to store and update a single password, retrievable only by the owner.
- Timestamp of audit: 2026-11-06
- Commit review: current state of `src/PasswordStore.sol`

### Disclaimer

The audit makes an effort to find any possible vulnerabilities within the contracts provided. However, any audit is a point-in-time assessment, and cannot guarantee findings are complete or exhaustive.

---

## Findings

### [S-1] The stored password is readable by anyone despite `private` visibility (Root cause: solidity storage visibility misconception + Impact: complete loss of confidentiality of the password)

**Description:**

The `s_password` variable is marked `private`, but in Ethereum, `private` only limits access from other contracts during execution — it does NOT make the data secret. All storage slots are publicly readable by anyone using standard RPC calls like `eth_getStorageAt` or tools such as Foundry's `vm.load`.

```solidity
// src/PasswordStore.sol
string private s_password;
```

**Impact:**

Any user — not just the owner — can retrieve the password directly from storage. This is a total breach of the protocol's core promise: _"This contract allows you to store a private password that others won't be able to see."_ Anyone can call an off-chain tool to read the password value.

**Proof of Concept:**

The test below proves the password is readable by a non-owner through storage.

```solidity
// test/PasswordStore.t.sol addition
function test_anyoneCanReadPasswordFromStorage() public {
    string memory ownerPassword = "myVerySecretPassword";
    passwordStore.setPassword(ownerPassword);
    string memory readOnlyPassword = "notTheRealPassword";

    address attacker = makeAddr("attacker");

    // Access the slot via storage introspection (e.g. Foundry cheats or eth_getStorageAt)
    string memory expectedOwnerPassword = vm.load(
        address(passwordStore),
        bytes32(uint256(2)) // slot of s_password
    );
    ...
}
```

Running it:

```bash
forge test --mt test_anyoneCanReadPasswordFromStorage -v
```

**Recommended Mitigation:**

Do not store plaintext passwords on-chain. Use an off-chain password manager (e.g. a dedicated vault). If the contract must reference a password, store only a hash (with a salt) or an off-chain pointer, and never assume `private` visibility provides confidentiality.

---

### [S-2] `setPassword` lacks access control — any user can set the password (Root cause: missing `onlyOwner` check + Impact: owner's password can be overwritten or denied)

**Description:**

Although the NatSpec states _"This function allows only the owner to set a new password"_, the function has no access control. Any external account can call `setPassword` and overwrite the owner's password.

```solidity
// src/PasswordStore.sol
function setPassword(string memory newPassword) external {
    s_password = newPassword; // no msg.sender != s_owner check
    emit SetNetPassword();
}
```

**Impact:**

A malicious user can permanently change the owner's password, effectively causing a denial of service for the owner and locking the owner out of the password the contract is supposed to protect. The owner would lose access to whatever the password protects off-chain.

**Proof of Concept:**

```solidity
// test/PasswordStore.t.sol addition
function test_nonOwnerCanSetPassword() public {
    string memory attackerPassword = "hackedPassword";
    address attacker = makeAddr("attacker");

    vm.prank(attacker); // non-owner call
    passwordStore.setPassword(attackerPassword);

    vm.prank(PasswordStore.owner);
    assertEq(passwordStore.getPassword(), attackerPassword);
}
```

This test is already provided in `test/PasswordStoreFuzz.t.sol` as `testFuzz_nonOwnerCanSetPassword`, and it succeeds — proving the vulnerability.

```bash
forge test --mt testFuzz_nonOwnerCanSetPassword -v
```

**Recommended Mitigation:**

Add an owner check, reverting with the existing dedicated error so gas is saved:

```solidity
function setPassword(string memory newPassword) external {
    if (msg.sender != s_owner) {
        revert PasswordStore__NotOwner();
    }
    s_password = newPassword;
    emit SetPassword(newPassword);
}
```

---

### [S-3] Empty and misnamed event provides no information (Root cause: `SetNetPassword()` is declared without parameters and contains a typo + Impact: observability and developer UX issues)

**Description:**

The event name `SetNetPassword` appears to be a typo of `SetPassword`, and it carries no parameters, so consumers cannot know the password was updated, by whom, or its hash. It emits `uint256(...)`-free data and wastes the listener's attention.

```solidity
// src/PasswordStore.sol
event SetNetPassword();
...
emit SetNetPassword();
```

**Impact:**

Off-chain indexers and clients cannot distinguish password updates between accounts, and the typo misleads integrators reading the ABI. This is a quality/observability issue rather than a direct security vulnerability.

**Proof of Concept:**

`forge inspect PasswordStore abi` shows `SetNetPassword` with an empty inputs list.

**Recommended Mitigation:**

Rename the event (Fix typo): `event SetPassword(string newPassword);` and emit it with the new value (or a hash of it, never the plaintext password itself):

```solidity
event SetPassword(string newPassword);
...
emit SetPassword(newPassword);
```

---

### [S-4] `getPassword` NatSpec documents a `@param` the function does not have (Root cause: stale copy-pasted doc comment + Impact: misleading documentation for integrators)

**Description:**

The NatSpec block for `getPassword` documents `@param newPassword The new password to set.`, but the function takes no arguments — it is a parameter-less `view` function. The comment appears to have been copy-pasted from `setPassword` and never cleaned up. An inline `@audit` note in the source marks exactly this issue:

```solidity
// src/PasswordStore.sol
/*
 * @notice This allows only the owner to retrieve the password.
 * @param newPassword The new password to set.   // <- nonexistent parameter
 * @audit - low: this function not recieve a parameter
 */
function getPassword() external view returns (string memory) {
```

**Impact:**

Low — documentation-only. Tooling that consumes NatSpec (ABI generators, docs sites, LLM-assisted tooling) and human integrators are misled into thinking `getPassword` receives an argument. There is no runtime or security impact since Solidity ignores the discrepancy at compile time.

**Proof of Concept:**

Compile and let the NatSpec-output mode reveal the doc entry, or simply compare the ABI: `forge inspect PasswordStore abi` shows `getPassword` with an empty `inputs` array, contradicting the documented `@param`.

**Recommended Mitigation:**

Remove the stale `@param` and document the function accurately:

```solidity
/*
 * @notice This allows only the owner to retrieve the password.
 * @return The stored password.
 */
function getPassword() external view returns (string memory) {
```

## General Comments

- Consider defining an `Ownable`-style modifier (`onlyOwner`) to centralize the access-control pattern if the contract grows.
