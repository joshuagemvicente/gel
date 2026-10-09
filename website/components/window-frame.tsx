import { cn } from "@/lib/utils"

// A macOS window frame: Carbon fill, Graphite hairline, Ash traffic lights, centred title. No shadow (design.md).
export function WindowFrame({
  title,
  className,
  bodyClassName,
  children,
}: {
  title?: string
  className?: string
  bodyClassName?: string
  children: React.ReactNode
}) {
  return (
    <div className={cn("overflow-hidden rounded-xl border bg-card", className)}>
      <div className="relative flex h-9 items-center border-b px-3.5">
        <div className="flex gap-1.5" aria-hidden>
          <span className="size-2.5 rounded-full bg-faint" />
          <span className="size-2.5 rounded-full bg-faint" />
          <span className="size-2.5 rounded-full bg-faint" />
        </div>
        {title && (
          <p className="absolute inset-x-16 truncate text-center text-[13px] text-muted-foreground">
            {title}
          </p>
        )}
      </div>
      <div className={bodyClassName}>{children}</div>
    </div>
  )
}
