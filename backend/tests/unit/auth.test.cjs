const jwt = require('jsonwebtoken');
const auth = require('../../middleware/auth.cjs');

// Mock do process.env
process.env.JWT_SECRET = 'test-secret-key';

describe('Auth Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      header: jest.fn(),
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    next = jest.fn();

    // Mock do console para evitar poluição
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('should return 401 if token is missing', () => {
    req.header.mockReturnValue(null);

    auth()(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      msg: 'Acesso negado. Token ausente.'
    });
  });

  test('should return 401 if token is invalid', () => {
    req.header.mockReturnValue('Bearer invalidtoken');

    auth()(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      msg: 'Token inválido'
    });
  });

  test('should call next if token is valid and role is not specified', () => {
    const decoded = { id: '123', role: 'aluno' };
    req.header.mockReturnValue('Bearer validtoken');
    
    // Mock jwt.verify para retornar decoded
    jest.spyOn(jwt, 'verify').mockReturnValue(decoded);

    auth()(req, res, next);

    expect(req.user).toEqual(decoded);
    expect(next).toHaveBeenCalled();
    expect(jwt.verify).toHaveBeenCalledWith('validtoken', process.env.JWT_SECRET);
  });

  test('should return 403 if role does not match', () => {
    const decoded = { id: '123', role: 'aluno' };
    req.header.mockReturnValue('Bearer validtoken');
    
    jest.spyOn(jwt, 'verify').mockReturnValue(decoded);

    auth(['professor'])(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({
      msg: 'Acesso negado. Permissão insuficiente.',
      required: ['professor'],
      userRole: 'aluno'
    });
  });

  test('should allow access if role matches', () => {
    const decoded = { id: '123', role: 'professor' };
    req.header.mockReturnValue('Bearer validtoken');
    
    jest.spyOn(jwt, 'verify').mockReturnValue(decoded);

    auth(['professor', 'admin'])(req, res, next);

    expect(req.user).toEqual(decoded);
    expect(next).toHaveBeenCalled();
  });
});