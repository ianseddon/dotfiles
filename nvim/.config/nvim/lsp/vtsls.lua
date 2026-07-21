return {
  cmd = { 'vtsls', '--stdio' },
  filetypes = {
    'javascript', 'javascriptreact',
    'typescript', 'typescriptreact',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  settings = {
    vtsls = {
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
          entriesLimit = 75,
        },
      },
    },
  },
}
