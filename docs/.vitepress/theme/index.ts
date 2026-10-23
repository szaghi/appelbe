// appelbe docs theme: the default VitePress theme with plasma colours and a figure frame.
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import './style.css'

export default {
  extends: DefaultTheme,
} satisfies Theme
