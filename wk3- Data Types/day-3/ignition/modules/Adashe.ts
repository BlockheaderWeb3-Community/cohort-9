import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const maxPeople = 10;
const amount = 10
const duration = 60
export default buildModule("AdasheModule", (m) => {
  const adashe = m.contract("Adashe",[maxPeople, amount, duration]);

  return { adashe };
});
