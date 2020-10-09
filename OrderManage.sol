pragma solidity ^0.5.4;
import "./VPIEternalStorage.sol";
import "./KeyManage.sol";

contract OrderManage {
    KeyManage private _keyManage;

    string constant NEW = "NEW";
    string constant APPROVE = "APPROVE";
    string constant ACCEPT = "ACCEPT";
    string constant PROCESS = "PROCESS";
    string constant CANCEL = "CANCEL";
    string constant DONE = "DONE";

    struct Order {
        bytes32 key;
        address customer;
        address transporter;
        bytes32 transporterKeyHash;
        bytes32 status;
        uint256 value;
        bytes32 data;
    }

    event NewOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    event CancelOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    event ApproveOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    event AcceptOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    event ProcessOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    event DoneOrder(
        string indexed key,
        address indexed customer,
        address indexed transporter,
        bytes32 transporterKeyHash,
        string status,
        uint256 value,
        string data
    );

    mapping(bytes32 => Order) private orders;

    constructor(address _keyManageAddress) public {
        _keyManage = KeyManage(_keyManageAddress);
    }

    function isValidOrder(bytes32 key) private returns (bool) {
        if (
            orders[key].status == stringToBytes32(DONE) ||
            orders[key].status == stringToBytes32(CANCEL)
        ) {
            return false;
        }
        return true;
    }

    function newOrder(
        string memory key,
        uint256 value,
        string memory data
    ) public {
        bytes32 _key = stringToBytes32(key);

        require(orders[_key].customer == address(0), "key already exist");

        orders[_key].key = stringToBytes32(key);
        orders[_key].customer = tx.origin;
        orders[_key].transporter = address(0);
        orders[_key].transporterKeyHash = bytes32(0);
        orders[_key].status = stringToBytes32(NEW);
        orders[_key].value = value;
        orders[_key].data = stringToBytes32(data);

        emit NewOrder(key, tx.origin, address(0), bytes32(0), NEW, value, data);
    }

    function cancelOrder(string memory key) public {
        bytes32 _key = stringToBytes32(key);
        require(orders[_key].customer == tx.origin);
        require(orders[_key].status == stringToBytes32(NEW));

        orders[_key].status = stringToBytes32(CANCEL);

        emit CancelOrder(
            key,
            tx.origin,
            address(0),
            bytes32(0),
            CANCEL,
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
    }

    function approveOrder(string memory key, bytes32 keyHash) public {
        bytes32 _key = stringToBytes32(key);

        require(orders[_key].customer != address(0), "key does not exist");
        require(orders[_key].status == stringToBytes32(NEW));

        orders[_key].transporter = tx.origin;
        orders[_key].transporterKeyHash = keyHash;
        orders[_key].status = stringToBytes32(APPROVE);

        emit ApproveOrder(
            key,
            orders[_key].customer,
            tx.origin,
            keyHash,
            APPROVE,
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
    }

    function acceptOrder(string memory key) public {
        bytes32 _key = stringToBytes32(key);

        require(orders[_key].transporter == tx.origin);
        require(isValidOrder(_key));

        orders[_key].status = stringToBytes32(ACCEPT);

        emit AcceptOrder(
            key,
            orders[_key].customer,
            tx.origin,
            orders[_key].transporterKeyHash,
            ACCEPT,
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
    }

    function processOrder(string memory key) public {
        bytes32 _key = stringToBytes32(key);

        require(orders[_key].transporter == tx.origin);
        require(isValidOrder(_key));

        orders[_key].status = stringToBytes32(PROCESS);

        emit ProcessOrder(
            key,
            orders[_key].customer,
            tx.origin,
            orders[_key].transporterKeyHash,
            PROCESS,
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
    }

    function doneOrder(string memory key, string memory transporterKey) public {
        bytes32 _key = stringToBytes32(key);
        require(orders[_key].customer == tx.origin);
        require(isValidOrder(_key));
        require(
            orders[_key].transporterKeyHash ==
                keccak256(abi.encodePacked(transporterKey))
        );

        orders[_key].status = stringToBytes32(DONE);

        emit DoneOrder(
            key,
            orders[_key].customer,
            orders[_key].transporter,
            orders[_key].transporterKeyHash,
            DONE,
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
    }

    function getOrder(string memory keyOrder)
        public
        view
        returns (
            string memory key,
            address customer,
            address transporter,
            string memory status,
            uint256 value,
            string memory data
        )
    {
        bytes32 _key = stringToBytes32(keyOrder);
        return (
            bytes32ToString(orders[_key].key),
            orders[_key].customer,
            orders[_key].transporter,
            bytes32ToString(orders[_key].status),
            orders[_key].value,
            bytes32ToString(orders[_key].data)
        );
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
