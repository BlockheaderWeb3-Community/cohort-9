import React, { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { parseEther } from 'viem';
import { openriverAbi, openriverAddress } from '../contracts';
import { NFTItemData, truncateAddress } from '../utils/nft';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  nft: NFTItemData | null;
  onSuccess?: () => void;
}

export const ListModal: React.FC<ModalProps> = ({ isOpen, onClose, nft, onSuccess }) => {
  const [priceEth, setPriceEth] = useState('');

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) {
      onSuccess?.();
      onClose();
      setPriceEth('');
    }
  }, [isSuccess, onSuccess, onClose]);

  if (!isOpen || !nft) return null;

  const handleList = () => {
    if (!priceEth || isNaN(Number(priceEth)) || Number(priceEth) <= 0) return;
    try {
      const priceWei = parseEther(priceEth);
      writeContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: 'listOnMarketplace',
        args: [nft.tokenId, priceWei],
      });
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="simple-card w-full max-w-md p-6 relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-white">✕</button>

        <h3 className="text-lg font-bold text-white mb-2">Put NFT For Sale</h3>
        <p className="text-xs text-slate-400 mb-4">Set a price in ETH to sell {nft.name}.</p>

        <div className="mb-4">
          <label className="block text-xs font-semibold text-slate-300 mb-1">Price (ETH)</label>
          <input
            type="number"
            step="0.001"
            placeholder="0.1"
            value={priceEth}
            onChange={(e) => setPriceEth(e.target.value)}
            className="simple-input w-full px-3 py-2 rounded text-sm"
          />
        </div>

        {writeError && (
          <div className="p-2 mb-4 bg-red-950 text-red-300 text-xs rounded border border-red-800">
            Error: {writeError.message.slice(0, 100)}...
          </div>
        )}

        <div className="flex gap-2">
          <button onClick={onClose} className="btn-secondary flex-1 py-2 text-xs">Cancel</button>
          <button
            onClick={handleList}
            disabled={isPending || isConfirming || !priceEth}
            className="btn-primary flex-1 py-2 text-xs"
          >
            {isPending || isConfirming ? 'Submitting...' : 'Confirm Listing'}
          </button>
        </div>
      </div>
    </div>
  );
};

export const TransferModal: React.FC<ModalProps> = ({ isOpen, onClose, nft, onSuccess }) => {
  const { address } = useAccount();
  const [recipient, setRecipient] = useState('');

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) {
      onSuccess?.();
      onClose();
      setRecipient('');
    }
  }, [isSuccess, onSuccess, onClose]);

  if (!isOpen || !nft) return null;

  const handleTransfer = () => {
    if (!address || !recipient.startsWith('0x') || recipient.length !== 42) return;
    writeContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'safeTransferFrom',
      args: [address as `0x${string}`, recipient as `0x${string}`, nft.tokenId],
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="simple-card w-full max-w-md p-6 relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-white">✕</button>

        <h3 className="text-lg font-bold text-white mb-2">Send NFT to Another Address</h3>
        <p className="text-xs text-slate-400 mb-4">Enter recipient wallet address below.</p>

        <div className="mb-4">
          <label className="block text-xs font-semibold text-slate-300 mb-1">Recipient Wallet Address (0x...)</label>
          <input
            type="text"
            placeholder="0x123..."
            value={recipient}
            onChange={(e) => setRecipient(e.target.value)}
            className="simple-input w-full px-3 py-2 rounded text-xs font-mono"
          />
        </div>

        {writeError && (
          <div className="p-2 mb-4 bg-red-950 text-red-300 text-xs rounded border border-red-800">
            Error: {writeError.message.slice(0, 100)}...
          </div>
        )}

        <div className="flex gap-2">
          <button onClick={onClose} className="btn-secondary flex-1 py-2 text-xs">Cancel</button>
          <button
            onClick={handleTransfer}
            disabled={isPending || isConfirming || !recipient.startsWith('0x')}
            className="btn-primary flex-1 py-2 text-xs"
          >
            {isPending || isConfirming ? 'Sending...' : 'Send NFT'}
          </button>
        </div>
      </div>
    </div>
  );
};

export const ApproveModal: React.FC<ModalProps> = ({ isOpen, onClose, nft, onSuccess }) => {
  const [operator, setOperator] = useState(openriverAddress);
  const [isForAll, setIsForAll] = useState(true);

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) {
      onSuccess?.();
      onClose();
    }
  }, [isSuccess, onSuccess, onClose]);

  if (!isOpen || !nft) return null;

  const handleApprove = () => {
    if (!operator.startsWith('0x')) return;
    if (isForAll) {
      writeContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: 'setApprovalForAll',
        args: [operator as `0x${string}`, true],
      });
    } else {
      writeContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: 'approve',
        args: [operator as `0x${string}`, nft.tokenId],
      });
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
      <div className="simple-card w-full max-w-md p-6 relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-white">✕</button>

        <h3 className="text-lg font-bold text-white mb-2">Approve Operator</h3>
        <p className="text-xs text-slate-400 mb-4">Grant permissions to contract address to handle your NFT.</p>

        <div className="space-y-3 mb-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Operator Address</label>
            <input
              type="text"
              value={operator}
              onChange={(e) => setOperator(e.target.value)}
              className="simple-input w-full px-3 py-2 rounded text-xs font-mono"
            />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="forAll"
              checked={isForAll}
              onChange={(e) => setIsForAll(e.target.checked)}
              className="w-4 h-4"
            />
            <label htmlFor="forAll" className="text-xs text-slate-300">
              Approve for all NFTs in collection
            </label>
          </div>
        </div>

        {writeError && (
          <div className="p-2 mb-4 bg-red-950 text-red-300 text-xs rounded border border-red-800">
            Error: {writeError.message.slice(0, 100)}...
          </div>
        )}

        <div className="flex gap-2">
          <button onClick={onClose} className="btn-secondary flex-1 py-2 text-xs">Cancel</button>
          <button
            onClick={handleApprove}
            disabled={isPending || isConfirming}
            className="btn-primary flex-1 py-2 text-xs"
          >
            {isPending || isConfirming ? 'Approving...' : 'Confirm Approval'}
          </button>
        </div>
      </div>
    </div>
  );
};

export const DetailModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  nft: NFTItemData | null;
  onOpenList: () => void;
  onOpenTransfer: () => void;
  onOpenApprove: () => void;
  onRefresh: () => void;
}> = ({ isOpen, onClose, nft, onOpenList, onOpenTransfer, onOpenApprove, onRefresh }) => {
  const { address } = useAccount();

  const { writeContract: buyContract, data: buyHash, isPending: isBuyPending } = useWriteContract();
  const { isLoading: isBuyConfirming, isSuccess: isBuySuccess } = useWaitForTransactionReceipt({ hash: buyHash });

  const { writeContract: delistContract, data: delistHash, isPending: isDelistPending } = useWriteContract();
  const { isLoading: isDelistConfirming, isSuccess: isDelistSuccess } = useWaitForTransactionReceipt({ hash: delistHash });

  useEffect(() => {
    if (isBuySuccess || isDelistSuccess) {
      onRefresh();
      onClose();
    }
  }, [isBuySuccess, isDelistSuccess, onRefresh, onClose]);

  if (!isOpen || !nft) return null;

  const isOwner = Boolean(address && nft.owner.toLowerCase() === address.toLowerCase());

  const handleBuy = () => {
    buyContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'purchase',
      args: [nft.tokenId],
      value: nft.price,
    });
  };

  const handleDelist = () => {
    delistContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'removeFromMarketplace',
      args: [nft.tokenId],
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4 overflow-y-auto">
      <div className="simple-card w-full max-w-2xl p-6 relative max-h-[90vh] overflow-y-auto">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-white">✕</button>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <div className="aspect-square rounded-lg overflow-hidden bg-slate-900 border border-slate-800 mb-3">
              <img src={nft.imageSrc} alt={nft.name} className="w-full h-full object-cover" />
            </div>
            <div className="p-3 simple-card bg-slate-900">
              <span className="text-xs text-slate-400 font-semibold uppercase">Price</span>
              <p className="text-xl font-bold text-sky-400">
                {nft.isListed ? `${nft.priceFormatted} ETH` : 'Not Listed'}
              </p>
            </div>
          </div>

          <div className="flex flex-col justify-between space-y-4">
            <div>
              <h2 className="text-2xl font-bold text-white mb-2">{nft.name}</h2>
              <p className="text-xs text-slate-300 mb-4">{nft.description || 'No description provided.'}</p>

              <div className="space-y-2 text-xs text-slate-400">
                <div className="flex justify-between p-2 bg-slate-900 rounded">
                  <span>Token ID:</span>
                  <span className="font-mono text-slate-200">#{nft.tokenId.toString()}</span>
                </div>
                <div className="flex justify-between p-2 bg-slate-900 rounded">
                  <span>Owner:</span>
                  <span className="font-mono text-slate-200">{isOwner ? 'You' : truncateAddress(nft.owner, 4)}</span>
                </div>
                <div className="flex justify-between p-2 bg-slate-900 rounded">
                  <span>Creator Royalty:</span>
                  <span className="text-amber-400 font-bold">{nft.royalty.toString()}%</span>
                </div>
              </div>
            </div>

            <div className="space-y-2 pt-4 border-t border-slate-800">
              {isOwner ? (
                <div className="space-y-2">
                  {nft.isListed ? (
                    <button
                      onClick={handleDelist}
                      disabled={isDelistPending || isDelistConfirming}
                      className="w-full btn-danger py-2 text-xs font-semibold"
                    >
                      {isDelistPending || isDelistConfirming ? 'Removing...' : 'Remove Listing'}
                    </button>
                  ) : (
                    <button
                      onClick={() => { onClose(); onOpenList(); }}
                      className="w-full btn-primary py-2 text-xs font-semibold"
                    >
                      Put Up For Sale
                    </button>
                  )}

                  <div className="flex gap-2">
                    <button
                      onClick={() => { onClose(); onOpenTransfer(); }}
                      className="btn-secondary flex-1 py-2 text-xs"
                    >
                      Send NFT
                    </button>
                    <button
                      onClick={() => { onClose(); onOpenApprove(); }}
                      className="btn-secondary flex-1 py-2 text-xs"
                    >
                      Approval Settings
                    </button>
                  </div>
                </div>
              ) : (
                nft.isListed ? (
                  <button
                    onClick={handleBuy}
                    disabled={isBuyPending || isBuyConfirming}
                    className="w-full btn-primary py-3 text-sm font-semibold"
                  >
                    {isBuyPending || isBuyConfirming ? 'Buying...' : `Buy Now for ${nft.priceFormatted} ETH`}
                  </button>
                ) : (
                  <div className="p-3 bg-slate-900 rounded text-center text-xs text-slate-400">
                    This item is not listed for sale.
                  </div>
                )
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
