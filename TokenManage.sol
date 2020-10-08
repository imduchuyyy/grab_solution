pragma solidity ^0.5.4;
import "./ERC20.sol";
import "./KeyManage.sol";

contract TokenManage {
    ERC20 private Token;
    KeyManage private _keyManage;

    mapping(address => uint256) private valuesReceive;

    constructor(address _tokenAddress, address _keyManageAddress) public {
        Token = ERC20(_tokenAddress);
        _keyManage = KeyManage(_keyManageAddress);
    }

    function sendToken(address user, uint256 _value) public payable {
        require(
            _keyManage.keyHasAccessRole(msg.sender, 1),
            "sender can not access token"
        );
        Token.transfer(user, _value, true);
    }

    function receiveToken(uint256 _value) public {
        require(
            _keyManage.keyHasAccessRole(msg.sender, 1),
            "sender can not access token"
        );
        Token.transfer(address(this), _value, false);
        valuesReceive[tx.origin] = _value;
    }

    function getValueReceive(address user) public view returns (uint256) {
        return valuesReceive[user];
    }

    function() external payable {}
}
