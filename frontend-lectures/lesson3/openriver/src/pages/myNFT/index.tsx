import { NextPage } from "next";
import { Cards } from "../../components/Cards";
import { useReadContract } from "wagmi";
import { openriverAbi, openriverAddress } from "../../contracts";
import { useEffect, useState } from "react";

const MyNFT: NextPage = () => {
    const [nftsNum, setNftsNum] = useState<bigint | null>()

    const { data: nftmaxNum } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    }) as any

    useEffect(() => {
        setNftsNum(nftmaxNum)
    }, [nftmaxNum])

    useEffect(() => {
        setNftsNum(nftmaxNum)
    }, [nftmaxNum])


    return (
        <div className="">

            <p>{nftsNum?.toString()}</p>
            <main className="">
                <Cards nftNum={nftsNum} />
            </main>

        </div>
    );
};

export default MyNFT;