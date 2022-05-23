const { expect } = require("chai");
const { BigNumber } = require("ethers");

describe("ERCToken.sol", () => {
    
    beforeEach(async () => {
        [owner, alice, bob] = await ethers.getSigners();
        initialSupply = BigNumber.from(100000);
        contractFactory = await ethers.getContractFactory("ERCToken");
        contract = await contractFactory.deploy(initialSupply);
        ownerAddress = await owner.getAddress();
        aliceAddress = await alice.getAddress();
        bobAddress = await bob.getAddress();
    });

    describe("Correct setup", () => {
        it("should be named 'DKToken", async () => {
            const name = await contract.name();
            expect(name).to.equal("DKToken");
        });
        
        it("owner should have all the supply", async () => {
            const ownerBalance = await contract.balanceOf(ownerAddress);
            expect(ownerBalance).to.equal(initialSupply);
        });
    });
});