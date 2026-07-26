-- 0007_replace_course_catalog.sql
--
-- Replaces the original seeded demo catalogue (c1..c8: "AI Foundations", "Machine
-- Learning Essentials", ...) with the real ProAIcademy course line-up.
--
-- Safe to run: at the time of writing no order_items or entitlements referenced any
-- course, so deleting the old rows orphans nothing. The delete is scoped to the
-- courses table only.
--
-- Deliberately NOT invented here: rating, reviews, students, lessons, hours and old_price
-- are 0 on every row. These are claims shown to real paying customers, so they stay empty
-- until there are genuine numbers to put in them. The storefront hides each badge while its
-- value is 0 — the ★ rating, the learner count, the "N lessons" / "Nh" line on the course
-- detail page, and the per-module lesson counts in the curriculum outline. Fill any of them
-- in and the corresponding badge reappears with no code change.

begin;

delete from public.courses;

insert into public.courses
  (id, cat, level, lessons, hours, rating, reviews, students, price, old_price,
   icon, grad, instructor, tag_key, title, description, sort_order, is_published)
values
  ('c1', 'Prompt Engineering', 'Beginner', 0, 0, 0, 0, 0, 150000, 0,
   '✍️', 'linear-gradient(135deg,#2563eb,#06b6d4)', 'ProAIcademy', '',
   '{"en":"Prompt Engineering","id":"Prompt Engineering"}',
   '{"en":"Write prompts that get reliable, high-quality results instead of guesswork.","id":"Tulis prompt yang menghasilkan output andal dan berkualitas, bukan tebak-tebakan."}',
   1, true),

  ('c2', 'Claude Fundamentals', 'Beginner', 0, 0, 0, 0, 0, 250000, 0,
   '👋', 'linear-gradient(135deg,#7c3aed,#4f46e5)', 'ProAIcademy', '',
   '{"en":"Claude Introduction","id":"Pengenalan Claude"}',
   '{"en":"Get to know Claude from the ground up — what it does well, and how to start using it today.","id":"Kenali Claude dari nol — apa keunggulannya dan bagaimana mulai memakainya hari ini."}',
   2, true),

  ('c3', 'Claude Fundamentals', 'Beginner', 0, 0, 0, 0, 0, 200000, 0,
   '🌱', 'linear-gradient(135deg,#059669,#0891b2)', 'ProAIcademy', '',
   '{"en":"Learn Claude - Beginner","id":"Belajar Claude - Pemula"}',
   '{"en":"Your first hands-on steps with Claude: conversations, context and everyday tasks.","id":"Langkah praktis pertamamu dengan Claude: percakapan, konteks, dan tugas sehari-hari."}',
   3, true),

  ('c4', 'Claude Fundamentals', 'Intermediate', 0, 0, 0, 0, 0, 300000, 0,
   '🚀', 'linear-gradient(135deg,#0891b2,#2563eb)', 'ProAIcademy', '',
   '{"en":"Learn Claude - Intermediate","id":"Belajar Claude - Menengah"}',
   '{"en":"Go deeper with projects, long documents and repeatable workflows that save real hours.","id":"Selami proyek, dokumen panjang, dan alur kerja berulang yang benar-benar menghemat waktu."}',
   4, true),

  ('c5', 'Claude Fundamentals', 'Advanced', 0, 0, 0, 0, 0, 400000, 0,
   '🧠', 'linear-gradient(135deg,#ea580c,#db2777)', 'ProAIcademy', '',
   '{"en":"Learn Claude - Advanced","id":"Belajar Claude - Mahir"}',
   '{"en":"Advanced techniques: tools, structured output and multi-step work you can trust.","id":"Teknik lanjutan: tools, output terstruktur, dan pekerjaan multi-langkah yang bisa diandalkan."}',
   5, true),

  ('c6', 'AI for Business', 'Intermediate', 0, 0, 0, 0, 0, 350000, 0,
   '📈', 'linear-gradient(135deg,#4f46e5,#2563eb)', 'ProAIcademy', '',
   '{"en":"Claude for Business Leader","id":"Claude untuk Pemimpin Bisnis"}',
   '{"en":"Spot high-ROI use cases, build an adoption plan and lead AI rollout across your team.","id":"Temukan use case ber-ROI tinggi, susun rencana adopsi, dan pimpin penerapan AI di timmu."}',
   6, true),

  ('c7', 'AI for Business', 'Intermediate', 0, 0, 0, 0, 0, 350000, 0,
   '💼', 'linear-gradient(135deg,#7c3aed,#db2777)', 'ProAIcademy', 'rec',
   '{"en":"Claude for Professional","id":"Claude untuk Profesional"}',
   '{"en":"Put Claude to work on the things your job actually demands — research, writing, analysis and reporting.","id":"Manfaatkan Claude untuk kebutuhan pekerjaanmu — riset, menulis, analisis, dan pelaporan."}',
   7, true),

  ('c8', 'Build with Claude', 'Advanced', 0, 0, 0, 0, 0, 500000, 0,
   '🛠️', 'linear-gradient(135deg,#7c3aed,#2563eb)', 'ProAIcademy', '',
   '{"en":"Build Professional Website using Claude Code","id":"Bangun Website Profesional dengan Claude Code"}',
   '{"en":"Design, build and ship a real professional website end to end using Claude Code.","id":"Rancang, bangun, dan luncurkan website profesional sungguhan dari awal sampai selesai dengan Claude Code."}',
   8, true),

  ('c9', 'Build with Claude', 'Beginner', 0, 0, 0, 0, 0, 250000, 0,
   '🎨', 'linear-gradient(135deg,#db2777,#7c3aed)', 'ProAIcademy', '',
   '{"en":"Build Professional Portfolio using Claude","id":"Bangun Portofolio Profesional dengan Claude"}',
   '{"en":"Turn your work into a portfolio that gets you hired — written, structured and polished with Claude.","id":"Ubah karyamu menjadi portofolio yang menarik perekrut — ditulis, disusun, dan dipoles bersama Claude."}',
   9, true);

commit;
