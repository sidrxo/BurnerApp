import {
  EVENT_STATUS_OPTIONS,
  EVENT_CATEGORY_OPTIONS,
  EVENT_TAG_OPTIONS,
  SCANNER_ROLE
} from '../lib/constants';

describe('Constants', () => {
  describe('EVENT_STATUS_OPTIONS', () => {
    test('should be an array', () => {
      expect(Array.isArray(EVENT_STATUS_OPTIONS)).toBe(true);
    });

    test('should contain all expected status options', () => {
      const values = EVENT_STATUS_OPTIONS.map(opt => opt.value);
      expect(values).toContain('draft');
      expect(values).toContain('scheduled');
      expect(values).toContain('active');
      expect(values).toContain('soldOut');
      expect(values).toContain('completed');
      expect(values).toContain('cancelled');
    });

    test('should have correct structure', () => {
      EVENT_STATUS_OPTIONS.forEach(option => {
        expect(option).toHaveProperty('value');
        expect(option).toHaveProperty('label');
        expect(typeof option.value).toBe('string');
        expect(typeof option.label).toBe('string');
      });
    });

    test('should have human-readable labels', () => {
      const draftOption = EVENT_STATUS_OPTIONS.find(opt => opt.value === 'draft');
      expect(draftOption?.label).toBe('Draft');

      const soldOutOption = EVENT_STATUS_OPTIONS.find(opt => opt.value === 'soldOut');
      expect(soldOutOption?.label).toBe('Sold Out');
    });

    test('should have 6 status options', () => {
      expect(EVENT_STATUS_OPTIONS).toHaveLength(6);
    });

    test('should not have duplicate values', () => {
      const values = EVENT_STATUS_OPTIONS.map(opt => opt.value);
      const uniqueValues = new Set(values);
      expect(uniqueValues.size).toBe(values.length);
    });
  });

  describe('EVENT_CATEGORY_OPTIONS', () => {
    test('should be an array', () => {
      expect(Array.isArray(EVENT_CATEGORY_OPTIONS)).toBe(true);
    });

    test('should contain all expected categories', () => {
      const values = EVENT_CATEGORY_OPTIONS.map(opt => opt.value);
      expect(values).toContain('music');
      expect(values).toContain('nightlife');
      expect(values).toContain('wellness');
      expect(values).toContain('arts');
      expect(values).toContain('community');
      expect(values).toContain('food');
      expect(values).toContain('other');
    });

    test('should have correct structure', () => {
      EVENT_CATEGORY_OPTIONS.forEach(option => {
        expect(option).toHaveProperty('value');
        expect(option).toHaveProperty('label');
        expect(typeof option.value).toBe('string');
        expect(typeof option.label).toBe('string');
      });
    });

    test('should have human-readable labels', () => {
      const artsOption = EVENT_CATEGORY_OPTIONS.find(opt => opt.value === 'arts');
      expect(artsOption?.label).toBe('Arts & Culture');

      const foodOption = EVENT_CATEGORY_OPTIONS.find(opt => opt.value === 'food');
      expect(foodOption?.label).toBe('Food & Drink');
    });

    test('should have 7 category options', () => {
      expect(EVENT_CATEGORY_OPTIONS).toHaveLength(7);
    });

    test('should not have duplicate values', () => {
      const values = EVENT_CATEGORY_OPTIONS.map(opt => opt.value);
      const uniqueValues = new Set(values);
      expect(uniqueValues.size).toBe(values.length);
    });

    test('should include "other" as fallback category', () => {
      const values = EVENT_CATEGORY_OPTIONS.map(opt => opt.value);
      expect(values).toContain('other');
    });
  });

  describe('EVENT_TAG_OPTIONS', () => {
    test('should be an array', () => {
      expect(Array.isArray(EVENT_TAG_OPTIONS)).toBe(true);
    });

    test('should contain music genre tags', () => {
      expect(EVENT_TAG_OPTIONS).toContain('techno');
      expect(EVENT_TAG_OPTIONS).toContain('house');
      expect(EVENT_TAG_OPTIONS).toContain('garage');
      expect(EVENT_TAG_OPTIONS).toContain('drum-and-bass');
      expect(EVENT_TAG_OPTIONS).toContain('bass');
    });

    test('should contain event type tags', () => {
      expect(EVENT_TAG_OPTIONS).toContain('live');
      expect(EVENT_TAG_OPTIONS).toContain('comedy');
      expect(EVENT_TAG_OPTIONS).toContain('wellness');
      expect(EVENT_TAG_OPTIONS).toContain('art');
      expect(EVENT_TAG_OPTIONS).toContain('burner');
    });

    test('should have 10 tag options', () => {
      expect(EVENT_TAG_OPTIONS).toHaveLength(10);
    });

    test('should contain only strings', () => {
      EVENT_TAG_OPTIONS.forEach(tag => {
        expect(typeof tag).toBe('string');
      });
    });

    test('should not have duplicate values', () => {
      const uniqueTags = new Set(EVENT_TAG_OPTIONS);
      expect(uniqueTags.size).toBe(EVENT_TAG_OPTIONS.length);
    });

    test('should use kebab-case for multi-word tags', () => {
      const multiWordTag = EVENT_TAG_OPTIONS.find(tag => tag === 'drum-and-bass');
      expect(multiWordTag).toBeDefined();
      expect(multiWordTag).not.toContain(' ');
    });
  });

  describe('SCANNER_ROLE', () => {
    test('should be a string', () => {
      expect(typeof SCANNER_ROLE).toBe('string');
    });

    test('should equal "scanner"', () => {
      expect(SCANNER_ROLE).toBe('scanner');
    });

    test('should be a constant (readonly)', () => {
      // TypeScript ensures this is readonly at compile time
      // At runtime, we can verify it's a primitive value
      expect(SCANNER_ROLE).toBe('scanner');
    });
  });

  describe('Options consistency', () => {
    test('status values should be camelCase', () => {
      EVENT_STATUS_OPTIONS.forEach(option => {
        // Check that values don't contain spaces or special chars except -
        expect(option.value).toMatch(/^[a-zA-Z]+$/);
      });
    });

    test('category values should be lowercase', () => {
      EVENT_CATEGORY_OPTIONS.forEach(option => {
        expect(option.value).toBe(option.value.toLowerCase());
      });
    });

    test('all tag options should be lowercase', () => {
      EVENT_TAG_OPTIONS.forEach(tag => {
        expect(tag).toBe(tag.toLowerCase());
      });
    });
  });

  describe('Type safety', () => {
    test('EVENT_STATUS_OPTIONS values should be unique types', () => {
      // This test ensures our types work correctly
      const statusValues: Array<typeof EVENT_STATUS_OPTIONS[number]['value']> = [
        'draft',
        'scheduled',
        'active',
        'soldOut',
        'completed',
        'cancelled'
      ];

      statusValues.forEach(value => {
        const found = EVENT_STATUS_OPTIONS.find(opt => opt.value === value);
        expect(found).toBeDefined();
      });
    });
  });
});
