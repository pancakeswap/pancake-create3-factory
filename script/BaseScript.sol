// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Create2Factory} from "../src/Create2Factory.sol";

abstract contract BaseScript is Script {
    string path;

    function setUp() public virtual {
        string memory scriptConfig = vm.envString("SCRIPT_CONFIG");
        console.log("[BaseScript] SCRIPT_CONFIG: ", scriptConfig);

        string memory root = vm.projectRoot();
        path = string.concat(root, "/script/config/", scriptConfig, ".json");
        console.log("[BaseScript] Reading config from: ", path);
    }

    // reference: https://github.com/foundry-rs/foundry/blob/master/testdata/default/cheats/Json.t.sol
    function getAddressFromConfig(string memory key) public view returns (address) {
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json, string.concat(".", key));

        // seems like foundry decode as 0x20 when address is not set or as "0x"
        address decodedData = abi.decode(data, (address));
        require(decodedData != address(0x20), "Address not set");

        return decodedData;
    }

    function getCreate2Factory() public view returns (Create2Factory) {
        address create2FactoryAddr = getAddressFromConfig("create2Factory");
        return Create2Factory(create2FactoryAddr);
    }
}
