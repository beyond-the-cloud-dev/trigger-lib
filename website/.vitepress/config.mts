import { defineConfig } from 'vitepress';
import llmstxt from 'vitepress-plugin-llms';
import { addOverviewLeaves, nav, sidebar } from './apex-api.mjs';
import { check, formatReport } from './scripts/check-docs.mjs';
import { generate } from './scripts/generate.mjs';

// https://vitepress.dev/reference/site-config

const siteUrl = 'https://trigger.beyondthecloud.dev';
const siteTitle = 'Trigger Lib';
const siteDescription =
  'Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control';

generate();

export default defineConfig({
  lang: 'en-US',
  title: siteTitle,
  description: siteDescription,
  cleanUrls: true,
  srcExclude: ['**/_parts/**'],
  markdown: {
    languageAlias: { cls: 'apex', trigger: 'apex' }
  },
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'author', content: 'Beyond The Cloud' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: siteTitle }],
    ['meta', { property: 'og:image', content: `${siteUrl}/logo.png` }],
    ['meta', { name: 'twitter:card', content: 'summary' }],
    [
      'script',
      { type: 'application/ld+json' },
      JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'SoftwareApplication',
        name: siteTitle,
        description: siteDescription,
        url: siteUrl,
        applicationCategory: 'DeveloperApplication',
        operatingSystem: 'Salesforce',
        license: 'https://opensource.org/licenses/MIT',
        codeRepository: 'https://github.com/beyond-the-cloud-dev/trigger-lib',
        isPartOf: {
          '@type': 'SoftwareApplication',
          name: 'Apex Fluently',
          url: 'https://apexfluently.beyondthecloud.dev'
        },
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
        author: {
          '@type': 'Organization',
          name: 'Beyond The Cloud',
          url: 'https://beyondthecloud.dev',
          sameAs: [
            'https://github.com/beyond-the-cloud-dev',
            'https://www.linkedin.com/company/beyondtheclouddev'
          ]
        }
      })
    ]
    // TODO: Configure Google Tag Manager
    // [
    //   'script',
    //   { async: '', src: 'https://www.googletagmanager.com/gtag/js?id=YOUR-GTM-ID' }
    // ],
    // [
    //   'script',
    //   {},
    //   `window.dataLayer = window.dataLayer || [];
    //   function gtag(){dataLayer.push(arguments);}
    //   gtag('js', new Date());
    //   gtag('config', 'YOUR-GTM-ID');`
    // ]
  ],
  sitemap: {
    hostname: siteUrl
  },
  vite: {
    plugins: [
      llmstxt({
        domain: siteUrl,
        sidebar: configSidebar => addOverviewLeaves(configSidebar)
      })
    ]
  },
  buildEnd(siteConfig) {
    const result = check({
      websiteDir: siteConfig.srcDir,
      sidebar: siteConfig.site.themeConfig.sidebar,
      nav: siteConfig.site.themeConfig.nav
    });
    if (result.errors.length === 0) {
      console.log('check-docs: passed');
      return;
    }
    console.error(formatReport(result));
    if (process.env.CHECK_DOCS === 'warn') return;
    throw new Error(
      `check-docs found ${result.errors.length} problem(s), listed above; run node website/.vitepress/scripts/check-docs.mjs to reproduce`
    );
  },
  transformPageData(pageData) {
    const canonicalUrl = `${siteUrl}/${pageData.relativePath}`
      .replace(/index\.md$/, '')
      .replace(/\.md$/, '')
      .replace(/\/$/, '');
    pageData.frontmatter.head ??= [];
    pageData.frontmatter.head.push(
      ['link', { rel: 'canonical', href: canonicalUrl || siteUrl }],
      ['meta', { property: 'og:url', content: canonicalUrl || siteUrl }]
    );
    const pageTitle = pageData.frontmatter.title || pageData.title;
    pageData.frontmatter.head.push(
      [
        'meta',
        {
          property: 'og:title',
          content:
            pageTitle && pageTitle !== siteTitle
              ? `${pageTitle} | ${siteTitle}`
              : siteTitle
        }
      ],
      [
        'meta',
        {
          property: 'og:description',
          content:
            pageData.frontmatter.description ||
            pageData.description ||
            siteDescription
        }
      ]
    );
  },
  themeConfig: {
    logo: '/logo.png',
    outline: [2, 3],
    search: {
      provider: 'local',
      options: {
        miniSearch: {
          options: {
            tokenize: (text: string) =>
              text
                .split(/[^A-Za-z0-9_]+/)
                .filter(Boolean)
                .flatMap(word => {
                  const parts = word.split(/(?<=[a-z0-9])(?=[A-Z])/);
                  return parts.length > 1 ? [word, ...parts] : [word];
                })
          }
        }
      }
    },
    // https://vitepress.dev/reference/default-theme-config
    nav,
    sidebar,
    socialLinks: [
      {
        icon: 'github',
        link: 'https://github.com/beyond-the-cloud-dev/trigger-lib'
      },
      {
        icon: 'linkedin',
        link: 'https://www.linkedin.com/company/beyondtheclouddev'
      }
    ]
  }
});
