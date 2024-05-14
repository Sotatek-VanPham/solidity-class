// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapContract is Initializable, ReentrancyGuard {
    address owner;
    address public treasury;
    uint public constant FEE = 5;

    enum Status {
        Pending,
        Approved,
        Rejected,
        Canceled
    }

    struct SwapRequest {
        address sender;
        address receiver;
        address tokenSend;
        address tokenReceive;
        uint256 amountSend;
        uint256 amountReceive;
        Status status;
    }

    mapping(bytes32 => SwapRequest) public swapRequests;
    mapping(address => uint256) public nonces;

    event SwapRequestCreated(
        bytes32 requestId,
        address sender,
        address receiver,
        address tokenSend,
        address tokenReceive,
        uint256 amountSend,
        uint256 amountReceive
    );
    event SwapRequestStatusChanged(bytes32 requestId, Status status);

    function initialize() public initializer {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner address");
        _;
    }

    function createSwapRequest(
        address _receiver,
        address _tokenSend,
        uint256 _amountSend,
        address _tokenReceive,
        uint256 _amountReceive
    ) external nonReentrant {
        require(_receiver != address(0), "Invalid receiver address");
        require(_tokenSend != address(0), "Invalid tokenSend address");
        require(_tokenReceive != address(0), "Invalid tokenReceive address");
        require(_amountSend > 0 && _amountReceive > 0, "Invalid amount");

        uint256 nonce = nonces[msg.sender]++;

        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, nonce));
        IERC20(_tokenSend).transferFrom(msg.sender, address(this), _amountSend);

        swapRequests[requestId] = SwapRequest(
            msg.sender,
            _receiver,
            _tokenSend,
            _tokenReceive,
            _amountSend,
            _amountReceive,
            Status.Pending
        );
        emit SwapRequestCreated(
            requestId,
            msg.sender,
            _receiver,
            _tokenSend,
            _tokenReceive,
            _amountSend,
            _amountReceive
        );
    }

    function approveSwapRequest(bytes32 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can approve");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        uint256 sendFee = (request.amountSend * FEE) / 100;
        uint256 receiveFee = (request.amountReceive * FEE) / 100;

        IERC20(request.tokenReceive).transferFrom(
            msg.sender,
            address(this),
            request.amountReceive
        );

        IERC20(request.tokenReceive).transfer(treasury, receiveFee);

        IERC20(request.tokenReceive).transfer(
            request.sender,
            request.amountReceive - receiveFee
        );

        IERC20(request.tokenSend).transfer(treasury, sendFee);

        IERC20(request.tokenSend).transfer(
            request.receiver,
            request.amountSend - sendFee
        );

        request.status = Status.Approved;
        emit SwapRequestStatusChanged(_requestId, Status.Approved);
    }

    function rejectSwapRequest(bytes32 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can reject");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        IERC20(request.tokenSend).transfer(request.sender, request.amountSend);

        request.status = Status.Rejected;
        emit SwapRequestStatusChanged(_requestId, Status.Rejected);
    }

    function cancelSwapRequest(bytes32 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.sender == msg.sender, "Only sender can cancel");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );
        IERC20(request.tokenSend).transfer(request.sender, request.amountSend);

        request.status = Status.Canceled;
        emit SwapRequestStatusChanged(_requestId, Status.Canceled);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }

    function updateTreasury(
        address _treasury
    ) external onlyOwner returns (bool) {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        return true;
    }
}
