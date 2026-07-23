import { ConnectButton } from '@rainbow-me/rainbowkit'
import Link from 'next/link'
import React from 'react'

const Header = () => {
  return (
    <div className='w-full bg-gray-100 flex justify-between items-center p-5'>
      <div className="font-extrabold text-4xl text-blue-700">Open River</div>
      <div className="flex gap-5">
        <Link href={"/"}>Home</Link>
        <Link href={"/mint"}>Minting</Link>
        <Link href={"/list"}>Listing</Link>
        <Link href={"/myNFT"}>MyNFTs</Link>

      </div>
      <div className="cta"><ConnectButton/></div>
    </div>
  )
}

export default Header