import type { ReactNode } from 'react'
import Header from '../components/Header'

type LayoutProps = {
  children: ReactNode
}

export default function DashboardLayout({ children }: LayoutProps) {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f8fafc' }}>
        <Header/>
      <main>{children}</main>
          <footer>Footer</footer>
    </div>
  )
}