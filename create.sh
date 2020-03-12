#!/usr/bin/env bash
set -euo pipefail
[ -z "${DEBUG:-}" ] || set -x

: Initialize package
npm init --yes

mkdir -p src
touch README.md
echo node_modules >.gitignore
git init || true

: Install development dependencies
npm install -D typescript \
    jest ts-jest @types/jest \
    husky lint-staged \
    commitizen cz-conventional-changelog \
    eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser \
    prettier eslint-config-prettier eslint-plugin-prettier \
    json

: Create tsconfig
cat <<EOF >tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "target": "es2016",
    "lib": ["es2016", "es2017", "es2018"],
    "module": "commonjs",
    "sourceMap": true,
    "outDir": "./lib",
    "rootDir": "./src",
    "esModuleInterop": true,
  },
  "exclude": [
    "node_modules",
    "**/*.test.ts"
  ]
}
EOF

: Create Jest config
# npx ts-jest config:init

: Create prettierrc
cat <<EOF >.prettierrc.json
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 120,
  "tabWidth": 2
}
EOF

: Create eslintrc
cat <<EOF >.eslintrc.js
module.exports = {
  env: {
    es6: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/eslint-recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier/@typescript-eslint',
    'plugin:prettier/recommended',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    'no-unused-vars': 'warn',
    'no-process-env': 'error',
    'no-process-exit': 'error',
  },
  overrides: [
    {
      files: ['bin/**/*.{ts,js}'],
      rules: {
        'no-process-env': 'off',
        'no-process-exit': 'off',
      },
    }
  ],
};
EOF

: Update package.json
npx json -I -f package.json \
    -e 'this.scripts.build="tsc"' \
    -e 'this.scripts.test="jest"' \
    -e 'this.husky={hooks:{}}' \
    -e 'this.husky.hooks["prepare-commit-msg"]="exec < /dev/tty && git cz --hook || true"' \
    -e 'this.husky.hooks["pre-commit"]="tsc --noEmit && lint-staged && npm run test"' \
    -e 'this["lint-staged"]={"src/**/*.{j,t}s{,x}":"eslint --fix"}' \
    -e 'this.config || (this.config = {})' \
    -e 'this.config.commitizen={path:"./node_modules/cz-conventional-changelog"}'

npm uninstall json