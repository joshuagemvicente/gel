import { Ask } from "@/components/sections/ask"
import { Claims } from "@/components/sections/claims"
import { Faq } from "@/components/sections/faq"
import { Footer } from "@/components/sections/footer"
import { Hero } from "@/components/sections/hero"
import { HowItWorks } from "@/components/sections/how-it-works"
import { Install } from "@/components/sections/install"
import { Nav } from "@/components/sections/nav"
import { Privacy } from "@/components/sections/privacy"
import { Research } from "@/components/sections/research"
import { Uses } from "@/components/sections/uses"

export default function Home() {
  return (
    <>
      <a
        href="#main"
        className="sr-only z-50 rounded-md bg-card px-3 py-2 focus:not-sr-only focus:fixed focus:top-3 focus:left-3"
      >
        Skip to content
      </a>
      <Nav />
      <main id="main">
        <Hero />
        <Research />
        <Claims />
        <Uses />
        <HowItWorks />
        <Privacy />
        <Ask />
        <Install />
        <Faq />
      </main>
      <Footer />
    </>
  )
}
