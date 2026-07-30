import { NextPage } from "next";
import { useReadContract } from "wagmi";
import { openriverAbi, openriverAddress } from "../../contracts";
import Card from "../../components/Card";

const Marketplace: NextPage = () => {
    const { data: totalSupplyRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const totalSupply = totalSupplyRaw as bigint | undefined;

    return (
        <div className="mt-16 px-6">
            <h1 className="text-3xl font-extrabold text-blue-700 mb-8">Marketplace</h1>
            
            <div className="flex gap-10 flex-wrap w-full">
                {Array.from({ length: Number(totalSupply ?? 0) }, (_, i) => i + 1).map((index) => (
                    <div key={index} className="flex-shrink-0">
                        <Card tokenId={BigInt(index)} showOnlyListed={true} />
                    </div>
                ))}
            </div>

            {totalSupply === BigInt(0) && (
                <div className="text-center mt-12">
                    <p className="text-xl text-slate-500">No NFTs listed yet</p>
                </div>
            )}
        </div>
    );
};

export default Marketplace;
