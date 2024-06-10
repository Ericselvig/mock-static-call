## Problem
Find the fee collected for a UniswapV3 LP Position by simulating a transaction, specifically, by invoking `collectFee` function of the `NonfungiblePositionManager` contract without actually modifying the state of the contract.

## Solution
Create a function which make a low level call to the `collectFee` function and store the response received in a bytes memory variable. Using assembly, revert with those bytes.<br>
The test contract makes a low level call to this function and if the success variable is false (which will be always the case), it logs the reponse data received.

## Running Tests
```bash
git clone https://github.com/ericselvig/mock-static-call.git
cd mock-static-call
npm install
forge test
```