import { useCallback, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  MapPin,
  Layers,
  Compass,
  AlertTriangle,
  PhoneCall,
  Activity,
  HeartPulse,
  Radio,
  Clock,
  Maximize2,
  ZoomIn,
  ZoomOut,
  Crosshair,
  ShieldCheck,
  CheckCircle2,
  Navigation,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { PCMC_FACILITIES, PCMC_WARDS } from '@/shared/api/mockData';
import { getMapFacilities, getMapSources, type MapFacility, type MapSource } from '@/shared/api/mapApi';
import { PcmcHeatPanel, type HeatView } from '@/features/map/PcmcHeatPanel';
import { outbreakWards, weekPoint, type WardWeek } from '@/features/clinical-desk/logic';

// Facility & Asset Geodata for PHC Shahpur Catchment
interface FacilityLocation {
  id: string;
  name: string;
  type: 'PHC' | 'SUBCENTRE';
  lat: number;
  lng: number;
  anm?: string;
  phone: string;
  distanceKm: number;
  activeReferrals: number;
  status: string;
}

interface AmbulanceAsset {
  id: string;
  code: string;
  lat: number;
  lng: number;
  speedKmH: number;
  patient?: string;
  condition?: string;
  etaMinutes: number;
  destination: string;
  driverPhone: string;
  status: 'en_route_emergency' | 'standby' | 'dispatched';
}

interface AshaFieldLocation {
  id: string;
  name: string;
  village: string;
  lat: number;
  lng: number;
  batteryPct: number;
  currentActivity: string;
  lastSyncMinsAgo: number;
  phone: string;
}

const PHC_COORDINATES: [number, number] = [25.3176, 82.9739];

const SUBCENTRES: FacilityLocation[] = [
  {
    id: 'sc-1',
    name: 'SC Ramnagar',
    type: 'SUBCENTRE',
    lat: 25.2780,
    lng: 83.0250,
    anm: 'Meena Kumari (ANM)',
    phone: '+91 94150 11201',
    distanceKm: 4.4,
    activeReferrals: 1,
    status: 'Online • 3 ASHAs synced',
  },
  {
    id: 'sc-2',
    name: 'SC Kalyanpur',
    type: 'SUBCENTRE',
    lat: 25.3560,
    lng: 82.9420,
    anm: 'Rekha Devi (ANM)',
    phone: '+91 94150 11202',
    distanceKm: 4.8,
    activeReferrals: 0,
    status: 'Online • VHSND Active',
  },
  {
    id: 'sc-3',
    name: 'SC Shivpur',
    type: 'SUBCENTRE',
    lat: 25.3620,
    lng: 82.9820,
    anm: 'Sunita Singh (CHO)',
    phone: '+91 94150 11203',
    distanceKm: 6.2,
    activeReferrals: 1,
    status: 'Online • 4 ASHAs synced',
  },
  {
    id: 'sc-4',
    name: 'SC Belwa',
    type: 'SUBCENTRE',
    lat: 25.2950,
    lng: 82.9350,
    anm: 'Pooja Rani (ANM)',
    phone: '+91 94150 11204',
    distanceKm: 4.3,
    activeReferrals: 0,
    status: 'Standby • Routine ANC',
  },
  {
    id: 'sc-5',
    name: 'SC Pipra',
    type: 'SUBCENTRE',
    lat: 25.2650,
    lng: 83.0450,
    anm: 'Anjali Sharma (ANM)',
    phone: '+91 94150 11205',
    distanceKm: 7.5,
    activeReferrals: 1,
    status: 'Offline Dead-Zone (SMS Sync)',
  },
  {
    id: 'sc-6',
    name: 'SC Madhuban',
    type: 'SUBCENTRE',
    lat: 25.3420,
    lng: 83.0280,
    anm: 'Geeta Verma (CHO)',
    phone: '+91 94150 11206',
    distanceKm: 7.0,
    activeReferrals: 0,
    status: 'Online • Immunization Hub',
  },
];

const AMBULANCES: AmbulanceAsset[] = [
  {
    id: 'amb-1',
    code: '108-UP-42',
    lat: 25.3340,
    lng: 82.9850,
    speedKmH: 48,
    patient: 'Sunita Devi (24y, G2P1)',
    condition: 'CRITICAL: Severe Pre-Eclampsia (BP 190/125)',
    etaMinutes: 8,
    destination: 'PHC Shahpur Emergency Triage',
    driverPhone: '+91 98390 12345',
    status: 'en_route_emergency',
  },
  {
    id: 'amb-2',
    code: '108-UP-09',
    lat: 25.3210,
    lng: 83.0020,
    speedKmH: 52,
    patient: 'Rajesh Kumar (52y)',
    condition: 'CRITICAL: Acute Chest Pain & Hypertensive Crisis',
    etaMinutes: 12,
    destination: 'PHC Shahpur Emergency Triage',
    driverPhone: '+91 98390 12346',
    status: 'en_route_emergency',
  },
  {
    id: 'amb-3',
    code: '108-UP-18',
    lat: 25.2950,
    lng: 82.9350,
    speedKmH: 0,
    etaMinutes: 0,
    destination: 'Stationed at Belwa Sub-Centre',
    driverPhone: '+91 98390 12347',
    status: 'standby',
  },
];

const ASHA_WORKERS: AshaFieldLocation[] = [
  {
    id: 'asha-1',
    name: 'Kamla Devi',
    village: 'Ramnagar Hamlet 2',
    lat: 25.2805,
    lng: 83.0220,
    batteryPct: 82,
    currentActivity: 'High-risk Pregnancy HBNC Check',
    lastSyncMinsAgo: 4,
    phone: '+91 94180 55441',
  },
  {
    id: 'asha-2',
    name: 'Radha Yadav',
    village: 'Kalyanpur East',
    lat: 25.3520,
    lng: 82.9480,
    batteryPct: 68,
    currentActivity: 'Infant Measles-Rubella Follow-up',
    lastSyncMinsAgo: 12,
    phone: '+91 94180 55442',
  },
  {
    id: 'asha-3',
    name: 'Meera Kumari',
    village: 'Pipra Tola',
    lat: 25.2680,
    lng: 83.0420,
    batteryPct: 45,
    currentActivity: 'NCD CBAC Hypertension Screening',
    lastSyncMinsAgo: 22,
    phone: '+91 94180 55443',
  },
  {
    id: 'asha-4',
    name: 'Sita Devi',
    village: 'Shahpur Ward 3',
    lat: 25.3220,
    lng: 82.9680,
    batteryPct: 91,
    currentActivity: 'Routine Household Survey Entry',
    lastSyncMinsAgo: 2,
    phone: '+91 94180 55444',
  },
];

const PCMC_CENTER: [number, number] = [18.66, 73.82];

function getTileLayer(style: 'osmand_topo' | 'osm_standard' | 'dark_tactical') {
  if (style === 'osmand_topo') {
    // OpenTopoMap / OsmAnd Topo styling
    return L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
      maxZoom: 17,
      subdomains: 'abc',
      attribution: '&copy; OpenStreetMap contributors, SRTM | OpenTopoMap',
    });
  } else if (style === 'osm_standard') {
    // OpenStreetMap Standard: Ultra-fast, clean global vector raster tiles (100% free, no API key required)
    return L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    });
  } else {
    // Dark Tactical: High-contrast night map with dark styling
    return L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      className: 'dark-tiles',
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    });
  }
}

export function OsmAndMapPage({ mode = 'field' }: { mode?: 'field' | 'heatmap' }) {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const layerGroupsRef = useRef<{ [key: string]: L.LayerGroup }>({});

  // Map state - default to OpenStreetMap Standard for instant reliable rendering
  const [mapStyle, setMapStyle] = useState<'osmand_topo' | 'osm_standard' | 'dark_tactical'>('osm_standard');
  const [showSubcentres, setShowSubcentres] = useState(true);
  const [showAmbulances, setShowAmbulances] = useState(true);
  const [showAshas, setShowAshas] = useState(true);
  const [showCatchmentRings, setShowCatchmentRings] = useState(true);
  const [showDeadZone, setShowDeadZone] = useState(true);
  const [selectedAsset, setSelectedAsset] = useState<any | null>(null);
  const [facilities, setFacilities] = useState<MapFacility[]>([]);
  const [mapSources, setMapSources] = useState<MapSource[]>([]);
  const [facilityLoadError, setFacilityLoadError] = useState<string | null>(null);
  const [heatView, setHeatView] = useState<HeatView>({
    week: 11,
    showFlags: true,
    showAnaemia: true,
    showStunting: false,
    showFacilities: true,
  });
  const onHeatView = useCallback((view: HeatView) => setHeatView(view), []);

  useEffect(() => {
    let active = true;
    getMapFacilities()
      .then((rows) => {
        if (active) {
          setFacilities(rows);
          setFacilityLoadError(null);
        }
      })
      .catch(() => {
        if (active) setFacilityLoadError('Facility data could not be loaded from the server.');
      });
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    getMapSources().then(setMapSources).catch(() => setMapSources([]));
  }, []);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Clean up any stale Leaflet ID on container before init
    if ((mapContainerRef.current as any)._leaflet_id) {
      delete (mapContainerRef.current as any)._leaflet_id;
    }

    // Create Map
    const map = L.map(mapContainerRef.current, {
      center: mode === 'heatmap' ? PCMC_CENTER : PHC_COORDINATES,
      zoom: 12,
      zoomControl: false,
    });
    mapInstanceRef.current = map;

    // Zoom control at bottom right
    L.control.zoom({ position: 'bottomright' }).addTo(map);

    // Attach initial tile layer immediately upon map creation
    const initialTile = getTileLayer(mapStyle).addTo(map);
    tileLayerRef.current = initialTile;

    // Initialize layer groups
    const subcentreLayer = L.layerGroup().addTo(map);
    const ambulanceLayer = L.layerGroup().addTo(map);
    const ashaLayer = L.layerGroup().addTo(map);
    const ringsLayer = L.layerGroup().addTo(map);
    const deadZoneLayer = L.layerGroup().addTo(map);
    const pcmcLayer = L.layerGroup().addTo(map);
    const facilitiesLayer = L.layerGroup().addTo(map);

    layerGroupsRef.current = {
      subcentres: subcentreLayer,
      ambulances: ambulanceLayer,
      ashas: ashaLayer,
      rings: ringsLayer,
      deadZone: deadZoneLayer,
      pcmc: pcmcLayer,
      facilities: facilitiesLayer,
    };

    // Auto-resize observer to handle any DOM changes or flex calculations
    const resizeObserver =
      typeof ResizeObserver !== 'undefined'
        ? new ResizeObserver(() => {
            map.invalidateSize();
          })
        : null;

    if (resizeObserver && mapContainerRef.current) {
      resizeObserver.observe(mapContainerRef.current);
    }

    // Staggered size invalidations to ensure proper tile rendering
    const t1 = setTimeout(() => map.invalidateSize(), 100);
    const t2 = setTimeout(() => map.invalidateSize(), 300);
    const t3 = setTimeout(() => map.invalidateSize(), 800);

    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      clearTimeout(t3);
      if (resizeObserver) {
        resizeObserver.disconnect();
      }
      map.remove();
      mapInstanceRef.current = null;
      tileLayerRef.current = null;
    };
  }, [mode]);

  useEffect(() => {
    const group = layerGroupsRef.current.facilities;
    if (!group) return;
    group.clearLayers();
    const colors: Record<string, string> = {
      hospital: '#b42318',
      phc: '#047857',
      chc: '#0f766e',
      subcentre: '#2563eb',
      lab: '#7c3aed',
      pharmacy: '#c2410c',
      other: '#475569',
    };
    for (const facility of facilities) {
      if (!Number.isFinite(facility.lat) || !Number.isFinite(facility.lon)) continue;
      const kind = String(facility.kind || 'other').toLowerCase();
      const color = colors[kind] ?? colors.other;
      L.circleMarker([facility.lat, facility.lon], {
        radius: 7,
        color,
        weight: 2,
        fillColor: color,
        fillOpacity: 0.9,
      })
        .bindPopup(
          `<strong>${facility.name}</strong><br/>${kind}<br/>${facility.district ?? ''} ${facility.block ?? ''}<br/>${facility.phone ?? ''}<br/><small>Verified server facility directory</small>`,
        )
        .addTo(group);
    }
  }, [facilities]);

  useEffect(() => {
    const group = layerGroupsRef.current.pcmc;
    if (!group || mode !== 'heatmap') return;
    group.clearLayers();
    const wards = PCMC_WARDS as WardWeek[];
    const hot = new Set(outbreakWards(wards, heatView.week));
    for (const ward of wards) {
      const point = weekPoint(ward, heatView.week);
      const rate = point.flags;
      const fill = !heatView.showFlags
        ? '#94a3b8'
        : rate >= 4
          ? '#e11d48'
          : rate >= 2
            ? '#f59e0b'
            : '#10b981';
      const bounds = (ward as WardWeek & { bounds: [[number, number], [number, number]] }).bounds;
      L.rectangle(bounds, {
        color: hot.has(ward.wardId) ? '#be123c' : fill,
        weight: hot.has(ward.wardId) ? 3 : 1,
        fillColor: fill,
        fillOpacity: 0.35,
      })
        .bindTooltip(`${ward.wardId}: ${point.dengueLike} dengue-like`)
        .addTo(group);
      if (hot.has(ward.wardId)) {
        const center: [number, number] = [
          (bounds[0][0] + bounds[1][0]) / 2,
          (bounds[0][1] + bounds[1][1]) / 2,
        ];
        L.circle(center, { radius: 1800, color: '#be123c', fillOpacity: 0.15 }).addTo(group);
      }
    }
    if (heatView.showFacilities) {
      for (const facility of PCMC_FACILITIES) {
        L.circleMarker([facility.lat, facility.lon], {
          radius: 7,
          color: '#064e3b',
          fillColor: '#10b981',
          fillOpacity: 1,
        })
          .bindTooltip(facility.name)
          .addTo(group);
      }
    }
  }, [mode, heatView]);

  // Handle Tile Layer Switching (OsmAnd Topo vs OSM Standard vs Dark Tactical)
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (tileLayerRef.current) {
      map.removeLayer(tileLayerRef.current);
    }

    const newTileLayer = getTileLayer(mapStyle).addTo(map);
    tileLayerRef.current = newTileLayer;
  }, [mapStyle]);

  // Update Markers & Layers
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    const { subcentres, ambulances, ashas, rings, deadZone } = layerGroupsRef.current;
    if (!subcentres) return;

    // Clear old layers
    subcentres.clearLayers();
    ambulances.clearLayers();
    ashas.clearLayers();
    rings.clearLayers();
    deadZone.clearLayers();

    // 1. Central PHC Shahpur Marker
    const phcIcon = L.divIcon({
      className: 'phc-pin-marker',
      html: `
        <div style="background:#10B981; width:36px; height:36px; border-radius:50%; border:3px solid #FFFFFF; box-shadow:0 4px 14px rgba(16,185,129,0.5); display:flex; align-items:center; justify-content:center; color:white; font-weight:bold; font-size:16px;">
          🏥
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
    });

    const phcMarker = L.marker(PHC_COORDINATES, { icon: phcIcon }).addTo(subcentres);
    phcMarker.bindPopup(`
      <div style="font-family:system-ui; font-size:12px; min-width:200px; color:#0F172A;">
        <strong style="font-size:14px; color:#10B981;">🏥 Primary Health Centre Shahpur</strong><br/>
        <span style="color:#64748B;">Central Command Facility • Code: PHC-SHP-04</span><br/>
        <div style="margin-top:6px; padding:6px; background:#F1F5F9; border-radius:6px;">
          • <strong>16 IPD Beds</strong> (12 Occupied, 4 Available)<br/>
          • <strong>24x7 MO On Duty</strong>: Dr. Rajesh Sharma<br/>
          • <strong>Active Triage Desk</strong>: SLA &lt; 30 mins
        </div>
      </div>
    `);

    // 2. Catchment Isochrone Rings (15-min / 30-min travel times)
    if (showCatchmentRings) {
      // 5 km ring (15 min ambulance transit)
      L.circle(PHC_COORDINATES, {
        radius: 5000,
        color: '#10B981',
        weight: 1.5,
        opacity: 0.6,
        fillColor: '#10B981',
        fillOpacity: 0.05,
        dashArray: '4, 4',
      }).addTo(rings).bindTooltip('15-min Ambulance Catchment (5 km)', { sticky: true });

      // 10 km ring (30 min ambulance transit)
      L.circle(PHC_COORDINATES, {
        radius: 10000,
        color: '#F59E0B',
        weight: 1.5,
        opacity: 0.5,
        fillColor: '#F59E0B',
        fillOpacity: 0.03,
        dashArray: '6, 6',
      }).addTo(rings).bindTooltip('30-min Ambulance Catchment (10 km)', { sticky: true });
    }

    // 3. Offline Dead-Zone Polygon
    if (showDeadZone) {
      const deadZoneCoords: [number, number][] = [
        [25.2600, 83.0350],
        [25.2750, 83.0600],
        [25.2550, 83.0700],
        [25.2480, 83.0400],
      ];
      L.polygon(deadZoneCoords, {
        color: '#F43F5E',
        weight: 1.5,
        fillColor: '#F43F5E',
        fillOpacity: 0.12,
        dashArray: '5, 5',
      }).addTo(deadZone).bindPopup(`
        <div style="font-family:system-ui; font-size:12px; color:#0F172A;">
          <strong style="color:#F43F5E;">⚠️ No-Network Dead-Zone (Pipra Sector)</strong><br/>
          <span style="color:#64748B;">Cellular towers down / riverine terrain</span><br/>
          <div style="margin-top:6px; font-size:11px;">
            • Frontline data syncs via <strong>SMS Gateway Modems</strong><br/>
            • 1 Sub-Centre (SC Pipra) & 2 ASHAs active here
          </div>
        </div>
      `);
    }

    // 4. Sub-Centres Markers
    if (showSubcentres) {
      SUBCENTRES.forEach((sc) => {
        const hasReferrals = sc.activeReferrals > 0;
        const scIcon = L.divIcon({
          className: 'subcentre-pin',
          html: `
            <div style="background:${hasReferrals ? '#F43F5E' : '#0284C7'}; width:28px; height:28px; border-radius:50%; border:2px solid white; box-shadow:0 2px 8px rgba(0,0,0,0.3); display:flex; align-items:center; justify-content:center; color:white; font-size:11px; font-weight:bold;">
              ${hasReferrals ? '🚨' : 'SC'}
            </div>
          `,
          iconSize: [28, 28],
          iconAnchor: [14, 14],
        });

        const marker = L.marker([sc.lat, sc.lng], { icon: scIcon }).addTo(subcentres);
        marker.bindPopup(`
          <div style="font-family:system-ui; font-size:12px; color:#0F172A;">
            <strong style="font-size:13px; color:#0284C7;">${sc.name}</strong><br/>
            <span style="color:#64748B;">${sc.distanceKm} km from PHC • ${sc.anm}</span><br/>
            <div style="margin-top:6px; padding:6px; background:#F8FAFC; border-radius:6px;">
              • Status: <strong>${sc.status}</strong><br/>
              • Active Referrals to PHC: <strong style="color:${hasReferrals ? '#F43F5E' : '#10B981'};">${sc.activeReferrals} Cases</strong><br/>
              • Phone: <a href="tel:${sc.phone}" style="color:#0284C7;">${sc.phone}</a>
            </div>
          </div>
        `);
      });
    }

    // 5. 108 Emergency Ambulances
    if (showAmbulances) {
      AMBULANCES.forEach((amb) => {
        const isEmergency = amb.status === 'en_route_emergency';
        const ambIcon = L.divIcon({
          className: 'amb-pin',
          html: `
            <div style="background:${isEmergency ? '#E11D48' : '#334155'}; width:32px; height:32px; border-radius:8px; border:2px solid white; box-shadow:0 3px 10px rgba(225,29,72,0.4); display:flex; align-items:center; justify-content:center; color:white; font-size:14px;">
              🚑
            </div>
          `,
          iconSize: [32, 32],
          iconAnchor: [16, 16],
        });

        const marker = L.marker([amb.lat, amb.lng], { icon: ambIcon }).addTo(ambulances);
        marker.bindPopup(`
          <div style="font-family:system-ui; font-size:12px; min-width:210px; color:#0F172A;">
            <strong style="font-size:13px; color:#E11D48;">🚑 Ambulance ${amb.code}</strong><br/>
            <span style="color:#64748B;">GPS Speed: ${amb.speedKmH} km/h • ETA: <strong>${amb.etaMinutes} mins</strong></span><br/>
            ${
              amb.patient
                ? `
              <div style="margin-top:6px; padding:6px; background:#FFF1F2; border:1px solid #FECDD3; border-radius:6px;">
                <strong>Patient:</strong> ${amb.patient}<br/>
                <span style="color:#E11D48; font-weight:600;">${amb.condition}</span><br/>
                <span>Destination: ${amb.destination}</span>
              </div>
            `
                : '<div style="margin-top:6px; color:#64748B;">Vehicle on standby at sub-centre.</div>'
            }
            <div style="margin-top:6px; text-align:right;">
              <a href="tel:${amb.driverPhone}" style="color:#0284C7; font-weight:600; text-decoration:none;">📞 Call Driver</a>
            </div>
          </div>
        `);

        // Draw animated routing line to PHC if in transit
        if (isEmergency) {
          L.polyline([[amb.lat, amb.lng], PHC_COORDINATES], {
            color: '#E11D48',
            weight: 3,
            dashArray: '6, 6',
            opacity: 0.7,
          }).addTo(ambulances);
        }
      });
    }

    // 6. ASHA Field Workers
    if (showAshas) {
      ASHA_WORKERS.forEach((asha) => {
        const ashaIcon = L.divIcon({
          className: 'asha-pin',
          html: `
            <div style="background:#8B5CF6; width:26px; height:26px; border-radius:50%; border:2px solid white; box-shadow:0 2px 6px rgba(139,92,246,0.4); display:flex; align-items:center; justify-content:center; color:white; font-size:11px;">
              👩‍⚕️
            </div>
          `,
          iconSize: [26, 26],
          iconAnchor: [13, 13],
        });

        const marker = L.marker([asha.lat, asha.lng], { icon: ashaIcon }).addTo(ashas);
        marker.bindPopup(`
          <div style="font-family:system-ui; font-size:12px; color:#0F172A;">
            <strong style="color:#8B5CF6; font-size:13px;">ASHA: ${asha.name}</strong><br/>
            <span style="color:#64748B;">Sector: ${asha.village} • Synced ${asha.lastSyncMinsAgo}m ago</span><br/>
            <div style="margin-top:6px; padding:6px; background:#F5F3FF; border-radius:6px;">
              • Task: <strong>${asha.currentActivity}</strong><br/>
              • Mobile Battery: <strong>${asha.batteryPct}%</strong><br/>
              • Phone: <a href="tel:${asha.phone}" style="color:#8B5CF6;">${asha.phone}</a>
            </div>
          </div>
        `);
      });
    }
  }, [showSubcentres, showAmbulances, showAshas, showCatchmentRings, showDeadZone]);

  // Center Map on PHC
  const handleCenterPHC = () => {
    mapInstanceRef.current?.setView(PHC_COORDINATES, 13, { animate: true });
  };

  // Focus Emergency Cases
  const handleFocusEmergency = () => {
    mapInstanceRef.current?.setView([25.3340, 82.9850], 14, { animate: true });
  };

  return (
    <div className="flex flex-col h-[calc(100vh-4rem)] overflow-hidden bg-white dark:bg-[#1E1E1E]">
      {mode === 'heatmap' && <PcmcHeatPanel onView={onHeatView} />}
      {/* 1. Header Toolbar */}
      <div className="shrink-0 p-4 border-b border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-xs">
        <div>
          <h1 className="text-lg lg:text-xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
            Catchment GIS Field Map & Fleet Surveillance
            <Badge variant="default" className="text-[10px]">
              OsmAnd Topo Powered
            </Badge>
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Server-backed India facility directory • {facilities.length} mapped facilities • {mapSources.length} registered data sources
          </p>
        </div>

        {/* Stats Pill Strip */}
        <div className="flex items-center gap-2 flex-wrap text-xs">
          <Link
            to="/india-map"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold shadow-sm transition-all"
          >
            <Navigation className="w-3.5 h-3.5" />
            <span>All-India PHC Map (29.5k)</span>
          </Link>
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-[#2E2E2E] bg-white dark:bg-[#222224] text-[#0F172A] dark:text-[#F8FAFC] font-semibold shadow-xs">
            <span className="w-2 h-2 rounded-full bg-rose-500 shrink-0" />
            <span>2 En-Route (ETA &lt; 15m)</span>
          </div>
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-[#2E2E2E] bg-white dark:bg-[#222224] text-[#0F172A] dark:text-[#F8FAFC] font-semibold shadow-xs">
            <Radio className="w-3.5 h-3.5 text-emerald-600" />
            <span>6 Sub-Centres Linked</span>
          </div>
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-[#2E2E2E] bg-white dark:bg-[#222224] text-[#525252] dark:text-[#94A3B8] shadow-xs">
            <Activity className="w-3.5 h-3.5 text-purple-500" />
            <span>14 ASHAs in Field</span>
          </div>
        </div>
      </div>

      {/* 2. Main Workspace: Map Canvas + Floating Overlay Controls */}
      <div className="flex-1 relative min-h-0 w-full h-full">
        {/* Leaflet DOM Node */}
        <div
          ref={mapContainerRef}
          style={{ width: '100%', height: '100%', minHeight: '520px' }}
          className="w-full h-full z-0"
        />

        {/* Floating Controls Overlay (Top Left) */}
        <div className="absolute top-4 left-4 z-20 space-y-2 max-w-xs sm:max-w-sm">
          {/* Map Base Layer Selector (OsmAnd Styles) */}
          <Card className="p-3 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-sm space-y-2">
            <div className="text-[11px] font-bold uppercase tracking-wider text-[#71717A] flex items-center justify-between">
              <span className="flex items-center gap-1">
                <Layers className="w-3.5 h-3.5" />
                Map Rendering Style
              </span>
            </div>
            <div className="grid grid-cols-3 gap-1.5 text-xs">
              <button
                onClick={() => setMapStyle('osmand_topo')}
                className={`px-2 py-1.5 rounded-lg font-semibold text-[11px] transition-all cursor-pointer ${
                  mapStyle === 'osmand_topo'
                    ? 'bg-emerald-600 text-white shadow-xs'
                    : 'bg-slate-100 dark:bg-[#1E1E1E] text-[#525252] dark:text-[#94A3B8] hover:bg-slate-200 dark:hover:bg-[#2A2A2A]'
                }`}
              >
                OsmAnd Topo
              </button>
              <button
                onClick={() => setMapStyle('osm_standard')}
                className={`px-2 py-1.5 rounded-lg font-semibold text-[11px] transition-all cursor-pointer ${
                  mapStyle === 'osm_standard'
                    ? 'bg-emerald-600 text-white shadow-xs'
                    : 'bg-slate-100 dark:bg-[#1E1E1E] text-[#525252] dark:text-[#94A3B8] hover:bg-slate-200 dark:hover:bg-[#2A2A2A]'
                }`}
              >
                OSM Standard
              </button>
              <button
                onClick={() => setMapStyle('dark_tactical')}
                className={`px-2 py-1.5 rounded-lg font-semibold text-[11px] transition-all cursor-pointer ${
                  mapStyle === 'dark_tactical'
                    ? 'bg-emerald-600 text-white shadow-xs'
                    : 'bg-slate-100 dark:bg-[#1E1E1E] text-[#525252] dark:text-[#94A3B8] hover:bg-slate-200 dark:hover:bg-[#2A2A2A]'
                }`}
              >
                Night Mode
              </button>
            </div>
          </Card>

          {/* Feature Layer Toggles */}
          <Card className="p-3 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-sm space-y-2">
            <div className="text-[11px] font-bold uppercase tracking-wider text-[#71717A]">
              GIS Layers & Assets
            </div>
            <div className="space-y-1.5 text-xs">
              <label className="flex items-center justify-between cursor-pointer hover:opacity-80">
                <span className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#F8FAFC]">
                  <span>🚑</span>
                  <span>108 Ambulances ({AMBULANCES.length})</span>
                </span>
                <input
                  type="checkbox"
                  checked={showAmbulances}
                  onChange={(e) => setShowAmbulances(e.target.checked)}
                  className="rounded text-rose-600 focus:ring-0"
                />
              </label>

              <label className="flex items-center justify-between cursor-pointer hover:opacity-80">
                <span className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#F8FAFC]">
                  <span>🏥</span>
                  <span>Sub-Centres ({SUBCENTRES.length})</span>
                </span>
                <input
                  type="checkbox"
                  checked={showSubcentres}
                  onChange={(e) => setShowSubcentres(e.target.checked)}
                  className="rounded text-sky-600 focus:ring-0"
                />
              </label>

              <label className="flex items-center justify-between cursor-pointer hover:opacity-80">
                <span className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#F8FAFC]">
                  <span>👩‍⚕️</span>
                  <span>ASHAs in Field ({ASHA_WORKERS.length})</span>
                </span>
                <input
                  type="checkbox"
                  checked={showAshas}
                  onChange={(e) => setShowAshas(e.target.checked)}
                  className="rounded text-purple-600 focus:ring-0"
                />
              </label>

              <label className="flex items-center justify-between cursor-pointer hover:opacity-80">
                <span className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#F8FAFC]">
                  <span className="w-2.5 h-2.5 rounded-full border border-emerald-500 inline-block" />
                  <span>15m & 30m Catchment Rings</span>
                </span>
                <input
                  type="checkbox"
                  checked={showCatchmentRings}
                  onChange={(e) => setShowCatchmentRings(e.target.checked)}
                  className="rounded text-emerald-600 focus:ring-0"
                />
              </label>

              <label className="flex items-center justify-between cursor-pointer hover:opacity-80">
                <span className="flex items-center gap-1.5 text-[#0F172A] dark:text-[#F8FAFC]">
                  <span className="w-2.5 h-2.5 rounded-sm bg-rose-500/40 inline-block" />
                  <span>Offline SMS Dead-Zones</span>
                </span>
                <input
                  type="checkbox"
                  checked={showDeadZone}
                  onChange={(e) => setShowDeadZone(e.target.checked)}
                  className="rounded text-rose-600 focus:ring-0"
                />
              </label>
            </div>
          </Card>

          {/* Quick Focus Controls */}
          <div className="flex items-center gap-2">
            <Button
              size="xs"
              variant="outline"
              onClick={handleCenterPHC}
              className="bg-white dark:bg-[#1E1E1E] border-[#E5E7EB] dark:border-[#2E2E2E] gap-1 text-[11px]"
            >
              <Crosshair className="w-3.5 h-3.5 text-emerald-600" />
              <span>Center PHC</span>
            </Button>
            <Button
              size="xs"
              variant="destructive"
              onClick={handleFocusEmergency}
              className="gap-1 text-[11px]"
            >
              <Activity className="w-3.5 h-3.5" />
              <span>Track 108 Alert</span>
            </Button>
          </div>
        </div>

        {/* Floating Live Fleet & Transit Drawer (Bottom Right) */}
        <div className="absolute bottom-6 left-4 right-4 sm:left-auto sm:right-6 sm:w-88 z-20">
          <Card className="p-4 border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#222224] shadow-lg space-y-3">
            <div className="flex items-center justify-between border-b border-[#E5E7EB] dark:border-[#2E2E2E] pb-2">
              <span className="text-xs font-bold text-[#0F172A] dark:text-[#F8FAFC] flex items-center gap-1.5">
                <Navigation className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400" />
                Live En-Route Emergency Fleet
              </span>
              <span className="text-[10px] font-mono text-emerald-600 dark:text-emerald-400 font-semibold">
                GPS Active (1s ping)
              </span>
            </div>

            <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
              {AMBULANCES.filter((a) => a.status === 'en_route_emergency').map((amb) => (
                <div
                  key={amb.id}
                  className="p-2.5 rounded-xl border-l-4 border-l-rose-500 border border-[#E5E7EB] dark:border-[#2E2E2E] bg-white dark:bg-[#1E1E1E] text-xs space-y-1"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-rose-700 dark:text-rose-400 flex items-center gap-1">
                      <span>🚑 {amb.code}</span>
                      <span className="text-[10px] text-[#525252] dark:text-[#A3A3A3]">({amb.speedKmH} km/h)</span>
                    </span>
                    <span className="px-1.5 py-0.5 rounded bg-rose-600 text-white text-[10px] font-bold">
                      ETA {amb.etaMinutes}m
                    </span>
                  </div>
                  <div className="font-semibold text-[#0F172A] dark:text-[#F8FAFC] text-[11px] truncate">
                    {amb.patient}
                  </div>
                  <div className="text-[10px] text-rose-600 dark:text-rose-400 font-medium">
                    {amb.condition}
                  </div>
                  <div className="flex items-center justify-between pt-1 border-t border-[#E5E7EB] dark:border-[#2E2E2E] text-[10px]">
                    <span className="text-[#525252] dark:text-[#94A3B8]">Destination: PHC Shahpur</span>
                    <a
                      href={`tel:${amb.driverPhone}`}
                      className="font-semibold text-sky-600 dark:text-sky-400 hover:underline"
                    >
                      Call Driver
                    </a>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
