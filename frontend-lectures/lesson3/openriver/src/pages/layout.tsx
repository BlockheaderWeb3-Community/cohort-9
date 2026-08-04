import type { ReactNode } from 'react'
import Header from '../components/Header'

type LayoutProps = {
  children: ReactNode
}

export default function DashboardLayout({ children }: LayoutProps) {
  return (
    <div className="min-h-screen bg-[#0a0a0f]">
      <Header />
      <main>{children}</main>
      <footer className="mt-16 border-t border-white/10 py-8 text-center text-sm text-slate-600">
        © 2024 OpenRiver · Built on Sepolia
      </footer>
    </div>
  )
}
