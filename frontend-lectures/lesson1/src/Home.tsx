import { useAccount, useReadContract, useWriteContract } from 'wagmi'
import Header from "./components/Header";
import { voteAbi, voteAddress } from "./contract/vote.ts";
import { useState } from 'react';

export default function Home() {
  const { writeContract } = useWriteContract()
  const {address} = useAccount()
  const [voteIndex, setVoteIndex] = useState(0n)


  const handle = () => {
    writeContract({
      abi: voteAbi,
      address: voteAddress,
      functionName: 'vote',
      args: [
        voteIndex,
      ],
    })
  }


  const hasVoted = () => {
    const {data} = useReadContract({
      abi: voteAbi,
      address: voteAddress,
      functionName: "hasVoted",
      args: [address]
    })

    return data;
  }




  return (
    <div className="">
      <Header />
      <p>Vote</p>
      <p>My address: {address}</p>
      <p>my vote: {hasVoted()? "Yes" : "No"}</p>

      <form className="">
        <input type="number" className="" min={1} max={20} onChange={(e)=> setVoteIndex(BigInt(e.target.value))}/>
      </form>
      <button className="" onClick={handle}>vote</button>
    </div>
  );
}