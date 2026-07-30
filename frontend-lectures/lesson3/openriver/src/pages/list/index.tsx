import { useState } from 'react'
import { useWriteContract } from 'wagmi';
import { openriverAbi, openriverAddress } from '../../contracts';
import Button from '../../components/Button';

const index = () => {
    const { writeContract: listNFT } = useWriteContract();
    const [tokenId, setTokenId] = useState(0);
    const [price, setPrice] = useState(0);

    const handleListNFT = () => {
        listNFT({
            abi: openriverAbi,
            address: openriverAddress,
            functionName: "listOnMarketplace",
            args: [
                BigInt(tokenId),   // contract expects uint256
                BigInt(price),     // contract expects uint256
            ],
        });
    };

    return (
        <div className='mt-20'>
            <div className="flex flex-col gap-5 items-center justify-center">
                <input
                    className='w-125 p-5'
                    type="number"
                    placeholder="Token Id"
                    onChange={(e) => setTokenId(Number(e.target.value))}
                />
                <input
                    className='w-125 p-5'
                    type="number"
                    placeholder="Price (in Wei)"
                    onChange={(e) => setPrice(Number(e.target.value))}
                />
                <Button label="List NFT" onClick={handleListNFT} />
            </div>
        </div>
    );
};

export default index;
