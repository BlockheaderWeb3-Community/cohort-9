import { useReadContract } from "wagmi";
import Card from "./Card";
import { openriverAbi, openriverAddress } from "../contracts";

export const Cards = ({ nftNum }: { nftNum?: bigint }) => {

    const { data: tokenIdsRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const tokenIds = tokenIdsRaw as bigint | undefined;

    // Use the prop if provided (e.g. from MyNFT page), otherwise fall back to
    // the value fetched directly from the contract (used on the home page).
    const count = nftNum ?? tokenIds;

    return (
        <div className="flex gap-10 flex-wrap w-360 mt-5 m-auto">
            {Array.from({ length: Number(count ?? 0) }, (_, i) => i + 1).map((index) => (
                <Card key={index} tokenId={BigInt(index)} />
            ))}
        </div>
    );
}
