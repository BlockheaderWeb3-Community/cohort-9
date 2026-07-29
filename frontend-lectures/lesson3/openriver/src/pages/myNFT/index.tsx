import type { NextPage } from 'next';
import Head from 'next/head';
import { useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { Cards } from '../../components/Cards';
import { useNFTs } from '../../hooks/useNFTs';
import { openriverAbi, openriverAddress } from '../../contracts';

const MyNFTPage: NextPage = () => {
  const { address, isConnected } = useAccount();
  const { refresh } = useNFTs();

  const { data: isApprovedForAll, refetch: refetchApproval } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'isApprovedForAll',
    args: address ? [address as `0x${string}`, openriverAddress as `0x${string}`] : undefined,
    query: { enabled: Boolean(address) },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) {
      refetchApproval();
      refresh();
    }
  }, [isSuccess, refetchApproval, refresh]);

  const handleToggleApproval = () => {
    if (!address) return;
    writeContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'setApprovalForAll',
      args: [openriverAddress, !isApprovedForAll],
    });
  };

  return (
    <>
      <Head>
        <title>My Collection | OpenRiver</title>
      </Head>

      <div className="space-y-6">
        <div className="simple-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-xl font-bold text-white">My NFT Collection</h1>
            <p className="text-xs text-slate-400 font-mono mt-1">
              {address ? address : 'Please connect your wallet'}
            </p>
          </div>

          {isConnected && (
            <div className="flex items-center gap-3">
              <span className="text-xs text-slate-300">
                Marketplace Approval: {isApprovedForAll ? '✓ Enabled' : 'Disabled'}
              </span>
              <button
                onClick={handleToggleApproval}
                disabled={isPending || isConfirming}
                className="btn-secondary px-3 py-1.5 text-xs"
              >
                {isPending || isConfirming
                  ? 'Updating...'
                  : isApprovedForAll
                  ? 'Revoke Approval'
                  : 'Enable Approval'}
              </button>
            </div>
          )}
        </div>

        <Cards initialFilter="my" />
      </div>
    </>
  );
};

export default MyNFTPage;