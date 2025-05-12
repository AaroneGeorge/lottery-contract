// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    
    // Mock LINK Token for testing purposes
    contract LinkToken is ERC20 {
        constructor() ERC20("MockLink", "mLINK") {
            // Mint a large amount of mock LINK to the deployer of this mock token
            _mint(msg.sender, 1000000 * 10**decimals());
        }
    
        /**
         * @dev Mock transferAndCall for compatibility with some Chainlink contracts.
         * In a real scenario, this would call the receiver contract.
         */
        function transferAndCall(address to, uint amount, bytes calldata data) external returns (bool) {
            transfer(to, amount);
            // Simulate a successful call to the receiver, data is ignored in this mock
            // For more advanced mocks, you might decode data and call a function on `to`
            return true;
        }
    } 