import { useEffect, useState } from 'react';
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from 'wagmi';
import { formatUnits } from 'viem';

import { faucetAbi } from '../contracts/faucetAbi';
import { erc20Abi } from '../contracts/erc20Abi';
import {
  FAUCET_ADDRESS,
  TOKEN_ADDRESS,
  SEPOLIA_CHAIN_ID,
} from '../contracts/config';

const Faucet = () => {
  const { address, isConnected, chainId } = useAccount();

  // --- reads -------------------------------------------------------------
  const { data: symbol } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: erc20Abi,
    functionName: 'symbol',
  });

  const { data: decimals } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: erc20Abi,
    functionName: 'decimals',
  });

  const { data: userBalance, refetch: refetchUserBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: faucetBalance, refetch: refetchFaucetBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: [FAUCET_ADDRESS],
  });

  const { data: claimAmount } = useReadContract({
    address: FAUCET_ADDRESS,
    abi: faucetAbi,
    functionName: 'claimAmount',
  });

  const { data: cooldownTime } = useReadContract({
    address: FAUCET_ADDRESS,
    abi: faucetAbi,
    functionName: 'cooldownTime',
  });

  const { data: lastClaim, refetch: refetchLastClaim } = useReadContract({
    address: FAUCET_ADDRESS,
    abi: faucetAbi,
    functionName: 'lastClaimTime',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  // --- write -------------------------------------------------------------
  const { data: hash, writeContract, isPending, error: writeError } =
    useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({ hash });

  // Refresh balances once a claim confirms.
  useEffect(() => {
    if (isConfirmed) {
      refetchUserBalance();
      refetchFaucetBalance();
      refetchLastClaim();
    }
  }, [isConfirmed, refetchUserBalance, refetchFaucetBalance, refetchLastClaim]);

  // --- cooldown countdown ------------------------------------------------
  const [now, setNow] = useState(() => Math.floor(Date.now() / 1000));
  useEffect(() => {
    const id = setInterval(() => setNow(Math.floor(Date.now() / 1000)), 1000);
    return () => clearInterval(id);
  }, []);

  const dec = decimals ?? 18;
  const nextClaimAt =
    lastClaim !== undefined && cooldownTime !== undefined
      ? Number(lastClaim) + Number(cooldownTime)
      : 0;
  const secondsLeft = Math.max(0, nextClaimAt - now);
  const onCooldown = secondsLeft > 0;

  const wrongNetwork = isConnected && chainId !== SEPOLIA_CHAIN_ID;
  const faucetEmpty =
    faucetBalance !== undefined &&
    claimAmount !== undefined &&
    faucetBalance < claimAmount;

  const fmt = (v?: bigint) =>
    v === undefined ? '—' : Number(formatUnits(v, dec)).toLocaleString();

  const formatDuration = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const sec = s % 60;
    return `${h}h ${m}m ${sec}s`;
  };

  const handleClaim = () => {
    writeContract({
      address: FAUCET_ADDRESS,
      abi: faucetAbi,
      functionName: 'claim',
    });
  };

  const claimDisabled =
    !isConnected ||
    wrongNetwork ||
    onCooldown ||
    faucetEmpty ||
    isPending ||
    isConfirming;

  return (
    <div className="faucet-card">
      <h2>Davee's TST Faucet</h2>
      <p className="faucet-sub">
        Claim {fmt(claimAmount)} {symbol ?? 'TST'} once every{' '}
        {cooldownTime ? Number(cooldownTime) / 3600 : 24}h on Sepolia.
      </p>

      <div className="faucet-stats">
        <div>
          <span className="label">Your balance</span>
          <span className="value">
            {isConnected ? `${fmt(userBalance)} ${symbol ?? ''}` : 'Connect wallet'}
          </span>
        </div>
        <div>
          <span className="label">Faucet remaining</span>
          <span className="value">
            {fmt(faucetBalance)} {symbol ?? ''}
          </span>
        </div>
      </div>

      {!isConnected && (
        <p className="faucet-note">Connect your wallet to claim.</p>
      )}
      {wrongNetwork && (
        <p className="faucet-note error">Switch your wallet to Sepolia.</p>
      )}
      {faucetEmpty && !wrongNetwork && (
        <p className="faucet-note error">The faucet is empty right now.</p>
      )}
      {onCooldown && !wrongNetwork && (
        <p className="faucet-note">
          Next claim available in {formatDuration(secondsLeft)}.
        </p>
      )}

      <button
        className="faucet-btn"
        onClick={handleClaim}
        disabled={claimDisabled}
      >
        {isPending
          ? 'Confirm in wallet…'
          : isConfirming
          ? 'Claiming…'
          : `Claim ${symbol ?? 'TST'}`}
      </button>

      {isConfirmed && (
        <p className="faucet-note success">
          ✅ Claimed! Import token {TOKEN_ADDRESS} in your wallet to see the balance.
        </p>
      )}
      {writeError && (
        <p className="faucet-note error">
          {writeError.message.split('\n')[0]}
        </p>
      )}
      {hash && (
        <a
          className="faucet-link"
          href={`https://sepolia.etherscan.io/tx/${hash}`}
          target="_blank"
          rel="noreferrer"
        >
          View transaction ↗
        </a>
      )}
    </div>
  );
};

export default Faucet;
