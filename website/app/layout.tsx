import type { Metadata, Viewport } from "next"
import { JetBrains_Mono } from "next/font/google"
import localFont from "next/font/local"

import { Providers } from "@/components/providers"
import "./globals.css"

// rsms's own Inter build (inter-ui): Google Fonts' Inter drops the cv01, ss03 and zero features the design uses (D-074, D-081).
const inter = localFont({
  src: "../node_modules/inter-ui/variable-latin/InterVariable-subset.woff2",
  variable: "--font-inter",
  weight: "100 900",
  display: "swap",
})

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
})

const description =
  "Gel warns you before personal data is pasted into an AI chat, and blacks it out of files before you upload them. Runs on your Mac."

// NEXT_PUBLIC_SITE_URL wins; on Vercel the production domain is used; locally, localhost.
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000")

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Gel: use AI without leaking personal data",
  description,
  openGraph: { title: "Gel: use AI without leaking personal data", description, type: "website" },
  twitter: { card: "summary_large_image", title: "Gel: use AI without leaking personal data", description },
}

export const viewport: Viewport = {
  themeColor: "#08090a",
  colorScheme: "dark",
}

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`dark ${inter.variable} ${jetbrainsMono.variable} antialiased`}>
      <body className="min-h-dvh">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
