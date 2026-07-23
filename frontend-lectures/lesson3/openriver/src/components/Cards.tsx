import { useReadContract } from "wagmi";
import Card from "./Card";
import { openriverAbi, openriverAddress } from "../contracts";

export const Cards = ({ nftNum }: { nftNum?: bigint }) => {
  
    const {data: tokenIds} = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    })





  
  return (
    <div className="flex gap-10 flex-wrap w-360 mt-5  m-auto ">
        {Array.from({ length: Number(nftNum) }, (_, i) => i + 1).map((index) => (
            <Card key={index} tokenId={BigInt(index)} />
        ))}
    </div>
  )
}
