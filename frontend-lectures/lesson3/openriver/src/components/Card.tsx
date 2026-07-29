import React, { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { openriverAbi, openriverAddress } from '../contracts';
import { NFTItemData, truncateAddress } from '../utils/nft';
import { ListModal, TransferModal, ApproveModal } from './NFTActionModals';

interface CardProps {
  nft: NFTItemData;
  onRefresh: () => void;
}

export const Card: React.FC<CardProps> = ({ nft, onRefresh }) => {
  const { address } = useAccount();

  const [showList, setShowList] = useState(false);
  const [showTransfer, setShowTransfer] = useState(false);
  const [showApprove, setShowApprove] = useState(false);

  const { writeContract: buyContract, data: buyHash, isPending: isBuyPending } = useWriteContract();
  const { isLoading: isBuyConfirming, isSuccess: isBuySuccess } = useWaitForTransactionReceipt({ hash: buyHash });

  const { writeContract: delistContract, data: delistHash, isPending: isDelistPending } = useWriteContract();
  const { isLoading: isDelistConfirming, isSuccess: isDelistSuccess } = useWaitForTransactionReceipt({ hash: delistHash });

  React.useEffect(() => {
    if (isBuySuccess || isDelistSuccess) {
      onRefresh();
    }
  }, [isBuySuccess, isDelistSuccess, onRefresh]);

  const isOwner = Boolean(address && nft.owner.toLowerCase() === address.toLowerCase());

  const handleQuickBuy = () => {
    buyContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'purchase',
      args: [nft.tokenId],
      value: nft.price,
    });
  };

  const handleQuickDelist = () => {
    delistContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'removeFromMarketplace',
      args: [nft.tokenId],
    });
  };

  return (
    <>
      <div className="simple-card p-4 flex flex-col justify-between">
        <div>
          <div className="relative aspect-square rounded-lg overflow-hidden mb-3 bg-slate-900 border border-slate-800">
            <img
              src={nft.imageSrc}
              alt={nft.name}
              className="w-full h-full object-cover"
            />
            <div className="absolute top-2 left-2">
              {nft.isListed ? (
                <span className="px-2 py-1 rounded text-xs font-bold bg-green-950 text-green-400 border border-green-800">
                  For Sale
                </span>
              ) : (
                <span className="px-2 py-1 rounded text-xs font-semibold bg-slate-800 text-slate-300">
                  Not Listed
                </span>
              )}
            </div>
            <div className="absolute top-2 right-2">
              <span className="px-2 py-1 rounded text-xs font-mono font-bold bg-slate-900 text-slate-200">
                #{nft.tokenId.toString()}
              </span>
            </div>
          </div>

          <div className="space-y-1 mb-3">
            <h3 className="font-bold text-base text-white truncate">
              {nft.name}
            </h3>
            <div className="flex justify-between items-center text-xs text-slate-400">
              <span>Owner:</span>
              <span className="font-mono text-slate-200">
                {isOwner ? 'You' : truncateAddress(nft.owner, 4)}
              </span>
            </div>
          </div>
        </div>

        <div className="pt-3 border-t border-slate-800 space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-xs text-slate-400 uppercase font-semibold">
              {nft.isListed ? 'Price' : 'Status'}
            </span>
            <span className="text-sm font-bold text-sky-400">
              {nft.isListed ? `${nft.priceFormatted} ETH` : 'Not Listed'}
            </span>
          </div>

          <div>
            {isOwner ? (
              nft.isListed ? (
                <button
                  onClick={handleQuickDelist}
                  disabled={isDelistPending || isDelistConfirming}
                  className="w-full btn-danger py-2 rounded text-xs font-semibold"
                >
                  {isDelistPending || isDelistConfirming ? 'Removing...' : 'Remove Listing'}
                </button>
              ) : (
                <button
                  onClick={() => setShowList(true)}
                  className="w-full btn-primary py-2 rounded text-xs font-semibold"
                >
                  Put Up For Sale
                </button>
              )
            ) : nft.isListed ? (
              <button
                onClick={handleQuickBuy}
                disabled={isBuyPending || isBuyConfirming}
                className="w-full btn-primary py-2 rounded text-xs font-semibold"
              >
                {isBuyPending || isBuyConfirming ? 'Buying...' : `Buy Now (${nft.priceFormatted} ETH)`}
              </button>
            ) : (
              <div className="text-center py-2 text-xs text-slate-400">
                Not Available
              </div>
            )}
          </div>
        </div>
      </div>

      <ListModal
        isOpen={showList}
        onClose={() => setShowList(false)}
        nft={nft}
        onSuccess={onRefresh}
      />
      <TransferModal
        isOpen={showTransfer}
        onClose={() => setShowTransfer(false)}
        nft={nft}
        onSuccess={onRefresh}
      />
      <ApproveModal
        isOpen={showApprove}
        onClose={() => setShowApprove(false)}
        nft={nft}
        onSuccess={onRefresh}
      />
    </>
  );
};

export default Card;