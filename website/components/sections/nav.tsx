"use client"

import { useEffect, useState } from "react"

import { DownloadButton } from "@/components/download-button"
import { GelDrop } from "@/components/gel-drop"
import { Container } from "@/components/section"
import { ThemeToggle } from "@/components/theme-toggle"
import { cn } from "@/lib/utils"

const LINKS = [
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
        scrolled && "border-border bg-background/85 backdrop-blur-md",
      )}
    >
      <Container className="flex h-16 items-center justify-between gap-4">
        <a href="#top" className="flex items-center gap-2 rounded-md text-xl font-semibold tracking-[-0.015em]">
          <GelDrop className="size-6" />
          Gel
        </a>
        <nav aria-label="Sections" className="hidden md:block">
          <ul className="flex items-center gap-1">
            {LINKS.map((l) => (
              <li key={l.href}>
                <a
                  href={l.href}
                  className="rounded-md px-3 py-2 text-sm text-muted-foreground transition-colors duration-150 hover:text-foreground"
                >
                  {l.label}
                </a>
              </li>
            ))}
          </ul>
        </nav>
        <div className="flex items-center gap-1.5">
          <ThemeToggle />
          <DownloadButton size="default" label="Download" className="h-8 px-3" />
        </div>
      </Container>
    </header>
  )
}
