pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;
import "./VPIEternalStorage.sol";
import "./ConstantsValue.sol";
import "./KeyManage.sol";

contract UserManage is ConstantsValue {
    EternalStorage private Database;
    KeyManage private _keyManage;

    struct Status {
        int256 score;
        string status;
    }

    struct User {
        address addr;
        string fullName;
        uint256 id;
    }

    mapping(address => User) private userInfo;

    mapping(address => address[]) private members;
    mapping(address => address[]) private memberOf;
    mapping(address => string) private companyCode;
    mapping(address => bool) private admin;

    mapping(uint256 => Status) private statuses;

    uint256 constant defaultScore = 100;

    constructor(address _databaseAddress, address _keyManageAddress) public {
        Database = EternalStorage(_databaseAddress);
        _keyManage = KeyManage(_keyManageAddress);

        statuses[0].score = 5;
        statuses[0].status = "BOOKINK_DONE";

        statuses[1].score = 5;
        statuses[1].status = "FAST_DELIVERY";

        statuses[2].score = -3;
        statuses[2].status = "SLOW_DELIVERY";

        statuses[3].score = -30;
        statuses[3].status = "REJECT_RECEIVE_PACKAGE";

        statuses[4].score = -100;
        statuses[4].status = "DONT_PAY_MONEY";
    }

    modifier canAccess() {
        bool isAdmin = admin[tx.origin];
        if (!isAdmin) revert();
        _;
    }

    // function addRole(address user, string memory code , uint256 role) private {
    //     _keyManage.addRole(keccak256(abi.encodePacked(user, code)), role);
    // }

    // function getRole(address user, string memory code) private returns(uint256) {
    //     uint256 role = _keyManage.getAccessRole(keccak256(abi.encodePacked(user, code)));

    //     return role;
    // }

    function hasRole(
        address user,
        string memory code,
        uint256 role
    ) private returns (bool) {
        if (role == 1) {
            bool hasAccess = _keyManage.keyHasRole(tx.origin, role);
            if (!hasAccess) return false;
            return true;
        } else {
            bool hasAccess = _keyManage.keyHasRole(tx.origin, code, role);
            if (!hasAccess) return false;
            return true;
        }
    }

    function addMember(
        address user,
        string memory fullName,
        string memory code,
        uint256 id,
        uint256 role
    ) public {
        require(hasRole(tx.origin, code, role - 1));
        require(role != 1);
        string memory _code = code;
        if (role != 2) {
            _code = companyCode[tx.origin];
        }

        if (role >= 4) {
            members[tx.origin].push(user);
            memberOf[user].push(tx.origin);

            bytes32 scoreKey = getKey(user, getScoreName());
            Database.set(scoreKey, defaultScore);
        } else {
            companyCode[user] = _code;
            admin[user] = true;
        }

        userInfo[user].addr = user;
        userInfo[user].fullName = fullName;
        userInfo[user].id = id;

        _keyManage.addRole(user, _code, role);
    }

    function addStatus(
        uint256 idStatus,
        int256 score,
        string memory status
    ) public canAccess {
        require(statuses[idStatus].score == 0);
        require(score != 0);

        statuses[idStatus].score = score;
        statuses[idStatus].status = status;
    }

    function removeMember(address user) public {
        string memory code = companyCode[tx.origin];
        uint256 role = _keyManage.getRole(user, code);

        require(hasRole(tx.origin, code, role - 1));

        _keyManage.removeRole(user, code);
    }

    /**
     * @dev add score for member
     * @param user : address member need to add (address)
     * @param score : score need to add (int256)
     */
    function addScore(address user, int256 score) public canAccess {
        bytes32 scoreKey = getKey(user, getScoreName());

        uint256 currentScore = Database.getUintValue(scoreKey);
        int256 newScore = score + int256(currentScore);

        newScore = newScore >= 0 ? newScore : 0;

        Database.set(scoreKey, uint256(newScore));
    }

    /**
     * @dev add history for member
     * @param user : address member need to add (address)
     * @param status : history need to add (string)
     */
    function addHistory(address user, string memory status) public canAccess {
        bytes32 historyKey = getKey(user, getHistoryName());

        Database.pushArray(historyKey, stringToBytes32(status));
    }

    /**
     * @dev add value for member + history
     * @param user : address member need to add
     * @param value : value need to add (uint256)
     * @param status : history need to add (string)
     */
    function addValue(
        address user,
        uint256 value,
        string memory status
    ) public canAccess {
        bytes32 valueKey = getKey(user, getValueName(), status);

        uint256 currentValue = Database.getUintValue(valueKey);
        Database.set(valueKey, currentValue + value);
    }

    function addAction(
        address user,
        uint256 idStatus,
        uint256 value
    ) public canAccess {
        addHistory(user, statuses[idStatus].status);
        addScore(user, statuses[idStatus].score);
        addValue(user, value, statuses[idStatus].status);
    }

    function addAction(
        address user,
        string memory status,
        int256 score,
        uint256 value
    ) public canAccess returns (int256 newScore) {
        addHistory(user, status);
        addScore(user, score);
        addValue(user, value, status);
    }

    /**
     * @dev get score of member
     * @param user : address member need to add
     * @return currentScore: score of member
     */
    function getScore(address user) public view returns (uint256 currentScore) {
        bytes32 scoreKey = getKey(user, getScoreName());

        uint256 currentScore = Database.getUintValue(scoreKey);

        return currentScore;
    }

    function getScore(uint256 idStatus)
        public
        view
        returns (int256 currentScore)
    {
        int256 currentScore = statuses[idStatus].score;

        return currentScore;
    }

    function stringToBytes32(string memory source)
        private
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

    /**
     * @dev get history of member
     * @param user : address member need to add
     * @return currentStatus: history of member
     */
    function getHistory(address user) public view returns (bytes32[] memory) {
        bytes32 historyKey = getKey(user, getHistoryName());

        bytes32[] memory currentStatus = Database.getArrayBytes32(historyKey);

        return currentStatus;
    }

    function getStatus(uint256 idStatus)
        public
        view
        returns (int256, string memory)
    {
        return (statuses[idStatus].score, statuses[idStatus].status);
    }

    function getValueHistory(address user, uint256 idStatus)
        public
        view
        returns (uint256)
    {
        bytes32 valueKey = getKey(
            user,
            getValueName(),
            statuses[idStatus].status
        );

        uint256 value = Database.getUintValue(valueKey);

        return value;
    }

    function getValueHistory(address user, string memory status)
        public
        view
        returns (uint256)
    {
        bytes32 valueKey = getKey(user, getValueName(), status);

        uint256 value = Database.getUintValue(valueKey);

        return value;
    }
}
