import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.create();


describe("Adashe Contract", function () {
    let adashe: any;
    const maxPeople = 3;
    const amountPerHead = 100;
    const duration = 30;
    let owner: any;
    let addr1: any;
    let addr2: any;
    let addr3: any;
    let addr4: any;
    let addr5: any;
    
    beforeEach(async function () {
    adashe = await ethers.deployContract("Adashe", [maxPeople, amountPerHead, duration]);
     [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
     return { owner, addr1, addr2, addr3, addr4, addr5 };
        
    });

describe("Deployment Successful", function () {
    it("Should set the number of people", async function () {
        const blockchainNoOfPeople = await adashe.maxPeople();
        expect(blockchainNoOfPeople).to.equal(maxPeople);
        console.log("blockchainNoOfPeople", blockchainNoOfPeople);
    });
    it("Should set the amount per head", async function () {
        const blockchainAmountPerHead = await adashe.amountPerHead();
        expect(blockchainAmountPerHead).to.equal(amountPerHead);
    });
    it("Should set the duration", async function () {
        const blockchainDuration = await adashe.duration();
        expect(blockchainDuration).to.equal(duration);
    });
    it("Should set the status to PENDING", async function () {
        const blockchainStatus = await adashe.status();
        expect(blockchainStatus).to.equal(0);
    });
});

describe.only("Registering a new member", function () {
    it("Should register a new member", async function () {
       await adashe.connect(addr1).registerForAdashe("John Doe");
       expect(await adashe.noOfPeople()).to.equal(1);

       const member1= await adashe.getAdasheMember(1);
       expect(member1.name).to.equal("John Doe");
       expect(member1.addr).to.equal(addr1.address);
       expect(member1.turn).to.equal(1);
       expect(member1.hasPaid).to.equal(false);

       const isRegistered = await adashe.isRegistered(addr1.address);
       expect(isRegistered).to.equal(true);
       
    });

    it("Should revert when the same address registers again", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await expect(adashe.connect(addr1).registerForAdashe("John Doe")).to.be.revertedWith("AlreadyRegistered");
    });

    it("Should revert when the name is empty", async function () {
        await expect(adashe.connect(addr1).registerForAdashe("")).to.be.revertedWith("EmptyName");
    });

    it("Should revert when the number of people is full", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        await expect(adashe.connect(addr4).registerForAdashe("Jack Doe")).to.be.revertedWith("AdasheFull");
    });
});
    
});
