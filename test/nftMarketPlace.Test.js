const { expect } = require("chai");
const { BigNumber } = require("ethers");

describe("NFTMarketplace", function () {
  let NFT;
  let nft;
  let ERC;
  let erc;
  let Marketplace;
  let marketplace;
  let deployer;
  let addr1;
  let addr2;
  let addr;
  let URI = "sample URI";

  beforeEach(async function () {
    // Get the ContractFactories and Signers
    ERC = await ethers.getContractFactory("ERCToken");
    erc = await ERC.deploy(BigNumber.from(100000));
    await erc.deployed();

    Marketplace = await ethers.getContractFactory("NFTMarketPlace");
    marketplace = await Marketplace.deploy(erc.address);
    await marketplace.deployed();

    // To deploy our contracts
    NFT = await ethers.getContractFactory("NFTContract");
    nft = await NFT.deploy(marketplace.address);
    await nft.deployed();

    [deployer, addr1, addr2, ...addr] = await ethers.getSigners();
  });

  describe("Deployment", function () {
    it("Should track name and symbol of the nft collection", async function () {
      const nftName = "DK NFT";
      const nftSymbol = "DK";
      expect(await nft.name()).to.equal(nftName);
      expect(await nft.symbol()).to.equal(nftSymbol);
    });
  });

  describe("Minting NFTs", function () {

    it("Should track each minted NFT", async function () {
      // addr1 mints an nft
      await nft.connect(addr1).createToken(URI)
      expect(await nft.ownerOf(0)).to.equal(addr1.address);
      expect(await nft.balanceOf(addr1.address)).to.equal(1);
      // addr2 mints an nft
      await nft.connect(addr2).createToken(URI)
      expect(await nft.ownerOf(0)).to.equal(addr1.address);
      expect(await nft.balanceOf(addr1.address)).to.equal(1);
    });
  })

  describe("Making marketplace items", function () {
    let price = 1000;
    let royality = 100;
    it("Should track newly created item, transfer NFT from seller to marketplace and emit nftTransferToMarket event", async function () {
      await nft.connect(addr1).createToken(URI);
      expect(await nft.ownerOf(0)).to.equal(addr1.address);
      expect(await nft.balanceOf(addr1.address)).to.equal(1);
      await nft.connect(addr1).approve(marketplace.address, 0);
      
      await expect(marketplace.connect(addr1).addItemToMarket(nft.address, 0, price, royality))
        .to.emit(marketplace, "nftTransferToMarket")
        .withArgs(0, 0, price, nft.address, addr1.address);

      expect(await nft.ownerOf(0)).to.equal(marketplace.address);
    });

    describe("Purchasing marketplace items", async function () {
        await erc
          .connect(deployer)
          .approve(marketplace.address, BigNumber.from(23400));

        const nftBeforePurchase = await nft.balanceOf(deployer.address);
        

        await expect(
          marketplace.connect(addr1).purchaseItem(0)
        ).to.be.revertedWith("seller should not be same as buyer");

        await expect(
          marketplace.connect(addr1).purchaseItem(1)
        ).to.be.revertedWith("item doesn't exist");

        await marketplace.connect(deployer).purchaseItem(0);
        expect(await nft.balanceOf(deployer.address)).to.equal(1);
        expect(await nft.balanceOf(addr1.address)).to.equal(0);

        await expect(
          marketplace.connect(deployer).purchaseItem(0)
        ).to.be.revertedWith("Item is sold out. Can't purchase.");

    });
});
});
