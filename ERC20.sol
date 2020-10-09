pragma solidity ^0.5.4;

contract Token {
    string public name = "Booking token";
    string public symbol = "SYS";
    uint256 public totalSupply = 0;
    uint8 public decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event MintToken(address indexed miner, uint256 indexed value);

    event BurnToken(address indexed burner, uint256 indexed value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[tx.origin][_spender] = _value;
        emit Approval(tx.origin, _spender, _value);
        return true;
    }

    function mint(uint256 _value) public {
        balanceOf[tx.origin] += _value;

        emit MintToken(tx.origin, _value);
    }

    function burn(uint256 _value) public {
        balanceOf[tx.origin] -= _value;

        emit BurnToken(tx.origin, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
