const jwt = require('jsonwebtoken');
const auth = require('../../middleware/auth.cjs');

describe('Auth Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = { header: jest.fn() };
    res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    next = jest.fn();
  });

  test('should return 401 if token is missing', () => {
    req.header.mockReturnValue(null);
    auth()(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ msg: 'Acesso negado. Token ausente.' });
  });

  test('should return 400 if token is invalid', () => {
    req.header.mockReturnValue('Bearer invalidtoken');
    jwt.verify = jest.fn().mockImplementation(() => { throw new Error('Invalid token'); });
    auth()(req, res, next);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ msg: 'Token inválido' });
  });

  test('should call next if token is valid and role is not specified', () => {
    const decoded = { id: '123', role: 'aluno' };
    req.header.mockReturnValue('Bearer validtoken');
    jwt.verify = jest.fn().mockReturnValue(decoded);
    auth()(req, res, next);
    expect(req.user).toEqual(decoded);
    expect(next).toHaveBeenCalled();
  });

  test('should return 403 if role does not match', () => {
    const decoded = { id: '123', role: 'aluno' };
    req.header.mockReturnValue('Bearer validtoken');
    jwt.verify = jest.fn().mockReturnValue(decoded);
    auth('professor')(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({ msg: 'Acesso negado. Permissão insuficiente.' });
  });
});