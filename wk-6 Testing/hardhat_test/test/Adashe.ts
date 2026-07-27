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

describe("Registering a new member", function () {
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
        await expect(adashe.connect(addr1).registerForAdashe("John Doe")).to.be.revertedWithCustomError(adashe, "AlreadyRegistered");
    });

    it("Should revert when the name is empty", async function () {
        await expect(adashe.connect(addr1).registerForAdashe("")).to.be.revertedWithCustomError(adashe, "EmptyName");
    });

    it("Should revert when the number of people is full", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        await expect(adashe.connect(addr4).registerForAdashe("Jack Doe")).to.be.revertedWithCustomError(adashe, "AdasheFull");
    });


});

// Tests for the contribute() function.
// Note: maxPeople = 3, amountPerHead = 100. The circle only becomes PACKED
// (contributions allowed) after the 3rd member registers — that's when
// registerForAdashe() auto-calls _packAdashe().
describe("A Member Paying Contribution", function () {

    it("Should revert when contributing before the circle is packed", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await expect(
            adashe.connect(addr1).contribute({ value: amountPerHead })
        ).to.be.revertedWithCustomError(adashe, "AdasheNotPacked");
    });

    it("Should revert when a non-member tries to contribute", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        await expect(
            adashe.connect(addr4).contribute({ value: amountPerHead })
        ).to.be.revertedWithCustomError(adashe, "NotRegistered");
    });

    it("Should revert when the wrong amount is sent", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        await expect(
            adashe.connect(addr1).contribute({ value: amountPerHead + 1 })
        ).to.be.revertedWithCustomError(adashe, "InvalidAmount");
    });

    it("Should allow a registered member to contribute and mark them as paid", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        // Only addr1 pays. If ALL three paid, _distributePayout() resets
        // everyone's hasPaid back to false, so we check after a single payment.
        await adashe.connect(addr1).contribute({ value: amountPerHead });

        const member1 = await adashe.getAdasheMember(1);
        expect(member1.hasPaid).to.equal(true);
    });

    it("Should revert when a member contributes twice in the same round", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");
        await adashe.connect(addr2).registerForAdashe("Jane Doe");
        await adashe.connect(addr3).registerForAdashe("Jim Doe");
        await adashe.connect(addr1).contribute({ value: amountPerHead });
        await expect(
            adashe.connect(addr1).contribute({ value: amountPerHead })
        ).to.be.revertedWithCustomError(adashe, "AlreadyPaid");
    });

});

// Tests for getAdasheMember()
describe("Reading a member with getAdasheMember", function () {
    it("Should return the stored member data by id", async function () {
        await adashe.connect(addr1).registerForAdashe("John Doe");

        const member1 = await adashe.getAdasheMember(1);
        expect(member1.name).to.equal("John Doe");
        expect(member1.addr).to.equal(addr1.address);
        expect(member1.turn).to.equal(1);
        expect(member1.hasPaid).to.equal(false);
    });

    it("Should revert for an out-of-range id", async function () {
        // No one registered yet, so id 1 is out of range (noOfPeople = 0).
        await expect(adashe.getAdasheMember(1)).to.be.revertedWithCustomError(adashe, "InvalidPersonId");
    });

    it("Should revert for id 0", async function () {
        await expect(adashe.getAdasheMember(0)).to.be.revertedWithCustomError(adashe, "InvalidPersonId");
    });
});

});
