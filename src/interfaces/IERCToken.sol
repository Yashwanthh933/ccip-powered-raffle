//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
interface IERCToken
{
    function mint(address to,uint256 amount) external;
    function burnFrom(address from,uint256 amount) external;
    function grantMintAndBurnRole(address) external;
    function balanceOf(address account) external view returns (uint256);
}