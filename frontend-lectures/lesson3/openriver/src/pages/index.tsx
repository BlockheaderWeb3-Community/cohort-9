import type { NextPage } from 'next'
import Head from 'next/head'
import Link from 'next/link'
import { Cards } from '../components/Cards'

const Home: NextPage = () => {
  return (
    <>
      <Head>
        <title>OpenRiver — NFT Marketplace</title>
        <meta name="description" content="Mint, list, and trade NFTs on OpenRiver" />
      </Head>

      <div className="mx-auto max-w-7xl px-6 py-12">
        {/* Hero */}
        <div className="mb-16 text-center">
          <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-violet-500/30 bg-violet-500/10 px-4 py-1.5 text-sm text-violet-300">
            <span className="inline-block h-1.5 w-1.5 rounded-full bg-violet-400"></span>
            Live on Sepolia Testnet
          </div>
          <h1 className="mb-4 text-5xl font-extrabold tracking-tight text-white md:text-6xl">
            Discover &amp; Trade
            <span className="block bg-gradient-to-r from-violet-400 to-indigo-400 bg-clip-text text-transparent">
              Digital Art
            </span>
          </h1>
          <p className="mx-auto mb-8 max-w-xl text-lg text-slate-400">
            OpenRiver is a decentralized NFT marketplace. Mint your creations, set royalties, and trade with the community.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/mint"
              className="rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 px-6 py-3 text-sm font-semibold text-white no-underline transition-opacity hover:opacity-90"
            >
              Mint an NFT
            </Link>
            <Link
              href="/myNFT"
              className="rounded-xl border border-white/10 bg-white/5 px-6 py-3 text-sm font-semibold text-white no-underline transition-colors hover:bg-white/10"
            >
              View My NFTs
            </Link>
          </div>
        </div>

        {/* Stats bar */}
        <div className="mb-12 grid grid-cols-3 gap-4 rounded-2xl border border-white/10 bg-white/5 p-6">
          {[
            { label: 'Total NFTs', value: 'On-chain' },
            { label: 'Network', value: 'Sepolia' },
            { label: 'Contract', value: '0x8900…4823' },
          ].map(({ label, value }) => (
            <div key={label} className="text-center">
              <p className="text-lg font-bold text-white">{value}</p>
              <p className="text-xs text-slate-500">{label}</p>
            </div>
          ))}
        </div>

        {/* Marketplace grid */}
        <div>
          <h2 className="mb-6 text-2xl font-bold text-white">Marketplace</h2>
          <Cards />
        </div>
      </div>
    </>
  )
}

export default Home
