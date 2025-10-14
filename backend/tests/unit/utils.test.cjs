function gerarCodigo() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

describe('gerarCodigo', () => {
  test('should generate a 6-digit code', () => {
    const code = gerarCodigo();
    expect(code).toMatch(/^\d{6}$/);
  });

  test('should generate different codes on multiple calls', () => {
    const code1 = gerarCodigo();
    const code2 = gerarCodigo();
    expect(code1).not.toBe(code2);
  });
});