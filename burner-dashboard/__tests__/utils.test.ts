import { cn, formatCurrency, formatNumber, debounce, formatDateSafe } from '../lib/utils';

describe('Utility Functions', () => {
  describe('cn (className merger)', () => {
    test('should merge single className', () => {
      const result = cn('text-red-500');
      expect(result).toBe('text-red-500');
    });

    test('should merge multiple classNames', () => {
      const result = cn('text-red-500', 'bg-blue-500', 'p-4');
      expect(result).toContain('text-red-500');
      expect(result).toContain('bg-blue-500');
      expect(result).toContain('p-4');
    });

    test('should handle conditional classNames', () => {
      const isActive = true;
      const result = cn('base-class', isActive && 'active-class');
      expect(result).toContain('base-class');
      expect(result).toContain('active-class');
    });

    test('should filter out falsy values', () => {
      const result = cn('text-red-500', false, null, undefined, 'p-4');
      expect(result).toContain('text-red-500');
      expect(result).toContain('p-4');
    });

    test('should handle tailwind merge conflicts', () => {
      // twMerge should resolve conflicting classes
      const result = cn('p-4', 'p-8');
      expect(result).toBe('p-8'); // Later class should override
    });

    test('should handle array of classNames', () => {
      const result = cn(['text-red-500', 'bg-blue-500']);
      expect(result).toContain('text-red-500');
      expect(result).toContain('bg-blue-500');
    });
  });

  describe('formatCurrency', () => {
    test('should format GBP by default', () => {
      const result = formatCurrency(50.99);
      expect(result).toContain('50.99');
      expect(result).toContain('£');
    });

    test('should format USD', () => {
      const result = formatCurrency(50.99, 'USD', 'en-US');
      expect(result).toContain('50.99');
      expect(result).toContain('$');
    });

    test('should format EUR', () => {
      const result = formatCurrency(50.99, 'EUR', 'de-DE');
      expect(result).toContain('50,99');
      expect(result).toContain('€');
    });

    test('should handle zero', () => {
      const result = formatCurrency(0);
      expect(result).toContain('0');
    });

    test('should handle negative numbers', () => {
      const result = formatCurrency(-50.99);
      expect(result).toContain('50.99');
      expect(result).toMatch(/[-−]/); // Dash or minus sign
    });

    test('should handle large numbers', () => {
      const result = formatCurrency(1000000);
      expect(result).toContain('1');
      expect(result).toContain('000');
    });

    test('should handle decimal precision', () => {
      const result = formatCurrency(50.5);
      expect(result).toContain('50.50');
    });

    test('should handle undefined/null as 0', () => {
      const result1 = formatCurrency(null as any);
      const result2 = formatCurrency(undefined as any);
      expect(result1).toContain('0');
      expect(result2).toContain('0');
    });

    test('should use correct locale formatting', () => {
      const resultGB = formatCurrency(1234.56, 'GBP', 'en-GB');
      const resultUS = formatCurrency(1234.56, 'USD', 'en-US');

      expect(resultGB).toContain('1,234.56');
      expect(resultUS).toContain('1,234.56');
    });
  });

  describe('formatNumber', () => {
    test('should format numbers with default locale', () => {
      const result = formatNumber(1234567);
      expect(result).toBe('1,234,567');
    });

    test('should handle zero', () => {
      const result = formatNumber(0);
      expect(result).toBe('0');
    });

    test('should handle negative numbers', () => {
      const result = formatNumber(-1234);
      expect(result).toBe('-1,234');
    });

    test('should handle decimals', () => {
      const result = formatNumber(1234.56);
      expect(result).toBe('1,234.56');
    });

    test('should format with different locale', () => {
      const result = formatNumber(1234567, 'de-DE');
      expect(result).toBe('1.234.567'); // German uses dots for thousands
    });

    test('should handle null/undefined as 0', () => {
      const result1 = formatNumber(null as any);
      const result2 = formatNumber(undefined as any);
      expect(result1).toBe('0');
      expect(result2).toBe('0');
    });

    test('should handle large numbers', () => {
      const result = formatNumber(1000000000);
      expect(result).toContain('1,000,000,000');
    });
  });

  describe('debounce', () => {
    jest.useFakeTimers();

    test('should delay function execution', () => {
      const mockFn = jest.fn();
      const debouncedFn = debounce(mockFn, 300);

      debouncedFn();
      expect(mockFn).not.toHaveBeenCalled();

      jest.advanceTimersByTime(300);
      expect(mockFn).toHaveBeenCalledTimes(1);
    });

    test('should cancel previous calls', () => {
      const mockFn = jest.fn();
      const debouncedFn = debounce(mockFn, 300);

      debouncedFn();
      debouncedFn();
      debouncedFn();

      jest.advanceTimersByTime(300);
      expect(mockFn).toHaveBeenCalledTimes(1); // Only last call should execute
    });

    test('should pass arguments to the function', () => {
      const mockFn = jest.fn();
      const debouncedFn = debounce(mockFn, 300);

      debouncedFn('arg1', 'arg2', 'arg3');

      jest.advanceTimersByTime(300);
      expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2', 'arg3');
    });

    test('should use custom wait time', () => {
      const mockFn = jest.fn();
      const debouncedFn = debounce(mockFn, 500);

      debouncedFn();
      jest.advanceTimersByTime(300);
      expect(mockFn).not.toHaveBeenCalled();

      jest.advanceTimersByTime(200);
      expect(mockFn).toHaveBeenCalledTimes(1);
    });

    test('should handle multiple sequential calls', () => {
      const mockFn = jest.fn();
      const debouncedFn = debounce(mockFn, 300);

      debouncedFn('first');
      jest.advanceTimersByTime(300);
      expect(mockFn).toHaveBeenCalledWith('first');

      debouncedFn('second');
      jest.advanceTimersByTime(300);
      expect(mockFn).toHaveBeenCalledWith('second');
      expect(mockFn).toHaveBeenCalledTimes(2);
    });

    afterEach(() => {
      jest.clearAllTimers();
    });
  });

  describe('formatDateSafe', () => {
    test('should format JavaScript Date object', () => {
      const date = new Date('2025-10-23T14:30:00Z');
      const result = formatDateSafe(date);

      expect(result).not.toBe('N/A');
      expect(result).not.toBe('-');
      expect(typeof result).toBe('string');
    });

    test('should format Firestore Timestamp', () => {
      const firestoreTimestamp = {
        toDate: () => new Date('2025-10-23T14:30:00Z')
      };
      const result = formatDateSafe(firestoreTimestamp);

      expect(result).not.toBe('N/A');
      expect(result).not.toBe('-');
    });

    test('should format ISO string', () => {
      const isoString = '2025-10-23T14:30:00Z';
      const result = formatDateSafe(isoString);

      expect(result).not.toBe('N/A');
      expect(result).not.toBe('-');
    });

    test('should return "N/A" for null', () => {
      const result = formatDateSafe(null);
      expect(result).toBe('N/A');
    });

    test('should return "N/A" for undefined', () => {
      const result = formatDateSafe(undefined);
      expect(result).toBe('N/A');
    });

    test('should return "-" for invalid date', () => {
      const result = formatDateSafe('invalid-date');
      expect(result).toBe('-');
    });

    test('should return "-" for NaN date', () => {
      const result = formatDateSafe(new Date('invalid'));
      expect(result).toBe('-');
    });

    test('should use custom locale', () => {
      const date = new Date('2025-10-23T14:30:00Z');
      const resultGB = formatDateSafe(date, 'en-GB');
      const resultUS = formatDateSafe(date, 'en-US');

      expect(resultGB).not.toBe('N/A');
      expect(resultUS).not.toBe('N/A');
      // Both should be valid strings but may differ in format
    });

    test('should include both date and time', () => {
      const date = new Date('2025-10-23T14:30:00Z');
      const result = formatDateSafe(date);

      // Should contain time components (colon separator)
      expect(result).toMatch(/:/);
    });

    test('should handle various date formats', () => {
      const formats = [
        new Date('2025-10-23'),
        new Date(2025, 9, 23), // Month is 0-indexed
        '2025-10-23',
        1729695000000, // Timestamp
      ];

      formats.forEach(format => {
        const result = formatDateSafe(format);
        expect(result).not.toBe('N/A');
        expect(result).not.toBe('-');
      });
    });

    test('should handle error gracefully', () => {
      const problematicDate = {
        toDate: () => {
          throw new Error('Conversion error');
        }
      };
      const result = formatDateSafe(problematicDate);
      expect(result).toBe('-');
    });
  });
});
