-- ProAIcademy seed data (idempotent upserts).
-- Mirrors the bundled fallback content shipped in app.html.

-- ===== COURSES =====
insert into public.courses (id,cat,level,lessons,hours,rating,reviews,students,price,old_price,icon,grad,instructor,tag_key,title,description,sort_order) values
('c1','Foundations','Beginner',24,6.5,4.9,842,3200,299000,499000,'🧠','linear-gradient(135deg,#7c3aed,#4f46e5)','Dr. Rina Pratama','best',
 '{"en":"AI Foundations: Zero to Confident","id":"Dasar AI: Dari Nol ke Mahir"}',
 '{"en":"Understand how modern AI works and start using it with confidence — no coding required.","id":"Pahami cara kerja AI modern dan mulai gunakan dengan percaya diri — tanpa coding."}',1),
('c2','Prompt Engineering','Intermediate',32,8,4.9,1204,5400,449000,649000,'✍️','linear-gradient(135deg,#2563eb,#06b6d4)','Andi Wijaya','hot',
 '{"en":"Prompt Engineering Mastery","id":"Mahir Prompt Engineering"}',
 '{"en":"Write prompts that get reliable, high-quality results from ChatGPT, Claude & Gemini.","id":"Tulis prompt yang menghasilkan output andal & berkualitas dari ChatGPT, Claude & Gemini."}',2),
('c3','Generative AI','Beginner',20,5,4.8,530,2700,349000,499000,'🎨','linear-gradient(135deg,#db2777,#7c3aed)','Sarah Lin','new',
 '{"en":"Generative AI for Content Creators","id":"AI Generatif untuk Kreator Konten"}',
 '{"en":"Create images, video scripts and social content 10x faster with generative tools.","id":"Buat gambar, naskah video & konten sosial 10x lebih cepat dengan tools generatif."}',3),
('c4','AI Automation','Intermediate',28,7.5,4.9,690,1980,549000,799000,'⚡','linear-gradient(135deg,#059669,#0891b2)','Budi Santoso','hot',
 '{"en":"AI Automation with No-Code","id":"Otomatisasi AI Tanpa Coding"}',
 '{"en":"Connect AI to your tools and automate real workflows with Make, n8n & Zapier.","id":"Hubungkan AI ke tools-mu dan otomatiskan alur kerja nyata dengan Make, n8n & Zapier."}',4),
('c5','AI for Business','Beginner',18,4.5,4.8,410,2300,599000,899000,'📈','linear-gradient(135deg,#4f46e5,#2563eb)','Dr. Rina Pratama','best',
 '{"en":"AI for Business Leaders","id":"AI untuk Pemimpin Bisnis"}',
 '{"en":"Build an AI roadmap, spot high-ROI use cases and lead adoption in your team.","id":"Susun roadmap AI, temukan use case ber-ROI tinggi & pimpin adopsi di timmu."}',5),
('c6','Machine Learning','Advanced',40,12,4.9,980,1500,799000,1199000,'🤖','linear-gradient(135deg,#ea580c,#db2777)','Andi Wijaya','',
 '{"en":"Machine Learning Essentials","id":"Esensi Machine Learning"}',
 '{"en":"Go hands-on with Python to build, train and evaluate real ML models.","id":"Praktik langsung dengan Python untuk membangun, melatih & mengevaluasi model ML."}',6),
('c7','Generative AI','Advanced',36,10,5.0,520,1120,899000,1299000,'🛠️','linear-gradient(135deg,#7c3aed,#db2777)','Sarah Lin','new',
 '{"en":"Building AI Agents","id":"Membangun AI Agent"}',
 '{"en":"Design autonomous agents that plan, use tools and complete multi-step tasks.","id":"Rancang agent otonom yang merencanakan, memakai tools & menyelesaikan tugas kompleks."}',7),
('c8','Prompt Engineering','Beginner',16,4,4.7,360,2600,249000,399000,'💬','linear-gradient(135deg,#0891b2,#2563eb)','Budi Santoso','',
 '{"en":"ChatGPT for Everyday Productivity","id":"ChatGPT untuk Produktivitas Harian"}',
 '{"en":"Save hours every week using AI for email, planning, research and writing.","id":"Hemat berjam-jam tiap minggu pakai AI untuk email, perencanaan, riset & menulis."}',8)
on conflict (id) do update set
  cat=excluded.cat, level=excluded.level, lessons=excluded.lessons, hours=excluded.hours,
  rating=excluded.rating, reviews=excluded.reviews, students=excluded.students, price=excluded.price,
  old_price=excluded.old_price, icon=excluded.icon, grad=excluded.grad, instructor=excluded.instructor,
  tag_key=excluded.tag_key, title=excluded.title, description=excluded.description, sort_order=excluded.sort_order;

-- ===== EBOOKS =====
insert into public.ebooks (id,cat,price,old_price,icon,grad,pages,rating,downloads,title,description,file_path,file_name,file_size_bytes,sort_order) values
('eb1','Foundations',79000,0,'📘','linear-gradient(135deg,#4f46e5,#2563eb)',34,0,0,
 '{"en":"AI Foundation Guide","id":"Panduan Fondasi AI"}',
 '{"en":"Your plain-English starting point for AI at work — what it is, how generative models work, and which assistant to use when (ChatGPT, Claude, Gemini, Copilot). Includes role-by-role playbooks, responsible-use guidance and a 30-day ramp-up plan. No coding required.","id":"Titik awal memahami AI untuk kerja dengan bahasa sederhana — apa itu AI, cara kerja model generatif, dan kapan memakai ChatGPT, Claude, Gemini, atau Copilot. Termasuk playbook per peran, panduan pakai yang bijak, dan rencana 30 hari. Tanpa perlu coding."}',
 'eb1/ai-foundation-guide.pdf','ProAIcademy-AI-Foundation-Guide.pdf',2742116,1),
('eb2','Foundations',75000,0,'📗','linear-gradient(135deg,#059669,#16a34a)',48,0,0,
 '{"en":"Getting Started with Claude AI","id":"Memulai dengan Claude AI"}',
 '{"en":"A friendly, no-nonsense beginner''s guide to Anthropic''s Claude. Learn what makes Claude different, how to set it up and prompt it well, and how to use its toolbox — Claude Code, Cowork, Connectors, Artifacts and Memory — to get real work done from day one.","id":"Panduan pemula yang ramah dan langsung ke inti tentang Claude dari Anthropic. Pahami keunggulan Claude, cara menyiapkan dan memberi prompt yang baik, serta memanfaatkan perangkatnya — Claude Code, Cowork, Connectors, Artifacts, dan Memory — untuk bekerja sejak hari pertama."}',
 'eb2/getting-started-with-claude-ai.pdf','ProAIcademy-Getting-Started-with-Claude-AI.pdf',2574007,2),
('eb3','Prompts',75000,0,'💬','linear-gradient(135deg,#7c3aed,#2563eb)',45,0,0,
 '{"en":"Mastering Prompt Engineering","id":"Menguasai Prompt Engineering"}',
 '{"en":"Write better prompts and get reliable, high-quality results from any AI assistant. Master the six-part anatomy of a strong prompt, core techniques like few-shot and chain-of-thought, and advanced patterns — with real worked case studies and a ready-to-use starter prompt library.","id":"Tulis prompt yang lebih baik dan dapatkan hasil yang andal dan berkualitas dari asisten AI mana pun. Kuasai enam komponen prompt yang kuat, teknik inti seperti few-shot dan chain-of-thought, serta pola lanjutan — dengan studi kasus nyata dan pustaka prompt siap pakai."}',
 'eb3/mastering-prompt-engineering.pdf','ProAIcademy-Mastering-Prompt-Engineering.pdf',1869757,3),
('eb4','Productivity',95000,0,'⚡','linear-gradient(135deg,#0891b2,#2563eb)',51,0,0,
 '{"en":"ChatGPT for Daily Productivity","id":"ChatGPT untuk Produktivitas Harian"}',
 '{"en":"A practical, self-paced course that turns ChatGPT into repeatable output. Eleven modules cover prompting, writing, summarizing, planning, working with data and building reusable workflows — backed by a full prompt library and a 30-day plan to save hours every week.","id":"Kursus praktis dan mandiri yang mengubah ChatGPT menjadi hasil kerja yang berulang. Sebelas modul mencakup prompting, menulis, meringkas, merencanakan, mengolah data, dan membangun alur kerja yang bisa dipakai ulang — plus pustaka prompt dan rencana 30 hari untuk menghemat waktu."}',
 'eb4/chatgpt-for-daily-productivity.pdf','ProAIcademy-ChatGPT-for-Daily-Productivity.pdf',2220523,4),
('eb5','Productivity',95000,0,'🧠','linear-gradient(135deg,#7c3aed,#db2777)',62,0,0,
 '{"en":"Claude AI for Daily Productivity","id":"Claude AI untuk Produktivitas Harian"}',
 '{"en":"A Claude-specific productivity course built around real work. Learn the C-G-C-O-R prompting framework and put Claude to work on planning, email, meetings, documents, research and decisions — then package your best prompts into Claude Projects. Includes a 120+ prompt library and 7- and 30-day challenges.","id":"Kursus produktivitas khusus Claude yang dibangun dari pekerjaan nyata. Pelajari kerangka prompting C-G-C-O-R dan gunakan Claude untuk perencanaan, email, rapat, dokumen, riset, dan keputusan — lalu kemas prompt terbaikmu ke Claude Projects. Termasuk 120+ prompt dan tantangan 7 & 30 hari."}',
 'eb5/claude-ai-for-daily-productivity.pdf','ProAIcademy-Claude-AI-for-Daily-Productivity.pdf',2782541,5),
('eb6','Tools',85000,0,'🧰','linear-gradient(135deg,#059669,#0891b2)',45,0,0,
 '{"en":"100 AI Tools for Business and Professional Workers","id":"100 Tool AI untuk Bisnis & Profesional"}',
 '{"en":"A curated reference to 100 top AI tools across 10 business categories — automation, writing, meetings, sales, design, project management, video, research, HR and scheduling. Each profile covers what the tool does, its best use case, who it''s for and its pricing, with a direct link to explore.","id":"Referensi terkurasi berisi 100 tool AI terbaik dalam 10 kategori bisnis — otomatisasi, penulisan, rapat, sales, desain, manajemen proyek, video, riset, HR, dan penjadwalan. Tiap profil menjelaskan fungsi, use case terbaik, target pengguna, dan harga, lengkap dengan tautan langsung."}',
 'eb6/100-ai-tools-for-business.pdf','ProAIcademy-100-AI-Tools-for-Business-and-Professional-Workers.pdf',2348653,6),
('eb7','Career',75000,0,'🗺️','linear-gradient(135deg,#ea580c,#db2777)',41,0,0,
 '{"en":"AI Career Roadmap 2026","id":"Roadmap Karier AI 2026"}',
 '{"en":"A no-nonsense transition plan for professionals moving into AI-driven roles. Audit your transferable strengths, build AI fluency without a CS degree, and follow three concrete tracks — Industrial, Financial & Quantitative, or the Academic Bridge — with a quarter-by-quarter 12-month execution plan.","id":"Rencana transisi yang lugas bagi profesional yang beralih ke peran berbasis AI. Audit kekuatan yang bisa dialihkan, bangun kefasihan AI tanpa gelar ilmu komputer, dan ikuti tiga jalur konkret — Industri, Keuangan & Kuantitatif, atau Jembatan Akademik — dengan rencana eksekusi 12 bulan."}',
 'eb7/ai-career-roadmap-2026.pdf','ProAIcademy-AI-Career-Roadmap-2026.pdf',2345693,7)
on conflict (id) do update set
  cat=excluded.cat, price=excluded.price, old_price=excluded.old_price, icon=excluded.icon, grad=excluded.grad,
  pages=excluded.pages, rating=excluded.rating, downloads=excluded.downloads, title=excluded.title,
  description=excluded.description, file_path=excluded.file_path, file_name=excluded.file_name,
  file_size_bytes=excluded.file_size_bytes, sort_order=excluded.sort_order;

-- ===== CONSULTING PACKAGES =====
insert into public.consulting_packages (id,price,unit_key,featured,icon,name,tagline,features,sort_order) values
('cs1',1500000,'session',false,'🎯',
 '{"en":"Strategy Session","id":"Sesi Strategi"}','{"en":"1-on-1, 90 minutes","id":"1-on-1, 90 menit"}',
 '{"en":["AI opportunity assessment","Personalized tool stack","Action plan & next steps","Session recording"],"id":["Asesmen peluang AI","Rekomendasi tool stack","Rencana aksi & langkah lanjut","Rekaman sesi"]}',1),
('cs2',8000000,'day',true,'👥',
 '{"en":"Team Workshop","id":"Workshop Tim"}','{"en":"Up to 20 people, 1 day","id":"Hingga 20 orang, 1 hari"}',
 '{"en":["Hands-on AI training","Role-based use cases","Custom prompt library","30-day follow-up support","Certificates of completion"],"id":["Pelatihan AI praktik langsung","Use case sesuai peran","Library prompt khusus","Dukungan lanjutan 30 hari","Sertifikat kelulusan"]}',2),
('cs3',0,'custom',false,'🏢',
 '{"en":"Enterprise Transformation","id":"Transformasi Enterprise"}','{"en":"Org-wide, multi-month","id":"Skala organisasi, multi-bulan"}',
 '{"en":["AI maturity audit","Roadmap & governance","Custom solution build","Change management","Executive briefings"],"id":["Audit kematangan AI","Roadmap & tata kelola","Pengembangan solusi khusus","Manajemen perubahan","Briefing eksekutif"]}',3)
on conflict (id) do update set
  price=excluded.price, unit_key=excluded.unit_key, featured=excluded.featured, icon=excluded.icon,
  name=excluded.name, tagline=excluded.tagline, features=excluded.features, sort_order=excluded.sort_order;

-- ===== TESTIMONIALS =====
insert into public.testimonials (id,name,role,avatar,grad,quote,sort_order) values
('t1','Maya Hartono','{"en":"Marketing Lead, Tokopedia seller","id":"Marketing Lead, seller Tokopedia"}','MH','linear-gradient(135deg,#7c3aed,#2563eb)',
 '{"en":"I went from AI-curious to running our whole content pipeline with AI. The prompt course alone paid for itself in a week.","id":"Dari sekadar penasaran soal AI, kini saya menjalankan seluruh pipeline konten dengan AI. Kelas prompt-nya balik modal dalam seminggu."}',1),
('t2','Rizky Pratama','{"en":"Founder, Logistics startup","id":"Founder, startup Logistik"}','RP','linear-gradient(135deg,#059669,#0891b2)',
 '{"en":"The consulting session gave us a clear AI roadmap. We automated 3 workflows in the first month.","id":"Sesi konsultasinya memberi kami roadmap AI yang jelas. Kami mengotomatiskan 3 alur kerja di bulan pertama."}',2),
('t3','Dewi Anggraini','{"en":"HR Manager, Manufacturing","id":"HR Manager, Manufaktur"}','DA','linear-gradient(135deg,#db2777,#7c3aed)',
 '{"en":"Clear, practical and in Bahasa Indonesia. My team finally feels confident using AI tools daily.","id":"Jelas, praktis, dan dalam Bahasa Indonesia. Tim saya akhirnya percaya diri memakai tools AI setiap hari."}',3),
('t4','Kevin Tanuwijaya','{"en":"Software Engineer","id":"Software Engineer"}','KT','linear-gradient(135deg,#ea580c,#db2777)',
 '{"en":"The AI Agents course is the most practical one I have taken. I shipped an internal agent two weeks later.","id":"Kelas AI Agents adalah yang paling praktis yang pernah saya ikuti. Dua minggu kemudian saya rilis agent internal."}',4),
('t5','Putri Maharani','{"en":"Freelance Designer","id":"Desainer Freelance"}','PM','linear-gradient(135deg,#4f46e5,#2563eb)',
 '{"en":"I doubled my output and started charging more. Best investment in my skills this year.","id":"Output saya berlipat dan saya berani menaikkan tarif. Investasi skill terbaik tahun ini."}',5)
on conflict (id) do update set
  name=excluded.name, role=excluded.role, avatar=excluded.avatar, grad=excluded.grad, quote=excluded.quote, sort_order=excluded.sort_order;

-- ===== FAQS =====
insert into public.faqs (id,question,answer,sort_order) values
('f1','{"en":"Do I need a technical background?","id":"Apakah saya perlu latar belakang teknis?"}',
 '{"en":"No. Most of our courses are designed for non-technical learners. We start from the fundamentals and build up step by step.","id":"Tidak. Sebagian besar kelas kami dirancang untuk pemula non-teknis. Kami mulai dari dasar dan membangun bertahap."}',1),
('f2','{"en":"Are the courses in Bahasa Indonesia?","id":"Apakah kelasnya berbahasa Indonesia?"}',
 '{"en":"Yes. Lessons, materials and support are available in Bahasa Indonesia, with English resources included where helpful.","id":"Ya. Materi dan dukungan tersedia dalam Bahasa Indonesia, dengan tambahan referensi berbahasa Inggris bila membantu."}',2),
('f3','{"en":"Do I get a certificate?","id":"Apakah saya mendapat sertifikat?"}',
 '{"en":"Every course includes a verifiable certificate of completion you can share on LinkedIn and with employers.","id":"Setiap kelas dilengkapi sertifikat kelulusan terverifikasi yang bisa dibagikan di LinkedIn dan ke perusahaan."}',3),
('f4','{"en":"How long do I have access?","id":"Berapa lama saya bisa mengakses?"}',
 '{"en":"You get lifetime access to course materials, including all future updates, with a single purchase.","id":"Kamu mendapat akses seumur hidup ke materi, termasuk semua pembaruan ke depan, dengan sekali bayar."}',4),
('f5','{"en":"What payment methods do you accept?","id":"Metode pembayaran apa saja yang diterima?"}',
 '{"en":"We support bank transfer, virtual account, e-wallets (GoPay, OVO, DANA) and credit cards via secure checkout.","id":"Kami mendukung transfer bank, virtual account, e-wallet (GoPay, OVO, DANA) dan kartu kredit lewat checkout aman."}',5),
('f6','{"en":"Is there a refund policy?","id":"Apakah ada kebijakan refund?"}',
 '{"en":"Yes — a 14-day money-back guarantee on all courses if they are not the right fit for you.","id":"Ya — garansi uang kembali 14 hari untuk semua kelas jika dirasa kurang cocok."}',6)
on conflict (id) do update set question=excluded.question, answer=excluded.answer, sort_order=excluded.sort_order;
