pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;
import "./VPIEternalStorage.sol";
import "./ConstantsValue.sol";
import "./KeyManage.sol";

contract UserManage is ConstantsValue {
    EternalStorage private Database;
    KeyManage private _keyManage;

    struct User {
        address addr;
        bytes32 code;
        bytes32 fullName;
        bytes32 email;
    }

    event AddMember(
        address indexed user,
        string indexed code,
        string indexed fullName,
        string email,
        uint256 role
    );

    event RemoveMember(
        address indexed user,
        string indexed code,
        string indexed fullName,
        string email
    );

    event AddHistory(
        address indexed user,
        string indexed code,
        string indexed history,
        string keyOrder
    );

    event AddScore(
        address indexed user,
        string indexed code,
        int256 score,
        string keyOrder
    );

    mapping(address => User) private userInfo;

    mapping(address => address[]) private members;
    mapping(address => address[]) private memberOf;
    mapping(address => bool) private admin;
    mapping(address => bytes32[]) private ordersOfMember;
    mapping(bytes32 => bytes32) private historiesKey;

    mapping(bytes32 => string[]) private histories;

    uint256 constant defaultScore = 100;

    constructor(address _databaseAddress, address _keyManageAddress) public {
        Database = EternalStorage(_databaseAddress);
        _keyManage = KeyManage(_keyManageAddress);
    }

    modifier canAccess() {
        bool isAdmin = admin[tx.origin];
        if (!isAdmin) revert();
        _;
    }

    function hasRole(
        address user,
        string memory code,
        uint256 role
    ) private returns (bool) {
        bool hasAccess = _keyManage.keyHasRole(user, code, role);
        if (!hasAccess) return false;
        return true;
    }

    function addOrganization(
        address user,
        string memory fullName,
        string memory code,
        string memory email
    ) public {
        require(hasRole(user, "ADMIN", 1));
        userInfo[user].fullName = stringToBytes32(fullName);
        userInfo[user].email = stringToBytes32(email);
        userInfo[user].code = stringToBytes32(code);

        _keyManage.addRole(user, code, 2);

        emit AddMember(user, code, fullName, email, 2);
    }

    function addMember(
        address user,
        string memory fullName,
        string memory email,
        uint256 role
    ) public {
        string memory code = bytes32ToString(userInfo[tx.origin].code);

        require(hasRole(tx.origin, code, role - 1));
        require(role != 1);

        if (role >= 4) {
            members[tx.origin].push(user);
            memberOf[user].push(tx.origin);

            bytes32 scoreKey = getKey(user, getScoreName());
            Database.set(scoreKey, defaultScore);
        }

        userInfo[user].code = stringToBytes32(code);
        userInfo[user].addr = user;
        userInfo[user].email = stringToBytes32(email);
        userInfo[user].fullName = stringToBytes32(fullName);

        _keyManage.addRole(user, code, role);

        emit AddMember(user, code, fullName, email, role);
    }

    function removeMember(address user) public {
        string memory code = bytes32ToString(userInfo[tx.origin].code);
        uint256 role = _keyManage.getRole(user, code);

        require(hasRole(tx.origin, code, role - 1));
        require(hasRole(tx.origin, code, 3));

        _keyManage.removeRole(user, code);

        emit RemoveMember(
            user,
            code,
            bytes32ToString(userInfo[user].fullName),
            bytes32ToString(userInfo[user].email)
        );
    }

    function addScore(
        address user,
        int256 score,
        string memory keyOrder
    ) public {
        string memory code = bytes32ToString(userInfo[tx.origin].code);

        require(userInfo[tx.origin].code == userInfo[user].code);

        require(hasRole(user, code, 5));
        require(hasRole(tx.origin, code, 3));
        bytes32 scoreKey = getKey(user, code, getScoreName());

        uint256 currentScore = Database.getUintValue(scoreKey);
        int256 newScore = score + int256(currentScore);

        newScore = newScore >= 0 ? newScore : 0;

        Database.set(scoreKey, uint256(newScore));

        emit AddScore(user, code, score, keyOrder);
    }

    function addHistory(
        address user,
        string memory status,
        string memory keyOrder
    ) public {
        string memory code = bytes32ToString(userInfo[tx.origin].code);

        require(userInfo[tx.origin].code == userInfo[user].code);
        require(hasRole(user, code, 5));
        require(hasRole(tx.origin, code, 3));

        bytes32 historyKey = getKey(user, code, getHistoryName());
        bytes32 historyKeyWithOrder = getKey(
            user,
            code,
            status,
            getHistoryName()
        );

        Database.pushArray(historyKey, status);
        Database.pushArray(historyKeyWithOrder, keyOrder);

        emit AddHistory(user, code, status, keyOrder);
    }

    function addAction(address user, string memory keyOrder) public {
        require(hasRole(msg.sender, "ADMIN", 1));

        addHistory(user, "BOOKING_DONE", keyOrder);
        addScore(user, 5, keyOrder);
    }

    function getScore(address user) public view returns (uint256 currentScore) {
        string memory code = bytes32ToString(userInfo[user].code);

        bytes32 scoreKey = getKey(user, code, getScoreName());

        uint256 currentScore = Database.getUintValue(scoreKey);

        return currentScore;
    }

    function getHistory(address user) public view returns (string[] memory) {
        string memory code = bytes32ToString(userInfo[user].code);

        bytes32 historyKey = getKey(user, code, getHistoryName());

        string[] memory currentStatus = Database.getArrayString(historyKey);

        return currentStatus;
    }

    function getKeyOrder(
        address user,
        string memory code,
        string memory status
    ) public view returns (string[] memory) {
        bytes32 historyKeyWithOrder = getKey(
            user,
            code,
            status,
            getHistoryName()
        );

        string[] memory keyOrders = Database.getArrayString(
            historyKeyWithOrder
        );

        return keyOrders;
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
