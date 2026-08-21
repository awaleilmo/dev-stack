#!/usr/bin/env bash
# lib/php_ext.sh - PHP extension installation (via pecl + enable in php.ini)
# PHP here is host-level, managed by mise (see detect.sh: detect_php).

if [[ -z "${_PHP_EXT_SH_SOURCED:-}" ]]; then
    _PHP_EXT_SH_SOURCED=1

set -uo pipefail

# Catalog of PHP extensions offered in the menu.
# Format: "name|method|description"
#   method=pecl    -> diinstal via `pecl install`, lalu diaktifkan di php.ini
#   method=builtin -> ekstensi bawaan PHP, cukup diaktifkan di php.ini
#                    (tanpa pecl; .so biasanya sudah ada di extension_dir)
declare -a PHP_EXTENSIONS=(
    # --- PECL (pecl install) ---
    "xdebug|pecl|Xdebug debugger/profiler (zend_extension)"
    "redis|pecl|Redis client (phpredis)"
    "mongodb|pecl|MongoDB driver"
    "imagick|pecl|ImageMagick"
    "pcov|pecl|Fast code coverage"
    "memcached|pecl|Memcached client"
    "amqp|pecl|AMQP / RabbitMQ"
    "swoole|pecl|Swoole async framework"
    "yaml|pecl|YAML parser"
    "grpc|pecl|gRPC"
    "apcu|pecl|APCu user cache"
    "igbinary|pecl|Igbinary serializer (lebih cepat dari JSON)"
    "msgpack|pecl|MessagePack serializer"
    "protobuf|pecl|Google Protocol Buffers"
    "rdkafka|pecl|Kafka client (butuh librdkafka)"
    "event|pecl|Libevent-based event loop"
    "phalcon|pecl|Phalcon framework"
    "ds|pecl|Data Structures (kelas Ds\*)"
    "psr|pecl|PSR interfaces"
    "oauth|pecl|OAuth consumer"
    "mailparse|pecl|Email parsing"
    "ssh2|pecl|SSH2 bindings"
    "lua|pecl|Lua scripting"
    "decimal|pecl|Arbitrary precision decimal"
    "xhprof|pecl|XHProf profiler"
    "uopz|pecl|PHP object patching (testing)"
    "trader|pecl|Trader technical analysis"
    "seaslog|pecl|Fast logging"
    "yaconf|pecl|Configuration container"
    "zmq|pecl|ZeroMQ"
    "parallel|pecl|Parallel concurrency"
    "gnupg|pecl|GnuPG"
    "sphinx|pecl|Sphinx full-text search"
    "memcache|pecl|Memcache client (lama)"
    "gearman|pecl|Gearman"
    "varnish|pecl|Varnish admin"
    "lzf|pecl|LZF compression"

    # --- Bundled / bawaan PHP (aktifkan via php.ini) ---
    "curl|builtin|HTTP client"
    "ffi|builtin|Foreign Function Interface"
    "ftp|builtin|FTP client"
    "fileinfo|builtin|File info / magic"
    "gd|builtin|Image processing (GD)"
    "gettext|builtin|Internationalization"
    "gmp|builtin|GNU Multiple Precision"
    "intl|builtin|Internationalization (ICU)"
    "imap|builtin|IMAP / POP3"
    "mbstring|builtin|Multibyte string"
    "exif|builtin|EXIF metadata"
    "mysqli|builtin|MySQL improved"
    "oci8_12c|builtin|Oracle OCI8 (client 12c)"
    "oci8_19|builtin|Oracle OCI8 (client 19)"
    "odbc|builtin|ODBC"
    "openssl|builtin|OpenSSL"
    "pdo_firebird|builtin|PDO Firebird"
    "pdo_mysql|builtin|PDO MySQL"
    "pdo_oci|builtin|PDO Oracle"
    "pdo_odbc|builtin|PDO ODBC"
    "pdo_pgsql|builtin|PDO PostgreSQL"
    "pdo_sqlite|builtin|PDO SQLite"
    "pgsql|builtin|PostgreSQL"
    "shmop|builtin|Shared memory"
    "snmp|builtin|SNMP"
    "soap|builtin|SOAP"
    "sockets|builtin|Sockets"
    "sodium|builtin|libsodium"
    "sqlite3|builtin|SQLite3"
    "tidy|builtin|Tidy HTML"
    "xsl|builtin|XSL"
    "zip|builtin|Zip"
)

# Ekstensi bawaan yang TIDAK ikut build default mise PHP dan butuh di-compile ulang.
# ext -> flag configure yang dipakai saat rebuild via mise.
declare -A EXT_CONFIGURE=(
    [ffi]="--with-ffi"
    [gmp]="--with-gmp"
    [imap]="--with-imap --with-kerberos --with-imap-ssl"
    [odbc]="--with-unixODBC"
    [pdo_firebird]="--with-pdo-firebird"
    [pdo_oci]="--with-pdo-oci"
    [pdo_odbc]="--with-pdo-odbc=unixODBC,/usr"
    [pdo_pgsql]="--with-pdo-pgsql"
    [pgsql]="--with-pgsql"
    [snmp]="--with-snmp"
    [sodium]="--with-sodium"
    [tidy]="--with-tidy"
    [xsl]="--with-xsl"
    [oci8_12c]="--with-oci8"
    [oci8_19]="--with-oci8"
)
# ext -> paket sistem (Debian/Ubuntu) yang wajib sebelum compile.
declare -A EXT_LIB=(
    [ffi]="libffi-dev"
    [gmp]="libgmp-dev"
    [imap]="libc-client2007e-dev libkrb5-dev"
    [odbc]="unixodbc-dev"
    [pdo_firebird]="firebird-dev"
    [pdo_oci]="oracle-instant-client (lihat dokumentasi Oracle)"
    [pdo_odbc]="unixodbc-dev"
    [pdo_pgsql]="libpq-dev"
    [pgsql]="libpq-dev"
    [snmp]="libsnmp-dev"
    [sodium]="libsodium-dev"
    [tidy]="libtidy-dev"
    [xsl]="libxslt1-dev"
    [oci8_12c]="oracle-instant-client (lihat dokumentasi Oracle)"
    [oci8_19]="oracle-instant-client (lihat dokumentasi Oracle)"
)

# Cetak instruksi rebuild PHP via mise untuk ekstensi bawaan yang tak ter-compile.
php_ext_print_rebuild_hint() {
    local ext="$1"
    local cfg="${EXT_CONFIGURE[$ext]:-}"
    local lib="${EXT_LIB[$ext]:-}"

    echo ""
    print_warning "Ekstensi '${ext}' TIDAK termasuk dalam build PHP mise saat ini."
    print_warning "Tidak ada file '${ext}.so' di extension_dir, sehingga TIDAK BISA diaktifkan lewat php.ini."
    echo ""
    echo -e "  ${CYAN}Cara menambahkannya — compile ulang PHP via mise:${NC}"

    if [[ -n "$lib" ]]; then
        echo -e "  ${YELLOW}# 1. Instal dependency sistem (Debian/Ubuntu)${NC}"
        echo "  sudo apt install -y $lib"
        echo ""
    fi

    if [[ -n "$cfg" ]]; then
        echo -e "  ${YELLOW}# 2. Compile ulang PHP dengan opsi configure (pakai --force!)${NC}"
        echo "  PHP_EXTRA_CONFIGURE_OPTIONS=\"$cfg\" mise install php@${MISE_PHP_VERSION} --force"
        echo ""
        echo -e "  ${YELLOW}#    atau simpan permanen lalu install:${NC}"
        echo "  mise config set env._.php.extra_configure_options \"$cfg\""
        echo "  mise install php@${MISE_PHP_VERSION} --force"
    else
        echo -e "  ${YELLOW}# Ekstensi ini butuh library khusus; cek dokumentasi PHP untuk opsi configure-nya.${NC}"
    fi

    echo ""
    echo -e "  ${RED}⚠️  Penting: pasang dependency sistem DI ATAS SEBELUM rebuild.${NC}"
    echo "  Plugin mendeteksi keberadaannya saat compile (mis. 'pg_config' untuk pdo_pgsql)."
    echo -e "  ${RED}⚠️  Compile ulang akan MENGGANTI instalasi PHP.${NC}"
    echo "  Ekstensi PECL yang sudah terpasang (mis. redis) harus diinstal ulang setelahnya."
    echo "  Setelah selesai, jalankan menu ini lagi untuk verifikasi."
}

# Resolve the best php.ini target for the mise-managed PHP.
# mise PHP parses a scan directory (conf.d) even when the main php.ini is
# "(none)", so we prefer dropping a file there; otherwise fall back to the
# ini-path directory's php.ini.
php_ext_ini_file() {
    local scan_dir=""
    scan_dir="$(php --ini 2>/dev/null \
        | grep -i "Scan for additional .ini files in" \
        | sed -E 's/.*:\s*//' \
        | sed -E 's/\s*$//')"
    if [[ -n "$scan_dir" && -d "$scan_dir" ]]; then
        echo "$scan_dir/99-devstack-extensions.ini"
        return
    fi

    local dir=""
    if command -v php-config >/dev/null 2>&1; then
        dir="$(php-config --ini-path 2>/dev/null | head -1)"
    fi
    if [[ -z "$dir" ]]; then
        dir="$(php --ini 2>/dev/null \
            | grep -i "Configuration File (php.ini) Path" \
            | sed -E 's/.*:\s*//' \
            | sed -E 's/\s*$//')"
    fi
    if [[ -n "$dir" && -d "$dir" ]]; then
        echo "$dir/php.ini"
    fi
}

# Check whether an extension is already loaded.
php_ext_is_loaded() {
    local ext="$1"
    php --ri "$ext" >/dev/null 2>&1 || php -m 2>/dev/null | grep -qi "^${ext}$"
}

# Install / enable a single PHP extension.
# $1 = extension name, $2 = method ("pecl" | "builtin", default pecl).
install_php_extension() {
    local ext="$1"
    local method="${2:-pecl}"

    # Sudah aktif? Langsung kabari, jangan tambah baris duplikat.
    if php_ext_is_loaded "$ext"; then
        print_info "Ekstensi '${ext}' sudah aktif."
        return 0
    fi

    # Tentukan baris php.ini yang akan ditambahkan.
    local ini_line
    if [[ "$method" == "pecl" ]]; then
        if [[ "$ext" == "xdebug" ]]; then
            ini_line="zend_extension=xdebug.so"
        else
            ini_line="extension=${ext}.so"
        fi
    else
        ini_line="extension=${ext}"
    fi

    # Ekstensi PECL butuh pecl; bawaan tidak.
    if [[ "$method" == "pecl" ]]; then
        echo ""
        echo -e "  ${CYAN}Menginstal ekstensi '${ext}' via pecl...${NC}"
        if ! command -v pecl >/dev/null 2>&1; then
            print_error "Perintah 'pecl' tidak ditemukan. PHP ${MISE_PHP_VERSION} (mise) butuh paket PEAR/pecl."
            return 1
        fi
        if ! pecl install -f "$ext" 2>&1; then
            print_error "Gagal menginstal '${ext}' via pecl. Lihat pesan di atas."
            return 1
        fi
    else
        echo ""
        echo -e "  ${CYAN}Mengaktifkan ekstensi bawaan '${ext}'...${NC}"
    fi

    # Ekstensi bawaan: kalau .so tidak ada di extension_dir, berarti ekstensi
    # ini tidak ikut build PHP mise -> tidak bisa diaktifkan lewat php.ini.
    # Langsung beri instruksi compile ulang, jangan tambah baris rusak.
    if [[ "$method" == "builtin" ]]; then
        local ext_dir
        ext_dir="$(php -i 2>/dev/null | grep -i 'extension_dir' | head -1 | sed -E 's/.*=>\s*//')"
        if [[ -n "$ext_dir" && ! -f "$ext_dir/${ext}.so" ]]; then
            php_ext_print_rebuild_hint "$ext"
            return 1
        fi
    fi

    local ini_file
    ini_file="$(php_ext_ini_file)"

    if [[ -z "$ini_file" ]]; then
        print_warning "Tidak bisa menemukan direktori php.ini; ekstensi belum diaktifkan otomatis."
        print_info "Aktifkan manual dengan menambahkan: ${ini_line}"
        return 1
    fi

    # mise PHP sering tidak punya php.ini loaded -> buat kalau belum ada.
    if [[ ! -f "$ini_file" ]]; then
        if ! touch "$ini_file" 2>/dev/null; then
            print_warning "Tidak bisa membuat $ini_file; aktifkan manual dengan: ${ini_line}"
            return 1
        fi
        print_info "Membuat php.ini baru di ${ini_file}"
    fi

    local escaped
    escaped="$(printf '%s' "$ini_line" | sed 's/[.[\*^$/]/\\&/g')"
    local added=false
    if grep -Eqs "(^|;)[[:space:]]*${escaped}" "$ini_file"; then
        print_info "'${ini_line}' sudah ada di php.ini (atau ter-comment); dilewati."
    else
        echo "$ini_line" >> "$ini_file"
        added=true
        print_success "Menambahkan '${ini_line}' ke ${ini_file}"
    fi

    if php_ext_is_loaded "$ext"; then
        print_success "Ekstensi '${ext}' terpasang & aktif."
    else
        # Gagal load (mis. .so tidak ter-compile sebagai shared module).
        # Cabut baris yang baru ditambah agar PHP tidak rusak/beringat.
        if [[ "$added" == true ]]; then
            grep -vF "$ini_line" "$ini_file" > "${ini_file}.tmp" && mv "${ini_file}.tmp" "$ini_file"
        fi
        local ext_dir
        ext_dir="$(php -i 2>/dev/null | grep -i 'extension_dir' | head -1 | sed -E 's/.*=>\s*//')"
        print_warning "Ekstensi '${ext}' gagal diaktifkan."
        if [[ "$method" == "builtin" ]]; then
            print_info "Kemungkinan ekstensi ini tidak ter-compile sebagai shared module pada PHP ${MISE_PHP_VERSION} (mise)."
            print_info "Coba instal ulang PHP dengan opsi ekstensi tersebut, atau cek apakah sudah statis aktif."
        elif [[ -n "$ext_dir" ]]; then
            print_info "Pastikan 'extension_dir' menunjuk ke: ${ext_dir}"
        fi
        print_info "Coba: 'mise reshim' atau buka shell baru, lalu cek 'php -m | grep ${ext}'."
    fi
}

# Install ALL bundled ("bawaan") extensions that are not yet active, in one
# PHP rebuild. Excludes Oracle (needs manual Instant Client). Restores PECL
# extensions afterwards, since mise --force replaces the whole PHP install.
install_all_builtin_extensions() {
    local -a targets=() libs=() flags=() pecl_loaded=()
    local -A seen_lib=() seen_flag=()
    local oci_note=false

    # Kumpulkan ekstensi bawaan yang belum aktif.
    for entry in "${PHP_EXTENSIONS[@]}"; do
        local name="${entry%%|*}"
        local rest="${entry#*|}"
        local method="${rest%%|*}"
        [[ "$method" == "builtin" ]] || continue
        case "$name" in
            oci8_12c|oci8_19|pdo_oci|pdo_odbc) oci_note=true; continue ;;
        esac
        php_ext_is_loaded "$name" && continue
        targets+=("$name")
        local lib="${EXT_LIB[$name]:-}"
        local cfg="${EXT_CONFIGURE[$name]:-}"
        if [[ -n "$lib" && -z "${seen_lib[$lib]:-}" ]]; then
            for lp in $lib; do
                [[ -z "${seen_lib[$lp]:-}" ]] || continue
                libs+=("$lp"); seen_lib[$lp]=1
            done
            seen_lib[$lib]=1
        fi
        if [[ -n "$cfg" && -z "${seen_flag[$cfg]:-}" ]]; then
            flags+=("$cfg"); seen_flag[$cfg]=1
        fi
    done

    # Catat PECL yang sedang aktif untuk dipasang ulang setelah rebuild.
    for entry in "${PHP_EXTENSIONS[@]}"; do
        local pname="${entry%%|*}"
        local prest="${entry#*|}"
        [[ "${prest%%|*}" == "pecl" ]] || continue
        php_ext_is_loaded "$pname" && pecl_loaded+=("$pname")
    done

    safe_clear
    print_header "Install Semua Ekstensi Bawaan"
    echo ""

    if [[ ${#targets[@]} -eq 0 ]]; then
        print_success "Semua ekstensi bawaan sudah aktif. Tidak ada yang perlu di-compile."
        return 0
    fi

    echo -e "  ${CYAN}Ekstensi yang akan ditambahkan:${NC}"
    echo "  ${targets[*]}"
    echo ""
    echo -e "  ${CYAN}Dependency sistem:${NC}"
    echo "  ${libs[*]}"
    echo ""
    echo -e "  ${CYAN}Configure flags:${NC}"
    echo "  ${flags[*]}"
    echo ""

    if [[ "$oci_note" == true ]]; then
        print_warning "Oracle (pdo_oci, oci8) DIKELUARKAN — butuh Oracle Instant Client manual (tidak via apt)."
        echo ""
    fi

    print_warning "AKSI INI: 'sudo apt install' dependency + 'mise install php@${MISE_PHP_VERSION} --force'."
    print_warning "PHP akan di-compile ulang (beberapa menit) & MENGGANTI instalasi PHP saat ini."
    print_warning "Ekstensi PECL (${pecl_loaded[*]:-none}) akan ikut terhapus & dipasang ulang otomatis."
    echo ""
    echo -n "  Lanjutkan? [y/N]: "
    local confirm=""
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "Dibatalkan."
        return 0
    fi

    # 1. Dependency sistem
    echo ""
    echo -e "  ${CYAN}Memasang dependency sistem...${NC}"
    if ! sudo apt install -y "${libs[@]}"; then
        print_error "Gagal menginstal dependency sistem. Periksa sudo / koneksi, lalu coba lagi."
        return 1
    fi

    # 2. Simpan perintah build untuk diulang bila gagal.
    local build_script="php-extensions-build.sh"
    cat > "$build_script" <<EOF
#!/usr/bin/env bash
# Generated by devstack — rebuild PHP with bundled extensions.
# Jika build gagal, edit hapus flag yang bermasalah lalu jalankan manual.
PHP_EXTRA_CONFIGURE_OPTIONS="${flags[*]}" mise install php@${MISE_PHP_VERSION} --force
EOF
    chmod +x "$build_script" 2>/dev/null || true

    # 3. Rebuild PHP
    echo ""
    echo -e "  ${CYAN}Compile ulang PHP (--force)...${NC}"
    if ! PHP_EXTRA_CONFIGURE_OPTIONS="${flags[*]}" mise install "php@${MISE_PHP_VERSION}" --force; then
        print_error "Build PHP gagal. Perintah tersimpan di ./${build_script} — hapus flag bermasalah lalu jalankan manual."
        return 1
    fi
    mise reshim php 2>/dev/null || true
    hash -r 2>/dev/null || true

    # 4. Restore PECL extensions
    if [[ ${#pecl_loaded[@]} -gt 0 ]]; then
        echo ""
        echo -e "  ${CYAN}Memasang ulang ekstensi PECL: ${pecl_loaded[*]}...${NC}"
        for p in "${pecl_loaded[@]}"; do
            local pline="extension=${p}.so"
            [[ "$p" == "xdebug" ]] && pline="zend_extension=xdebug.so"
            pecl install -f "$p" >/dev/null 2>&1 || true
            local ini_file; ini_file="$(php_ext_ini_file)"
            if [[ -n "$ini_file" ]]; then
                touch "$ini_file" 2>/dev/null || true
                local pesc; pesc="$(printf '%s' "$pline" | sed 's/[.[\*^$/]/\\&/g')"
                if ! grep -Eqs "(^|;)[[:space:]]*${pesc}" "$ini_file"; then
                    echo "$pline" >> "$ini_file"
                fi
            fi
        done
    fi

    # 5. Verify
    echo ""
    echo -e "  ${CYAN}Verifikasi:${NC}"
    for t in "${targets[@]}"; do
        if php_ext_is_loaded "$t"; then
            print_success "$t aktif"
        else
            print_error "$t GAGAL aktif"
        fi
    done
    echo ""
    print_info "Perintah build tersimpan di ./${build_script} untuk diulang jika perlu."
}

# Install PHP runtime via mise ATAS DASAR plus semua dependency sistem dan
# semua ekstensi bawaan sekaligus — satu kali sudo, sekali build.
# Opsional: pasangkan pecl exts setelahnya (redis, xdebug, dll).
install_php_with_extensions() {
    if ! is_interactive; then
        print_error "Fitur ini memerlukan terminal interaktif (TTY) karena butuh sudo."
        return 1
    fi
    if [[ "$HAS_MISE" != true ]]; then
        print_error "mise belum terinstall. Pilih [I] Install Mise Runtime dari Main Menu dulu."
        return 1
    fi

    safe_clear
    print_header "Install PHP via Mise + Semua Ekstensi"
    echo ""

    # Kumpulkan dependency sistem yang WAJIB (base compile + ekstensi bawaan).
    # Base compile deps (perlu untuk GD/intl/zip/openssl/dll & lain-lain).
    local -a base_libs=(
        libssl-dev libzip-dev libonig-dev libxml2-dev libpng-dev libicu-dev
        libjpeg-dev libbz2-dev zlib1g-dev libcurl4-openssl-dev libtidy-dev
        libsqlite3-dev libreadline-dev libgmp-dev libsodium-dev libfreetype6-dev
        libwebp-dev libargon2-dev libpspell-dev libsnmp-dev libldap2-dev
        unixodbc-dev libdb-dev libldb-dev libmcrypt-dev libgd-dev libxslt1-dev
    )
    # Ekstensi bawaan yang butuh lib tambahan (sudah dibersihkan dari nama yang salah).
    local -a ext_libs=(
        "libc-client2007e-dev libkrb5-dev"   # imap
        "libpq-dev"                          # pdo_pgsql / pgsql
        "unixodbc-dev"                       # odbc / pdo_odbc
        "firebird-dev"                       # pdo_firebird
    )
    # Flag configure untuk ekstensi bawaan yang tidak otomatis masuk.
    local -a cfg_flags=(
        "--with-ffi" "--with-gmp"
        "--with-imap" "--with-kerberos" "--with-imap-ssl"
        "--with-unixODBC" "--with-pdo-firebird"
        "--with-pdo-pgsql" "--with-pgsql" "--with-snmp"
        "--with-sodium" "--with-tidy" "--with-xsl"
    )

    # Dedupe base_libs yang sudah ada di ext_libs (unixodbc-dev muncul dua kali).
    local -A seen_lib=()
    local -a libs=()
    for entry in "${base_libs[@]}" "${ext_libs[@]}"; do
        for lp in $entry; do
            [[ -z "${seen_lib[$lp]:-}" ]] || continue
            libs+=("$lp"); seen_lib[$lp]=1
        done
    done

    echo -e "  ${CYAN}Akan dipasang dependency (sudo):${NC}"
    echo "  ${libs[*]}"
    echo ""
    echo -e "  ${CYAN}Configure flags (PHP_EXTRA_CONFIGURE_OPTIONS):${NC}"
    echo "  ${cfg_flags[*]}"
    echo ""
    echo -e "  ${YELLOW}⚠️  Aksi ini:${NC}"
    echo "    - Membutuhkan sudo untuk apt install (sekali password)."
    echo "    - Compile ulang PHP via mise (--force). Butuh beberapa menit."
    echo "    - Menghasilkan PHP ${MISE_PHP_VERSION} siap pakai dengan semua ekstensi bawaan."
    echo -e "  ${YELLOW}Oracle (pdo_oci/oci8) DILANGKAUKAN${NC} — butuh Oracle Instant Client manual."
    echo ""
    echo -n "  Lanjutkan? [y/N]: "
    local confirm=""
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "Dibatalkan."
        return 0
    fi

    # 1. Dependency sistem
    echo ""
    echo -e "  ${CYAN}Memasang dependency sistem (${#libs[@]} paket)...${NC}"
    if ! sudo apt install -y "${libs[@]}"; then
        print_error "Gagal menginstal dependency sistem. Periksa akses sudo / koneksi."
        return 1
    fi

    # 2. Simpan perintah untuk diulang bila gagal.
    local build_script="php-extensions-install.sh"
    cat > "$build_script" <<EOF
#!/usr/bin/env bash
# Generated by devstack — install PHP via mise + all bundled extensions.
sudo apt install -y ${libs[*]}
PHP_EXTRA_CONFIGURE_OPTIONS="${cfg_flags[*]}" mise install php@${MISE_PHP_VERSION} --force
mise reshim php
# Restore PECL (redis, xdebug, dll) jika ingin.
# pecl install -f redis 2>/dev/null || true
# echo 'extension=redis.so' >> \$(php --ini 2>/dev/null | grep 'Scan for additional' | sed -E 's/.*:\s*//' 2>/dev/null)/99-devstack-extensions.ini
EOF
    chmod +x "$build_script" 2>/dev/null || true

    # 3. Install / rebuild PHP via mise
    echo ""
    echo -e "  ${CYAN}Compile & install PHP ${MISE_PHP_VERSION} via mise --force...${NC}"
    if ! PHP_EXTRA_CONFIGURE_OPTIONS="${cfg_flags[*]}" mise install "php@${MISE_PHP_VERSION}" --force; then
        print_error "Build PHP gagal. Perintah tersimpan di ./${build_script} — hapus flag bermasalah lalu jalankan manual."
        return 1
    fi
    mise reshim php 2>/dev/null || true
    hash -r 2>/dev/null || true

    # 4. Verifikasi ekstensi bawaan
    echo ""
    echo -e "  ${CYAN}Verifikasi ekstensi bawaan:${NC}"
    local ok=0; local fail=0
    for entry in "${PHP_EXTENSIONS[@]}"; do
        local name="${entry%%|*}"
        local rest="${entry#*|}"
        local method="${rest%%|*}"
        [[ "$method" == "builtin" ]] || continue
        case "$name" in oci8_12c|oci8_19|pdo_oci) continue ;; esac
        if php_ext_is_loaded "$name"; then
            print_success "$name aktif"
            ok=$((ok+1))
        else
            print_error "$name GAGAL aktif"
            fail=$((fail+1))
        fi
    done

    echo ""
    if [[ $fail -eq 0 ]]; then
        print_success "PHP ${MISE_PHP_VERSION} + semua ekstensi bawaan TERPASANG. Anda bisa tutup script ini."
    else
        print_warning "Sebagian ekstensi gagal. Perintah build tersimpan di ./${build_script} — hapus flag bermasalah lalu jalankan ulang."
    fi
    return $fail
}

# Show the PHP extension submenu.
show_php_ext_menu() {
    safe_clear
    print_header "Install PHP Extensions (PHP ${PHP_VERSION:-$MISE_PHP_VERSION})"
    echo ""
    echo -e "  ${CYAN}Pilih ekstensi untuk diinstal:${NC}"

    local i=1
    for entry in "${PHP_EXTENSIONS[@]}"; do
        local name="${entry%%|*}"
        local rest="${entry#*|}"
        local method="${rest%%|*}"
        local desc="${rest##*|}"
        local tag="[pecl]"
        [[ "$method" == "builtin" ]] && tag="[bawaan]"
        if php_ext_is_loaded "$name"; then
            printf "  ${GREEN}%2d)${NC} %-12s ${GREEN}✅ installed${NC}  %s %s\n" "$i" "$name" "$tag" "$desc"
        else
            printf "  ${GREEN}%2d)${NC} %-12s              %s %s\n" "$i" "$name" "$tag" "$desc"
        fi
        i=$((i + 1))
    done

    echo ""
    echo -e "  ${CYAN}[A]${NC} Install semua ekstensi bawaan"
    echo -e "  ${CYAN}[C]${NC} Install custom (input nama)   ${CYAN}[0]${NC} Kembali ke Main Menu"
    echo ""
    echo -ne "  ${BOLD}Pilihan: ${NC}"
}

# Main entry for the [E] action.
php_ext_menu() {
    if ! is_interactive; then
        print_error "Menu ini membutuhkan terminal interaktif (TTY)."
        return 1
    fi

    # Precondition: PHP must be configured via mise.
    if [[ "$HAS_PHP" != true ]]; then
        safe_clear
        print_header "Install PHP Extensions"
        echo ""
        print_warning "PHP belum terinstall / belum dikonfigurasi via mise."
        echo ""
        echo -e "  ${CYAN}[I]${NC} Install PHP via mise + semua ekstensi bawaan (otomatis sudo apt install dependency)."
        echo -e "  ${CYAN}[0]${NC} Kembali ke Main Menu"
        echo ""
        echo -n "  Pilihan: "
        local choice=""
        read -r choice
        if [[ "$choice" =~ ^[Ii]$ ]]; then
            install_php_with_extensions
            echo ""
            echo -n "  Press Enter to continue..."
            read -r || true
        fi
        return 0
    fi

    while true; do
        show_php_ext_menu
        local choice=""
        if ! read -r choice; then
            return 0
        fi

        if [[ "$choice" == "0" ]]; then
            return 0
        elif [[ "$choice" =~ ^[Aa]$ ]]; then
            install_all_builtin_extensions
        elif [[ "$choice" =~ ^[Cc]$ ]]; then
            echo -ne "  Nama ekstensi: "
            local custom=""
            if ! read -r custom; then
                return 0
            fi
            if [[ -n "$custom" ]]; then
                install_php_extension "$custom"
            fi
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PHP_EXTENSIONS[@]} )); then
            local entry="${PHP_EXTENSIONS[$((choice - 1))]}"
            local name="${entry%%|*}"
            local method="${entry#*|}"
            method="${method%%|*}"
            install_php_extension "$name" "$method"
        else
            print_error "Pilihan tidak valid."
        fi

        echo ""
        echo -n "  Press Enter to continue..."
        if ! read -r; then
            return 0
        fi
    done
}

fi
