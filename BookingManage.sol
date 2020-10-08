pragma solidity ^0.5.4;
import './UserManage.sol';
import './TokenManage.sol';
import './VPIEternalStorage.sol';
import './ConstantsValue.sol';

contract BookingManager {
    TokenManage private _tokenManage;
    UserManage private _userManage;
    KeyManage private _keyManage;
    
    uint256 private requestNonce;
    uint256 private reportNonce;
    
    struct Request {
        address customer;
        address transporter;
        bytes32 transporterKeyHash;
        uint256 value;
        bool isCancel;
        bool isDone;
    }
    
    struct Report {
        uint256 requestNonce;
        string reason;
        address reporter;
        bool isExcute;
    }
    
    mapping(uint256 => Request) private requests;
    mapping(address => uint256[]) private userRequests;
    mapping(uint256 => Report) private reports;
    
    event BookingStarted (
        address indexed transporter,
        address indexed customer,
        uint256 idRequest,
        uint256 value
    );
    
    event DoneBooking (
        address indexed transporter,
        address indexed customer,
        uint256 idRequest,
        uint256 value
    );
    
    event ReportEvent (
        address indexed transporter,
        address indexed customer
    );
    
    modifier hasAccessKey(address user ,uint256 _accessRole) {
        bool hasAccess = _keyManage.keyHasAccessRole(user, _accessRole);
        if (!hasAccess) revert();
        _;
    }
    
    modifier isValidRequestNonce(uint256 _requestNonce) {
        if (_requestNonce >= requestNonce) revert();
        _;
    }
    
    modifier isValidReportNonce(uint256 _reportNonce) {
        if (_reportNonce >= reportNonce) revert();
        _;
    }
    
    constructor (address payable _tokenManageAddress, address _userManageAddress, address _keyManageAddress) public {
        _tokenManage = TokenManage(_tokenManageAddress);
        _userManage = UserManage(_userManageAddress);
        _keyManage = KeyManage(_keyManageAddress);
    }
    
    function newRequest (uint256 value) private {
        requests[requestNonce].customer = msg.sender;
        requests[requestNonce].transporter = address(0);
        requests[requestNonce].value = value;
        requests[requestNonce].isCancel = false;
        requests[requestNonce].isDone = false;
        
        requestNonce++;
    }
    
    function newReport (uint256 _requestNonce, string memory reason) private {
        reports[reportNonce].requestNonce = _requestNonce;
        reports[reportNonce].reason = reason;
        reports[reportNonce].reporter = msg.sender;
        reports[reportNonce].isExcute = false;
        
        reportNonce ++;
    }
    
    function customerRequest (uint256 value) public payable hasAccessKey(msg.sender, 2) returns(uint256) {
        newRequest(value);
        
        _tokenManage.receiveToken(value);
        
        userRequests[msg.sender].push(requestNonce - 1);
    } 
    
    function getUserRequests(address user) public hasAccessKey(msg.sender, 2) returns(uint256[] memory) {
        return userRequests[user];
    }
    
    function customerCancel(uint256 _requestNonce) public isValidRequestNonce(_requestNonce) hasAccessKey(msg.sender, 2) {
        require(requests[_requestNonce].customer == msg.sender);
        require(!requests[_requestNonce].isDone);
        require(requests[_requestNonce].transporter == address(0));
        
        _tokenManage.sendToken(msg.sender, requests[_requestNonce].value);
        requests[_requestNonce].isCancel = true;
    }
    
    function transporterApproveRequest(uint256 _requestNonce, bytes32 _transporterKeyHash) public isValidRequestNonce(_requestNonce) hasAccessKey(msg.sender, 2) {
        require(!requests[_requestNonce].isDone);
        require(!requests[_requestNonce].isCancel);
        require(requests[_requestNonce].transporter == address(0));
        
        requests[_requestNonce].transporterKeyHash = _transporterKeyHash;
        requests[_requestNonce].transporter = msg.sender;
        
        emit BookingStarted(msg.sender, requests[_requestNonce].customer, _requestNonce ,requests[_requestNonce].value);
    }
    
    function getRequest(uint256 _requestNonce) public isValidRequestNonce(_requestNonce) view returns(address customer, address transporter, bytes32 transporterKeyHash, uint256 value, bool isCancel, bool isDone) {
        return (requests[_requestNonce].customer, requests[_requestNonce].transporter, requests[_requestNonce].transporterKeyHash, requests[_requestNonce].value, requests[_requestNonce].isCancel, requests[_requestNonce].isDone);
    }
    
    function customerConfirm (uint256 _requestNonce, string memory transporterKey) public isValidRequestNonce(_requestNonce) payable hasAccessKey(msg.sender, 2) {
        require(requests[_requestNonce].customer == msg.sender);
        require(requests[_requestNonce].transporter != address(0));
        bytes32 _transporterKeyHash = keccak256(abi.encodePacked(transporterKey));
        require(requests[_requestNonce].transporterKeyHash == _transporterKeyHash);
        
        address transporter = requests[_requestNonce].transporter;
        uint256 value = requests[_requestNonce].value;
        
        _tokenManage.sendToken(transporter, value);
        _userManage.addAction(transporter, 0, value);
        _userManage.addAction(msg.sender, 0,value);
        
        requests[_requestNonce].isDone = true;
        
        emit DoneBooking(transporter, msg.sender, _requestNonce, value);

    }
    
    function reportCustomer (string memory reason, uint256 _requestNonce) public isValidRequestNonce(_requestNonce) hasAccessKey(msg.sender, 2) {
        require(!requests[_requestNonce].isDone);
        require(!requests[_requestNonce].isCancel);
        require(requests[_requestNonce].transporter == msg.sender);
        
        newReport(_requestNonce, reason);
        
        emit ReportEvent(msg.sender, requests[_requestNonce].customer);
    }
    
    function reportTransporter (string memory reason, uint256 _requestNonce) public isValidRequestNonce(_requestNonce) hasAccessKey(msg.sender, 2) {
        require(!requests[_requestNonce].isDone);
        require(!requests[_requestNonce].isCancel);
        require(requests[_requestNonce].customer == msg.sender);
        
        newReport(_requestNonce, reason);
        
        emit ReportEvent(requests[_requestNonce].transporter, msg.sender);
    }
    
    function getReport (uint256 _reportNonce) public isValidReportNonce(_reportNonce) hasAccessKey(msg.sender, 2) view returns(uint256, string memory, address) {
        return (reports[_reportNonce].requestNonce, reports[_reportNonce].reason, reports[_reportNonce].reporter);
    }
    
    function excuteReport (bool customerFault, uint256 _reportNonce) isValidReportNonce(_reportNonce) hasAccessKey(msg.sender, 1) public {
        require(!reports[_reportNonce].isExcute);
        
        uint256 _requestNonce = reports[_reportNonce].requestNonce;
        
        require(!requests[_requestNonce].isDone);
        require(!requests[_requestNonce].isCancel);
        
        address customer = requests[_requestNonce].customer;
        address transporter = requests[_requestNonce].transporter;
        uint256 value = requests[_requestNonce].value;
        
        if (customerFault) {
            _tokenManage.sendToken(transporter, value);
        } else {
            _tokenManage.sendToken(customer, value);
        }
        
        reports[_reportNonce].isExcute = true;
        requests[_requestNonce].isCancel = true;
    }
}