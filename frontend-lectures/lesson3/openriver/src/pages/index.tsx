import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import Header from '../components/Header';
import { Cards } from '../components/Cards';

const Home: NextPage = () => {
  return (
    <div className="">
      <Header />
      <main className="">
        <Cards />
        </main>
      <footer>Footer</footer>
    </div>
  );
};

export default Home;
