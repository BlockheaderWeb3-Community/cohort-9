import { NextPage } from "next";
import { Cards } from "../../components/Cards";
import { useReadContract } from "wagmi";
import { openriverAbi, openriverAddress } from "../../contracts";

const MyNFT: NextPage = () => {
    const { data } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const nftmaxNum = data as bigint | undefined;

    // nftmaxNum is bigint | undefined — pass directly to Cards
    return (
        <div>
            <p>{nftmaxNum?.toString()}</p>
            <main>
                <Cards nftNum={nftmaxNum} />
            </main>
        </div>
    );
};

export default MyNFT;
