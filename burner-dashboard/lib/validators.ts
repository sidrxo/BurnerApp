import { z } from "zod";

export const eventFormSchema = z
  .object({
    name: z.string().min(2, "Event name is required"),
    venueName: z.string().min(2, "Venue is required"),
    venueId: z
      .string()
      .optional()
      .transform((value) => (value && value.trim().length > 0 ? value : null)),
    price: z.coerce.number().min(0),
    maxTickets: z.coerce.number().int().min(0),
    startTime: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null)),
    endTime: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null)),
    imageUrl: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null))
      .refine(
        (value) => !value || /^https?:\/\//.test(value),
        "Image URL must be valid"
      ),
    description: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null)),
    status: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : "active")),
    category: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null)),
    isFeatured: z.boolean().default(false),
    tagId: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null)),
    tagName: z
      .string()
      .optional()
      .transform((value) => (value && value.length > 0 ? value : null))
  })
  .superRefine((data, ctx) => {
    if (data.startTime && data.endTime) {
      const start = new Date(data.startTime);
      const end = new Date(data.endTime);

      if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["startTime"],
          message: "Invalid date value"
        });
        return;
      }

      if (end <= start) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["endTime"],
          message: "End time must be after start time"
        });
      }
    }
  });

export const tagFormSchema = z.object({
  name: z.string().min(2, "Tag name is required"),
  color: z
    .string()
    .optional()
    .transform((value) => (value && value.length > 0 ? value : null)),
  description: z
    .string()
    .optional()
    .transform((value) => (value && value.length > 0 ? value : null))
});

export const scannerFormSchema = z.object({
  displayName: z.string().min(2, "Scanner name is required"),
  email: z.string().email("Valid email is required"),
  venueId: z
    .string()
    .optional()
    .transform((value) => (value && value.length > 0 ? value : null)),
  venueName: z
    .string()
    .optional()
    .transform((value) => (value && value.length > 0 ? value : null)),
  notes: z
    .string()
    .optional()
    .transform((value) => (value && value.length > 0 ? value : null)),
  active: z.boolean().default(true)
});

export type EventFormValues = z.infer<typeof eventFormSchema>;
export type TagFormValues = z.infer<typeof tagFormSchema>;
export type ScannerFormValues = z.infer<typeof scannerFormSchema>;
