// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapContract is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address owner;
    address public treasury;
    uint256 public constant FEE = 5;

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
        require(_amountSend != 0, "Invalid amount");
        require(_amountReceive != 0, "Invalid amount");

        uint256 nonce = nonces[msg.sender]++;

        bytes32 requestId = keccak256(abi.encode(msg.sender, nonce));

        swapRequests[requestId] = SwapRequest(
            msg.sender,
            _receiver,
            _tokenSend,
            _tokenReceive,
            _amountSend,
            _amountReceive,
            Status.Pending
        );

        IERC20(_tokenSend).safeTransferFrom(
            msg.sender,
            address(this),
            _amountSend
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
        SwapRequest memory request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can approve");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        uint256 sendFee = (request.amountSend * FEE) / 100;
        uint256 receiveFee = (request.amountReceive * FEE) / 100;

        swapRequests[_requestId].status = Status.Approved;

        IERC20(request.tokenReceive).safeTransferFrom(
            msg.sender,
            address(this),
            request.amountReceive
        );

        IERC20(request.tokenReceive).safeTransfer(treasury, receiveFee);

        IERC20(request.tokenReceive).safeTransfer(
            request.sender,
            request.amountReceive - receiveFee
        );

        IERC20(request.tokenSend).safeTransfer(treasury, sendFee);

        IERC20(request.tokenSend).safeTransfer(
            request.receiver,
            request.amountSend - sendFee
        );

        emit SwapRequestStatusChanged(_requestId, Status.Approved);
    }

    function rejectSwapRequest(bytes32 _requestId) external nonReentrant {
        SwapRequest memory request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can reject");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        swapRequests[_requestId].status = Status.Rejected;

        IERC20(request.tokenSend).safeTransfer(
            request.sender,
            request.amountSend
        );

        emit SwapRequestStatusChanged(_requestId, Status.Rejected);
    }

    function cancelSwapRequest(bytes32 _requestId) external nonReentrant {
        SwapRequest memory request = swapRequests[_requestId];
        require(request.sender == msg.sender, "Only sender can cancel");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        swapRequests[_requestId].status = Status.Canceled;

        IERC20(request.tokenSend).safeTransfer(
            request.sender,
            request.amountSend
        );

        emit SwapRequestStatusChanged(_requestId, Status.Canceled);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }
}
