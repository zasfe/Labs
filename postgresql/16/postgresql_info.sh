# 한 줄 요약 정보
echo "=== PostgreSQL 16 Quick Summary ===" && \
echo "Status: $(systemctl is-active postgresql@16-main)" && \
echo "Version: $(sudo -u postgres psql -t -c 'SELECT version();' 2>/dev/null | grep PostgreSQL | cut -d' ' -f1-3)" && \
echo "Data Dir: /data/postgresql/16/main ($(du -sh /data/postgresql/16/main 2>/dev/null | cut -f1))" && \
echo "Connections: $(ss -tan | grep :5432 | grep ESTAB | wc -l) active" && \
echo "Access: External enabled on $(hostname -I | awk '{print $1}'):5432"
