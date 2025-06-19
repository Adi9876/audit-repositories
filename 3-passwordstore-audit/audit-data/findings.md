# Findings Report

## [H-1] Storing the password on-chain makes it visible to anyone, and no longer private

**Description:** All data stored on-chain is visible to anyone and can be read from the blockchain directly. The `PasswordStore::s_password` variable is intended to be private  varible and only accessed throught the `PasswordStore::getPassoword` function, which is only inteded to be used by the owner of that contract.

We show one such method of reading any data off chain below.

**Impact:** Anyone can read the password. Severly breaking the functionality of the protocol.

**Proof of Concept:** (Proof of Code)

The below test case shows how anyone can raad the password directly from the blockchain

1. Create a locally running chain

```bash
make anvil
```

2. Deploy the contract

```bash
make deploy
```

3. Run the storage tool

We use `1` because that's the storage slot of the `s_password` in the contract

```bash
cast storage <ADDRESS_HERE> 1 --rpc-url http://127.0.0.1:8545
```

You'll get an output that looks like this

`0x6d7950617373776f726400000000000000000000000000000000000000000014`

You can then parse the hex to a string with:

```bash
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
```

You'll get an output of:

```bash
myPassword
```

**Recommended Mitigation:** The contract shift its logic of storing password off-chain and then calling it onchain for verification.

---

## [H-2] `PasswordStore::setPassword` has no access control, meaning a non-owner can change the password

**Description:** The `PasswordStore::setPassword` function is set to be an `external` function, however, the natspec of the function and overall purpose of the smart contract is that `This function allows only the owner to set a new password.`

```javascript
    function setPassword(string memory newPassword) external {
@>        //@audit: There is not access control
            s_password = newPassword;
            emit SetNetPassword();
    }
```

**Impact:** Anyone can set or change the password, severly breaking the contract functionlity.

**Proof of Concept:** Add the following to the `PasswordStore.t.sol` test file

<details>
<summary> Code </summary>

```javascript
    function test_anyone_can_set_password(address randomAddress) public {
        vm.assume(randomAddress != owner);
        vm.prank(randomAddress);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);

        vm.prank(owner);
        string memory actualPassword = passwordStore.getPassword();

        assertEq(actualPassword,expectedPassword);
    }
```

</details>

**Recommended Mitigation:** Add an access control additional to the `setPassword` function.

```javascript
if(msg.sender != s_owner){
    revert PasswordStore_NotOwner();
}
```

## [I-1] The `PasswordStore::getPassword` function natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect

**Description:**

```javascript
 /*
     * @notice This allows only the owner to retrieve the password.
     * @param newPassword The new password to set.
     */
    function getPassword() external view returns (string memory)
```

The funciton `PasswordStore::getPassword` function signature is `getPassword()` which the natspec says it should be `getPassword(string)`

**Impact:** The natspec is incorrect.

**Recommended Mitigation:** Remove natspec incorrect line.

```diff
-     * @param newPassword The new password to set.
```
