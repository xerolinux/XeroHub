import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const updates = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/updates' }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    date: z.coerce.date(),
    image: z.string().optional(),
    tags: z.array(z.string()).optional().default([]),
    draft: z.boolean().optional().default(false),
  }),
});

const pages = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/pages' }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    // about-specific
    birthdate: z.coerce.date().optional(),
    // download-specific
    alert: z.string().optional(),
    isoFeatures: z.array(z.string()).optional(),
    tuiFeatures: z.array(z.string()).optional(),
    // videos-specific
    youtubeHandle: z.string().optional(),
    // gear-specific
    info: z.array(z.string()).optional(),
    hardwareIntro: z.string().optional(),
    hardware: z.array(z.object({
      name: z.string(),
      subtitle: z.string(),
      image: z.string(),
      description: z.string(),
    })).optional(),
    otherSystems: z.object({
      image: z.string(),
      text: z.array(z.string()),
    }).optional(),
    thanks: z.string().optional(),
  }),
});

export const collections = { updates, pages };
