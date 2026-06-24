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
insert into public.ebooks (id,cat,price,old_price,icon,grad,pages,rating,downloads,title,description,sort_order) values
('eb1','Prompts',99000,149000,'📕','linear-gradient(135deg,#7c3aed,#2563eb)',120,4.9,5400,
 '{"en":"The Prompt Playbook","id":"Buku Sakti Prompt"}','{"en":"200+ copy-paste prompts for work & business.","id":"200+ prompt siap pakai untuk kerja & bisnis."}',1),
('eb2','Tools',79000,0,'🧰','linear-gradient(135deg,#059669,#0891b2)',64,4.8,3100,
 '{"en":"100 AI Tools for Business","id":"100 Tools AI untuk Bisnis"}','{"en":"A curated directory with use cases & pricing.","id":"Direktori terkurasi lengkap use case & harga."}',2),
('eb3','Career',0,0,'🗺️','linear-gradient(135deg,#ea580c,#db2777)',38,4.9,8700,
 '{"en":"AI Career Roadmap 2026","id":"Roadmap Karier AI 2026"}','{"en":"Free guide to landing an AI-powered role.","id":"Panduan gratis meraih karier berbasis AI."}',3),
('eb4','Productivity',89000,0,'⚙️','linear-gradient(135deg,#2563eb,#06b6d4)',88,4.7,2400,
 '{"en":"Automate Your Workday","id":"Otomatiskan Hari Kerjamu"}','{"en":"Templates to automate repetitive tasks.","id":"Template untuk otomatisasi tugas berulang."}',4),
('eb5','Productivity',69000,99000,'⚡','linear-gradient(135deg,#0891b2,#2563eb)',72,4.8,4100,
 '{"en":"ChatGPT for Productivity","id":"ChatGPT untuk Produktivitas"}','{"en":"Save 10+ hours a week with smart workflows.","id":"Hemat 10+ jam seminggu dengan alur kerja cerdas."}',5),
('eb6','Business',119000,179000,'💼','linear-gradient(135deg,#4f46e5,#7c3aed)',96,4.9,1900,
 '{"en":"AI for Small Business Owners","id":"AI untuk Pemilik Usaha Kecil"}','{"en":"Cut costs and grow with practical AI playbooks.","id":"Hemat biaya & bertumbuh dengan playbook AI praktis."}',6),
('eb7','Creative',99000,0,'🎨','linear-gradient(135deg,#db2777,#7c3aed)',84,4.7,2600,
 '{"en":"The Image Generation Handbook","id":"Panduan Generasi Gambar AI"}','{"en":"Master Midjourney, DALL·E & Stable Diffusion.","id":"Kuasai Midjourney, DALL·E & Stable Diffusion."}',7),
('eb8','Foundations',0,0,'📗','linear-gradient(135deg,#059669,#16a34a)',24,4.8,11200,
 '{"en":"AI Foundations Cheat Sheet","id":"Lembar Sakti Dasar AI"}','{"en":"The free quick-start every beginner needs.","id":"Panduan cepat gratis untuk setiap pemula."}',8)
on conflict (id) do update set
  cat=excluded.cat, price=excluded.price, old_price=excluded.old_price, icon=excluded.icon, grad=excluded.grad,
  pages=excluded.pages, rating=excluded.rating, downloads=excluded.downloads, title=excluded.title,
  description=excluded.description, sort_order=excluded.sort_order;

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
