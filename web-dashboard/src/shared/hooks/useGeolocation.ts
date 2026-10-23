import { useCallback, useEffect, useRef, useState } from 'react';

export interface UserCoordinates {
  lat: number;
  lng: number;
  accuracy: number;
  timestamp: number;
}

export interface UseGeolocationOptions {
  autoLocateDefault?: boolean;
  onLocationUpdate?: (coords: UserCoordinates) => void;
}

const STORAGE_KEY = 'asha-web-auto-locate';

export function useGeolocation(options: UseGeolocationOptions = {}) {
  const { autoLocateDefault = false, onLocationUpdate } = options;

  const [location, setLocation] = useState<UserCoordinates | null>(null);
  const [isLocating, setIsLocating] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [isWatching, setIsWatching] = useState<boolean>(false);

  const [autoLocate, setAutoLocateState] = useState<boolean>(() => {
    if (typeof window === 'undefined') return autoLocateDefault;
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored !== null) return stored === 'true';
    return autoLocateDefault;
  });

  const watchIdRef = useRef<number | null>(null);
  const onLocationUpdateRef = useRef(onLocationUpdate);
  onLocationUpdateRef.current = onLocationUpdate;

  const setAutoLocate = useCallback((enabled: boolean) => {
    setAutoLocateState(enabled);
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, enabled ? 'true' : 'false');
    }
  }, []);

  const requestLocation = useCallback(
    (): Promise<UserCoordinates | null> => {
      if (typeof window === 'undefined' || !navigator.geolocation) {
        const msg = 'Geolocation is not supported by your browser.';
        setError(msg);
        return Promise.resolve(null);
      }

      setIsLocating(true);
      setError(null);

      return new Promise((resolve) => {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            const coords: UserCoordinates = {
              lat: pos.coords.latitude,
              lng: pos.coords.longitude,
              accuracy: pos.coords.accuracy,
              timestamp: pos.timestamp,
            };
            setLocation(coords);
            setIsLocating(false);
            setError(null);
            onLocationUpdateRef.current?.(coords);
            resolve(coords);
          },
          (err) => {
            let msg = 'Unable to retrieve your location.';
            if (err.code === err.PERMISSION_DENIED) {
              msg = 'Location permission denied. Please enable location access in your browser.';
            } else if (err.code === err.POSITION_UNAVAILABLE) {
              msg = 'Location information is currently unavailable.';
            } else if (err.code === err.TIMEOUT) {
              msg = 'Location request timed out. Please retry.';
            }
            setError(msg);
            setIsLocating(false);
            resolve(null);
          },
          {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 30000,
          }
        );
      });
    },
    []
  );

  const startWatching = useCallback(() => {
    if (typeof window === 'undefined' || !navigator.geolocation) return;

    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
    }

    setIsWatching(true);
    setError(null);

    watchIdRef.current = navigator.geolocation.watchPosition(
      (pos) => {
        const coords: UserCoordinates = {
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
          accuracy: pos.coords.accuracy,
          timestamp: pos.timestamp,
        };
        setLocation(coords);
        setIsLocating(false);
        setError(null);
        onLocationUpdateRef.current?.(coords);
      },
      (err) => {
        if (err.code === err.PERMISSION_DENIED) {
          setError('Live tracking disabled: location permission denied.');
          setIsWatching(false);
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 5000,
      }
    );
  }, []);

  const stopWatching = useCallback(() => {
    if (watchIdRef.current !== null && typeof window !== 'undefined' && navigator.geolocation) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
    setIsWatching(false);
  }, []);

  // Cleanup watcher on unmount
  useEffect(() => {
    return () => {
      if (watchIdRef.current !== null && typeof window !== 'undefined' && navigator.geolocation) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, []);

  // Auto-locate on mount if autoLocate is enabled
  useEffect(() => {
    if (autoLocate) {
      requestLocation();
    }
  }, [autoLocate, requestLocation]);

  return {
    location,
    isLocating,
    error,
    autoLocate,
    setAutoLocate,
    isWatching,
    requestLocation,
    startWatching,
    stopWatching,
    clearError: () => setError(null),
  };
}
