import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  MapPin,
  Search,
  Filter,
  Navigation,
  Globe2,
  ExternalLink,
  Copy,
  Check,
  Building2,
  Crosshair,
  Layers,
  Sparkles,
  Info,
  Hospital,
  Activity,
  LocateFixed,
  RefreshCw,
  Share2,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

export interface PhcRecord {
  id: string;
  n: string; // Facility Name
  s: string; // State
  d: string; // District
  sd: string; // Subdistrict
  t: 'PHC' | 'CHC' | 'DH'; // Type
  lat: number;
  lng: number;
  loc: string; // Rural / Urban
}

interface StateMeta {
  name: string;
  count: number;
}

interface DistrictMeta {
  name: string;
  count: number;
}

interface MetaData {
  total: number;
  types: Record<string, number>;
  states: StateMeta[];
  districtsByState: Record<string, DistrictMeta[]>;
}

type TileStyle = 'positron' | 'dark_matter' | 'osm_standard' | 'satellite';

const INDIA_CENTER: [number, number] = [22.3511, 78.6677];
const INDIA_DEFAULT_ZOOM = 5;

const REGIONS: { name: string; center: [number, number]; zoom: number }[] = [
  { name: '🇮🇳 All India', center: INDIA_CENTER, zoom: 5 },
  { name: 'North', center: [30.5, 76.8], zoom: 6 },
  { name: 'South', center: [12.8, 77.5], zoom: 6 },
  { name: 'West', center: [19.8, 73.8], zoom: 6 },
  { name: 'East', center: [23.8, 85.8], zoom: 6 },
  { name: 'North-East', center: [26.2, 92.9], zoom: 6 },
  { name: 'Central', center: [23.2, 79.5], zoom: 6 },
];

function getTileLayer(style: TileStyle): L.TileLayer {
  switch (style) {
    case 'positron':
      return L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        maxZoom: 19,
        subdomains: 'abcd',
        attribution: '&copy; <a href="https://carto.com/">CARTO</a> &copy; OpenStreetMap',
      });
    case 'dark_matter':
      return L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        maxZoom: 19,
        subdomains: 'abcd',
        attribution: '&copy; <a href="https://carto.com/">CARTO</a> &copy; OpenStreetMap',
      });
    case 'satellite':
      return L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        {
          maxZoom: 18,
          attribution: '&copy; Esri, Maxar, Earthstar Geographics',
        }
      );
    case 'osm_standard':
    default:
      return L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap contributors',
      });
  }
}

export function IndiaPhcMapPage() {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const canvasRendererRef = useRef<L.Canvas | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const selectedPinMarkerRef = useRef<L.Marker | null>(null);

  // Data states
  const [facilities, setFacilities] = useState<PhcRecord[]>([]);
  const [meta, setMeta] = useState<MetaData | null>(null);
  const [stateBounds, setStateBounds] = useState<Record<string, { center: [number, number]; bounds: [[number, number], [number, number]]; count: number }>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  // Filters
  const [selectedState, setSelectedState] = useState<string>('ALL');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('ALL');
  const [facilityType, setFacilityType] = useState<'ALL' | 'PHC' | 'CHC' | 'DH'>('PHC');
  const [searchQuery, setSearchQuery] = useState('');
  const [mapStyle, setMapStyle] = useState<TileStyle>('positron');

  // Selected Facility
  const [selectedFacility, setSelectedFacility] = useState<PhcRecord | null>(null);
  const [copiedCoords, setCopiedCoords] = useState(false);
  const [savedActivePhc, setSavedActivePhc] = useState<string | null>(() => localStorage.getItem('selected_active_phc_name'));

  // 1. Fetch metadata and facilities JSON
  useEffect(() => {
    let isMounted = true;
    setIsLoading(true);

    Promise.all([
      fetch('/data/india_phcs_meta.json').then((r) => r.json()),
      fetch('/data/india_state_bounds.json').then((r) => r.json()),
      fetch('/data/india_phcs.json').then((r) => r.json()),
    ])
      .then(([metaData, boundsData, records]) => {
        if (!isMounted) return;
        setMeta(metaData);
        setStateBounds(boundsData);
        setFacilities(records);
        setIsLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        console.error('Failed to load India PHC data:', err);
        setLoadError('Failed to load geocoded PHC dataset. Please check your network connection.');
        setIsLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, []);

  // 2. Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if ((mapContainerRef.current as any)._leaflet_id) {
      delete (mapContainerRef.current as any)._leaflet_id;
    }

    const map = L.map(mapContainerRef.current, {
      center: INDIA_CENTER,
      zoom: INDIA_DEFAULT_ZOOM,
      zoomControl: false,
      preferCanvas: true,
    });
    mapInstanceRef.current = map;

    L.control.zoom({ position: 'bottomright' }).addTo(map);

    const initialTile = getTileLayer(mapStyle).addTo(map);
    tileLayerRef.current = initialTile;

    const renderer = L.canvas({ padding: 0.25 });
    canvasRendererRef.current = renderer;

    const layerGroup = L.layerGroup().addTo(map);
    markersLayerRef.current = layerGroup;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // 3. Update Tile Layer on Style Change
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (tileLayerRef.current) {
      map.removeLayer(tileLayerRef.current);
    }
    const newTile = getTileLayer(mapStyle).addTo(map);
    tileLayerRef.current = newTile;
  }, [mapStyle]);

  // 4. Filter Facilities
  const filteredFacilities = useMemo(() => {
    if (!facilities.length) return [];

    const query = searchQuery.trim().toLowerCase();

    return facilities.filter((f) => {
      // Type filter
      if (facilityType !== 'ALL' && f.t !== facilityType) return false;

      // State filter
      if (selectedState !== 'ALL' && f.s.toLowerCase() !== selectedState.toLowerCase()) return false;

      // District filter
      if (selectedDistrict !== 'ALL' && f.d.toLowerCase() !== selectedDistrict.toLowerCase()) return false;

      // Search query
      if (query) {
        const matchName = f.n.toLowerCase().includes(query);
        const matchDist = f.d.toLowerCase().includes(query);
        const matchSub = f.sd.toLowerCase().includes(query);
        const matchState = f.s.toLowerCase().includes(query);
        if (!matchName && !matchDist && !matchSub && !matchState) return false;
      }

      return true;
    });
  }, [facilities, selectedState, selectedDistrict, facilityType, searchQuery]);

  // 5. Select & Focus a Facility
  const handleSelectFacility = useCallback((fac: PhcRecord) => {
    setSelectedFacility(fac);
    const map = mapInstanceRef.current;
    if (!map) return;

    // Smooth fly to coordinate
    map.flyTo([fac.lat, fac.lng], Math.max(map.getZoom(), 13), {
      duration: 1.2,
      easeLinearity: 0.25,
    });

    // Remove previous pulsing pin
    if (selectedPinMarkerRef.current) {
      map.removeLayer(selectedPinMarkerRef.current);
      selectedPinMarkerRef.current = null;
    }

    // Modern HTML Pulsing Pin Icon
    const pulseIcon = L.divIcon({
      className: 'modern-pulse-pin',
      html: `
        <div class="relative flex items-center justify-center -translate-x-1/2 -translate-y-1/2">
          <span class="animate-ping absolute inline-flex h-10 w-10 rounded-full ${
            fac.t === 'PHC' ? 'bg-emerald-400' : fac.t === 'CHC' ? 'bg-blue-400' : 'bg-amber-400'
          } opacity-75"></span>
          <span class="relative inline-flex rounded-full h-6 w-6 ${
            fac.t === 'PHC' ? 'bg-emerald-600' : fac.t === 'CHC' ? 'bg-blue-600' : 'bg-amber-600'
          } border-2 border-white shadow-xl items-center justify-center">
            <span class="h-2 w-2 rounded-full bg-white"></span>
          </span>
        </div>
      `,
      iconSize: [24, 24],
      iconAnchor: [12, 12],
    });

    const marker = L.marker([fac.lat, fac.lng], { icon: pulseIcon }).addTo(map);
    selectedPinMarkerRef.current = marker;
  }, []);

  // 6. Draw Markers onto Canvas Layer
  useEffect(() => {
    const map = mapInstanceRef.current;
    const layerGroup = markersLayerRef.current;
    const renderer = canvasRendererRef.current;
    if (!map || !layerGroup || !renderer) return;

    layerGroup.clearLayers();

    // Color definitions
    const colorMap = {
      PHC: { fill: '#10B981', stroke: '#047857' }, // Emerald
      CHC: { fill: '#3B82F6', stroke: '#1D4ED8' }, // Blue
      DH: { fill: '#F59E0B', stroke: '#B45309' }, // Amber
    };

    filteredFacilities.forEach((f) => {
      const colors = colorMap[f.t] || colorMap.PHC;

      const circle = L.circleMarker([f.lat, f.lng], {
        renderer,
        radius: 5,
        fillColor: colors.fill,
        color: colors.stroke,
        weight: 1.5,
        opacity: 0.9,
        fillOpacity: 0.75,
      });

      // Simple tooltip on hover
      circle.bindTooltip(
        `<div class="text-xs font-semibold"><b>${f.n}</b><br/><span class="text-gray-500">${f.d}, ${f.s}</span></div>`,
        { direction: 'top', offset: [0, -4], opacity: 0.95 }
      );

      // On click
      circle.on('click', () => {
        handleSelectFacility(f);
      });

      layerGroup.addLayer(circle);
    });
  }, [filteredFacilities, handleSelectFacility]);

  // 7. Pan/Zoom when State or District changes
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (selectedState !== 'ALL' && stateBounds[selectedState]) {
      const info = stateBounds[selectedState];
      map.flyToBounds(info.bounds, { padding: [40, 40], duration: 1.0 });
    } else if (selectedState === 'ALL' && !searchQuery) {
      map.flyTo(INDIA_CENTER, INDIA_DEFAULT_ZOOM, { duration: 1.0 });
    }
  }, [selectedState, stateBounds, searchQuery]);

  // Copy coordinates helper
  const handleCopyCoords = (lat: number, lng: number) => {
    navigator.clipboard.writeText(`${lat}, ${lng}`);
    setCopiedCoords(true);
    setTimeout(() => setCopiedCoords(false), 2000);
  };

  // Set as Active PHC helper
  const handleSetActivePhc = (fac: PhcRecord) => {
    localStorage.setItem('selected_active_phc_name', fac.n);
    localStorage.setItem('selected_active_phc_state', fac.s);
    localStorage.setItem('selected_active_phc_district', fac.d);
    setSavedActivePhc(fac.n);
  };

  const availableDistricts = useMemo(() => {
    if (!meta || selectedState === 'ALL') return [];
    return meta.districtsByState[selectedState] || [];
  }, [meta, selectedState]);

  return (
    <div className="relative flex flex-col h-[calc(100vh-4rem)] w-full overflow-hidden bg-slate-50 dark:bg-slate-950 font-sans">
      {/* ── Top Header & Stats Strip ─────────────────────────────────────── */}
      <div className="z-10 bg-white/95 dark:bg-slate-900/95 backdrop-blur border-b border-slate-200 dark:border-slate-800 px-4 py-3 shadow-xs">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-600 text-white shadow-md shadow-emerald-500/20">
              <Hospital className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-base font-bold text-slate-900 dark:text-white">
                  National Primary Health Centre (PHC) Geo-Portal
                </h1>
                <Badge variant="outline" className="bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400 border-emerald-200 text-[11px] font-semibold">
                  MOHFW Geocoded
                </Badge>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Live interactive spatial map of 29,564 PHCs and health facilities across all 37 Indian States & UTs
              </p>
            </div>
          </div>

          {/* Quick Metrics Badges */}
          <div className="flex items-center gap-2 text-xs">
            <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-950/50 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 font-semibold">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>PHCs: 29,564</span>
            </div>
            <div className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 dark:bg-blue-950/50 text-blue-800 dark:text-blue-300 border border-blue-200 dark:border-blue-800 font-semibold">
              <span className="h-2 w-2 rounded-full bg-blue-500"></span>
              <span>CHCs: 5,371</span>
            </div>
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200 font-bold border border-slate-200 dark:border-slate-700">
              <span>Showing:</span>
              <span className="text-emerald-600 dark:text-emerald-400 font-extrabold">
                {filteredFacilities.length.toLocaleString('en-IN')}
              </span>
            </div>
          </div>
        </div>

        {/* ── Filters & Controls Toolbar ─────────────────────────────────── */}
        <div className="mt-3 flex flex-wrap items-center gap-2.5 pt-2 border-t border-slate-100 dark:border-slate-800/60">
          {/* Search Input */}
          <div className="relative min-w-[220px] max-w-xs flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <Input
              type="text"
              placeholder="Search PHC name, district, or block..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 h-9 text-xs bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 rounded-lg"
            />
          </div>

          {/* State Dropdown */}
          <div className="flex items-center gap-1">
            <label className="text-[11px] font-semibold text-slate-500 hidden sm:inline">State:</label>
            <select
              value={selectedState}
              onChange={(e) => {
                setSelectedState(e.target.value);
                setSelectedDistrict('ALL');
              }}
              className="h-9 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white rounded-lg px-2.5 py-1 font-medium focus:ring-2 focus:ring-emerald-500 outline-none"
            >
              <option value="ALL">All States & UTs (37)</option>
              {meta?.states.map((st) => (
                <option key={st.name} value={st.name}>
                  {st.name} ({st.count.toLocaleString('en-IN')})
                </option>
              ))}
            </select>
          </div>

          {/* District Dropdown */}
          {selectedState !== 'ALL' && availableDistricts.length > 0 && (
            <div className="flex items-center gap-1 animate-fadeIn">
              <label className="text-[11px] font-semibold text-slate-500 hidden sm:inline">District:</label>
              <select
                value={selectedDistrict}
                onChange={(e) => setSelectedDistrict(e.target.value)}
                className="h-9 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white rounded-lg px-2.5 py-1 font-medium focus:ring-2 focus:ring-emerald-500 outline-none max-w-[180px]"
              >
                <option value="ALL">All Districts ({availableDistricts.length})</option>
                {availableDistricts.map((d) => (
                  <option key={d.name} value={d.name}>
                    {d.name} ({d.count})
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Facility Type Filter Pills */}
          <div className="flex items-center rounded-lg bg-slate-100 dark:bg-slate-800 p-0.5 border border-slate-200 dark:border-slate-700 text-xs font-semibold">
            <button
              onClick={() => setFacilityType('PHC')}
              className={`px-3 py-1.5 rounded-md transition-all ${
                facilityType === 'PHC'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              PHC Only (29.5k)
            </button>
            <button
              onClick={() => setFacilityType('CHC')}
              className={`px-3 py-1.5 rounded-md transition-all ${
                facilityType === 'CHC'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              CHC (5.3k)
            </button>
            <button
              onClick={() => setFacilityType('ALL')}
              className={`px-3 py-1.5 rounded-md transition-all ${
                facilityType === 'ALL'
                  ? 'bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              All Types
            </button>
          </div>

          {/* Quick Region Presets */}
          <div className="hidden lg:flex items-center gap-1 text-xs">
            <span className="text-slate-400 text-[11px] font-medium mr-1">Jump to:</span>
            {REGIONS.map((r) => (
              <button
                key={r.name}
                onClick={() => {
                  setSelectedState('ALL');
                  setSelectedDistrict('ALL');
                  setSearchQuery('');
                  mapInstanceRef.current?.flyTo(r.center, r.zoom, { duration: 1.0 });
                }}
                className="px-2 py-1 rounded bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 font-medium transition-colors"
              >
                {r.name}
              </button>
            ))}
          </div>

          {/* Map Layer Switcher */}
          <div className="ml-auto flex items-center gap-1.5">
            <select
              value={mapStyle}
              onChange={(e) => setMapStyle(e.target.value as TileStyle)}
              className="h-9 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 rounded-lg px-2 font-medium outline-none"
            >
              <option value="positron">🗺️ Clean Light (Carto)</option>
              <option value="dark_matter">🌙 Dark Matter</option>
              <option value="osm_standard">🌍 Street (OSM)</option>
              <option value="satellite">🛰️ Satellite (Esri)</option>
            </select>
          </div>
        </div>
      </div>

      {/* ── Main Map Canvas Container ───────────────────────────────────── */}
      <div className="relative flex-1 w-full h-full">
        {/* Loading Overlay */}
        {isLoading && (
          <div className="absolute inset-0 z-30 flex flex-col items-center justify-center bg-white/80 dark:bg-slate-950/80 backdrop-blur-xs">
            <div className="flex flex-col items-center gap-3 p-6 rounded-2xl bg-white dark:bg-slate-900 shadow-xl border border-slate-200 dark:border-slate-800">
              <RefreshCw className="h-8 w-8 text-emerald-600 animate-spin" />
              <div className="text-center">
                <h3 className="font-bold text-slate-900 dark:text-white">Mapping 29,564 Health Facilities</h3>
                <p className="text-xs text-slate-500 mt-1">Plotting geocoded coordinates over India basemap…</p>
              </div>
            </div>
          </div>
        )}

        {/* Load Error Banner */}
        {loadError && (
          <div className="absolute top-4 left-1/2 -translate-x-1/2 z-30 max-w-md w-full p-4 rounded-xl bg-red-50 text-red-800 border border-red-200 shadow-lg flex items-center gap-3">
            <Info className="h-5 w-5 text-red-600 shrink-0" />
            <p className="text-xs">{loadError}</p>
          </div>
        )}

        {/* Leaflet Map Div */}
        <div ref={mapContainerRef} className="w-full h-full z-0" />

        {/* ── Map Legend (Floating Bottom Left) ──────────────────────────── */}
        <div className="absolute bottom-5 left-5 z-20 bg-white/95 dark:bg-slate-900/95 backdrop-blur rounded-xl p-3 shadow-lg border border-slate-200 dark:border-slate-800 text-xs">
          <div className="font-bold text-slate-900 dark:text-white mb-2 flex items-center gap-1.5">
            <Layers className="h-3.5 w-3.5 text-emerald-600" />
            <span>Map Pointer Legend</span>
          </div>
          <div className="space-y-1.5">
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-emerald-500 border border-emerald-700 shadow-xs"></span>
              <span className="text-slate-700 dark:text-slate-300 font-medium">Primary Health Centre (PHC)</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-blue-500 border border-blue-700 shadow-xs"></span>
              <span className="text-slate-700 dark:text-slate-300 font-medium">Community Health Centre (CHC)</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="h-3 w-3 rounded-full bg-amber-500 border border-amber-700 shadow-xs"></span>
              <span className="text-slate-700 dark:text-slate-300 font-medium">District Hospital (DH)</span>
            </div>
          </div>
        </div>

        {/* ── Selected Facility Inspector Panel (Floating Top Right) ──────── */}
        {selectedFacility && (
          <Card className="absolute top-4 right-4 z-20 w-84 sm:w-96 p-4 rounded-2xl bg-white/95 dark:bg-slate-900/95 backdrop-blur shadow-2xl border-2 border-emerald-500/40 dark:border-emerald-500/30 animate-in slide-in-from-right-4 duration-200">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-2">
                <Badge
                  className={`text-[11px] font-bold ${
                    selectedFacility.t === 'PHC'
                      ? 'bg-emerald-600 text-white'
                      : selectedFacility.t === 'CHC'
                      ? 'bg-blue-600 text-white'
                      : 'bg-amber-600 text-white'
                  }`}
                >
                  {selectedFacility.t}
                </Badge>
                <Badge variant="outline" className="text-[10px] text-slate-500 dark:text-slate-400">
                  {selectedFacility.loc}
                </Badge>
              </div>
              <button
                onClick={() => setSelectedFacility(null)}
                className="text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 p-1 rounded-md"
              >
                ✕
              </button>
            </div>

            <div className="mt-2.5">
              <h2 className="text-base font-extrabold text-slate-900 dark:text-white leading-tight">
                {selectedFacility.n}
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                {selectedFacility.sd ? `${selectedFacility.sd} • ` : ''}
                {selectedFacility.d}, {selectedFacility.s}
              </p>
            </div>

            <div className="mt-3.5 pt-3 border-t border-slate-100 dark:border-slate-800 space-y-2 text-xs">
              <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                <span className="font-medium">State:</span>
                <span className="font-semibold text-slate-900 dark:text-slate-200">{selectedFacility.s}</span>
              </div>
              <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                <span className="font-medium">District:</span>
                <span className="font-semibold text-slate-900 dark:text-slate-200">{selectedFacility.d}</span>
              </div>
              <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                <span className="font-medium">Subdistrict / Block:</span>
                <span className="font-semibold text-slate-900 dark:text-slate-200">{selectedFacility.sd || 'NA'}</span>
              </div>
              <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                <span className="font-medium">Coordinates:</span>
                <div className="flex items-center gap-1 font-mono text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                  <span>{selectedFacility.lat.toFixed(4)}, {selectedFacility.lng.toFixed(4)}</span>
                  <button
                    onClick={() => handleCopyCoords(selectedFacility.lat, selectedFacility.lng)}
                    className="p-1 hover:bg-slate-100 dark:hover:bg-slate-800 rounded text-slate-500"
                    title="Copy Lat, Lng"
                  >
                    {copiedCoords ? <Check className="h-3 w-3 text-emerald-600" /> : <Copy className="h-3 w-3" />}
                  </button>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800 flex flex-col gap-2">
              <Button
                variant={savedActivePhc === selectedFacility.n ? 'secondary' : 'default'}
                className={`w-full text-xs font-bold ${
                  savedActivePhc === selectedFacility.n
                    ? 'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300'
                    : 'bg-emerald-600 hover:bg-emerald-700 text-white'
                }`}
                onClick={() => handleSetActivePhc(selectedFacility)}
              >
                {savedActivePhc === selectedFacility.n ? (
                  <>
                    <Check className="h-3.5 w-3.5 mr-1.5" />
                    Active Selected Facility
                  </>
                ) : (
                  <>
                    <Crosshair className="h-3.5 w-3.5 mr-1.5" />
                    Set as Active PHC Context
                  </>
                )}
              </Button>

              <div className="flex gap-2">
                <a
                  href={`https://www.google.com/maps/search/?api=1&query=${selectedFacility.lat},${selectedFacility.lng}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1"
                >
                  <Button variant="outline" className="w-full text-xs font-semibold">
                    <ExternalLink className="h-3.5 w-3.5 mr-1.5" />
                    Directions
                  </Button>
                </a>
                <Button
                  variant="outline"
                  className="text-xs font-semibold px-3"
                  onClick={() => {
                    handleSelectFacility(selectedFacility);
                  }}
                  title="Re-center facility"
                >
                  <LocateFixed className="h-3.5 w-3.5" />
                </Button>
              </div>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
}

export default IndiaPhcMapPage;
