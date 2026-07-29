import type { NextPage } from 'next';
import Head from 'next/head';
import Link from 'next/link';
import { Cards } from '../components/Cards';
import { useNFTs } from '../hooks/useNFTs';

const Home: NextPage = () => {
  const { totalTokens, listedNFTs, loading } = useNFTs();

  return (
    <>
      <Head>
        <title>OpenRiver | Simple NFT Store</title>
        <meta name="description" content="A simple NFT store built with React and Wagmi." />
      </Head>

      <div className="space-y-8">
        <section className="simple-card p-8">
          <div className="max-w-2xl space-y-4">
            <h1 className="text-3xl font-bold text-white">
              Welcome to OpenRiver NFT Store 🌊
            </h1>

            <p className="text-sm text-slate-300">
              This is a simple marketplace where you can create (mint) new NFTs, list your NFTs for sale, and buy NFTs from other users.
            </p>

            <div className="flex gap-3 pt-2">
              <Link href="/mint" className="btn-primary px-5 py-2.5 text-sm font-semibold">
                Mint New NFT
              </Link>
              <Link href="/list" className="btn-secondary px-5 py-2.5 text-sm font-semibold">
                Sell Your NFT
              </Link>
            </div>

            <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-800 max-w-sm">
              <div>
                <span className="text-xs text-slate-400 font-semibold uppercase">Total Minted</span>
                <p className="text-xl font-bold text-white">
                  {loading ? '...' : totalTokens}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400 font-semibold uppercase">Items For Sale</span>
                <p className="text-xl font-bold text-sky-400">
                  {loading ? '...' : listedNFTs.length}
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white">Explore NFTs</h2>
          <Cards initialFilter="all" />
        </section>
      </div>
    </>
  );
};

export default Home;
