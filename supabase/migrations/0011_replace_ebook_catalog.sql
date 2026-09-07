-- Replace the placeholder e-book catalogue with ProAIcademy's 7 real, published
-- e-books. Prices and page counts come from the official price list; each row
-- points at the PDF uploaded to the private `ebook-files` bucket (eb1..eb7).
--
-- Ratings/downloads are intentionally 0 at launch (no fabricated social proof);
-- the storefront hides the star until a real rating is set. old_price is 0 — the
-- price list quotes a single price with no "was" figure.
--
-- Safe to run repeatedly: it upserts eb1..eb7 and removes any other e-book rows.
-- order_items / entitlements store their own title/price snapshots and have no FK
-- to ebooks, so replacing the catalogue does not affect order history.

delete from public.ebooks where id not in ('eb1','eb2','eb3','eb4','eb5','eb6','eb7');

insert into public.ebooks (id,cat,price,old_price,icon,grad,pages,rating,downloads,title,description,file_path,file_name,file_size_bytes,is_published,sort_order) values
('eb1','Foundations',79000,0,'📘','linear-gradient(135deg,#4f46e5,#2563eb)',34,0,0,
 '{"en":"AI Foundation Guide","id":"Panduan Fondasi AI"}',
 '{"en":"Your plain-English starting point for AI at work — what it is, how generative models work, and which assistant to use when (ChatGPT, Claude, Gemini, Copilot). Includes role-by-role playbooks, responsible-use guidance and a 30-day ramp-up plan. No coding required.","id":"Titik awal memahami AI untuk kerja dengan bahasa sederhana — apa itu AI, cara kerja model generatif, dan kapan memakai ChatGPT, Claude, Gemini, atau Copilot. Termasuk playbook per peran, panduan pakai yang bijak, dan rencana 30 hari. Tanpa perlu coding."}',
 'eb1/ai-foundation-guide.pdf','ProAIcademy-AI-Foundation-Guide.pdf',13008128,true,1),
('eb2','Foundations',75000,0,'📗','linear-gradient(135deg,#059669,#16a34a)',48,0,0,
 '{"en":"Getting Started with Claude AI","id":"Memulai dengan Claude AI"}',
 '{"en":"A friendly, no-nonsense beginner''s guide to Anthropic''s Claude. Learn what makes Claude different, how to set it up and prompt it well, and how to use its toolbox — Claude Code, Cowork, Connectors, Artifacts and Memory — to get real work done from day one.","id":"Panduan pemula yang ramah dan langsung ke inti tentang Claude dari Anthropic. Pahami keunggulan Claude, cara menyiapkan dan memberi prompt yang baik, serta memanfaatkan perangkatnya — Claude Code, Cowork, Connectors, Artifacts, dan Memory — untuk bekerja sejak hari pertama."}',
 'eb2/getting-started-with-claude-ai.pdf','ProAIcademy-Getting-Started-with-Claude-AI.pdf',2574007,true,2),
('eb3','Prompts',75000,0,'💬','linear-gradient(135deg,#7c3aed,#2563eb)',45,0,0,
 '{"en":"Mastering Prompt Engineering","id":"Menguasai Prompt Engineering"}',
 '{"en":"Write better prompts and get reliable, high-quality results from any AI assistant. Master the six-part anatomy of a strong prompt, core techniques like few-shot and chain-of-thought, and advanced patterns — with real worked case studies and a ready-to-use starter prompt library.","id":"Tulis prompt yang lebih baik dan dapatkan hasil yang andal dan berkualitas dari asisten AI mana pun. Kuasai enam komponen prompt yang kuat, teknik inti seperti few-shot dan chain-of-thought, serta pola lanjutan — dengan studi kasus nyata dan pustaka prompt siap pakai."}',
 'eb3/mastering-prompt-engineering.pdf','ProAIcademy-Mastering-Prompt-Engineering.pdf',1869757,true,3),
('eb4','Productivity',95000,0,'⚡','linear-gradient(135deg,#0891b2,#2563eb)',51,0,0,
 '{"en":"ChatGPT for Daily Productivity","id":"ChatGPT untuk Produktivitas Harian"}',
 '{"en":"A practical, self-paced course that turns ChatGPT into repeatable output. Eleven modules cover prompting, writing, summarizing, planning, working with data and building reusable workflows — backed by a full prompt library and a 30-day plan to save hours every week.","id":"Kursus praktis dan mandiri yang mengubah ChatGPT menjadi hasil kerja yang berulang. Sebelas modul mencakup prompting, menulis, meringkas, merencanakan, mengolah data, dan membangun alur kerja yang bisa dipakai ulang — plus pustaka prompt dan rencana 30 hari untuk menghemat waktu."}',
 'eb4/chatgpt-for-daily-productivity.pdf','ProAIcademy-ChatGPT-for-Daily-Productivity.pdf',2220523,true,4),
('eb5','Productivity',95000,0,'🧠','linear-gradient(135deg,#7c3aed,#db2777)',62,0,0,
 '{"en":"Claude AI for Daily Productivity","id":"Claude AI untuk Produktivitas Harian"}',
 '{"en":"A Claude-specific productivity course built around real work. Learn the C-G-C-O-R prompting framework and put Claude to work on planning, email, meetings, documents, research and decisions — then package your best prompts into Claude Projects. Includes a 120+ prompt library and 7- and 30-day challenges.","id":"Kursus produktivitas khusus Claude yang dibangun dari pekerjaan nyata. Pelajari kerangka prompting C-G-C-O-R dan gunakan Claude untuk perencanaan, email, rapat, dokumen, riset, dan keputusan — lalu kemas prompt terbaikmu ke Claude Projects. Termasuk 120+ prompt dan tantangan 7 & 30 hari."}',
 'eb5/claude-ai-for-daily-productivity.pdf','ProAIcademy-Claude-AI-for-Daily-Productivity.pdf',2782541,true,5),
('eb6','Tools',85000,0,'🧰','linear-gradient(135deg,#059669,#0891b2)',45,0,0,
 '{"en":"100 AI Tools for Business and Professional Workers","id":"100 Tool AI untuk Bisnis & Profesional"}',
 '{"en":"A curated reference to 100 top AI tools across 10 business categories — automation, writing, meetings, sales, design, project management, video, research, HR and scheduling. Each profile covers what the tool does, its best use case, who it''s for and its pricing, with a direct link to explore.","id":"Referensi terkurasi berisi 100 tool AI terbaik dalam 10 kategori bisnis — otomatisasi, penulisan, rapat, sales, desain, manajemen proyek, video, riset, HR, dan penjadwalan. Tiap profil menjelaskan fungsi, use case terbaik, target pengguna, dan harga, lengkap dengan tautan langsung."}',
 'eb6/100-ai-tools-for-business.pdf','ProAIcademy-100-AI-Tools-for-Business-and-Professional-Workers.pdf',2348653,true,6),
('eb7','Career',75000,0,'🗺️','linear-gradient(135deg,#ea580c,#db2777)',41,0,0,
 '{"en":"AI Career Roadmap 2026","id":"Roadmap Karier AI 2026"}',
 '{"en":"A no-nonsense transition plan for professionals moving into AI-driven roles. Audit your transferable strengths, build AI fluency without a CS degree, and follow three concrete tracks — Industrial, Financial & Quantitative, or the Academic Bridge — with a quarter-by-quarter 12-month execution plan.","id":"Rencana transisi yang lugas bagi profesional yang beralih ke peran berbasis AI. Audit kekuatan yang bisa dialihkan, bangun kefasihan AI tanpa gelar ilmu komputer, dan ikuti tiga jalur konkret — Industri, Keuangan & Kuantitatif, atau Jembatan Akademik — dengan rencana eksekusi 12 bulan."}',
 'eb7/ai-career-roadmap-2026.pdf','ProAIcademy-AI-Career-Roadmap-2026.pdf',2345693,true,7)
on conflict (id) do update set
  cat=excluded.cat, price=excluded.price, old_price=excluded.old_price, icon=excluded.icon, grad=excluded.grad,
  pages=excluded.pages, rating=excluded.rating, downloads=excluded.downloads, title=excluded.title,
  description=excluded.description, file_path=excluded.file_path, file_name=excluded.file_name,
  file_size_bytes=excluded.file_size_bytes, is_published=excluded.is_published, sort_order=excluded.sort_order;
