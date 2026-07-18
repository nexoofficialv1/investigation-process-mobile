import { Router } from 'express';
import { requireAuth } from '../middleware/auth.mjs';
import { query } from '../db/pool.mjs';

const router = Router();
router.use(requireAuth);

async function callOpenAI({ task, input, language = 'en-IN' }) {
  if (!process.env.OPENAI_API_KEY || process.env.AI_PROVIDER === 'disabled') {
    return {
      provider: 'disabled',
      draft: '',
      note: 'AI provider is disabled. Configure OPENAI_API_KEY and AI_PROVIDER=openai in server .env.'
    };
  }

  const prompt = `You are INVESTIGO, a police investigation drafting assistant. Task: ${task}. Language: ${language}. Always produce a DRAFT only. User/IO must verify before official use.\n\nInput:\n${input}`;
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'Draft official police investigation text. Do not invent facts. Mention uncertainty clearly.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.2
    })
  });
  if (!response.ok) throw new Error(`OpenAI error ${response.status}: ${await response.text()}`);
  const data = await response.json();
  return { provider: 'openai', draft: data.choices?.[0]?.message?.content || '', usage: data.usage || null };
}

router.post('/draft', async (req, res) => {
  const { task = 'draft', input = '', language = 'en-IN', entity_type = null, entity_local_id = null } = req.body || {};
  if (!input) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'input required' });
  const result = await callOpenAI({ task, input, language });
  await query(
    `insert into ai_usage_logs (officer_id, task, entity_type, entity_local_id, provider, request_chars, response_chars)
     values ($1,$2,$3,$4,$5,$6,$7)`,
    [req.user.officer_id, task, entity_type, entity_local_id, result.provider, input.length, (result.draft || '').length]
  );
  res.json({ ...result, warning: 'AI output is draft only. IO review/edit/approval is mandatory before use.' });
});

export default router;
