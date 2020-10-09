pragma solidity ^0.5.4;
import "./Ownable.sol";

contract ConstantsValue {
    string private constant HISTORY = "HISTORY";
    string private constant SCORE = "SCORE";
    string private constant MEMBER = "MEMBER";
    string private constant VALUE = "VALUE";
    string private constant ACCESS_KEY = "ACCESS_KEY";
    string private constant KEY_APPLICATION = "BOOKING_DUCHUY";

    /**
     * @dev return history variable name.
     */
    function getHistoryName() internal view returns (string memory) {
        return HISTORY;
    }

    /**
     * @dev return score variable name.
     */
    function getScoreName() internal view returns (string memory) {
        return SCORE;
    }

    /**
     * @dev return member variable name.
     */
    function getMemberName() internal view returns (string memory) {
        return MEMBER;
    }

    /**
     * @dev return value variable name.
     */
    function getValueName() internal view returns (string memory) {
        return VALUE;
    }

    /**
     * @dev return access key variable name.
     */
    function getAccessKey() internal view returns (string memory) {
        return ACCESS_KEY;
    }

    /**
     * @dev return application variable name.
     */
    function getApplicationName() internal view returns (string memory) {
        return KEY_APPLICATION;
    }

    /**
     * @dev return key for use to access Database
     * @param user : address member in application
     * @param variableName : name of variable need to get
     * @return bytes32 key
     */
    function getKey(address user, string memory variableName)
        internal
        view
        returns (bytes32)
    {
        bytes32 key = keccak256(
            abi.encodePacked(user, variableName, getApplicationName())
        );
        return key;
    }

    /**
     * @dev return key for use to access Database
     * @param user1 : member in application: (transporter address)
     * @param user2 : member in application: (customer address)
     * @param variableName : name of variable need to get
     * @return bytes32 key
     */
    function getKey(
        address user1,
        address user2,
        string memory variableName
    ) internal view returns (bytes32) {
        bytes32 key = keccak256(
            abi.encodePacked(user1, user2, variableName, getApplicationName())
        );
        return key;
    }

    /**
     * @dev return key for use to access Database
     * @param user : member in application
     * @param variableName : name of variable need to get
     * @param typeName : name of type variable need to get
     * @return bytes32 key
     */
    function getKey(
        address user,
        string memory variableName,
        string memory typeName
    ) internal view returns (bytes32) {
        bytes32 key = keccak256(
            abi.encodePacked(user, typeName, variableName, getApplicationName())
        );
        return key;
    }

    function getKey(
        address user,
        string memory code,
        string memory keyOrder,
        string memory variableName
    ) internal view returns (bytes32) {
        bytes32 key = keccak256(
            abi.encodePacked(
                user,
                code,
                keyOrder,
                variableName,
                getApplicationName()
            )
        );
        return key;
    }
}
