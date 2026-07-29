import { formatEther } from 'viem';

export interface NFTMetadata {
  name?: string;
  description?: string;
  image?: string;
  attributes?: Array<{ trait_type: string; value: string | number }>;
}

export interface NFTItemData {
  tokenId: bigint;
  tokenURI: string;
  owner: string;
  isListed: boolean;
  price: bigint;
  priceFormatted: string;
  publisher: string;
  royalty: bigint;
  metadata?: NFTMetadata | null;
  imageSrc: string;
  name: string;
  description: string;
}

export function resolveIPFS(url: string | undefined | null): string {
  if (!url) return '';
  const cleanUrl = url.trim();

  if (cleanUrl.startsWith('ipfs://')) {
    const cid = cleanUrl.replace('ipfs://', '');
    return `https://ipfs.io/ipfs/${cid}`;
  }

  return cleanUrl;
}

export async function fetchNFTMetadata(tokenURI: string): Promise<NFTMetadata | null> {
  if (!tokenURI) return null;

  const resolved = resolveIPFS(tokenURI);

  if (
    resolved.match(/\.(jpeg|jpg|gif|png|svg|webp)$/i) ||
    resolved.startsWith('data:image/') ||
    resolved.includes('picsum.photos') ||
    resolved.includes('unsplash.com')
  ) {
    return {
      image: resolved,
      name: undefined,
      description: undefined,
    };
  }

  try {
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      const res = await fetch(resolved);
      
      if (res.ok) {
        const contentType = res.headers.get('content-type') || '';

        if (contentType.includes('image/')) {
          return { image: resolved };
        }

        try {
          const json = await res.json();
          return {
            name: json.name || json.title,
            description: json.description,
            image: resolveIPFS(json.image || json.image_url),
            attributes: json.attributes || [],
          };
        } catch {
          return { image: resolved };
        }
      }
    }
  } catch (error) {
    console.log('Using image fallback for tokenURI:', tokenURI);
  }

  return null;
}

export function truncateAddress(address: string, chars = 4): string {
  if (!address) return '';
  return `${address.substring(0, chars + 2)}...${address.substring(address.length - chars)}`;
}

export function formatPrice(priceWei: bigint | undefined | null): string {
  if (priceWei === undefined || priceWei === null) return '0';
  try {
    return formatEther(priceWei);
  } catch {
    return '0';
  }
}

export function getFallbackImage(tokenId: bigint): string {
  const hues = [210, 260, 320, 180, 45, 140, 280, 15];
  const hue1 = hues[Number(tokenId % BigInt(hues.length))];
  const hue2 = (hue1 + 60) % 360;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
    <defs>
      <linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="hsl(${hue1}, 85%, 55%)"/>
        <stop offset="100%" stop-color="hsl(${hue2}, 85%, 45%)"/>
      </linearGradient>
    </defs>
    <rect width="400" height="400" fill="url(#g)"/>
    <circle cx="200" cy="200" r="70" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="6"/>
    <text x="200" y="212" font-family="sans-serif" font-size="38" font-weight="bold" fill="#ffffff" text-anchor="middle">#${tokenId.toString()}</text>
    <text x="200" y="340" font-family="sans-serif" font-size="14" font-weight="normal" fill="rgba(255,255,255,0.8)" text-anchor="middle">NFT ITEM</text>
  </svg>`;

  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}
