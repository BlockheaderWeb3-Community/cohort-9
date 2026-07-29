import { useWriteContract } from "wagmi";
import { openriverAbi, openriverAddress } from "../../contracts";
import { useState } from "react";

const Dashboard = () => {
    const { writeContract: mintNFT } = useWriteContract();
    
    const [tokenUrI, setTokenUrI] = useState("");
    const [royalty, setRoyalty] = useState(0);

    const handleMintNFT = async () => {
        mintNFT({
            abi: openriverAbi,
            address: openriverAddress,
            functionName: "newItem",
            args: [
                tokenUrI,
                royalty
            ]
        });
    };

    return (
        <div className="simple-card p-6 max-w-md mx-auto space-y-4">
            <h2 className="text-lg font-bold text-white">Dashboard - Quick Mint</h2>
            <div className="space-y-3">
                <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">
                        Token URI / Image Link
                    </label>
                    <input
                        type="text"
                        placeholder="https://..."
                        onChange={(e) => setTokenUrI(e.target.value)}
                        className="simple-input w-full px-3 py-2 text-xs rounded"
                    />
                </div>

                <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">
                        Royalty Percentage (%)
                    </label>
                    <input
                        type="number"
                        placeholder="e.g. 5"
                        onChange={(e) => setRoyalty(Number(e.target.value))}
                        className="simple-input w-full px-3 py-2 text-xs rounded"
                    />
                </div>

                <button onClick={handleMintNFT} className="btn-primary w-full py-2 text-xs font-semibold">
                    Mint NFT
                </button>
            </div>
        </div>
    );
};

export default Dashboard;