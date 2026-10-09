"use client"

import { useEffect, useState } from "react"

import { NavDownload } from "@/components/download-button"
import { GelDrop } from "@/components/gel-drop"
import { Container } from "@/components/section"
import { cn } from "@/lib/utils"

const LINKS = [
  { href: "#research", label: "Research" },
  { href: "#how-it-works", label: "How it works" },
  { href: "#privacy", label: "Privacy" },
  { href: "#install", label: "Install" },
  { href: "#faq", label: "FAQ" },
]

export function Nav() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  return (
    <header
      className={cn(
        "sticky top-0 z-40 border-b border-transparent transition-colors duration-150 ease-standard",
        scrolled && "border-border bg-card/85 backdrop-blur-md",
      )}
    >
      <Container className="flex h-14 items-center justify-between gap-4">
        <a
          href="#top"
          className="flex items-center gap-2 rounded-md text-base font-medium tracking-[-0.011em] text-foreground outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
        >
          <GelDrop className="size-5" />
          Gel
        </a>
        <div className="flex items-center gap-2">
          <nav aria-label="Sections" className="hidden md:block">
            <ul className="flex items-center">
              {LINKS.map((l) => (
                <li key={l.href}>
                  <a
                    href={l.href}
                    className="rounded-md px-3 py-2 text-[13px] text-body underline-offset-4 outline-none transition-colors duration-150 hover:text-foreground hover:underline focus-visible:ring-3 focus-visible:ring-ring/50"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </nav>
          <NavDownload className="ml-2" />
        </div>
      </Container>
    </header>
  )
}
