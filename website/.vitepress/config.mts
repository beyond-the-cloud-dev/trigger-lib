import { defineConfig } from 'vitepress';
import llmstxt from 'vitepress-plugin-llms';

// https://vitepress.dev/reference/site-config

const siteUrl = 'https://trigger.beyondthecloud.dev';
const siteTitle = 'Trigger Lib';
const siteDescription =
  'Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control';

export default defineConfig({
  lang: 'en-US',
  title: siteTitle,
  description: siteDescription,
  cleanUrls: true,
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
    plugins: [llmstxt({ domain: siteUrl })]
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
    search: {
      provider: 'local'
    },
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Docs', link: '/introduction' }
    ],

    sidebar: [
      {
        text: 'Introduction',
        collapsed: false,
        items: [
          { text: 'Introduction', link: '/introduction' },
          { text: 'Installation', link: '/installation' },
          {
            text: 'Design Principles',
            link: '/introduction/design-principles'
          }
        ]
      },
      {
        text: 'Guide',
        collapsed: false,
        items: [
          { text: 'Orchestrator', link: '/guide/orchestrator' },
          { text: 'Handlers', link: '/guide/handlers' },
          { text: 'Record Qualification', link: '/guide/qualification' },
          { text: 'Parent Enrichment', link: '/guide/enrichment' },
          { text: 'Bypasses', link: '/guide/bypasses' },
          { text: 'Recursion Control', link: '/guide/recursion-control' },
          { text: 'Finalizers', link: '/guide/finalizers' },
          { text: 'Error Handling', link: '/guide/error-handling' }
        ]
      },
      {
        text: 'API',
        collapsed: false,
        items: [
          { text: 'TriggerOrchestrator', link: '/api/trigger-orchestrator' },
          { text: 'Context Interfaces', link: '/api/context-interfaces' },
          { text: 'Record Interfaces', link: '/api/record' },
          {
            text: 'TriggerHandler.ParentFields',
            link: '/api/field-selection'
          }
        ]
      }
    ],
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
