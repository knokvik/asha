import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useGeolocation } from '@/shared/hooks/useGeolocation';

describe('useGeolocation Hook', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
    vi.stubGlobal('navigator', {
      ...navigator,
      geolocation: {
        getCurrentPosition: vi.fn(),
        watchPosition: vi.fn(),
        clearWatch: vi.fn(),
      },
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('initializes with default values and reads from localStorage', () => {
    localStorage.setItem('asha-web-auto-locate', 'true');

    const { result } = renderHook(() => useGeolocation());

    expect(result.current.autoLocate).toBe(true);
    expect(result.current.location).toBeNull();
    // Auto-locate initiates location request on mount
    expect(result.current.isLocating).toBe(true);
    expect(result.current.error).toBeNull();
  });

  it('updates autoLocate state and persists in localStorage', () => {
    const { result } = renderHook(() => useGeolocation());

    act(() => {
      result.current.setAutoLocate(true);
    });

    expect(result.current.autoLocate).toBe(true);
    expect(localStorage.getItem('asha-web-auto-locate')).toBe('true');

    act(() => {
      result.current.setAutoLocate(false);
    });

    expect(result.current.autoLocate).toBe(false);
    expect(localStorage.getItem('asha-web-auto-locate')).toBe('false');
  });

  it('successfully requests location and sets coordinates', async () => {
    const mockGeolocation = {
      getCurrentPosition: vi.fn().mockImplementation((success) => {
        success({
          coords: {
            latitude: 28.5535,
            longitude: 77.1215,
            accuracy: 12,
          },
          timestamp: 1700000000000,
        });
      }),
      watchPosition: vi.fn(),
      clearWatch: vi.fn(),
    };

    vi.stubGlobal('navigator', {
      ...navigator,
      geolocation: mockGeolocation,
    });

    const { result } = renderHook(() => useGeolocation());

    let coords: any;
    await act(async () => {
      coords = await result.current.requestLocation();
    });

    expect(coords).toEqual({
      lat: 28.5535,
      lng: 77.1215,
      accuracy: 12,
      timestamp: 1700000000000,
    });
    expect(result.current.location).toEqual({
      lat: 28.5535,
      lng: 77.1215,
      accuracy: 12,
      timestamp: 1700000000000,
    });
    expect(result.current.isLocating).toBe(false);
    expect(result.current.error).toBeNull();
  });

  it('handles permission denied error properly', async () => {
    const mockGeolocation = {
      getCurrentPosition: vi.fn().mockImplementation((_, error) => {
        error({
          code: 1, // PERMISSION_DENIED
          PERMISSION_DENIED: 1,
          POSITION_UNAVAILABLE: 2,
          TIMEOUT: 3,
        });
      }),
      watchPosition: vi.fn(),
      clearWatch: vi.fn(),
    };

    vi.stubGlobal('navigator', {
      ...navigator,
      geolocation: mockGeolocation,
    });

    const { result } = renderHook(() => useGeolocation());

    let coords: any;
    await act(async () => {
      coords = await result.current.requestLocation();
    });

    expect(coords).toBeNull();
    expect(result.current.location).toBeNull();
    expect(result.current.error).toContain('permission denied');
  });

  it('starts and stops live tracking with watchPosition', () => {
    const clearWatchMock = vi.fn();
    const mockGeolocation = {
      getCurrentPosition: vi.fn(),
      watchPosition: vi.fn().mockReturnValue(12345),
      clearWatch: clearWatchMock,
    };

    vi.stubGlobal('navigator', {
      ...navigator,
      geolocation: mockGeolocation,
    });

    const { result } = renderHook(() => useGeolocation());

    act(() => {
      result.current.startWatching();
    });

    expect(mockGeolocation.watchPosition).toHaveBeenCalled();
    expect(result.current.isWatching).toBe(true);

    act(() => {
      result.current.stopWatching();
    });

    expect(clearWatchMock).toHaveBeenCalledWith(12345);
    expect(result.current.isWatching).toBe(false);
  });
});
