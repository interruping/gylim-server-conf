#!/bin/bash
set -e

source .env

echo "=== n8n + Nginx + PostgreSQL 초기 설정 ==="
echo "도메인: ${DOMAIN_NAME}"
echo ""

# ─── 1. HTTP 모드로 Nginx 시작 (인증서 발급용) ───
echo "[1/5] HTTP 모드로 Nginx 시작..."
NGINX_TEMPLATE=http.conf.template docker compose up -d nginx

echo "[2/5] Nginx 기동 대기 (5초)..."
sleep 5

# ─── 2. 인증서 발급 ───
echo "[3/5] Let's Encrypt 인증서 발급 중..."
docker compose run --rm --entrypoint "certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${SSL_EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${DOMAIN_NAME}" certbot

# ─── 3. HTTPS 전환 + 로컬 전용으로 시작 (certbot 제외) ───
echo "[4/5] HTTPS 모드 전환 (LAN 전용)..."
BIND_ADDRESS=${LOCAL_IP} docker compose up -d postgres n8n nginx

echo ""
echo "=== 관리자 계정을 생성하세요 ==="
echo "같은 네트워크의 PC에서 https://${LOCAL_IP} 접속 후"
echo "관리자 계정을 생성하고 Enter 를 눌러주세요."
echo "(자체 서명 인증서 경고가 뜨지만 무시하고 진행)"
echo ""
read -p "관리자 계정 생성 완료 → Enter..."

# ─── 4. 외부 접근 개방 + certbot 포함 전체 시작 ───
echo "[5/5] 외부 접근 개방 중..."
docker compose up -d

echo ""
echo "=== 설정 완료! ==="
echo "https://${DOMAIN_NAME} 으로 접속 가능합니다."
