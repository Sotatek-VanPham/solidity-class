// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SwapContract is Initializable{
    enum Status {
        Pending,
        Approved,
        Rejected,
        Canceled
    }

    struct SwapRequest {
        address sender;
        address receiver;
        uint256 amount;
        Status status;
    }

    mapping(uint256 => SwapRequest) public swapRequests;
    address owner;
    uint256 public nextRequestId;
    address public treasury;
    bool private _locked;
    uint public constant FEE = 5;
    bool private _initialized;

    event SwapRequestCreated(
        uint256 indexed requestId,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        Status status
    );
    event SwapRequestStatusChanged(uint256 indexed requestId, Status status);

    function initialize() public initializer {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner address");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    function createSwapRequest(
        address _receiver,
        uint256 _amount
    ) external payable {
        require(_receiver != address(0), "Invalid receiver address");

        swapRequests[nextRequestId] = SwapRequest(
            msg.sender,
            _receiver,
            _amount,
            Status.Pending
        );
        emit SwapRequestCreated(
            nextRequestId,
            msg.sender,
            _receiver,
            _amount,
            Status.Pending
        );
        nextRequestId++;
    }

    function approveSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can approve");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        uint256 feeAmount = (request.amount * FEE) / 100;
        uint256 transferAmount = request.amount - feeAmount;
        payable(request.sender).transfer(transferAmount);
        payable(treasury).transfer(feeAmount);

        request.status = Status.Approved;
        emit SwapRequestStatusChanged(_requestId, Status.Approved);
    }

    function rejectSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.receiver == msg.sender, "Only receiver can reject");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        request.status = Status.Rejected;
        emit SwapRequestStatusChanged(_requestId, Status.Rejected);
    }

    function cancelSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.sender == msg.sender, "Only sender can cancel");
        require(
            request.status == Status.Pending,
            "Swap request status is not pending"
        );

        payable(request.sender).transfer(request.amount);
        request.status = Status.Canceled;
        emit SwapRequestStatusChanged(_requestId, Status.Canceled);
    }

    function setTreasury(address _treasury) external onlyOwner {
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
