import { useState, useEffect, useCallback } from 'react';
import { useReadContract, useReadContracts, useAccount } from 'wagmi';
import { openriverAbi, openriverAddress } from '../contracts';
import { fetchNFTMetadata, getFallbackImage, NFTItemData, formatPrice } from '../utils/nft';

export function useNFTs() {
  const { address } = useAccount();
  const [nfts, setNfts] = useState<NFTItemData[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const { data: totalTokens, refetch: refetchTotal } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenIds',
  });

  const count = totalTokens ? Number(totalTokens) : 0;

  const calls = [];
  for (let i = 1; i <= count; i++) {
    const tid = BigInt(i);
    calls.push({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'tokenURI',
      args: [tid],
    });
    calls.push({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'ownerOf',
      args: [tid],
    });
    calls.push({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'marketplace',
      args: [tid],
    });
  }

  const { data: rawData, refetch: refetchDetails, isLoading: detailsLoading } = useReadContracts({
    contracts: calls as any,
    query: {
      enabled: count > 0,
    }
  });

  const loadAllNFTs = useCallback(async () => {
    if (!count || !rawData || rawData.length === 0) {
      setNfts([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    const items: NFTItemData[] = [];

    for (let i = 1; i <= count; i++) {
      const idx = (i - 1) * 3;
      const uriResult = rawData[idx]?.result as string | undefined;
      const ownerResult = rawData[idx + 1]?.result as string | undefined;
      const marketResult = rawData[idx + 2]?.result as [boolean, bigint, string, bigint] | undefined;

      const tokenId = BigInt(i);
      const tokenURI = uriResult || '';
      const owner = ownerResult || '0x0000000000000000000000000000000000000000';

      const isListed = Boolean(marketResult?.[0]);
      const price = marketResult?.[1] ? BigInt(marketResult[1].toString()) : BigInt(0);
      const publisher = marketResult?.[2] || owner;
      const royalty = marketResult?.[3] ? BigInt(marketResult[3].toString()) : BigInt(0);

      let metadata = null;
      let imageSrc = getFallbackImage(tokenId);
      let name = `NFT Item #${tokenId.toString()}`;
      let description = `OpenRiver NFT #${tokenId.toString()}`;

      if (tokenURI) {
        metadata = await fetchNFTMetadata(tokenURI);
        if (metadata) {
          if (metadata.image) imageSrc = metadata.image;
          if (metadata.name) name = metadata.name;
          if (metadata.description) description = metadata.description;
        } else if (
          tokenURI.startsWith('http://') ||
          tokenURI.startsWith('https://') ||
          tokenURI.startsWith('ipfs://') ||
          tokenURI.startsWith('data:image')
        ) {
          imageSrc = tokenURI.startsWith('ipfs://')
            ? `https://ipfs.io/ipfs/${tokenURI.replace('ipfs://', '')}`
            : tokenURI;
        }
      }

      items.push({
        tokenId,
        tokenURI,
        owner,
        isListed,
        price,
        priceFormatted: formatPrice(price),
        publisher,
        royalty,
        metadata,
        imageSrc,
        name,
        description,
      });
    }

    setNfts(items.reverse());
    setLoading(false);
  }, [count, rawData]);

  useEffect(() => {
    loadAllNFTs();
  }, [loadAllNFTs]);

  const refresh = useCallback(() => {
    refetchTotal();
    refetchDetails();
  }, [refetchTotal, refetchDetails]);

  return {
    nfts,
    totalTokens: count,
    loading: loading || detailsLoading,
    refresh,
    userNFTs: nfts.filter((item) => address && item.owner.toLowerCase() === address.toLowerCase()),
    listedNFTs: nfts.filter((item) => item.isListed),
  };
}
