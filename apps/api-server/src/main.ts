import Fastify from 'fastify';
import cors from '@fastify/cors';
import { evaluateGate2, scoreGAD7, scorePHQ9, scoreSCOFF } from '@therapy-sculpt/clinical-core';
import { assertClinicalDataAccess, screeningSubmissionSchema } from '@therapy-sculpt/contracts';

const app = Fastify({ logger: true });
await app.register(cors, { origin: false });
app.get('/health', async () => ({ status: 'ok', region: process.env.UAE_REGION ?? 'uaenorth', service: 'api-server' }));
app.addHook('preHandler', async (request, reply) => { const role = String(request.headers['x-role'] ?? 'PATIENT') as Parameters<typeof assertClinicalDataAccess>[0]; try { assertClinicalDataAccess(role); } catch { return reply.code(403).send({ error: 'Clinical data access denied for employer, HR, or insurer roles.' }); } });
app.post('/screenings', async (request, reply) => { const parsed = screeningSubmissionSchema.safeParse(request.body); if (!parsed.success) return reply.code(400).send({ error: 'Invalid screening submission', details: parsed.error.flatten() }); const data = parsed.data; const phq9 = scorePHQ9(data.phq9); const gad7 = scoreGAD7(data.gad7); const scoff = scoreSCOFF(data.scoff); const gate = evaluateGate2({ phq9Question9: data.phq9[8], freeText: data.freeText }); if (gate.criticalFlag) return reply.code(200).send({ gate, phq9, gad7, scoff, aiAllowed: false, dispatch: { queue: 'worker-crisis-dispatch', slaMinutes: 15 } }); return { gate, phq9, gad7, scoff, aiAllowed: true }; });
app.listen({ port: Number(process.env.PORT ?? 4000), host: '0.0.0.0' }).catch((error) => { app.log.error(error); process.exit(1); });