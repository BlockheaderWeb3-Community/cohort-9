import { useReadContract } from "wagmi";
import Card from "./Card";
import { openriverAbi, openriverAddress } from "../contracts";

export const Cards = () => {
    const nfts = [1,2,3,4,5,6,7,8,9];
    const {data: tokenIds} = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    })

       const {data: marketData} = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "marketplace",
        args: [tokenIds]
    })

    console.log(marketData)
  
  return (
    <div className="flex gap-10 flex-wrap w-360 mt-5  m-auto ">
        {nfts.map(index => <Card key={index}/>)}
    </div>
  )
}
