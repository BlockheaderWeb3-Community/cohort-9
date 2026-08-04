import { ConnectButton } from '@rainbow-me/rainbowkit'
import Link from 'next/link'
import { useRouter } from 'next/router'

const navLinks = [
  { href: '/', label: 'Explore' },
  { href: '/mint', label: 'Mint' },
  { href: '/list', label: 'List' },
  { href: '/myNFT', label: 'My NFTs' },
]

const Header = () => {
  const router = useRouter()

  return (
    <header className="sticky top-0 z-50 w-full border-b border-white/10 bg-[#0a0a0f]/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 no-underline">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500 to-indigo-600">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="white">
              <path d="M8 1C4.13 1 1 4.13 1 8s3.13 7 7 7 7-3.13 7-7-3.13-7-7-7zm0 2.5c1.38 0 2.5 1.12 2.5 2.5S9.38 8.5 8 8.5 5.5 7.38 5.5 6 6.62 3.5 8 3.5zm0 9c-1.75 0-3.29-.9-4.2-2.26C3.85 9.06 5.85 8.5 8 8.5s4.15.56 4.2 1.74C11.29 11.6 9.75 12.5 8 12.5z" />
            </svg>
          </div>
          <span className="text-xl font-bold text-white tracking-tight">
            Open<span className="text-violet-400">River</span>
          </span>
        </Link>

        {/* Nav links */}
        <nav className="hidden md:flex items-center gap-1">
          {navLinks.map(({ href, label }) => (
            <Link
              key={href}
              href={href}
              className={`rounded-lg px-4 py-2 text-sm font-medium no-underline transition-colors ${
                router.pathname === href
                  ? 'bg-white/10 text-white'
                  : 'text-slate-400 hover:bg-white/5 hover:text-white'
              }`}
            >
              {label}
            </Link>
          ))}
        </nav>

        {/* Wallet */}
        <ConnectButton showBalance={false} chainStatus="icon" accountStatus="avatar" />
      </div>
    </header>
  )
}

export default Header
