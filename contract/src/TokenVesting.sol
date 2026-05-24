// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    using SafeERC20 for IERC20;

    struct Vesting {
        uint256 total;
        uint256 claimed;
        uint256 start;
        uint256 duration;
    }

    mapping(address => Vesting) public vestings;

    event VestingCreated(address indexed user, uint256 amount, uint256 duration);

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function createVesting(address user, uint256 amount, uint256 duration) external onlyOwner {
        require(user != address(0), "zero address");
        require(amount > 0, "zero amount");
        require(duration > 0, "zero duration");

        vestings[user] = Vesting({total: amount, claimed: 0, start: block.timestamp, duration: duration});

        emit VestingCreated(user, amount, duration);
    }

    function releasableAmount(address user) public view returns (uint256) {
        Vesting memory v = vestings[user];

        if (v.total == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp - v.start;

        if (elapsed >= v.duration) {
            return v.total - v.claimed;
        }

        uint256 vested = (v.total * elapsed) / v.duration;

        return vested - v.claimed;
    }

    function claim() external {
        uint256 amount = releasableAmount(msg.sender);

        require(amount > 0, "nothing to claim");

        vestings[msg.sender].claimed += amount;

        token.safeTransfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }
}
