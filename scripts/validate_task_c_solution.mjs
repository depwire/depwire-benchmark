import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'

const [monorepoRoot, groundTruthFile] = process.argv.slice(2)
if (!monorepoRoot || !groundTruthFile) {
  console.error('usage: validate_task_c_solution.mjs MONOREPO_ROOT GROUND_TRUTH_FILE')
  process.exit(2)
}

const requireFromRepo = createRequire(path.join(monorepoRoot, 'package.json'))
const ts = requireFromRepo('typescript')
const requiredFiles = fs
  .readFileSync(groundTruthFile, 'utf8')
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter((line) => line && !line.startsWith('#'))

const codePattern = /^[A-Z][A-Z0-9_]*$/
const valid = []
const invalid = []

function isStringType(node) {
  return Boolean(node?.type && node.type.kind === ts.SyntaxKind.StringKeyword)
}

function isErrorCodeLiteral(node) {
  return Boolean(ts.isStringLiteralLike(node) && codePattern.test(node.text))
}

function validateCore(sourceFile) {
  let propertyIsReadonly = false
  let constructorIsValid = false
  let apiErrorStoresCode = false
  let apiErrorPassesCodeToBase = false
  let baseStoresCode = false

  function visit(node) {
    if (
      ts.isClassDeclaration(node) &&
      (node.name?.text === 'APIError' || node.name?.text === 'ExtendableError')
    ) {
      for (const member of node.members) {
        if (
          ts.isPropertyDeclaration(member) &&
          member.name?.getText(sourceFile) === 'errorCode' &&
          member.modifiers?.some((modifier) => modifier.kind === ts.SyntaxKind.ReadonlyKeyword)
        ) {
          propertyIsReadonly = true
        }
        if (ts.isConstructorDeclaration(member)) {
          const first = member.parameters[0]
          const hasErrorCodeFirst =
            first?.name.getText(sourceFile) === 'errorCode' && isStringType(first)

          if (node.name.text === 'APIError' && hasErrorCodeFirst) {
            constructorIsValid = true
            if (first.modifiers?.some((modifier) => modifier.kind === ts.SyntaxKind.ReadonlyKeyword)) {
              propertyIsReadonly = true
              apiErrorStoresCode = true
            }
            member.body?.statements.forEach((statement) => {
              if (
                ts.isExpressionStatement(statement) &&
                ts.isBinaryExpression(statement.expression) &&
                statement.expression.left.getText(sourceFile) === 'this.errorCode' &&
                statement.expression.right.getText(sourceFile) === 'errorCode'
              ) {
                apiErrorStoresCode = true
              }
              if (
                ts.isExpressionStatement(statement) &&
                ts.isCallExpression(statement.expression) &&
                statement.expression.expression.kind === ts.SyntaxKind.SuperKeyword &&
                statement.expression.arguments[0]?.getText(sourceFile) === 'errorCode'
              ) {
                apiErrorPassesCodeToBase = true
              }
            })
          }

          if (node.name.text === 'ExtendableError' && hasErrorCodeFirst) {
            member.body?.statements.forEach((statement) => {
              if (
                ts.isExpressionStatement(statement) &&
                ts.isBinaryExpression(statement.expression) &&
                statement.expression.left.getText(sourceFile) === 'this.errorCode' &&
                statement.expression.right.getText(sourceFile) === 'errorCode'
              ) {
                baseStoresCode = true
              }
            })
          }
        }
      }
    }
    ts.forEachChild(node, visit)
  }

  visit(sourceFile)
  return (
    propertyIsReadonly &&
    constructorIsValid &&
    (apiErrorStoresCode || (apiErrorPassesCodeToBase && baseStoresCode))
  )
}

function validateConsumers(sourceFile) {
  let relevantCalls = 0
  let invalidCalls = 0

  function visit(node, insideApiErrorSubclass = false) {
    let nextInsideApiErrorSubclass = insideApiErrorSubclass
    if (ts.isClassDeclaration(node)) {
      nextInsideApiErrorSubclass = Boolean(
        node.heritageClauses?.some((clause) =>
          clause.token === ts.SyntaxKind.ExtendsKeyword &&
          clause.types.some((type) => type.expression.getText(sourceFile) === 'APIError'),
        ),
      )
    }

    if (ts.isNewExpression(node) && node.expression.getText(sourceFile) === 'APIError') {
      relevantCalls += 1
      if (!isErrorCodeLiteral(node.arguments?.[0])) invalidCalls += 1
    }

    if (
      nextInsideApiErrorSubclass &&
      ts.isCallExpression(node) &&
      node.expression.kind === ts.SyntaxKind.SuperKeyword
    ) {
      relevantCalls += 1
      if (!isErrorCodeLiteral(node.arguments[0])) invalidCalls += 1
    }
    ts.forEachChild(node, (child) => visit(child, nextInsideApiErrorSubclass))
  }

  visit(sourceFile)
  return relevantCalls > 0 && invalidCalls === 0
}

for (const relativeFile of requiredFiles) {
  const absoluteFile = path.join(monorepoRoot, relativeFile)
  if (!fs.existsSync(absoluteFile)) {
    invalid.push({ file: relativeFile, reason: 'missing file' })
    continue
  }

  const text = fs.readFileSync(absoluteFile, 'utf8')
  const sourceFile = ts.createSourceFile(
    absoluteFile,
    text,
    ts.ScriptTarget.Latest,
    true,
    absoluteFile.endsWith('.tsx') ? ts.ScriptKind.TSX : ts.ScriptKind.TS,
  )
  const ok = relativeFile === 'packages/payload/src/errors/APIError.ts'
    ? validateCore(sourceFile)
    : validateConsumers(sourceFile)

  if (ok) valid.push(relativeFile)
  else invalid.push({ file: relativeFile, reason: 'constructor contract not fully updated' })
}

process.stdout.write(`${JSON.stringify({ valid, invalid })}\n`)
