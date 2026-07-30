import { useReadContract, useAccount } from "wagmi";
import { openriverAbi, openriverAddress } from "../../contracts";
import Link from "next/link";
import Button from "../../components/Button";

const Dashboard = () => {
    const { address, isConnected } = useAccount();

    const { data: totalSupplyRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const totalSupply = totalSupplyRaw as bigint | undefined;

    const { data: ownedCount } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "balanceOf",
        args: address ? [address] : undefined,
        query: { enabled: !!address },
    }) as { data?: bigint };

    if (!isConnected) {
        return (
            <div className="flex flex-col items-center justify-center mt-32 gap-4">
                <p className="text-xl text-slate-600">Connect your wallet to view your dashboard.</p>
            </div>
        );
    }

    return (
        <div className="max-w-3xl mx-auto mt-16 px-6">
            <h1 className="text-3xl font-extrabold text-blue-700 mb-8">Dashboard</h1>

            <div className="grid grid-cols-2 gap-6 mb-10">
                <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
                    <p className="text-sm text-slate-500 mb-1">Total NFTs minted</p>
                    <p className="text-4xl font-bold text-blue-700">{totalSupply?.toString() ?? '—'}</p>
                </div>
                <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
                    <p className="text-sm text-slate-500 mb-1">NFTs you own</p>
                    <p className="text-4xl font-bold text-blue-700">{ownedCount?.toString() ?? '—'}</p>
                </div>
            </div>

            <div className="flex gap-4">
                <Link href="/mint"><Button label="Mint an NFT" /></Link>
                <Link href="/list"><Button label="List an NFT" variant="danger" /></Link>
                <Link href="/marketplace"><Button label="Marketplace" /></Link>
                <Link href="/myNFT"><Button label="My NFTs" /></Link>
            </div>
        </div>
    );
};

export default Dashboard;