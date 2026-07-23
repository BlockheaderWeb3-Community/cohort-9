import { useWriteContract } from "wagmi"
import { openriverAbi, openriverAddress } from "../../contracts";
import { useState } from "react";


const Dashboard = () => {
    const { writeContract: mintNFT } = useWriteContract();
    const [tokenUrI, setTokenUrI] = useState("");
    const [royalty, setRoyalty] = useState(0);

    const handleMintNFT = async () => {
        mintNFT(
            {
                abi: openriverAbi,
                address: openriverAddress,
                functionName: "newItem",
                args: [
                    tokenUrI,
                    royalty
                ]
            }
        )
    }
    return (
        <div>
            <div className="">
                <input type="text" placeholder="Token URI" onChange={(e) => setTokenUrI(e.target.value)} />
                <input type="number" placeholder="Royalty" onChange={(e) => setRoyalty(Number(e.target.value))} />
                <button onClick={handleMintNFT}>Mint NFT</button>
            </div>
        </div>
    )
}

export default Dashboard