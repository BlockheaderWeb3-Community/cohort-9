import React, { useState } from 'react'
import { useWriteContract } from 'wagmi';
import { openriverAbi, openriverAddress } from '../../contracts';
import Button from '../../components/Button';

const index = () => {
    const { writeContract: mintNFT } = useWriteContract();
    const [tokenUrI, setTokenUrI] = useState("");
    const [royalty, setRoyalty] = useState(0);

    const handleMintNFT = () => {
        mintNFT({
            abi: openriverAbi,
            address: openriverAddress,
            functionName: "newItem",
            args: [
                tokenUrI,
                BigInt(royalty),   // contract expects uint256
            ],
        });
    };

    return (
        <div className='mt-20'>
            <div className="flex flex-col gap-5 items-center justify-center">
                <input
                    className='w-125 p-5'
                    type="text"
                    placeholder="Token URI"
                    onChange={(e) => setTokenUrI(e.target.value)}
                />
                <input
                    className='w-125 p-5'
                    type="number"
                    placeholder="Royalty"
                    onChange={(e) => setRoyalty(Number(e.target.value))}
                />
                <Button label="Mint NFT" onClick={handleMintNFT} />
            </div>
        </div>
    );
};

export default index;
