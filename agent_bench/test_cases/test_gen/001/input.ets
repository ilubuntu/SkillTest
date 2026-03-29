// 测试生成任务
// 请为以下代码生成单元测试用例

export function add(a: number, b: number): number {
  return a + b
}

export function subtract(a: number, b: number): number {
  return a - b
}

export function multiply(a: number, b: number): number {
  return a * b
}

export function divide(a: number, b: number): number {
  if (b === 0) {
    throw new Error('除数不能为0')
  }
  return a / b
}

export function isEven(n: number): boolean {
  return n % 2 === 0
}
