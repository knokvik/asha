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
  SlidersHorizontal,
  ChevronRight,
  Droplet,
  Phone,
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
  t: 'PHC' | 'CHC' | 'DH' | 'BLOOD_BANK'; // Type
  lat: number;
  lng: number;
  loc: string; // Rural / Urban
  phone?: string;
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

type TileStyle = 'osm_standard' | 'esri_topo' | 'esri_gray' | 'esri_dark' | 'satellite';

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

/**
 * 100% Free Tile Layers with ZERO API key required and NO watermarks.
 */
function getTileLayer(style: TileStyle): L.TileLayer {
  switch (style) {
    case 'esri_topo':
      return L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
        {
          maxZoom: 18,
          attribution: '&copy; <a href="https://www.esri.com/">Esri</a>, DeLorme, NAVTEQ',
        }
      );
    case 'esri_gray':
      return L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
        {
          maxZoom: 16,
          attribution: '&copy; <a href="https://www.esri.com/">Esri</a>, HERE, Garmin',
        }
      );
    case 'esri_dark':
      return L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
        {
          maxZoom: 16,
          attribution: '&copy; <a href="https://www.esri.com/">Esri</a>, HERE, Garmin',
        }
      );
    case 'satellite':
      return L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        {
          maxZoom: 18,
          attribution: '&copy; <a href="https://www.esri.com/">Esri</a>, Maxar, Earthstar Geographics',
        }
      );
    case 'osm_standard':
    default:
      return L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      });
  }
}

/**
 * Modern SVG Pin Pointer for detailed local view (Zoom >= 10)
 */
function createModernPinIcon(type: 'PHC' | 'CHC' | 'DH' | 'BLOOD_BANK', isSelected = false) {
  const color =
    type === 'BLOOD_BANK'
      ? '#DC2626'
      : type === 'DH'
      ? '#F59E0B'
      : type === 'CHC'
      ? '#2563EB'
      : '#10B981';
  const strokeColor =
    type === 'BLOOD_BANK'
      ? '#7F1D1D'
      : type === 'DH'
      ? '#92400E'
      : type === 'CHC'
      ? '#1E3A8A'
      : '#064E3B';
  const label =
    type === 'BLOOD_BANK' ? 'B' : type === 'DH' ? 'H' : type === 'CHC' ? 'C' : 'P';
  const size = isSelected ? 36 : 26;
  const height = Math.round(size * 1.25);

  return L.divIcon({
    className: 'modern-pin-container',
    html: `
      <div style="position:relative; width:${size}px; height:${height}px; display:flex; flex-direction:column; align-items:center; cursor:pointer;">
        ${isSelected ? `<span class="animate-ping" style="position:absolute; top:2px; width:${size}px; height:${size}px; border-radius:50%; background:${color}; opacity:0.65;"></span>` : ''}
        <svg width="${size}" height="${height}" viewBox="0 0 32 40" fill="none" xmlns="http://www.w3.org/2000/svg" style="filter:drop-shadow(0 3px 6px rgba(0,0,0,0.35));">
          <path d="M16 0C7.163 0 0 7.163 0 16c0 10.5 16 24 16 24s16-13.5 16-24c0-8.837-7.163-16-16-16z" fill="${color}"/>
          <path d="M16 1C7.716 1 1 7.716 1 16c0 9.8 14.5 22.3 15 22.7.5-.4 15-12.9 15-22.7 0-8.284-6.716-15-15-15z" stroke="${strokeColor}" stroke-width="1.5"/>
          <circle cx="16" cy="15" r="8" fill="white"/>
          <text x="16" y="19" font-family="system-ui, -apple-system, sans-serif" font-size="10" font-weight="900" fill="${color}" text-anchor="middle">${label}</text>
        </svg>
      </div>
    `,
    iconSize: [size, height],
    iconAnchor: [size / 2, height],
    popupAnchor: [0, -height],
  });
}

/**
 * State Hub aggregate badge icon for zoomed-out overview
 */
function createStateHubIcon(stateName: string, count: number) {
  const shortCount = count >= 1000 ? `${(count / 1000).toFixed(1)}k` : `${count}`;
  return L.divIcon({
    className: 'state-hub-badge',
    html: `
      <div class="group cursor-pointer flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/95 dark:bg-slate-900/95 border border-emerald-500/50 shadow-md hover:scale-110 hover:shadow-xl transition-all duration-150 backdrop-blur-xs">
        <span class="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
        <span class="text-[11px] font-bold text-slate-800 dark:text-slate-100 whitespace-nowrap">${stateName}</span>
        <span class="text-[10px] font-extrabold px-1.5 py-0.2 rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">${shortCount}</span>
      </div>
    `,
    iconSize: [120, 24],
    iconAnchor: [60, 12],
  });
}

export function IndiaPhcMapPage() {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const canvasRendererRef = useRef<L.Canvas | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const pinMarkersLayerRef = useRef<L.LayerGroup | null>(null);
  const stateHubsLayerRef = useRef<L.LayerGroup | null>(null);
  const selectedPinMarkerRef = useRef<L.Marker | null>(null);

  // Data states
  const [facilities, setFacilities] = useState<PhcRecord[]>([]);
  const [meta, setMeta] = useState<MetaData | null>(null);
  const [stateBounds, setStateBounds] = useState<Record<string, { center: [number, number]; bounds: [[number, number], [number, number]]; count: number }>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  // Filters — default to 'ALL' so blood banks, yellow (DH) and blue (CHC) are visible immediately!
  const [selectedState, setSelectedState] = useState<string>('ALL');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('ALL');
  const [facilityType, setFacilityType] = useState<'ALL' | 'PHC' | 'CHC' | 'DH' | 'BLOOD_BANK'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [mapStyle, setMapStyle] = useState<TileStyle>('osm_standard');
  const [currentZoom, setCurrentZoom] = useState<number>(INDIA_DEFAULT_ZOOM);
  const [adaptiveLod, setAdaptiveLod] = useState<boolean>(true);

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

    const pinGroup = L.layerGroup().addTo(map);
    pinMarkersLayerRef.current = pinGroup;

    const hubGroup = L.layerGroup().addTo(map);
    stateHubsLayerRef.current = hubGroup;

    // Listen to zoom events for progressive Level of Detail (LOD)
    const onZoom = () => {
      setCurrentZoom(map.getZoom());
    };
    map.on('zoomend', onZoom);

    return () => {
      map.off('zoomend', onZoom);
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

  // 4. Filter Facilities and Order (DH on top, CHC middle, PHC base)
  const filteredFacilities = useMemo(() => {
    if (!facilities.length) return [];

    const query = searchQuery.trim().toLowerCase();

    const result = facilities.filter((f) => {
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

    // IMPORTANT: Sort so PHC (green) renders first, CHC (blue) renders second,
    // DH (yellow/amber) renders next, and Blood Banks (crimson red) render ON TOP!
    // This ensures high-acuity facilities and blood banks are never obscured by base green dots.
    const typeOrder: Record<string, number> = { PHC: 0, CHC: 1, DH: 2, BLOOD_BANK: 3 };
    return result.sort((a, b) => (typeOrder[a.t] ?? 0) - (typeOrder[b.t] ?? 0));
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

    const marker = L.marker([fac.lat, fac.lng], {
      icon: createModernPinIcon(fac.t, true),
      zIndexOffset: 1000,
    }).addTo(map);
    selectedPinMarkerRef.current = marker;
  }, []);

  // 6. Draw State Hubs when Zoomed Out (Zoom 4–6)
  useEffect(() => {
    const hubGroup = stateHubsLayerRef.current;
    const map = mapInstanceRef.current;
    if (!hubGroup || !map) return;

    hubGroup.clearLayers();

    // Only show state hub labels when zoomed out (zoom <= 6) and viewing All India
    if (adaptiveLod && currentZoom <= 6 && selectedState === 'ALL' && !searchQuery) {
      Object.entries(stateBounds).forEach(([stName, info]) => {
        if (!info.center || info.count < 10) return;

        const marker = L.marker(info.center, {
          icon: createStateHubIcon(stName, info.count),
          zIndexOffset: 500,
        });

        marker.on('click', () => {
          setSelectedState(stName);
          map.flyToBounds(info.bounds, { padding: [40, 40], duration: 1.2 });
        });

        hubGroup.addLayer(marker);
      });
    }
  }, [currentZoom, stateBounds, adaptiveLod, selectedState, searchQuery]);

  // 7. Render Markers with Dynamic Zoom-Level LOD
  useEffect(() => {
    const map = mapInstanceRef.current;
    const canvasLayer = markersLayerRef.current;
    const pinLayer = pinMarkersLayerRef.current;
    const renderer = canvasRendererRef.current;
    if (!map || !canvasLayer || !pinLayer || !renderer) return;

    canvasLayer.clearLayers();
    pinLayer.clearLayers();

    const isZoomedInClose = currentZoom >= 10;
    const isOverview = currentZoom <= 6;

    // Radius scaling according to zoom
    const getRadius = (type: 'PHC' | 'CHC' | 'DH' | 'BLOOD_BANK') => {
      if (type === 'BLOOD_BANK') {
        return isOverview ? 7 : isZoomedInClose ? 10 : 8;
      } else if (type === 'DH') {
        return isOverview ? 6.5 : isZoomedInClose ? 9 : 7.5;
      } else if (type === 'CHC') {
        return isOverview ? 4.5 : isZoomedInClose ? 7.5 : 6;
      } else {
        return isOverview ? 2.5 : isZoomedInClose ? 6 : 4;
      }
    };

    // Color definitions
    const colorMap: Record<string, { fill: string; stroke: string; opacity: number }> = {
      PHC: { fill: '#10B981', stroke: '#064E3B', opacity: isOverview ? 0.6 : 0.85 }, // Green
      CHC: { fill: '#2563EB', stroke: '#1E3A8A', opacity: 0.95 }, // Blue
      DH: { fill: '#F59E0B', stroke: '#92400E', opacity: 1.0 }, // Vibrant Golden Yellow
      BLOOD_BANK: { fill: '#DC2626', stroke: '#7F1D1D', opacity: 1.0 }, // Crimson Red
    };

    // When zoomed in very close (zoom >= 10) and filtering to state/district:
    // Render modern SVG Teardrop Pin Pointers!
    if (isZoomedInClose && filteredFacilities.length <= 800) {
      filteredFacilities.forEach((f) => {
        const pin = L.marker([f.lat, f.lng], {
          icon: createModernPinIcon(f.t, false),
          zIndexOffset: f.t === 'BLOOD_BANK' ? 400 : f.t === 'DH' ? 300 : f.t === 'CHC' ? 200 : 100,
        });

        pin.bindTooltip(
          `<div class="text-xs font-semibold"><b>${f.n}</b><br/><span class="text-gray-500">${f.d}, ${f.s}</span></div>`,
          { direction: 'top', offset: [0, -28], opacity: 0.95 }
        );

        pin.on('click', () => handleSelectFacility(f));
        pinLayer.addLayer(pin);
      });
      return;
    }

    // Canvas rendering for high-performance smooth rendering
    filteredFacilities.forEach((f) => {
      const colors = colorMap[f.t] || colorMap.PHC;
      const radius = getRadius(f.t);

      const circle = L.circleMarker([f.lat, f.lng], {
        renderer,
        radius,
        fillColor: colors.fill,
        color: colors.stroke,
        weight: f.t === 'DH' ? 2.0 : f.t === 'CHC' ? 1.5 : 1.0,
        opacity: 0.9,
        fillOpacity: colors.opacity,
      });

      // Hover tooltip
      circle.bindTooltip(
        `<div class="text-xs font-semibold"><b>${f.n}</b> (${f.t})<br/><span class="text-gray-500">${f.d}, ${f.s}</span></div>`,
        { direction: 'top', offset: [0, -radius], opacity: 0.95 }
      );

      circle.on('click', () => handleSelectFacility(f));
      canvasLayer.addLayer(circle);
    });
  }, [filteredFacilities, currentZoom, handleSelectFacility]);

  // 8. Pan/Zoom when State or District changes
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

  // Helper actions
  const handleCopyCoords = (lat: number, lng: number) => {
    navigator.clipboard.writeText(`${lat}, ${lng}`);
    setCopiedCoords(true);
    setTimeout(() => setCopiedCoords(false), 2000);
  };

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

  // Counts of each type currently shown
  const typeCounts = useMemo(() => {
    const counts: Record<string, number> = { PHC: 0, CHC: 0, DH: 0, BLOOD_BANK: 0 };
    filteredFacilities.forEach((f) => {
      counts[f.t] = (counts[f.t] || 0) + 1;
    });
    return counts;
  }, [filteredFacilities]);

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
                  All-India Health Centres & PHC Geo-Portal
                </h1>
                <Badge variant="outline" className="bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400 border-emerald-200 text-[11px] font-semibold">
                  MOHFW Geocoded
                </Badge>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Interactive spatial map of 35,907 national facilities across 37 States & UTs • Zoom in for modern pointer pins
              </p>
            </div>
          </div>

          {/* Quick Metrics Badges with Visual Colors */}
          <div className="flex items-center gap-2 text-xs flex-wrap">
            <button
              onClick={() => setFacilityType('PHC')}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border font-semibold transition-all cursor-pointer ${
                facilityType === 'PHC'
                  ? 'bg-emerald-600 text-white border-emerald-700 shadow-xs'
                  : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800 hover:bg-emerald-100'
              }`}
              title="Filter to Primary Health Centres"
            >
              <span className="h-2.5 w-2.5 rounded-full bg-emerald-500 border border-white shadow-xs"></span>
              <span>PHCs: {(typeCounts.PHC || 0).toLocaleString('en-IN')}</span>
            </button>

            <button
              onClick={() => setFacilityType('CHC')}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border font-semibold transition-all cursor-pointer ${
                facilityType === 'CHC'
                  ? 'bg-blue-600 text-white border-blue-700 shadow-xs'
                  : 'bg-blue-50 dark:bg-blue-950/40 text-blue-800 dark:text-blue-300 border-blue-200 dark:border-blue-800 hover:bg-blue-100'
              }`}
              title="Filter to Community Health Centres"
            >
              <span className="h-2.5 w-2.5 rounded-full bg-blue-500 border border-white shadow-xs"></span>
              <span>CHCs: {(typeCounts.CHC || 0).toLocaleString('en-IN')}</span>
            </button>

            <button
              onClick={() => setFacilityType('DH')}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border font-semibold transition-all cursor-pointer ${
                facilityType === 'DH'
                  ? 'bg-amber-600 text-white border-amber-700 shadow-xs'
                  : 'bg-amber-50 dark:bg-amber-950/40 text-amber-900 dark:text-amber-300 border-amber-300 dark:border-amber-800 hover:bg-amber-100'
              }`}
              title="Filter to District Hospitals"
            >
              <span className="h-2.5 w-2.5 rounded-full bg-amber-500 border border-white shadow-xs"></span>
              <span>Hospitals: {(typeCounts.DH || 0).toLocaleString('en-IN')}</span>
            </button>

            <button
              onClick={() => setFacilityType('BLOOD_BANK')}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border font-semibold transition-all cursor-pointer ${
                facilityType === 'BLOOD_BANK'
                  ? 'bg-red-600 text-white border-red-700 shadow-xs'
                  : 'bg-red-50 dark:bg-red-950/40 text-red-900 dark:text-red-300 border-red-300 dark:border-red-800 hover:bg-red-100'
              }`}
              title="Filter to Blood Banks (e-RaktKosh)"
            >
              <span className="h-2.5 w-2.5 rounded-full bg-red-600 border border-white shadow-xs"></span>
              <span>Blood Banks: {(typeCounts.BLOOD_BANK || 0).toLocaleString('en-IN')}</span>
            </button>

            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200 font-bold border border-slate-200 dark:border-slate-700">
              <span>Total Shown:</span>
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
              onClick={() => setFacilityType('ALL')}
              className={`px-3 py-1.5 rounded-md transition-all cursor-pointer ${
                facilityType === 'ALL'
                  ? 'bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              All Types
            </button>
            <button
              onClick={() => setFacilityType('PHC')}
              className={`px-3 py-1.5 rounded-md transition-all cursor-pointer ${
                facilityType === 'PHC'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              🟢 PHC Only
            </button>
            <button
              onClick={() => setFacilityType('CHC')}
              className={`px-3 py-1.5 rounded-md transition-all cursor-pointer ${
                facilityType === 'CHC'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              🔵 CHC Only
            </button>
            <button
              onClick={() => setFacilityType('DH')}
              className={`px-3 py-1.5 rounded-md transition-all cursor-pointer ${
                facilityType === 'DH'
                  ? 'bg-amber-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
              }`}
            >
              🟡 DH Only
            </button>
            <button
              onClick={() => setFacilityType('BLOOD_BANK')}
              className={`px-3 py-1.5 rounded-md transition-all cursor-pointer flex items-center gap-1 ${
                facilityType === 'BLOOD_BANK'
                  ? 'bg-red-600 text-white shadow-xs'
                  : 'text-red-600 dark:text-red-400 hover:text-red-700'
              }`}
            >
              <Droplet className="h-3.5 w-3.5 fill-current" />
              <span>Blood Banks</span>
            </button>
          </div>

          {/* Quick Region Presets */}
          <div className="hidden lg:flex items-center gap-1 text-xs">
            <span className="text-slate-400 text-[11px] font-medium mr-1">Region:</span>
            {REGIONS.map((r) => (
              <button
                key={r.name}
                onClick={() => {
                  setSelectedState('ALL');
                  setSelectedDistrict('ALL');
                  setSearchQuery('');
                  mapInstanceRef.current?.flyTo(r.center, r.zoom, { duration: 1.0 });
                }}
                className="px-2 py-1 rounded bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 font-medium transition-colors cursor-pointer"
              >
                {r.name}
              </button>
            ))}
          </div>

      {/* Map Layer Switcher — 100% Free layers, No API Key needed */}
      <div className="ml-auto flex items-center gap-1.5">
        <select
          value={mapStyle}
          onChange={(e) => setMapStyle(e.target.value as TileStyle)}
          className="h-9 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 rounded-lg px-2 font-medium outline-none cursor-pointer"
        >
          <option value="osm_standard">🌍 OpenStreetMap (Clean Light)</option>
          <option value="esri_topo">🏔️ Esri Topo Terrain (Light)</option>
          <option value="esri_gray">⚪ Esri Clean Gray Canvas (Light)</option>
          <option value="satellite">🛰️ Satellite Aerial</option>
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
                <h3 className="font-bold text-slate-900 dark:text-white">Loading National Health Facilities</h3>
                <p className="text-xs text-slate-500 mt-1">Plotting 35,868 geocoded health centres across India…</p>
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

        {/* ── Zoom Level Indicator & LOD Helper (Floating Top Left) ─────── */}
        <div className="absolute top-4 left-4 z-20 flex items-center gap-2">
          <div className="px-3 py-1.5 rounded-xl bg-white/95 dark:bg-slate-900/95 backdrop-blur border border-slate-200 dark:border-slate-800 shadow-md text-xs font-semibold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
            <Sparkles className="h-3.5 w-3.5 text-emerald-600" />
            <span>
              {currentZoom <= 6
                ? 'Overview Zoom (Showing state hubs & high-priority centres)'
                : currentZoom <= 9
                ? 'Regional Zoom (Showing all district facilities)'
                : 'Local Zoom (Showing modern pin pointers)'}
            </span>
          </div>

          <button
            onClick={() => setAdaptiveLod(!adaptiveLod)}
            className={`px-2.5 py-1.5 rounded-xl border text-xs font-bold transition-all shadow-md cursor-pointer ${
              adaptiveLod
                ? 'bg-emerald-600 text-white border-emerald-700'
                : 'bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700'
            }`}
            title="Toggle between clean adaptive zooming and raw point rendering"
          >
            {adaptiveLod ? 'Clean LOD Active' : 'Raw Points'}
          </button>
        </div>

        {/* ── Map Pointer Legend (Floating Bottom Left) ─────────────────── */}
        <div className="absolute bottom-5 left-5 z-20 bg-white/95 dark:bg-slate-900/95 backdrop-blur rounded-2xl p-3.5 shadow-xl border border-slate-200 dark:border-slate-800 text-xs">
          <div className="font-bold text-slate-900 dark:text-white mb-2.5 flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Layers className="h-3.5 w-3.5 text-emerald-600" />
              <span>Facility Pointers</span>
            </span>
            <span className="text-[10px] text-slate-400 font-normal">Layered by priority</span>
          </div>
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="h-3.5 w-3.5 rounded-full bg-red-600 border-2 border-red-900 shadow-xs"></span>
                <span className="text-slate-800 dark:text-slate-200 font-semibold">Blood Bank (e-RaktKosh)</span>
              </div>
              <Badge variant="outline" className="text-[10px] bg-red-50 dark:bg-red-950/40 text-red-800 dark:text-red-300 border-red-300">
                {(typeCounts.BLOOD_BANK || 29)} Top
              </Badge>
            </div>
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="h-3.5 w-3.5 rounded-full bg-amber-500 border-2 border-amber-800 shadow-xs"></span>
                <span className="text-slate-800 dark:text-slate-200 font-semibold">District Hospital (DH)</span>
              </div>
              <Badge variant="outline" className="text-[10px] bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 border-amber-300">
                {(typeCounts.DH || 936).toLocaleString('en-IN')} Mid-High
              </Badge>
            </div>
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="h-3 w-3 rounded-full bg-blue-500 border border-blue-800 shadow-xs"></span>
                <span className="text-slate-800 dark:text-slate-200 font-semibold">Community Health Centre (CHC)</span>
              </div>
              <Badge variant="outline" className="text-[10px] bg-blue-50 dark:bg-blue-950/40 text-blue-800 dark:text-blue-300 border-blue-300">
                {(typeCounts.CHC || 5374).toLocaleString('en-IN')} Mid
              </Badge>
            </div>
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500 border border-emerald-800 shadow-xs"></span>
                <span className="text-slate-800 dark:text-slate-200 font-semibold">Primary Health Centre (PHC)</span>
              </div>
              <Badge variant="outline" className="text-[10px] bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 border-emerald-300">
                {(typeCounts.PHC || 29568).toLocaleString('en-IN')} Base
              </Badge>
            </div>
          </div>
          <div className="mt-2.5 pt-2 border-t border-slate-100 dark:border-slate-800 text-[10px] text-slate-400">
            Zoom in to zoom 10+ to reveal teardrop pin markers.
          </div>
        </div>

        {/* ── Selected Facility Inspector Panel (Floating Top Right) ──────── */}
        {selectedFacility && (
          <Card className="absolute top-4 right-4 z-20 w-84 sm:w-96 p-4 rounded-2xl bg-white/95 dark:bg-slate-900/95 backdrop-blur shadow-2xl border-2 border-emerald-500/40 dark:border-emerald-500/30 animate-in slide-in-from-right-4 duration-200">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-2">
                <Badge
                  className={`text-[11px] font-bold ${
                    selectedFacility.t === 'BLOOD_BANK'
                      ? 'bg-red-600 text-white'
                      : selectedFacility.t === 'PHC'
                      ? 'bg-emerald-600 text-white'
                      : selectedFacility.t === 'CHC'
                      ? 'bg-blue-600 text-white'
                      : 'bg-amber-600 text-white'
                  }`}
                >
                  {selectedFacility.t === 'BLOOD_BANK'
                    ? 'Blood Bank (e-RaktKosh)'
                    : selectedFacility.t === 'PHC'
                    ? 'Primary Health Centre'
                    : selectedFacility.t === 'CHC'
                    ? 'Community Health Centre'
                    : 'District Hospital'}
                </Badge>
                <Badge variant="outline" className="text-[10px] text-slate-500 dark:text-slate-400">
                  {selectedFacility.loc}
                </Badge>
              </div>
              <button
                onClick={() => setSelectedFacility(null)}
                className="text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 p-1 rounded-md cursor-pointer"
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
              {selectedFacility.phone && (
                <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                  <span className="font-medium">Helpline / Phone:</span>
                  <a
                    href={`tel:${selectedFacility.phone}`}
                    className="flex items-center gap-1 font-semibold text-blue-600 dark:text-blue-400 hover:underline"
                  >
                    <Phone className="h-3 w-3" />
                    <span>{selectedFacility.phone}</span>
                  </a>
                </div>
              )}
              <div className="flex items-center justify-between text-slate-600 dark:text-slate-400">
                <span className="font-medium">Coordinates:</span>
                <div className="flex items-center gap-1 font-mono text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                  <span>{selectedFacility.lat.toFixed(4)}, {selectedFacility.lng.toFixed(4)}</span>
                  <button
                    onClick={() => handleCopyCoords(selectedFacility.lat, selectedFacility.lng)}
                    className="p-1 hover:bg-slate-100 dark:hover:bg-slate-800 rounded text-slate-500 cursor-pointer"
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
