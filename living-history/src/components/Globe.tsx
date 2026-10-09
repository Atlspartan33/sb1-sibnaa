import { useEffect, useMemo, useRef, useState } from 'react';
import type { KeyboardEvent as ReactKeyboardEvent, PointerEvent as ReactPointerEvent } from 'react';
import { geoDistance, geoGraticule10, geoOrthographic, geoPath } from 'd3-geo';
import { feature } from 'topojson-client';
import type { GeometryCollection, Topology } from 'topojson-specification';
import landTopology from 'world-atlas/land-110m.json';
import type { Civilization } from '../types';
import { isActiveIn } from '../data/civilizations';

type Rotation = [number, number];

const topology = landTopology as unknown as Topology<{ land: GeometryCollection }>;
const land = feature(topology, topology.objects.land);
const graticule = geoGraticule10();

const AUTO_ROTATE_DEG_PER_SEC = 4;
const FLY_TO_MS = 900;
const DRAG_THRESHOLD_PX = 4;

function shortestAngle(from: number, to: number): number {
  return ((((to - from) % 360) + 540) % 360) - 180;
}

function easeInOutCubic(t: number): number {
  return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;
}

function prefersReducedMotion(): boolean {
  return typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

interface Props {
  civilizations: Civilization[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  /** When set, civilizations that did not exist in this year are dimmed. */
  year: number | null;
}

export default function Globe({ civilizations, selectedId, onSelect, year }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState(320);
  const [rotation, setRotation] = useState<Rotation>([-20, -20]);
  const [hoveredId, setHoveredId] = useState<string | null>(null);

  const rotationRef = useRef(rotation);
  rotationRef.current = rotation;
  const dragRef = useRef<{ x: number; y: number; start: Rotation; moved: boolean } | null>(null);
  const suppressClickRef = useRef(false);
  const flyingRef = useRef(false);
  const pausedRef = useRef(false);
  pausedRef.current = selectedId !== null || hoveredId !== null;

  // Keep the globe square and as large as its container allows.
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const observer = new ResizeObserver(([entry]) => {
      setSize(Math.max(260, Math.min(entry.contentRect.width, 640)));
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  // Slow idle spin, paused while dragging, flying, hovering, or when something is selected.
  useEffect(() => {
    if (prefersReducedMotion()) return;
    let frame = 0;
    let last = performance.now();
    const tick = (now: number) => {
      const dt = (now - last) / 1000;
      last = now;
      if (!dragRef.current && !flyingRef.current && !pausedRef.current) {
        setRotation(([lambda, phi]) => [lambda + AUTO_ROTATE_DEG_PER_SEC * dt, phi]);
      }
      frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, []);

  // Fly to the selected civilization.
  useEffect(() => {
    const civ = civilizations.find((c) => c.id === selectedId);
    if (!civ) return;
    const from = rotationRef.current;
    const target: Rotation = [-civ.location.lng, Math.max(-50, Math.min(50, -civ.location.lat))];
    const dLambda = shortestAngle(from[0], target[0]);
    const dPhi = target[1] - from[1];

    if (prefersReducedMotion()) {
      setRotation(target);
      return;
    }

    flyingRef.current = true;
    const startTime = performance.now();
    let frame = 0;
    const step = (now: number) => {
      const t = Math.min(1, (now - startTime) / FLY_TO_MS);
      const k = easeInOutCubic(t);
      setRotation([from[0] + dLambda * k, from[1] + dPhi * k]);
      if (t < 1) frame = requestAnimationFrame(step);
      else flyingRef.current = false;
    };
    frame = requestAnimationFrame(step);
    return () => {
      cancelAnimationFrame(frame);
      flyingRef.current = false;
    };
  }, [selectedId, civilizations]);

  const radius = size / 2 - 8;
  const projection = useMemo(
    () => geoOrthographic().scale(radius).translate([size / 2, size / 2]).rotate(rotation).clipAngle(90),
    [radius, size, rotation]
  );
  const path = geoPath(projection);

  const handlePointerDown = (e: ReactPointerEvent<SVGSVGElement>) => {
    if (e.button !== 0) return;
    dragRef.current = { x: e.clientX, y: e.clientY, start: rotationRef.current, moved: false };
    flyingRef.current = false;

    const onMove = (ev: PointerEvent) => {
      const drag = dragRef.current;
      if (!drag) return;
      const dx = ev.clientX - drag.x;
      const dy = ev.clientY - drag.y;
      if (!drag.moved && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX) return;
      drag.moved = true;
      // One radius of drag turns the globe about one radian.
      const degPerPx = 180 / Math.PI / radius;
      setRotation([drag.start[0] + dx * degPerPx, Math.max(-70, Math.min(70, drag.start[1] - dy * degPerPx))]);
    };
    const onUp = () => {
      suppressClickRef.current = dragRef.current?.moved ?? false;
      dragRef.current = null;
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerup', onUp);
      window.removeEventListener('pointercancel', onUp);
    };
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
    window.addEventListener('pointercancel', onUp);
  };

  const select = (id: string) => {
    if (suppressClickRef.current) {
      suppressClickRef.current = false;
      return;
    }
    onSelect(id);
  };

  const handleKey = (e: ReactKeyboardEvent, id: string) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onSelect(id);
    }
  };

  const center: [number, number] = [-rotation[0], -rotation[1]];
  const markers = civilizations
    .map((civ) => {
      const coords: [number, number] = [civ.location.lng, civ.location.lat];
      const point = projection(coords);
      const visible = geoDistance(coords, center) < Math.PI / 2 - 0.04;
      return { civ, point, visible };
    })
    .filter((m): m is { civ: Civilization; point: [number, number]; visible: boolean } => m.point !== null && m.visible);

  return (
    <div ref={containerRef} className="mx-auto w-full max-w-[640px]">
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className="mx-auto block cursor-grab touch-none select-none active:cursor-grabbing"
        onPointerDown={handlePointerDown}
        role="group"
        aria-label="Interactive globe of civilizations. Drag to rotate; select a marker to learn more."
      >
        <defs>
          <radialGradient id="ocean" cx="38%" cy="32%" r="75%">
            <stop offset="0%" stopColor="#2f4f8f" />
            <stop offset="65%" stopColor="#1b2f57" />
            <stop offset="100%" stopColor="#111c33" />
          </radialGradient>
          <radialGradient id="glow" cx="50%" cy="50%" r="50%">
            <stop offset="85%" stopColor="#d08a3c" stopOpacity="0.25" />
            <stop offset="100%" stopColor="#d08a3c" stopOpacity="0" />
          </radialGradient>
          <radialGradient id="shade" cx="35%" cy="30%" r="80%">
            <stop offset="55%" stopColor="#000" stopOpacity="0" />
            <stop offset="100%" stopColor="#000" stopOpacity="0.45" />
          </radialGradient>
        </defs>

        <circle cx={size / 2} cy={size / 2} r={radius + 8} fill="url(#glow)" />
        <path d={path({ type: 'Sphere' }) ?? undefined} fill="url(#ocean)" />
        <path d={path(graticule) ?? undefined} fill="none" stroke="#f5eedd" strokeOpacity={0.08} strokeWidth={0.6} />
        <path d={path(land) ?? undefined} fill="#dcc28a" stroke="#965620" strokeOpacity={0.35} strokeWidth={0.5} />
        <path d={path({ type: 'Sphere' }) ?? undefined} fill="url(#shade)" pointerEvents="none" />

        {markers.map(({ civ, point: [x, y] }) => {
          const active = year === null || isActiveIn(civ, year);
          const selected = civ.id === selectedId;
          const hovered = civ.id === hoveredId;
          const published = civ.status === 'published';
          const r = selected ? 9 : published ? 7 : 5.5;
          const showLabel = selected || hovered || (published && active);
          // Rough text width at 12px; flip the label to the left if it would run off the edge.
          const flipLabel = x + r + 6 + civ.name.length * 6.6 > size;

          return (
            <g
              key={civ.id}
              transform={`translate(${x}, ${y})`}
              role="button"
              tabIndex={0}
              aria-label={`${civ.name}, ${civ.dateLabel}${active ? '' : ', not in the selected year'}`}
              aria-pressed={selected}
              className="cursor-pointer outline-none focus-visible:[&>circle:last-of-type]:stroke-white"
              opacity={active ? 1 : 0.3}
              onClick={() => select(civ.id)}
              onKeyDown={(e) => handleKey(e, civ.id)}
              onPointerEnter={() => setHoveredId(civ.id)}
              onPointerLeave={() => setHoveredId((h) => (h === civ.id ? null : h))}
            >
              {/* Larger invisible hit area for touch. */}
              <circle r={16} fill="transparent" />
              {published && active && !selected && (
                <circle r={r} fill="none" stroke="#d08a3c" strokeWidth={2} className="animate-ping-slow" />
              )}
              {selected && <circle r={r + 6} fill="none" stroke="#fbf8f1" strokeWidth={1.5} strokeOpacity={0.8} />}
              <circle
                r={r}
                fill={published ? '#d08a3c' : '#fbf8f1'}
                stroke={published ? '#fbf8f1' : '#d08a3c'}
                strokeWidth={2}
              />
              {showLabel && (
                <text
                  x={flipLabel ? -(r + 6) : r + 6}
                  y={4}
                  textAnchor={flipLabel ? 'end' : 'start'}
                  className="pointer-events-none font-sans text-[12px] font-semibold"
                  fill="#fbf8f1"
                  stroke="#161412"
                  strokeWidth={3}
                  paintOrder="stroke"
                >
                  {civ.name}
                </text>
              )}
            </g>
          );
        })}
      </svg>
    </div>
  );
}
