// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/facets/StakingFacet.sol";

import "../contracts/WOWToken.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/AUCFacet.sol";
// import "../contracts/facets/AuctionHouseFacet.sol";

import "../contracts/libraries/LibAppStorage.sol";
import "../contracts/libraries/LibAuctionStorage.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    StakingFacet sFacet;
    WOWToken wow;
    AUCFacet aucFacet;
    // AuctionHouseFacet ahFacet;

    address A = address(0xa);
    address B = address(0xb);

    StakingFacet boundStaking;
    AUCFacet boundAUC;
    // AuctionHouseFacet boundAuctionHouse;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        sFacet = new StakingFacet();
        wow = new WOWToken(address(diamond));
        aucFacet = new AUCFacet();
        // ahFacet = new AuctionHouseFacet(address(diamond));

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(sFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StakingFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(aucFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AUCFacet")
            })
        );

        // cut[4] = (
        //     FacetCut({
        //         facetAddress: address(ahFacet),
        //         action: FacetCutAction.Add,
        //         functionSelectors: generateSelectors("AuctionHouseFacet")
        //     })
        // );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //set rewardToken
        diamond.setRewardToken(address(wow));
        A = mkaddr("staker a");
        B = mkaddr("staker b");

        //mint test tokens
        AUCFacet(address(diamond)).mintTo(A);

        boundStaking = StakingFacet(address(diamond));
        boundAUC = AUCFacet(address(diamond));
        // boundAuctionHouse = AuctionHouseFacet(address(diamond));
    }

    function testAUCMint() public {
        switchSigner(A);
        uint256 balance = boundAUC.balanceOf(A);
        assertTrue(balance == 100_000_000e18, "Unsuccessful Minting");
    }

    function testAUCApproval() public {
        switchSigner(A);
        boundAUC.approve(B, 70_000_000e18);
        uint256 allowance = boundAUC.allowance(A, B);
        assertTrue(allowance == 70_000_000e18, "Allowance is not equal to 70_000_000e18");
    }

    function testTransfer() public {
        switchSigner(A);
        boundAUC.transfer(B, 40_000_000e18);

        uint256 balanceOfA = boundAUC.balanceOf(A);
        assertTrue(balanceOfA == 60_000_000e18, "Balance after transfer is not equal to 60_000_000e18");

        uint256 balanceOfB = boundAUC.balanceOf(B);
        assertTrue(balanceOfB == 40_000_000e18, "Balance after transfer is not equal to 60_000_000e18");
    }

    function testTransferRevert() public {
        vm.expectRevert("ERC20: Not enough tokens to transfer");

        boundAUC.transfer(B, 100_000_000e18);
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }

        // uint256[]=new uint256[](2)
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
