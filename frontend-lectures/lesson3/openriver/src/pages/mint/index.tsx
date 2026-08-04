import { useState } from 'react'
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { openriverAbi, openriverAddress } from '../../contracts'
import Head from 'next/head'

const MintPage = () => {
  const [tokenUri, setTokenUri] = useState('')
  const [royalty, setRoyalty] = useState('')

  const { data: hash, writeContract, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const handleMint = () => {
    if (!tokenUri) return
    writeContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'newItem',
      args: [tokenUri, BigInt(royalty || '0')],
    })
  }

  return (
    <>
      <Head><title>Mint NFT — OpenRiver</title></Head>
      <div className="mx-auto max-w-lg px-6 py-16">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-extrabold text-white">Mint an NFT</h1>
          <p className="mt-2 text-slate-400">Upload your creation to the OpenRiver marketplace</p>
        </div>

        <div className="rounded-2xl border border-white/10 bg-[#13131a] p-8">
          <div className="flex flex-col gap-5">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-300">Token URI</label>
              <input
                type="text"
                placeholder="ipfs://... or https://..."
                value={tokenUri}
                onChange={(e) => setTokenUri(e.target.value)}
                className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder-slate-600 outline-none transition focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-300">
                Royalty <span className="text-slate-500">(0–100)</span>
              </label>
              <input
                type="number"
                placeholder="e.g. 10"
                min="0"
                max="100"
                value={royalty}
                onChange={(e) => setRoyalty(e.target.value)}
                className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder-slate-600 outline-none transition focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
              />
            </div>

            <button
              onClick={handleMint}
              disabled={!tokenUri || isPending || isConfirming}
              className="mt-2 w-full rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 py-3 text-sm font-semibold text-white transition-opacity hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
            >
              {isPending ? 'Confirm in wallet…' : isConfirming ? 'Minting…' : 'Mint NFT'}
            </button>
          </div>

          {isSuccess && (
            <div className="mt-4 rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-3 text-center text-sm text-emerald-400">
              ✅ NFT minted successfully!
            </div>
          )}
          {error && (
            <div className="mt-4 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-center text-sm text-red-400">
              {error.message.split('\n')[0]}
            </div>
          )}
          {hash && (
            <a
              href={`https://sepolia.etherscan.io/tx/${hash}`}
              target="_blank"
              rel="noreferrer"
              className="mt-3 block text-center text-xs text-violet-400 hover:underline"
            >
              View transaction ↗
            </a>
          )}
        </div>
      </div>
    </>
  )
}

export default MintPage
