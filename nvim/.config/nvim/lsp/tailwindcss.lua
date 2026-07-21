return {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  filetypes = {
    'html', 'css', 'javascript', 'javascriptreact',
    'typescript', 'typescriptreact', 'svelte',
  },
  root_markers = { 'tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.mjs', '.git' },
}
