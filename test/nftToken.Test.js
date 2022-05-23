const { expect } = require("chai");

let NFT;
let nft;
let deployer;
let addr1;
let URI = "sample URI";

beforeEach(async function () {
  // Get the ContractFactories and Signers
  NFT = await ethers.getContractFactory("NFTContract");
  [deployer, addr1] = await ethers.getSigners();

  // deployed marketplace contract address
  nft = await NFT.deploy("0xa513E6E4b8f2a923D98304ec87F64353C4D5C853");
  await nft.deployed();
});
describe("Minting NFTs", function () {
  it("Should track each minted NFT", async function () {
    // addr1 mints an nft
    nft = nft.connect(addr1);
    await nft.createToken(URI);
    expect(await nft.ownerOf(0)).to.equal(addr1.address);
    expect(await nft.balanceOf(addr1.address)).to.equal(1);
    expect(await nft.getApproved(0)).to.equal(
      "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853"
    );
  });
});
