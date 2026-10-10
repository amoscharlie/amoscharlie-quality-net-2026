# Panduan memahami dan mempertahankan keputusan

## Mulai dari tujuan produk

Produk ini membantu assessor menilai keterampilan kandidat melalui interview suara. Hasil akhirnya bukan hanya chat: level, kutipan, coverage dan perbandingan lowongan disimpan untuk mendukung keputusan. Karena itu, data salah dan akses organisasi yang salah lebih berbahaya daripada tampilan yang kurang rapi.

Browser React menerima input dan menampilkan keadaan interview. Rails memutuskan siapa boleh mengakses data dan kapan session boleh selesai. PostgreSQL menyimpan fakta. Redis mengirim pekerjaan; Sidekiq menjalankan analisis di belakang layar. Provider AI menerima audio dan memberi analisis, tetapi responsnya tetap harus dianggap input yang bisa salah.

Alurnya: konfigurasi skill → undangan → memulai sesi → transcript → coverage → selesai → portfolio → review/override → perbandingan lowongan → export. Pada setiap perpindahan, tanyakan: siapa berwenang, data apa yang sudah terbukti, dan apa yang terjadi jika proses gagal?

## Keputusan yang perlu kamu jelaskan

**Mengapa P1?** Akses lintas organisasi membocorkan hasil kandidat. Selesai palsu dan evidence palsu membuat data keputusan salah. Skill yang muncul kembali setelah dihapus juga mengubah apa yang dinilai. Tidak ada P0 yang terbukti; jangan menyamakan instalasi Ruby bermasalah dengan produk yang mustahil berfungsi.

**Mengapa test dahulu?** Assertion yang gagal menunjukkan defect nyata dan membuat kita tahu perubahan mana yang menutupnya. History menyimpan RED, fix dan GREEN. Jangan bilang test gagal membuktikan defect jika kegagalannya sebenarnya karena setup, import atau akun yang salah.

**Mengapa tidak banyak test?** Kita memilih batas berisiko: request, DB write, payload form dan outcome koneksi. Test owner-access adalah kontrol positif agar solusi yang menolak semua orang tidak dianggap benar. Test valid portfolio memastikan validator tidak menolak semua respons.

**Mengapa join ke session tenant?** Portfolio tidak memiliki tenant_id sendiri. Organisasi pemilik berada pada session induknya. Menemukan portfolio berdasarkan id saja tidak membuktikan hak akses. Token valid juga belum membuktikan bahwa token berwenang atas resource tersebut.

**Mengapa login berubah?** Organisasi tidak boleh dipilih oleh client hanya karena ia memiliki password admin. User memiliki membership yang disimpan server. Akun lama tanpa membership ditolak sampai owner memprovisikan hubungan tersebut. Migrasi tidak otomatis menebak organisasinya.

**Mengapa validator AI diperlukan?** Prompt adalah permintaan kepada model; validator adalah aturan yang server benar-benar jalankan. Level 9 tidak diubah diam-diam menjadi 5. Kutipan harus ditemukan pada transcript kandidat. Seluruh hasil divalidasi sebelum mengganti data lama. Transaksi menjaga agar kegagalan tidak meninggalkan separuh hasil.

**Apa yang belum dibuktikan validator?** Kutipan nyata belum tentu relevan dengan skill, dan level model belum tentu akurat. Test terkontrol membuktikan pengolahan data, bukan kecerdasan model. Live/provider acceptance tetap dibutuhkan.

**Mengapa row lock?** Dua objek session bisa membaca status active yang sama. Lock membuat pemanggil kedua membaca keadaan terbaru sebelum memutuskan menulis. Nomor transcript dialokasikan dari database di bawah lock, bukan dipercaya dari counter per koneksi. Lease koneksi membatasi timer lama setelah refresh.

**Bagaimana jika antrean mati?** Catatan pending portfolio tetap tersimpan. Dispatcher mengirim lalu menandai generating. Recovery loop mengulang pending/stale work. Crash di antara enqueue dan commit dapat menyebabkan pengiriman duplikat; worker diserialisasi dan tidak mengganti hasil yang sudah complete. Ini at-least-once delivery, bukan klaim exactly-once. Thread recovery perlu worker tetap dijalankan; restart worker memulai polling lagi.

**Mengapa CI GREEN tetapi release BLOCKED?** CI membuktikan pemeriksaan yang dijalankan. Interview suara nyata belum diverifikasi. Gate release membaca required acceptance checks selain finding P0/P1. Kita tidak menghapus ketidakpastian hanya agar badge hijau.

## Batas sistem quality

Metadata PR membuktikan input tersedia, bukan bahwa isinya bagus. Changed-test gate membuktikan regression file berubah, bukan testnya bermakna. Reviewer masih harus membaca assertion. Protected main memaksa checks sebelum merge; owner repository tetap memiliki kemampuan administratif untuk mengubah policy, sehingga policy juga perlu dijaga.

Net ini belum mengukur kapasitas multi-process, latensi suara, perilaku interupsi dan kualitas scoring provider. Deployment manifest adalah contoh yang masih perlu review. Public signup tidak tersedia pada API; akun assessor diprovisikan oleh owner. Jangan menjanjikan hal yang belum diuji.

## Simulasi defense 60–90 menit

1. 10 menit: jelaskan tujuan, arsitektur dan satu flow tanpa membaca kode.
2. 15 menit: pilih tiga P1, peragakan bukti RED dan dampak bisnisnya.
3. 20 menit: jalankan net, telusuri satu assertion hingga query/transaction dan jelaskan kontrol positifnya.
4. 10 menit: buka PR blocked/pass dan tunjukkan policy yang benar-benar menahan merge.
5. 10 menit: buka tag, notes dan release gate; pertahankan keputusan BLOCKED.
6. 10–25 menit: jawab counterexample, ubah acceptance jika fakta berubah, dan jelaskan risiko tersisa.

Pertanyaan latihan:

- Token A valid. Mengapa request portfolio B masih harus gagal?
- Apa masalahnya kalau audio_complete dipercaya hanya karena frontend memanggilnya?
- Model memberi level 9 dan kutipan asli. Apa hasil yang benar, dan mengapa tidak clamp?
- Jika database commit berhasil tetapi Redis mati, bukti apa yang menyatakan pekerjaan belum hilang?
- Apa counterexample yang belum dilindungi oleh test reconnect saat ini?
- Apa bukti minimum yang kamu butuhkan untuk mengubah release dari BLOCKED menjadi RELEASABLE?

Jawab dengan kata sendiri. Urutkan jawaban: trigger → dampak → bukti → fix → batas verifikasi. Jika tidak tahu, sebutkan ketidakpastiannya dan cara membuktikannya; jangan mengarang jaminan.

## Checklist submission

Tiga dokumen utama ada; repository independen dan public; history dan file bebas identitas sumber/secret; CI behavioral RED dan GREEN dapat dibuka; PR blocked/pass dan main protection nyata; tag immutable dan notes cocok dengan keputusan; perintah setup/net dapat dijalankan; risiko tersisa punya owner. Provider acceptance yang belum selesai harus tetap terlihat jelas dalam keputusan release.
