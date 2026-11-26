import { expect } from "chai";
import { anyValue } from "@nomicfoundation/hardhat-ethers-chai-matchers/withArgs";

import { network } from "hardhat";

const { ethers, networkHelpers } = await network.create();
const { time } = networkHelpers;



describe.only(" Escrow Contract", function() {
    const DURATION = 3600; // 1 hour
    const DEPOSIT_AMOUNT = ethers.parseEther("1");
    let escrow: any;
    let buyer: any;
    let seller: any;
    let stranger: any; // added this stranger variable only because i wanted to test }
    const State = {
      AWAITING_PAYMENT: 0,
      PENDING: 1,
      PAID: 2,
      REFUNDED: 3,
    };// but why is the state needed here but in the adashe contract
    
  beforeEach(async function () {
      [buyer, seller,stranger] = await ethers.getSigners();// is line 27 dependent on this line or the state variable i declarec
       escrow = await ethers.deployContract("MyEscrow",[buyer, seller,DURATION]);
       return { buyer , seller, stranger};
        
  }); 

  describe.only("Deployment", function () {
    it("sets buyer, seller and deadline correctly", async function () {
      const block = await ethers.provider.getBlock("latest");
    
       if (!block) {
    throw new Error("Latest block not found");
  }
      expect(await escrow.buyer()).to.equal(buyer.address);
      expect(await escrow.seller()).to.equal(seller.address);
      expect( await escrow.deadline()).to.equal(block.timestamp + DURATION);
    });

    it("starts in AWAITING_PAYMENT state with zero amount", async function () {
      expect (await escrow.amount()).to.equal(0);
      expect( await escrow.state()).to.equal(State.AWAITING_PAYMENT);
    });
  });

  describe.only("deposit()", function () {
    it("lets the buyer deposit, updates amount/state and emits Deposited", async function () {
      await expect(escrow.connect(buyer).deposit({ value: DEPOSIT_AMOUNT }))
       .to.emit(escrow, "Deposited")// .to.emit is used to test events in hardhat
        .withArgs(buyer.address, DEPOSIT_AMOUNT, anyValue); //and it should emit with args

      expect(await escrow.amount()).to.equal(DEPOSIT_AMOUNT);
      expect(await escrow.state()).to.equal(State.PENDING);
      expect(await ethers.provider.getBalance(await escrow.getAddress())).to.equal(
        DEPOSIT_AMOUNT
      );
    });

    it("reverts if called by anyone other than the buyer", async function () {
      await expect(
        escrow.connect(seller).deposit({ value: DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Only Buyer can call this function");

      await expect(
        escrow.connect(stranger).deposit({ value: DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Only Buyer can call this function");
    });

    it("reverts on a zero-value deposit", async function () {
      await expect(
        escrow.connect(buyer).deposit({ value: 0 })
      ).to.be.revertedWith("Amount must be greater than zero");
    });

    it("reverts on a second deposit (already past AWAITING_PAYMENT)", async function () {
      await escrow.connect(buyer).deposit({ value: DEPOSIT_AMOUNT });// this is the first deposit 

      await expect(
        escrow.connect(buyer).deposit({ value: DEPOSIT_AMOUNT })
      ).to.be.revertedWith("Invalid state for this action");
    });
  });

  describe.only("release()", function () {
    beforeEach(async function () {
      await escrow.connect(buyer).deposit({ value: DEPOSIT_AMOUNT });
    });

    it("lets the buyer release funds to the seller and emits Released", async function () {
      const before = await ethers.provider.getBalance(seller.address);

      await expect(escrow.connect(buyer).release())
        .to.emit(escrow, "Released")
        .withArgs(seller.address, DEPOSIT_AMOUNT, anyValue);

      const after = await ethers.provider.getBalance(seller.address);
      expect(after - before).to.equal(DEPOSIT_AMOUNT);
      expect(await escrow.state()).to.equal(State.PAID);
    });

    it("works even after the deadline has passed (no deadline gate on release)", async function () {
      await time.increase(DURATION + 1);

      const before = await ethers.provider.getBalance(seller.address);
      await escrow.connect(buyer).release();
      const after = await ethers.provider.getBalance(seller.address);

      expect(after - before).to.equal(DEPOSIT_AMOUNT);
    });

    it("reverts if called by anyone other than the buyer", async function () {
      await expect(escrow.connect(seller).release()).to.be.revertedWith(
        "Only Buyer can call this function"
      );
      await expect(escrow.connect(stranger).release()).to.be.revertedWith(
        "Only Buyer can call this function"
      );
    });

    it("reverts if called twice", async function () {
      await escrow.connect(buyer).release();

      await expect(escrow.connect(buyer).release()).to.be.revertedWith(
        "Invalid state for this action"
      );
    });
  });

  it("release() reverts if there is nothing pending (no deposit yet)", async function () {
    await expect(escrow.connect(buyer).release()).to.be.revertedWith(
      "Invalid state for this action"
    );
  });

  describe.only("refund()", function () {
    beforeEach(async function () {
      await escrow.connect(buyer).deposit({ value: DEPOSIT_AMOUNT });
    });

    it("reverts before the deadline has passed", async function () {
      await expect(escrow.connect(buyer).refund()).to.be.revertedWith(
        "Deadline has not passed yet"
      );
    });

    it("lets the buyer reclaim funds after the deadline and emits Refunded", async function () {
      await time.increase(DURATION + 1);

      await expect(escrow.connect(buyer).refund())
        .to.emit(escrow, "Refunded")
        .withArgs(buyer.address, DEPOSIT_AMOUNT, anyValue);

      expect(await escrow.state()).to.equal(State.REFUNDED);
    });

    it("reverts if called by anyone other than the buyer", async function () {
      await time.increase(DURATION + 1);

      await expect(escrow.connect(seller).refund()).to.be.revertedWith(
        "Only Buyer can call this function"
      );
      await expect(escrow.connect(stranger).refund()).to.be.revertedWith(
        "Only Buyer can call this function"
      );
    });

    it("reverts if already released", async function () {
      await escrow.connect(buyer).release();
      await time.increase(DURATION + 1);

      await expect(escrow.connect(buyer).refund()).to.be.revertedWith(
        "Invalid state for this action"
      );
    });
  });

  it("refund() reverts if there is nothing pending (no deposit yet)", async function () {
    await time.increase(DURATION + 1);

    await expect(escrow.connect(buyer).refund()).to.be.revertedWith(
      "Invalid state for this action"
    );
  });
});