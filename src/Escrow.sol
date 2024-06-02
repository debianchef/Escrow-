// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Escrow {
    struct Deposit {
        uint256 amount;
        bool fundsReleased;
    }

    address public admin;
    mapping(address => Deposit) public deposits;
    mapping(address => address payable) public receivers;

    event ReceiverSet(address indexed depositor, address receiver);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsReleased(address indexed depositor, address receiver, uint256 amount);
    event RefundIssued(address indexed depositor, uint256 amount);

    error InvalidReceiverDepositor();

    /**
     * @dev Sets the admin of the contract.
     * @param _admin The address of the admin.
     */
    constructor(address _admin) {
        admin = _admin;
    }

    /**
     * @dev Modifier to restrict function access to the admin only.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this.");
        _;
    }

    /**
     * @dev Sets or changes the receiver address for the sender.
     * @param _receiver The address of the receiver.
     */
    function setReceiver(address payable _receiver) public {
        receivers[msg.sender] = _receiver;
        emit ReceiverSet(msg.sender, _receiver);
    }

    /**
     * @dev Deposits funds into the contract and associates it with the sender.
     * @param _amount The amount to deposit in wei.
     * Requirements:
     * - The receiver address for the sender must be set.
     * - The sender must not have an existing deposit.
     * - The deposit amount must be greater than zero.
     * - The sent ether value must match the deposit amount.
     */
    function deposit(uint256 _amount) public payable {
        if (receivers[msg.sender] == address(0) || deposits[msg.sender].amount != 0) {
            revert InvalidReceiverDepositor();
        }
        require(_amount > 0, "Deposit amount must be greater than zero.");
        require(msg.value == _amount, "Incorrect ether sent.");

        deposits[msg.sender] = Deposit({
            amount: _amount,
            fundsReleased: false
        });

        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Releases the deposited funds to the receiver set by the sender.
     * Requirements:
     * - The funds must not have been released already.
     * - The deposit amount must be greater than zero.
     */
    function releaseFunds() public {
        Deposit storage userDeposit = deposits[msg.sender];
        require(!userDeposit.fundsReleased, "Funds have already been released.");
        require(userDeposit.amount > 0, "No funds to release.");

        userDeposit.fundsReleased = true;
        uint256 amountToTransfer = userDeposit.amount;
        userDeposit.amount = 0; // Reset the amount to zero
        address payable receiver = receivers[msg.sender];
        receiver.transfer(amountToTransfer);

        emit FundsReleased(msg.sender, receiver, amountToTransfer);
    }

    /**
     * @dev Allows the admin to refund the depositor's funds if they have not been released.
     * @param depositor The address of the depositor to refund.
     * Requirements:
     * - The funds must not have been released already.
     * - The deposit amount must be greater than zero.
     */
    function refund(address depositor) public onlyAdmin {
        Deposit storage userDeposit = deposits[depositor];
        require(!userDeposit.fundsReleased, "Funds have already been released.");
        require(userDeposit.amount > 0, "No funds to refund.");

        uint256 refundAmount = userDeposit.amount;
        userDeposit.amount = 0;
        userDeposit.fundsReleased = true;
        address payable _depositor = payable(depositor);

        _depositor.transfer(refundAmount);
        emit RefundIssued(depositor, refundAmount);
    }

    /**
     * @dev Fallback function to prevent direct ether transfers. Redirects to the deposit function.
     */
    receive() external payable {
        revert("Use the deposit function to send funds.");
    }
}
