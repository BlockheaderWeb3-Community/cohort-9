# OpenRiver - Explicación Completa del Código en ES5

## Tabla de Contenidos
1. [Estructura General](#estructura-general)
2. [Configuración Principal (_app.tsx)](#configuración-principal)
3. [Configuración Web3 (wagmi.ts)](#configuración-web3)
4. [Layout (layout.tsx)](#layout)
5. [Header (Header.tsx)](#header)
6. [Componentes de Tarjetas (Card.tsx, Cards.tsx)](#componentes-tarjetas)
7. [Páginas (list, mint, dashboard, marketplace, myNFT)](#páginas)
8. [Contratos Inteligentes (contracts.ts)](#contratos)

---

## Estructura General

Este es un proyecto de **NFT Marketplace** construido con:
- **Next.js**: Framework React para aplicaciones web
- **wagmi**: Librería para interactuar con contratos de Ethereum
- **RainbowKit**: Interfaz para conectar carteras de criptomonedas
- **Tailwind CSS**: Framework para estilos

El proyecto permite a usuarios:
✓ Conectar su cartera de criptomonedas
✓ Crear (mintear) nuevos NFTs
✓ Listar NFTs en el mercado
✓ Ver NFTs disponibles para comprar
✓ Ver su colección personal de NFTs

---

## Configuración Principal (_app.tsx)

```typescript
import '../styles/globals.css';
import '@rainbow-me/rainbowkit/styles.css';
```

**Línea por línea:**

1. `import '../styles/globals.css'`
   - Importa los estilos CSS globales que se aplican a toda la aplicación
   - Estos estilos definen el look general de la aplicación

2. `import '@rainbow-me/rainbowkit/styles.css'`
   - Importa los estilos de la librería RainbowKit
   - Estila el botón de conectar cartera y los modales

```typescript
import type { AppProps } from 'next/app';
```

3. `import type { AppProps }`
   - Importa el tipo TypeScript que define las propiedades que recibe el componente App
   - `AppProps` contiene `Component` (el componente actual) y `pageProps` (las propiedades)

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
```

4. `QueryClient` - Objeto que maneja el caché de datos
5. `QueryClientProvider` - Componente que proporciona QueryClient a toda la aplicación

```typescript
import { WagmiProvider } from 'wagmi';
```

6. `WagmiProvider` - Componente que proporciona funciones para interactuar con Ethereum a toda la aplicación

```typescript
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
```

7. `RainbowKitProvider` - Componente que proporciona la interfaz de cartera a toda la aplicación

```typescript
import { config } from '../wagmi';
import DashboardLayout from './layout';
```

8. `config` - Configuración de wagmi (redes, proyecto ID, etc.)
9. `DashboardLayout` - Componente que proporciona el header y footer a todas las páginas

```typescript
const client = new QueryClient();
```

10. Se crea una instancia de QueryClient para manejar datos

```typescript
function MyApp({ Component, pageProps }: AppProps) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={client}>
        <RainbowKitProvider>
          <DashboardLayout>
            <Component {...pageProps} />
          </DashboardLayout>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

11. `MyApp` es el componente raíz que envuelve toda la aplicación

**Estructura de Providers (como cajas anidadas):**
```
WagmiProvider (acceso a Ethereum)
  └─ QueryClientProvider (caché de datos)
     └─ RainbowKitProvider (cartera)
        └─ DashboardLayout (header y footer)
           └─ Component (página actual)
```

Cada provider proporciona funcionalidades especiales a sus componentes internos.

---

## Configuración Web3 (wagmi.ts)

```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
```

1. `getDefaultConfig` - Función que crea una configuración lista para usar
2. `sepolia` - Red de prueba de Ethereum (usada para desarrollo, no requiere dinero real)

```typescript
export const config = getDefaultConfig({
  appName: 'RainbowKit App',
```

3. `appName` - Nombre de la aplicación que aparecerá en la cartera

```typescript
  projectId: 'd69f9edb23bbe0354a3b186e1bee340c',
```

4. `projectId` - ID único para este proyecto en WalletConnect (servicio que conecta aplicaciones con carteras)

```typescript
  chains: [sepolia],
```

5. `chains` - Array de redes disponibles. Aquí solo Sepolia (red de prueba)

```typescript
  ssr: true,
```

6. `ssr: true` - Server-Side Rendering habilitado (renderiza en el servidor para mejor rendimiento)

---

## Layout (layout.tsx)

```typescript
import type { ReactNode } from 'react'
import Header from '../components/Header'

type LayoutProps = {
  children: ReactNode
}
```

1. `ReactNode` - Tipo que representa cualquier contenido React (componentes, texto, etc.)
2. `LayoutProps` - Define que este componente recibe `children` (contenido interno)

```typescript
export default function DashboardLayout({ children }: LayoutProps) {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f8fafc' }}>
        <Header/>
      <main>{children}</main>
          <footer>Footer</footer>
    </div>
  )
}
```

3. `minHeight: '100vh'` - La altura mínima es la altura total de la pantalla
4. `backgroundColor: '#f8fafc'` - Color de fondo gris claro
5. `<Header/>` - Componente de navegación
6. `{children}` - Aquí va el contenido de cada página
7. `<footer>` - Pie de página

Este componente es como una "plantilla" que todas las páginas usan.

---

## Header (Header.tsx)

```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit'
import Link from 'next/link'
```

1. `ConnectButton` - Botón que permite conectar la cartera
2. `Link` - Componente de Next.js para navegación entre páginas

```typescript
const Header = () => {
  return (
    <div className='w-full bg-gray-100 flex justify-between items-center p-5'>
```

3. `w-full` - Ancho completo
4. `bg-gray-100` - Fondo gris claro
5. `flex justify-between items-center` - Alinea elementos horizontalmente con espacio entre ellos
6. `p-5` - Padding (espacio interno) de 5 unidades

```typescript
      <div className="font-extrabold text-4xl text-blue-700">Open River</div>
```

7. Título de la aplicación en azul, muy grande y negrita

```typescript
      <div className="flex gap-5">
        <Link href={"/"}>Home</Link>
        <Link href={"/dashboard"}>Dashboard</Link>
        <Link href={"/mint"}>Minting</Link>
        <Link href={"/list"}>Listing</Link>
        <Link href={"/myNFT"}>MyNFTs</Link>
      </div>
```

8. Menú de navegación con 5 enlaces (Home, Dashboard, Minting, Listing, MyNFTs)
9. `gap-5` - Espacio de 5 unidades entre cada enlace

```typescript
      <div className="cta"><ConnectButton/></div>
```

10. `cta` - "Call To Action" (botón para conectar cartera en el lado derecho)

---

## Componentes Tarjetas (Card.tsx y Cards.tsx)

### Cards.tsx (Contenedor de múltiples tarjetas)

```typescript
export const Cards = ({ nftNum }: { nftNum?: bigint }) => {
```

1. Recibe `nftNum` - el número total de NFTs (tipo `bigint` = número muy grande)

```typescript
    const { data: tokenIdsRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });
```

2. `useReadContract` - Hook que llama a una función de lectura del contrato
3. `abi` - "Application Binary Interface" - interfaz del contrato
4. `address` - Dirección del contrato en Ethereum
5. `functionName: "tokenIds"` - Llamamos a la función `tokenIds` del contrato
6. `data` - Resultado de la llamada

```typescript
    const tokenIds = tokenIdsRaw as bigint | undefined;
    const count = nftNum ?? tokenIds;
```

7. `as bigint | undefined` - Decimos que el resultado es un número grande o indefinido
8. `??` - Si `nftNum` es nulo, usamos `tokenIds`

```typescript
    return (
        <div className="flex gap-10 flex-wrap w-360 mt-5 m-auto">
            {Array.from({ length: Number(count ?? 0) }, (_, i) => i + 1).map((index) => (
                <Card key={index} tokenId={BigInt(index)} />
            ))}
        </div>
    )
```

9. `flex gap-10 flex-wrap` - Los elementos se colocan horizontalmente con espacio, envolviendo en nuevas líneas
10. `Array.from(...)` - Crea un array con números del 1 al total de NFTs
11. `.map(...)` - Por cada número, crea un componente `<Card>`
12. `key={index}` - Identifica únicamente cada Card
13. `tokenId={BigInt(index)}` - Envía el ID del NFT a Card

### Card.tsx (Una sola tarjeta de NFT)

```typescript
const Card = ({ tokenId, showOnlyListed }: { tokenId: bigint; showOnlyListed?: boolean }) => {
```

1. Recibe `tokenId` - ID único del NFT
2. Recibe `showOnlyListed` - Si es true, solo muestra NFTs listados (opcional)

```typescript
  const { data: onchainNFT } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenURI',
    args: [tokenId],
  });
```

3. Llama a `tokenURI` del contrato para obtener la URL del NFT
4. `args: [tokenId]` - Envía el ID del NFT como parámetro

```typescript
  const normalizedImageSrc = React.useMemo(() => {
    if (typeof onchainNFT !== 'string' || !onchainNFT) {
      return null;
    }
    if (onchainNFT.startsWith('ipfs://')) {
      return `https://ipfs.io/ipfs/${onchainNFT.replace('ipfs://', '')}`;
    }
    return onchainNFT;
  }, [onchainNFT]);
```

5. `useMemo` - Optimización: solo recalcula si `onchainNFT` cambia
6. Si la URL es de IPFS (almacenamiento descentralizado), la convierte a HTTP
7. Ejemplo: `ipfs://QmX...` → `https://ipfs.io/ipfs/QmX...`

```typescript
  const { data: marketData } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'marketplace',
    args: [tokenId],
  });
```

8. Obtiene datos de mercado del NFT (si está listado, precio, etc.)

```typescript
  React.useEffect(() => {
    console.log(`Token ${tokenId.toString()} marketplace data:`, marketData);
  }, [marketData, tokenId]);
```

9. `useEffect` - Se ejecuta cuando `marketData` o `tokenId` cambian
10. Registra en consola los datos (para debugging)

```typescript
  const isListed = (() => {
    if (!marketData) return false;
    if (Array.isArray(marketData)) return marketData[0];
    return (marketData as any).listing ?? false;
  })();
```

11. Determina si el NFT está listado
12. Maneja dos formatos: array o objeto

```typescript
  const priceWei = (() => {
    if (!marketData) return BigInt(0);
    if (Array.isArray(marketData)) return marketData[1] as bigint;
    return (marketData as any).price ?? BigInt(0);
  })();
  
  const priceEth = formatEther(priceWei);
```

13. Obtiene el precio en Wei (unidad pequeña de Ethereum)
14. `formatEther` - Convierte Wei a ETH (unidad legible)
15. Ejemplo: 1000000000000000000 Wei = 1 ETH

```typescript
  if (showOnlyListed && !isListed) {
    return null;
  }
```

16. Si solo queremos NFTs listados y este no lo está, no mostramos nada

```typescript
  return (
    <div className="w-full max-w-[300px] rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex h-[180px] items-center justify-center overflow-hidden rounded-md bg-slate-100">
        {normalizedImageSrc ? (
          <img
            alt={`NFT #${tokenId}`}
            src={normalizedImageSrc}
            className="h-full w-full object-cover"
          />
        ) : (
          <p className="text-sm text-slate-500">NFT image unavailable</p>
        )}
      </div>
      <div className="flex justify-between py-5">
        <h2 className="text-3xl">#{tokenId.toString()}</h2>
        <h2 className="text-3xl font-bold">
          {isListed ? `${priceEth} ETH` : 'Not listed'}
        </h2>
      </div>
    </div>
  );
```

17. `max-w-[300px]` - Ancho máximo de 300 píxeles
18. `rounded-lg` - Esquinas redondeadas
19. `border border-slate-200` - Borde gris
20. `shadow-sm` - Sombra pequeña
21. `h-[180px]` - Altura de imagen de 180px
22. Muestra la imagen del NFT o mensaje si no hay
23. Muestra el ID del NFT (ej: #1)
24. Muestra el precio en ETH o "Not listed"

---

## Páginas

### list/index.tsx - Página para Listar NFTs

```typescript
const index = () => {
    const { writeContract: listNFT } = useWriteContract();
```

1. `useWriteContract` - Hook para escribir en el contrato (realizar transacciones)
2. `writeContract` se renombra como `listNFT`

```typescript
    const [tokenId, setTokenId] = useState(0);
    const [price, setPrice] = useState(0);
```

3. Estado local para guardar ID del NFT y precio
4. Inician en 0

```typescript
    const handleListNFT = () => {
        listNFT({
            abi: openriverAbi,
            address: openriverAddress,
            functionName: "listOnMarketplace",
            args: [
                BigInt(tokenId),
                BigInt(price),
            ],
        });
    };
```

5. Función que se llama al hacer clic en "List NFT"
6. Llama a `listOnMarketplace` en el contrato
7. Envía el ID y precio como parámetros
8. `BigInt()` - Convierte números a formato que el contrato entiende

```typescript
    return (
        <div className='mt-20'>
            <div className="flex flex-col gap-5 items-center justify-center">
                <input
                    className='w-125 p-5'
                    type="number"
                    placeholder="Token Id"
                    onChange={(e) => setTokenId(Number(e.target.value))}
                />
```

9. `mt-20` - Margen superior de 20 unidades
10. `flex flex-col` - Elementos apilados verticalmente
11. Input para número del NFT
12. `onChange` - Actualiza estado cuando el usuario escribe

```typescript
                <input
                    className='w-125 p-5'
                    type="number"
                    placeholder="Price (in Wei)"
                    onChange={(e) => setPrice(Number(e.target.value))}
                />
```

13. Input para el precio en Wei

```typescript
                <Button label="List NFT" onClick={handleListNFT} />
```

14. Botón que ejecuta `handleListNFT`

### mint/index.tsx - Página para Crear NFTs

Estructura similar a `list`, pero llama a `newItem` en lugar de `listOnMarketplace`.

### dashboard/index.tsx - Panel de Control

```typescript
const { address, isConnected } = useAccount();
```

1. `useAccount` - Hook que obtiene información de la cartera conectada
2. `address` - Dirección de la cartera
3. `isConnected` - Si la cartera está conectada

```typescript
    const { data: totalSupplyRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });
```

4. Obtiene el número total de NFTs creados

```typescript
    const { data: ownedCount } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "balanceOf",
        args: address ? [address] : undefined,
        query: { enabled: !!address },
    }) as { data?: bigint };
```

5. Obtiene cuántos NFTs posee el usuario actual
6. `args: address ? [address] : undefined` - Solo llama si hay dirección
7. `enabled: !!address` - Solo ejecuta la consulta si hay dirección

```typescript
    if (!isConnected) {
        return (
            <div className="flex flex-col items-center justify-center mt-32 gap-4">
                <p className="text-xl text-slate-600">Connect your wallet to view your dashboard.</p>
            </div>
        );
    }
```

8. Si no hay cartera conectada, muestra mensaje

```typescript
    return (
        <div className="max-w-3xl mx-auto mt-16 px-6">
            <h1 className="text-3xl font-extrabold text-blue-700 mb-8">Dashboard</h1>

            <div className="grid grid-cols-2 gap-6 mb-10">
                <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
                    <p className="text-sm text-slate-500 mb-1">Total NFTs minted</p>
                    <p className="text-4xl font-bold text-blue-700">{totalSupply?.toString() ?? '—'}</p>
                </div>
                <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
                    <p className="text-sm text-slate-500 mb-1">NFTs you own</p>
                    <p className="text-4xl font-bold text-blue-700">{ownedCount?.toString() ?? '—'}</p>
                </div>
            </div>
```

9. `grid grid-cols-2` - Crea 2 columnas
10. Muestra dos cajas: NFTs totales y NFTs del usuario
11. `??` - Si el valor es null, muestra "—"

### marketplace/index.tsx - Página del Mercado

```typescript
const Marketplace: NextPage = () => {
    const { data: totalSupplyRaw } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const totalSupply = totalSupplyRaw as bigint | undefined;

    return (
        <div className="mt-16 px-6">
            <h1 className="text-3xl font-extrabold text-blue-700 mb-8">Marketplace</h1>
            
            <div className="flex gap-10 flex-wrap w-full">
                {Array.from({ length: Number(totalSupply ?? 0) }, (_, i) => i + 1).map((index) => (
                    <div key={index} className="flex-shrink-0">
                        <Card tokenId={BigInt(index)} showOnlyListed={true} />
                    </div>
                ))}
            </div>

            {totalSupply === BigInt(0) && (
                <div className="text-center mt-12">
                    <p className="text-xl text-slate-500">No NFTs listed yet</p>
                </div>
            )}
        </div>
    );
};
```

1. Obtiene el número total de NFTs
2. Itera por cada NFT y muestra Card
3. `showOnlyListed={true}` - Solo muestra NFTs listados para venta
4. Si no hay NFTs, muestra mensaje

### myNFT/index.tsx - Mis NFTs

```typescript
const MyNFT: NextPage = () => {
    const { data } = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "tokenIds",
    });

    const nftmaxNum = data as bigint | undefined;

    return (
        <div>
            <p>{nftmaxNum?.toString()}</p>
            <main>
                <Cards nftNum={nftmaxNum} />
            </main>
        </div>
    );
};
```

1. Obtiene total de NFTs
2. Muestra el número total
3. Usa el componente `<Cards>` para mostrar todos

---

## Contratos Inteligentes (contracts.ts)

Este archivo contiene:

1. **openriverAddress** - La dirección del contrato en Ethereum
2. **openriverAbi** - Especificación de todas las funciones del contrato

### Funciones Principales del Contrato:

**approve(address to, uint256 tokenId)**
- Autoriza a otra dirección a transferir tu NFT

**listOnMarketplace(uint256 _tokenId, uint256 _price)**
- Lista un NFT en el mercado a un precio específico
- Parámetros: ID del NFT, precio en Wei

**removeFromMarketplace(uint256 _tokenId)**
- Quita un NFT de la venta

**balanceOf(address account)**
- Retorna cuántos NFTs posee una dirección

**tokenIds()**
- Retorna el número total de NFTs creados

**marketplace(uint256 tokenId)**
- Retorna información del NFT:
  - listing (bool) - ¿está listado?
  - price (uint256) - precio en Wei
  - publisher (address) - quién lo creó
  - royalty (uint256) - regalías del creador

**newItem(string tokenURI, uint256 royalty)**
- Crea un nuevo NFT
- Parámetros: URL de metadatos, porcentaje de regalías

**tokenURI(uint256 tokenId)**
- Retorna la URL de los metadatos del NFT (imagen, descripción, etc.)

---

## Flujo Completo de la Aplicación

1. **Usuario abre la app**
   - Componente `_app.tsx` carga
   - Todos los Providers se inicializan
   - El usuario ve el Header y puede navegar

2. **Usuario se conecta con cartera**
   - Hace clic en ConnectButton (en Header)
   - RainbowKit muestra opciones de cartera
   - Se conecta a su cartera

3. **Usuario va al Dashboard**
   - Ve cuántos NFTs existen en total
   - Ve cuántos NFTs posee él

4. **Usuario va a Minting**
   - Ingresa URL del NFT y regalías
   - Hace clic en "Mint"
   - Se crea un nuevo NFT

5. **Usuario va a Listing**
   - Ingresa el ID del NFT y precio
   - Hace clic en "List"
   - El NFT se lista en el mercado

6. **Usuario va al Marketplace**
   - Ve todos los NFTs listados (solo los que tienen `listing = true`)
   - Ve el precio de cada uno en ETH

7. **Usuario va a MyNFTs**
   - Ve todos sus NFTs (listados o no)
   - Ve los precios de los que están listados

---

## Resumen de Tecnologías

| Tecnología | Propósito |
|-----------|----------|
| Next.js | Framework React con rutas automáticas |
| React | Librería para crear interfaces |
| wagmi | Interactuar con contratos de Ethereum |
| RainbowKit | Conectar carteras de criptomonedas |
| Tailwind CSS | Estilos CSS predefinidos |
| Ethereum/Solidity | Contratos inteligentes en blockchain |

---

## Conceptos Clave

**BigInt**: Números muy grandes que usa JavaScript para Ethereum (hasta 2^256)

**Wei**: Unidad más pequeña de Ethereum. 1 ETH = 1,000,000,000,000,000,000 Wei

**ABI**: Especificación de cómo hablar con un contrato (qué funciones tiene, qué parámetros)

**Hook**: Función de React que proporciona funcionalidad especial (`useReadContract`, `useState`, etc.)

**Provider**: Componente que proporciona funcionalidades a todos sus componentes internos

**Blockchain**: Red de computadoras que mantiene un registro permanente de transacciones

**NFT**: "Non-Fungible Token" - activo digital único que no puede ser copiado
