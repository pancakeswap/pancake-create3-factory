// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CustomizedProxyChild {
    error NotFromParent();
    error BackrunExecutionFailed();

    address public immutable parent;

    constructor() {
        parent = msg.sender;
    }

    function deploy(bytes memory creationCode, uint256 creationFund, bytes calldata backRunPayload, uint256 backRunFund)
        external
        payable
        returns (address addr)
    {
        // make sure only Create3Factory can deploy contract in case of unauthorized deployment
        if (msg.sender != parent) {
            revert NotFromParent();
        }

        assembly {
            /// @dev create with creation code, deterministic addr since create(thisAddr=fixed, nonce=0)
            addr := create(creationFund, add(creationCode, 32), mload(creationCode))
        }

        if (backRunPayload.length != 0) {
            /// @dev This could be helpful when newly deployed contract
            /// needs to run some initialization logic for example owner update
            (bool success, bytes memory reason) = addr.call{value: backRunFund}(backRunPayload);
            if (!success) {
                // bubble up the revert reason from backrun if any
                if (reason.length > 0) {
                    assembly {
                        revert(add(reason, 32), mload(reason))
                    }
                }
                revert BackrunExecutionFailed();
            }
        }
    }
}
