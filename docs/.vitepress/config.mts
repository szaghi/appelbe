import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

// one sidebar, in reading order, for the guide and the manual: prev/next links walk the whole documentation
const docs = [
  {
    text: 'Start here',
    items: [
      { text: 'About',              link: '/guide/' },
      { text: 'Installation',       link: '/guide/install' },
      { text: 'The physics',        link: '/guide/physics' },
    ],
  },
  {
    text: 'Tutorial',
    items: [
      { text: 'Overview',                        link: '/manual/' },
      { text: '1. Transport coefficients',       link: '/manual/tutorial/01-coefficients' },
      { text: '2. A drifting fast-ion population', link: '/manual/tutorial/02-fast-ions' },
      { text: '3. A magnetised plasma',          link: '/manual/tutorial/03-magnetised' },
      { text: '4. The heat flow',                link: '/manual/tutorial/04-heat-flow' },
      { text: '5. Magnetic fields',              link: '/manual/tutorial/05-magnetic-field' },
      { text: '6. Energy spectra',               link: '/manual/tutorial/06-spectra' },
      { text: '7. The paper, number by number',  link: '/manual/tutorial/07-paper' },
    ],
  },
  {
    text: 'Recipes',
    items: [
      { text: 'Cookbook', link: '/manual/cookbook' },
    ],
  },
  {
    text: 'Reference',
    items: [
      { text: 'Feature map',         link: '/guide/features' },
      { text: 'Kinetic solver',      link: '/guide/kinetic-solver' },
      { text: 'Algebraic closure',   link: '/guide/algebraic-closure' },
      { text: 'Transport terms',     link: '/guide/transport' },
      { text: 'Energy spectra',      link: '/guide/distributions' },
      { text: "The paper's set-up",  link: '/guide/paper-setup' },
      { text: 'Drivers and results', link: '/guide/drivers' },
      { text: 'Report pipeline',     link: '/guide/report' },
      { text: 'Architecture',        link: '/guide/architecture' },
    ],
  },
  {
    text: 'Results',
    items: [
      { text: 'Reproduction status', link: '/guide/validation' },
      { text: 'Findings and errata', link: '/guide/errata' },
    ],
  },
  {
    text: 'Project',
    items: [
      { text: 'API Reference', link: '/guide/api-reference' },
      { text: 'Contributing',  link: '/guide/contributing' },
      { text: 'Changelog',     link: '/guide/changelog' },
    ],
  },
]

export default withMermaid({
  title: 'appelbe',
  description: 'Electron transport modified by collisions with fast ions, in Fortran',
  base: '/appelbe/',
  // ford.md is the formal project file, examples/src the raw example sources: not pages
  srcExclude: ['ford.md', 'examples/**'],

  markdown: {
    math: true,
    languages: ['fortran-free-form', 'fortran-fixed-form'],
    languageAlias: {
      fortran: 'fortran-free-form',
      f90: 'fortran-free-form',
      F90: 'fortran-free-form',
      f03: 'fortran-free-form',
      f08: 'fortran-free-form',
      gp: 'gnuplot',
    },
  },

  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Start here', link: '/guide/', activeMatch: '^/guide/(index|install|physics)?$' },
      { text: 'Tutorial', link: '/manual/tutorial/01-coefficients', activeMatch: '^/manual/(index|tutorial/)' },
      { text: 'Cookbook', link: '/manual/cookbook', activeMatch: '^/manual/cookbook' },
      {
        text: 'Reference',
        link: '/guide/features',
        activeMatch: '^/guide/(features|kinetic-solver|algebraic-closure|transport|distributions|paper-setup|drivers|report|architecture)',
      },
      { text: 'Results', link: '/guide/validation', activeMatch: '^/guide/(validation|errata)' },
      { text: 'API', link: '/api/' },
      {
        text: 'Project',
        items: [
          { text: 'Contributing', link: '/guide/contributing' },
          { text: 'Changelog',    link: '/guide/changelog' },
          { text: 'Report (PDF)', link: 'https://github.com/szaghi/appelbe/blob/main/report/appelbe_report.pdf' },
        ],
      },
    ],

    sidebar: {
      '/guide/': docs,
      '/manual/': docs,
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
          ],
        },
        ...apiSidebar,
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/szaghi/appelbe' },
    ],

    search: {
      provider: 'local',
    },

    outline: [2, 3],

    footer: {
      message: 'Released under the <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPL v3 License</a>.',
      copyright: 'Copyright © 2026 Federico Negro, Luca Senni, Stefano Zaghi',
    },
  },

  mermaid: {},

  vite: {
    // explicit modern target: mermaid 11.16+ emits syntax esbuild refuses to lower to es2020
    build: {
      target: 'es2022',
    },
  },
})
