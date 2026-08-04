import { NextPage } from 'next'
import Head from 'next/head'
import { Cards } from '../../components/Cards'
import { useReadContract, useAccount } from 'wagmi'
import { openriverAbi, openriverAddress } from '../../contracts'
import { useEffect, useState } from 'react'

const MyNFT: NextPage = () => {
  const { isConnected } = useAccount()
  const [nftsNum, setNftsNum] = useState<bigint | undefined>()

  const { data: nftmaxNum } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenIds',
  }) as any

  useEffect(() => {
    setNftsNum(nftmaxNum)
  }, [nftmaxNum])

  return (
    <>
      <Head><title>My NFTs — OpenRiver</title></Head>
      <div className="mx-auto max-w-7xl px-6 py-12">
        <div className="mb-10">
          <h1 className="text-3xl font-extrabold text-white">My NFTs</h1>
          <p className="mt-1 text-slate-400">
            {isConnected
              ? `${nftsNum?.toString() ?? '…'} NFTs minted on-chain`
              : 'Connect your wallet to get started'}
          </p>
        </div>

        {!isConnected ? (
          <div className="flex flex-col items-center justify-center rounded-2xl border border-white/10 bg-[#13131a] py-24 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-white/5">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-slate-500">
                <path d="M20 7H4a2 2 0 00-2 2v10a2 2 0 002 2h16a2 2 0 002-2V9a2 2 0 00-2-2z" />
                <path d="M16 3H8a2 2 0 00-2 2v2h12V5a2 2 0 00-2-2z" />
                <circle cx="12" cy="14" r="2" />
              </svg>
            </div>
            <p className="text-lg font-medium text-slate-400">Wallet not connected</p>
            <p className="mt-1 text-sm text-slate-600">Connect using the button in the header</p>
          </div>
        ) : (
          <Cards nftNum={nftsNum} />
        )}
      </div>
    </>
  )
}

export default MyNFT
