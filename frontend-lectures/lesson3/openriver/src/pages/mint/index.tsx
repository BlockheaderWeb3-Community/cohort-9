import React, { useState } from 'react'
import { useWriteContract } from 'wagmi';
import { openriverAbi, openriverAddress } from '../../contracts';

 const index = () => {
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
        <div className='mt-20'>
            <div className="flex flex-col gap-5 items-center justify-center">
                <input className='w-125 p-5' type="text" placeholder="Token URI" onChange={(e) => setTokenUrI(e.target.value)} />
                <input className='w-125 p-5' type="number" placeholder="Royalty" onChange={(e) => setRoyalty(Number(e.target.value))} />
                <button className='w-52 bg-blue-500 text-white py-2 px-4 rounded' onClick={handleMintNFT}>Mint NFT</button>
            </div>
        </div>
    )
}


export default index