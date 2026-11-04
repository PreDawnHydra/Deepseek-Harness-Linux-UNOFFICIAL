#!/usr/bin/env node
// Print the highest semver among dsh-v<version> tags listed one per line in the given file.
import { readFileSync } from 'node:fs'

const SEMVER = /^dsh-v(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/u

function compareIdentifiers(a, b) {
  const an = /^\d+$/u.test(a), bn = /^\d+$/u.test(b)
  if (an && bn) return Number(a) - Number(b)
  if (an !== bn) return an ? -1 : 1
  return a < b ? -1 : a > b ? 1 : 0
}

export function compareTags(a, b) {
  const [, ...x] = SEMVER.exec(a), [, ...y] = SEMVER.exec(b)
  for (let i = 0; i < 3; i++) if (Number(x[i]) !== Number(y[i])) return Number(x[i]) - Number(y[i])
  if (x[3] === undefined || y[3] === undefined) return (x[3] === undefined ? 1 : 0) - (y[3] === undefined ? 1 : 0)
  const p = x[3].split('.'), q = y[3].split('.')
  for (let i = 0; i < Math.max(p.length, q.length); i++) {
    if (p[i] === undefined) return -1
    if (q[i] === undefined) return 1
    const c = compareIdentifiers(p[i], q[i])
    if (c !== 0) return c
  }
  return 0
}

if (import.meta.main ?? process.argv[1] === new URL(import.meta.url).pathname) {
  const tags = readFileSync(process.argv[2], 'utf8').split('\n').map(t => t.trim()).filter(t => SEMVER.test(t))
  if (tags.length === 0) { console.error('no dsh-v* release tags found'); process.exit(1) }
  console.log(tags.sort(compareTags).at(-1))
}
