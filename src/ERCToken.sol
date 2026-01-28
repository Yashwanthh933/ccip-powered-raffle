//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import{AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import{ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ERCToken is ERC20,ERC20Burnable,Ownable,AccessControl
{

    error InValidAddress();

    bytes32 private MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    event MintAndBurnRoleUpdated(address indexed);
    
    constructor() ERC20("ccip_lottery","CLY")Ownable(msg.sender)
    {
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
    function grantMintAndBurnRole(address _account) public onlyOwner
    {
        if(_account == address(0)) revert InValidAddress();
        _grantRole(MINT_AND_BURN_ROLE,_account);
        emit MintAndBurnRoleUpdated(_account);
    }
    function mint(address to,uint256 amount) external onlyRole(MINT_AND_BURN_ROLE)
    {
        _mint(to,amount);
    }
    function decimals() public pure override returns(uint8)
    {
        return 18;
    }

}