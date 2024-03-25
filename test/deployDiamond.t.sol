// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/WOWToken.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/AUCFacet.sol";
import "../contracts/facets/AuctionHouseFacet.sol";

import "../contracts/libraries/LibBurn.sol";
import "../contracts/libraries/LibAuctionStorage.sol";
import "../contracts/ERC721Token.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    WOWToken wow;
    AUCFacet aucFacet;
    AuctionHouseFacet ahFacet;
    ERC721Token erc721Token;

    address AUCOwner = address(0xa);
    address NFTSeller = address(0xe);
    address Bidder1 = address(0xb);
    address Bidder2 = address(0xc);
    address Bidder3 = address(0xd);

    AUCFacet boundAUC;
    AuctionHouseFacet boundAuctionHouse;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        // wow = new WOWToken(address(diamond));
        aucFacet = new AUCFacet();
        ahFacet = new AuctionHouseFacet(address(aucFacet));
        erc721Token = new ERC721Token();

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
                facetAddress: address(aucFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AUCFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(ahFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionHouseFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //set rewardToken
        // diamond.setRewardToken(address(aucFacet));
        AUCOwner = mkaddr("AUC Token Owner");
        Bidder1 = mkaddr("Bidder 1");
        Bidder2 = mkaddr("Bidder 2");
        Bidder3 = mkaddr("Bidder 3");
        NFTSeller = mkaddr("NFT Seller");

        //mint test tokens
        AUCFacet(address(diamond)).mintTo(AUCOwner);

        boundAUC = AUCFacet(address(diamond));
        boundAuctionHouse = AuctionHouseFacet(address(diamond));

        //set rewardToken
        diamond.setRewardToken(address(boundAUC));
    }

    function testAUCMint() public {
        switchSigner(AUCOwner);
        uint256 balance = boundAUC.balanceOf(AUCOwner);
        assertTrue(balance == 100_000_000e18, "Unsuccessful Minting");
    }

    function testAUCApproval() public {
        switchSigner(AUCOwner);
        boundAUC.approve(Bidder1, 70_000_000e18);
        uint256 allowance = boundAUC.allowance(AUCOwner, Bidder1);
        assertTrue(allowance == 70_000_000e18, "Allowance is not equal to 70_000_000e18");
    }

    function testTransfer() public {
        switchSigner(AUCOwner);
        boundAUC.transfer(Bidder1, 40_000_000e18);

        uint256 balanceOfA = boundAUC.balanceOf(AUCOwner);
        assertTrue(balanceOfA == 60_000_000e18, "Balance after transfer is not equal to 60_000_000e18");

        uint256 balanceOfB = boundAUC.balanceOf(Bidder1);
        assertTrue(balanceOfB == 40_000_000e18, "Balance after transfer is not equal to 60_000_000e18");
    }

    function testAUCTransferFrom() public {
        switchSigner(AUCOwner);

        boundAUC.approve(address(diamond), 100_000_000e18);
        boundAUC.allowance(AUCOwner, address(diamond));
        boundAUC.transferFrom(AUCOwner, Bidder1, 40_000_000e18);

        uint256 balance = boundAUC.balanceOf(Bidder1);
        assertTrue(balance == 40_000_000e18, "Balance after transfer is not equal to 40_000_000e18");
    }

    function testTransferRevert() public {
        vm.expectRevert("ERC20: Not enough tokens to transfer");

        boundAUC.transfer(Bidder1, 100_000_000e18);
    }

    // BURN IS NOW AN INTERNAL FUNCTION
    // function testBurn() public {
    //     switchSigner(AUCOwner);

    //     boundAuctionHouse.burn(40_000_000e18);
    //     console.log("success");
    // }

    function testCreateAuction() public {
        // switchSigner(AUCOwner);
        
        // boundAUC.transfer(Bidder1, 10_000_000e18);
        // boundAUC.transfer(Bidder2, 20_000_000e18);
        // boundAUC.transfer(Bidder3, 40_000_000e18);

        switchSigner(NFTSeller);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);

        boundAuctionHouse.createAuction(1, 5 days, false, 8_000_000e18, address(erc721Token));
    }

    function testBid() public {

        switchSigner(NFTSeller);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);

        boundAuctionHouse.createAuction(1, 5 days, false, 8_000_000e18, address(erc721Token));

        switchSigner(AUCOwner);
        boundAUC.transfer(Bidder1, 40_000_000e18);

        switchSigner(Bidder1);
        boundAUC.approve(address(diamond), 40_000_000e18);
        boundAuctionHouse.bid(1, 15_000_000e18);
    }

    function testNextBid() public {

        switchSigner(NFTSeller);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);

        boundAuctionHouse.createAuction(1, 5 days, false, 8_000_000e18, address(erc721Token));

        switchSigner(AUCOwner);
        boundAUC.transfer(Bidder1, 20_000_000e18);
        boundAUC.transfer(Bidder2, 20_000_000e18);

        switchSigner(Bidder1);
        boundAUC.approve(address(diamond), 20_000_000e18);
        boundAuctionHouse.bid(1, 15_000_000e18);

        switchSigner(Bidder2);
        boundAUC.approve(address(diamond), 20_000_000e18);
        boundAuctionHouse.bid(1, 18_000_000e18);
    }

    function testMultipleBidders() public {

        switchSigner(NFTSeller);
        erc721Token.mint();
        erc721Token.approve(address(diamond), 1);

        boundAuctionHouse.createAuction(1, 5 days, false, 8_000_000e18, address(erc721Token));

        switchSigner(AUCOwner);
        boundAUC.transfer(Bidder1, 20_000_000e18);
        boundAUC.transfer(Bidder2, 20_000_000e18);
        boundAUC.transfer(Bidder3, 20_000_000e18);

        switchSigner(Bidder1);
        boundAUC.approve(address(diamond), 20_000_000e18);
        boundAuctionHouse.bid(1, 15_000_000e18);

        switchSigner(Bidder2);
        boundAUC.approve(address(diamond), 20_000_000e18);
        boundAuctionHouse.bid(1, 18_000_000e18);

        switchSigner(Bidder3);
        boundAUC.approve(address(diamond), 20_000_000e18);
        boundAuctionHouse.bid(1, 20_000_000e18);
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
