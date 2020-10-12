pragma solidity ^0.5.4;
import "./UserManage.sol";
import "./ERC20.sol";
import "./VPIEternalStorage.sol";
import "./ConstantsValue.sol";
import "./OrderManage.sol";
import "./String.sol";

contract BookingManager {
    using Strings for string;
    UserManage private userManage;
    OrderManage private orderManage;

    function getCode(string memory keyOrder) private returns (string memory) {
        string memory result = keyOrder.substring(3);
        return result;
    }

    constructor(address userManageAddr, address orderManageAddr) public {
        userManage = UserManage(userManageAddr);
        orderManage = OrderManage(orderManageAddr);
    }

    function matchingCode(string memory key) private returns (bool) {
        string memory userCode = userManage.getUserCode(tx.origin);
        string memory keyCode = getCode(key);

        return stringToBytes32(userCode) == stringToBytes32(keyCode);
    }

    function newBooking(
        string memory key,
        uint256 value,
        string memory data
    ) public {
        require(matchingCode(key));

        orderManage.newOrder(key, value, data);
    }

    function cancelBooking(string memory key) public {
        require(matchingCode(key));

        orderManage.cancelOrder(key);
    }

    function approveBooking(string memory key, bytes32 keyHash) public {
        require(matchingCode(key));

        orderManage.approveOrder(key, keyHash);
    }

    function acceptBooking(string memory key) public {
        require(matchingCode(key));

        orderManage.acceptOrder(key);
        userManage.addScore(tx.origin, 3, key);
    }

    function processBooking(string memory key) public {
        require(matchingCode(key));

        orderManage.processOrder(key);
        userManage.addScore(tx.origin, 3, key);
    }

    function doneBooking(string memory key, string memory transporterKey)
        public
    {
        require(matchingCode(key));

        orderManage.doneOrder(key, transporterKey);

        string memory _key;
        address customer;
        address transporter;
        string memory status;
        uint256 value;
        string memory data;

        (_key, customer, transporter, status, value, data) = orderManage
            .getOrder(key);

        userManage.addScore(customer, 10, key);
        userManage.addScore(transporter, 10, key);
        userManage.addHistory(customer, "DONE_BOOKING", key);
        userManage.addHistory(transporter, "DONE_BOOKING", key);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        private
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
