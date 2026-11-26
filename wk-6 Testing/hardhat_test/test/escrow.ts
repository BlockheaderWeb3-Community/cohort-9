import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.create();

describe("Escrow", function () {

    let escrow: any;

    let buyer: any;
    let seller: any;
    let holder: any;

    beforeEach(async function () {

        [buyer, seller, holder] =
            await ethers.getSigners();

        escrow =
            await ethers.deployContract("Escrow");

    });

    // ─── createEscrow ─────────────────────────────────────────────────────────

    describe("createEscrow", function () {

        it("should create an escrow and emit EscrowCreated", async function () {

            await expect(
                escrow.createEscrow(buyer.address, seller.address)
            )
                .to.emit(escrow, "EscrowCreated")
                .withArgs(1, buyer.address, seller.address);

            const deal = await escrow.getEscrow(1);
            expect(deal.id).to.equal(1);
            expect(deal.buyer).to.equal(buyer.address);
            expect(deal.seller).to.equal(seller.address);
            expect(deal.amount).to.equal(0);
            expect(deal.state).to.equal(0); // State.OPEN

        });

        it("should increment escrowCount on each creation", async function () {

            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.createEscrow(buyer.address, seller.address);

            expect(await escrow.escrowCount()).to.equal(2);

        });

        it("should revert if buyer address is zero", async function () {

            await expect(
                escrow.createEscrow(ethers.ZeroAddress, seller.address)
            ).to.be.revertedWithCustomError(escrow, "InvalidAddress");

        });

        it("should revert if seller address is zero", async function () {

            await expect(
                escrow.createEscrow(buyer.address, ethers.ZeroAddress)
            ).to.be.revertedWithCustomError(escrow, "InvalidAddress");

        });

    });

    // ─── deposit ──────────────────────────────────────────────────────────────

    describe("deposit", function () {

        it("should revert for zero amount", async function () {

            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(buyer).deposit(1, { value: ethers.parseEther("0") })
            ).to.be.revertedWithCustomError(escrow, "ZeroAmount");

        });

        it("should allow buyer to deposit and emit Deposited", async function () {

            const amount = ethers.parseEther("1");

            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(buyer).deposit(1, { value: amount })
            )
                .to.emit(escrow, "Deposited")
                .withArgs(1, buyer.address, amount);

        });

        it("should revert if caller is not buyer", async function () {

            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(holder).deposit(1, { value: ethers.parseEther("1") })
            ).to.be.revertedWithCustomError(escrow, "NotBuyer");

        });

        it("should set state to FUNDED after deposit", async function () {

            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: ethers.parseEther("1") });

            const deal = await escrow.getEscrow(1);
            expect(deal.state).to.equal(1); // State.FUNDED

        });

        it("should revert if escrow is not in OPEN state", async function () {

            const amount = ethers.parseEther("1");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });

            // Already FUNDED — second deposit should fail
            await expect(
                escrow.connect(buyer).deposit(1, { value: amount })
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

    });

    // ─── confirmDelivery ──────────────────────────────────────────────────────

    describe("confirmDelivery", function () {

        it("should confirm delivery, pay seller, and emit DeliveryConfirmed", async function () {

            const amount = ethers.parseEther("1");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });

            const sellerBefore = await ethers.provider.getBalance(seller.address);

            await expect(
                escrow.connect(buyer).confirmDelivery(1)
            )
                .to.emit(escrow, "DeliveryConfirmed")
                .withArgs(1, seller.address, amount);

            const sellerAfter = await ethers.provider.getBalance(seller.address);
            expect(sellerAfter - sellerBefore).to.equal(amount);

            const deal = await escrow.getEscrow(1);
            expect(deal.state).to.equal(2); // State.COMPLETE
            expect(deal.amount).to.equal(0);

        });

        it("should revert if caller is not buyer", async function () {

            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: ethers.parseEther("1") });

            await expect(
                escrow.connect(holder).confirmDelivery(1)
            ).to.be.revertedWithCustomError(escrow, "NotBuyer");

        });

        it("should revert if state is not FUNDED", async function () {

            // Still OPEN — never deposited
            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(buyer).confirmDelivery(1)
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

        it("should revert if already COMPLETE", async function () {

            const amount = ethers.parseEther("1");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });
            await escrow.connect(buyer).confirmDelivery(1);

            await expect(
                escrow.connect(buyer).confirmDelivery(1)
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

    });

    

    describe("cancelEscrow", function () {

        it("should cancel an OPEN escrow and emit EscrowCancelled", async function () {

            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(buyer).cancelEscrow(1)
            )
                .to.emit(escrow, "EscrowCancelled")
                .withArgs(1);

            const deal = await escrow.getEscrow(1);
            expect(deal.state).to.equal(3); // State.CANCELLED

        });

        it("should revert if caller is not buyer", async function () {

            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(holder).cancelEscrow(1)
            ).to.be.revertedWithCustomError(escrow, "NotBuyer");

        });

        it("should revert if escrow is not OPEN (e.g. FUNDED)", async function () {

            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: ethers.parseEther("1") });

            await expect(
                escrow.connect(buyer).cancelEscrow(1)
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

    });

    // ─── refund ───────────────────────────────────────────────────────────────

    describe("refund", function () {

        it("should refund buyer and set state to CANCELLED", async function () {

            const amount = ethers.parseEther("1");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });

            const buyerBefore = await ethers.provider.getBalance(buyer.address);

            await escrow.connect(seller).refund(1);

            const buyerAfter = await ethers.provider.getBalance(buyer.address);
            expect(buyerAfter - buyerBefore).to.equal(amount);

            const deal = await escrow.getEscrow(1);
            expect(deal.state).to.equal(3); // State.CANCELLED
            expect(deal.amount).to.equal(0);

        });

        it("should revert if caller is not seller", async function () {

            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: ethers.parseEther("1") });

            await expect(
                escrow.connect(holder).refund(1)
            ).to.be.revertedWithCustomError(escrow, "NotSeller");

        });

        it("should revert if state is not FUNDED", async function () {

            // OPEN state — no deposit yet
            await escrow.createEscrow(buyer.address, seller.address);

            await expect(
                escrow.connect(seller).refund(1)
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

        it("should revert if already CANCELLED", async function () {

            const amount = ethers.parseEther("1");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });
            await escrow.connect(seller).refund(1);

            await expect(
                escrow.connect(seller).refund(1)
            ).to.be.revertedWithCustomError(escrow, "InvalidState");

        });

    });

   

    describe("getEscrow", function () {

        it("should return correct escrow data", async function () {

            await escrow.createEscrow(buyer.address, seller.address);

            const deal = await escrow.getEscrow(1);

            expect(deal.id).to.equal(1);
            expect(deal.buyer).to.equal(buyer.address);
            expect(deal.seller).to.equal(seller.address);
            expect(deal.amount).to.equal(0);
            expect(deal.state).to.equal(0); // State.OPEN

        });

        it("should reflect updated state after deposit", async function () {

            const amount = ethers.parseEther("2");
            await escrow.createEscrow(buyer.address, seller.address);
            await escrow.connect(buyer).deposit(1, { value: amount });

            const deal = await escrow.getEscrow(1);

            expect(deal.amount).to.equal(amount);
            expect(deal.state).to.equal(1); // State.FUNDED

        });

    });

});
