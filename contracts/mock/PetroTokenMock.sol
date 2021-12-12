// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../token/PetroToken.sol";

contract PetroTokenMock is PetroToken {

    function getRevision() internal pure override returns (uint256) {
        return 0x2;
    }
}