// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DaoTreasury {
    IERC20 public immutable usdc;
    address public admin;

    struct Proposal {
        address recipient;
        uint256 amount;
        string reason;
        uint256 votes;
        bool executed;
        uint256 createdAt;
    }
    Proposal[] public proposals;
    mapping(address => bool) public isMember;
    mapping(uint256 => mapping(address => bool)) public voted;
    uint256 public memberCount;
    uint256 public quorum;

    event ProposalCreated(uint256 indexed id, address recipient, uint256 amount);
    event Voted(uint256 indexed id, address voter);
    event Executed(uint256 indexed id, address recipient, uint256 amount);

    constructor(address _usdc) {
        require(_usdc != address(0), "BAD_USDC");
        usdc = IERC20(_usdc);
        admin = msg.sender;
        isMember[msg.sender] = true;
        memberCount = 1;
        quorum = 1;
    }

    modifier onlyAdmin() { require(msg.sender == admin, "NOT_ADMIN"); _; }
    modifier onlyMember() { require(isMember[msg.sender], "NOT_MEMBER"); _; }

    function addMember(address m) external onlyAdmin { if (!isMember[m]) { isMember[m] = true; memberCount++; } }
    function setQuorum(uint256 q) external onlyAdmin { quorum = q; }

    function propose(address recipient, uint256 amount, string calldata reason) external onlyMember returns (uint256) {
        proposals.push(Proposal(recipient, amount, reason, 0, false, block.timestamp));
        emit ProposalCreated(proposals.length - 1, recipient, amount);
        return proposals.length - 1;
    }

    function vote(uint256 id) external onlyMember {
        require(!voted[id][msg.sender], "ALREADY_VOTED");
        voted[id][msg.sender] = true;
        proposals[id].votes++;
        emit Voted(id, msg.sender);
    }

    function execute(uint256 id) external onlyMember {
        Proposal storage p = proposals[id];
        require(!p.executed && p.votes >= quorum, "CANNOT");
        p.executed = true;
        require(usdc.transfer(p.recipient, p.amount), "TRANSFER_FAILED");
        emit Executed(id, p.recipient, p.amount);
    }
}
