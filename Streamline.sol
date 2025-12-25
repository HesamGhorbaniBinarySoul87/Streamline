// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from,address to,uint256 value) external returns (bool);
}

contract MiniFlux {
    error NotSender();
    error NotRecipient();
    error ZeroAmount();
    error InvalidTime();
    error NothingToClaim();

    event StreamCreated(uint256 id, address sender, address recipient, address token, uint128 total, uint64 start, uint64 end);
    event Claimed(uint256 id, address recipient, uint128 amount);
    event StreamCanceled(uint256 id, uint128 refunded, uint128 claimed);

    struct Stream {
        address sender;
        address recipient;
        address token;
        uint128 total;
        uint128 claimed;
        uint64 start;
        uint64 end;
        bool cancelable;
    }

    uint256 public nextId;
    mapping(uint256 => Stream) public streams;

    modifier onlySender(uint256 id) {
        if (msg.sender != streams[id].sender) revert NotSender();
        _;
    }

    modifier onlyRecipient(uint256 id) {
        if (msg.sender != streams[id].recipient) revert NotRecipient();
        _;
    }

    function createStream(address recipient, address token, uint128 total, uint64 start, uint64 end, bool cancelable) external returns (uint256 id) {
        if (total == 0) revert ZeroAmount();
        if (end <= start) revert InvalidTime();

        id = ++nextId;
        streams[id] = Stream(msg.sender, recipient, token, total, 0, start, end, cancelable);
        bool ok = IERC20(token).transferFrom(msg.sender, address(this), total);
        require(ok, "TRANSFER_FAIL");

        emit StreamCreated(id, msg.sender, recipient, token, total, start, end);
    }

    function accrued(uint256 id) public view returns (uint128) {
        Stream memory s = streams[id];
        if (block.timestamp <= s.start) return 0;
        if (block.timestamp >= s.end) return s.total - s.claimed;
        uint256 vested = (uint256(s.total) * (block.timestamp - s.start)) / (s.end - s.start);
        return uint128(vested - s.claimed);
    }

    function claim(uint256 id) external onlyRecipient(id) {
        uint128 amount = accrued(id);
        if (amount == 0) revert NothingToClaim();
        streams[id].claimed += amount;
        emit Claimed(id, msg.sender, amount);
        IERC20(streams[id].token).transfer(msg.sender, amount);
    }

    function cancel(uint256 id) external onlySender(id) {
        Stream memory s = streams[id];
        if (!s.cancelable) revert("Not cancelable");
        uint128 claimable = accrued(id);
        uint128 remainder = s.total - s.claimed - claimable;
        delete streams[id];
        if (claimable > 0) IERC20(s.token).transfer(s.recipient, claimable);
        if (remainder > 0) IERC20(s.token).transfer(s.sender, remainder);
        emit StreamCanceled(id, remainder, claimable);
    }
}