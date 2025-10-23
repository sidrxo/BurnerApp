import { renderHook, act } from '@testing-library/react';
import { useIsMobile } from '../hooks/use-mobile';

describe('useIsMobile Hook', () => {
  const MOBILE_BREAKPOINT = 768;

  // Mock window.matchMedia
  let matchMediaMock: jest.Mock;
  let listenerCallbacks: Array<() => void> = [];

  beforeEach(() => {
    listenerCallbacks = [];

    matchMediaMock = jest.fn((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addEventListener: jest.fn((event: string, callback: () => void) => {
        listenerCallbacks.push(callback);
      }),
      removeEventListener: jest.fn((event: string, callback: () => void) => {
        listenerCallbacks = listenerCallbacks.filter(cb => cb !== callback);
      }),
      dispatchEvent: jest.fn(),
    }));

    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: matchMediaMock,
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
    listenerCallbacks = [];
  });

  describe('Initial state', () => {
    test('should initialize with false when window is wider than mobile breakpoint', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);
    });

    test('should initialize with true when window is narrower than mobile breakpoint', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 500,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);
    });

    test('should initialize with false at exact mobile breakpoint', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: MOBILE_BREAKPOINT,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);
    });

    test('should initialize with true at one pixel below mobile breakpoint', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: MOBILE_BREAKPOINT - 1,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);
    });
  });

  describe('Media query setup', () => {
    test('should create correct media query', () => {
      renderHook(() => useIsMobile());

      expect(matchMediaMock).toHaveBeenCalledWith('(max-width: 767px)');
    });

    test('should register change event listener', () => {
      const { result } = renderHook(() => useIsMobile());

      const mockMediaQuery = matchMediaMock.mock.results[0].value;
      expect(mockMediaQuery.addEventListener).toHaveBeenCalledWith(
        'change',
        expect.any(Function)
      );
    });
  });

  describe('Responsive behavior', () => {
    test('should update when window resizes from desktop to mobile', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);

      // Simulate resize to mobile
      act(() => {
        Object.defineProperty(window, 'innerWidth', {
          writable: true,
          configurable: true,
          value: 500,
        });
        listenerCallbacks.forEach(callback => callback());
      });

      expect(result.current).toBe(true);
    });

    test('should update when window resizes from mobile to desktop', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 500,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);

      // Simulate resize to desktop
      act(() => {
        Object.defineProperty(window, 'innerWidth', {
          writable: true,
          configurable: true,
          value: 1024,
        });
        listenerCallbacks.forEach(callback => callback());
      });

      expect(result.current).toBe(false);
    });

    test('should handle multiple resize events', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024,
      });

      const { result } = renderHook(() => useIsMobile());

      // First resize
      act(() => {
        Object.defineProperty(window, 'innerWidth', {
          writable: true,
          configurable: true,
          value: 500,
        });
        listenerCallbacks.forEach(callback => callback());
      });
      expect(result.current).toBe(true);

      // Second resize
      act(() => {
        Object.defineProperty(window, 'innerWidth', {
          writable: true,
          configurable: true,
          value: 1024,
        });
        listenerCallbacks.forEach(callback => callback());
      });
      expect(result.current).toBe(false);

      // Third resize
      act(() => {
        Object.defineProperty(window, 'innerWidth', {
          writable: true,
          configurable: true,
          value: 600,
        });
        listenerCallbacks.forEach(callback => callback());
      });
      expect(result.current).toBe(true);
    });
  });

  describe('Cleanup', () => {
    test('should remove event listener on unmount', () => {
      const { unmount } = renderHook(() => useIsMobile());

      const mockMediaQuery = matchMediaMock.mock.results[0].value;

      unmount();

      expect(mockMediaQuery.removeEventListener).toHaveBeenCalledWith(
        'change',
        expect.any(Function)
      );
    });

    test('should not cause memory leaks', () => {
      const { rerender, unmount } = renderHook(() => useIsMobile());

      // Rerender multiple times
      rerender();
      rerender();
      rerender();

      const mockMediaQuery = matchMediaMock.mock.results[0].value;

      // Should still only have one listener registered
      expect(mockMediaQuery.addEventListener).toHaveBeenCalledTimes(1);

      unmount();

      // Should remove the listener
      expect(mockMediaQuery.removeEventListener).toHaveBeenCalledTimes(1);
    });
  });

  describe('Edge cases', () => {
    test('should handle window.innerWidth = 0', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 0,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);
    });

    test('should handle very large window widths', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 10000,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);
    });

    test('should be consistent across multiple hook instances', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 500,
      });

      const { result: result1 } = renderHook(() => useIsMobile());
      const { result: result2 } = renderHook(() => useIsMobile());

      expect(result1.current).toBe(result2.current);
      expect(result1.current).toBe(true);
    });
  });

  describe('Common breakpoint scenarios', () => {
    test('should detect iPhone SE (375px)', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 375,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);
    });

    test('should detect iPhone 12 Pro (390px)', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 390,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(true);
    });

    test('should detect iPad Mini (768px)', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 768,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false); // At breakpoint, not mobile
    });

    test('should detect iPad Pro (1024px)', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);
    });

    test('should detect desktop (1920px)', () => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1920,
      });

      const { result } = renderHook(() => useIsMobile());
      expect(result.current).toBe(false);
    });
  });
});
