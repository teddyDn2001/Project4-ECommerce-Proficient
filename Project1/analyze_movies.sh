#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

URL="https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv"
FILE="tmdb-movies.csv"

echo -e "${BLUE}=== PHÂN TÍCH DỮ LIỆU PHIM TMDB ===${NC}\n"

echo -e "${YELLOW}[1/8] Đang tải dữ liệu...${NC}"
if [ ! -f "$FILE" ]; then
    curl -k -o "$FILE" "$URL" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Tải dữ liệu thành công${NC}\n"
    else
        echo -e "${RED}✗ Lỗi khi tải dữ liệu${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ File dữ liệu đã tồn tại${NC}\n"
fi

if [ ! -s "$FILE" ]; then
    echo -e "${RED}✗ File dữ liệu rỗng${NC}"
    exit 1
fi

HEADER=$(head -1 "$FILE")
DATE_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /release_date/) print i}')
RATING_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /vote_average/) print i}')
REV_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /^revenue$/) print i}')
BUDGET_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /^budget$/) print i}')
DIR_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /director/) print i}')
CAST_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /^cast$/) print i}')
GENRE_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /^genres$/) print i}')
TITLE_COL=$(echo "$HEADER" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /original_title|title/) print i}')

echo -e "${YELLOW}[2/8] Sắp xếp phim theo ngày phát hành${NC}"
if [ ! -z "$DATE_COL" ]; then
    TOTAL=$(tail -n +2 "$FILE" | wc -l)
    echo -e "${GREEN}✓ Tổng số phim: ${TOTAL}${NC}"
    echo -e "${GREEN}Top 5 phim mới nhất:${NC}"
    (head -1 "$FILE"; tail -n +2 "$FILE" | sort -t',' -k${DATE_COL} -r) | head -6 | tail -5 | awk -F',' -v t="$TITLE_COL" -v d="$DATE_COL" '{printf "  - %s (%s)\n", $t, $d}'
else
    echo -e "${RED}✗ Không tìm thấy cột release_date${NC}"
fi
echo ""

echo -e "${YELLOW}[3/8] Phim có đánh giá > 7.5${NC}"
if [ ! -z "$RATING_COL" ]; then
    NUM=$(awk -F',' -v c="$RATING_COL" -v a="7.5" 'NR>1 && $c > a' "$FILE" | wc -l)
    echo -e "${GREEN}✓ Số phim: ${NUM}${NC}"
    echo -e "${GREEN}Top 5 phim đánh giá cao nhất:${NC}"
    awk -F',' -v c="$RATING_COL" -v t="$TITLE_COL" 'NR>1 && $c > 0 {printf "%.2f|%s\n", $c, $t}' "$FILE" | sort -t'|' -k1 -rn | head -5 | awk -F'|' '{printf "  - %s (%.2f/10)\n", $2, $1}'
else
    echo -e "${RED}✗ Không tìm thấy cột vote_average${NC}"
fi
echo ""

echo -e "${YELLOW}[4/8] Phim có doanh thu cao nhất và thấp nhất${NC}"
if [ ! -z "$REV_COL" ] && [ ! -z "$TITLE_COL" ]; then
    HIGHEST=$(awk -F',' -v r="$REV_COL" -v t="$TITLE_COL" '
    NR>1 && $r > 0 {
        if ($r > max || max == "") {
            max = $r
            name = $t
        }
    }
    END {
        printf "%s|%.0f", name, max
    }' "$FILE")
    
    LOWEST=$(awk -F',' -v r="$REV_COL" -v t="$TITLE_COL" '
    NR>1 && $r > 0 {
        if ($r < min || min == "") {
            min = $r
            name = $t
        }
    }
    END {
        printf "%s|%.0f", name, min
    }' "$FILE")
    
    echo -e "${GREEN}Doanh thu CAO NHẤT:${NC}"
    echo "$HIGHEST" | awk -F'|' '{printf "  - %s: $%.0f\n", $1, $2}'
    echo -e "${GREEN}Doanh thu THẤP NHẤT:${NC}"
    echo "$LOWEST" | awk -F'|' '{printf "  - %s: $%.0f\n", $1, $2}'
else
    echo -e "${RED}✗ Không tìm thấy cột revenue hoặc title${NC}"
fi
echo ""

echo -e "${YELLOW}[5/8] Tổng doanh thu${NC}"
if [ ! -z "$REV_COL" ]; then
    SUM=$(awk -F',' -v r="$REV_COL" 'NR>1 {sum += $r} END {printf "%.0f", sum}' "$FILE")
    echo -e "${GREEN}✓ Tổng doanh thu: $${SUM}${NC}"
else
    echo -e "${RED}✗ Không tìm thấy cột revenue${NC}"
fi
echo ""

echo -e "${YELLOW}[6/8] Top 10 phim có lợi nhuận cao nhất${NC}"
if [ ! -z "$REV_COL" ] && [ ! -z "$BUDGET_COL" ] && [ ! -z "$TITLE_COL" ]; then
    awk -F',' -v r="$REV_COL" -v b="$BUDGET_COL" -v t="$TITLE_COL" '
    NR>1 {
        p = $r - $b
        if (p > 0) {
            printf "%.0f|%s\n", p, $t
        }
    }' "$FILE" | sort -t'|' -k1 -rn | head -10 | awk -F'|' '{printf "  %2d. %s - $%.0f\n", NR, $2, $1}'
else
    echo -e "${RED}✗ Không tìm thấy cột revenue, budget hoặc title${NC}"
fi
echo ""

echo -e "${YELLOW}[7/8] Đạo diễn và diễn viên có nhiều phim nhất${NC}"
if [ ! -z "$DIR_COL" ]; then
    RESULT=$(awk -F',' -v d="$DIR_COL" '
    NR>1 && $d != "" {
        split($d, arr, "|")
        for (i in arr) {
            gsub(/^[ \t]+|[ \t]+$/, "", arr[i])
            if (arr[i] != "") {
                cnt[arr[i]]++
            }
        }
    }
    END {
        m = 0
        for (x in cnt) {
            if (cnt[x] > m) {
                m = cnt[x]
                top = x
            }
        }
        printf "%s|%d", top, m
    }' "$FILE")
    echo -e "${GREEN}Đạo diễn:${NC}"
    echo "$RESULT" | awk -F'|' '{printf "  - %s (%d phim)\n", $1, $2}'
fi

if [ ! -z "$CAST_COL" ]; then
    RESULT=$(awk -F',' -v c="$CAST_COL" '
    NR>1 && $c != "" {
        split($c, arr, "|")
        for (i in arr) {
            gsub(/^[ \t]+|[ \t]+$/, "", arr[i])
            if (arr[i] != "") {
                cnt[arr[i]]++
            }
        }
    }
    END {
        m = 0
        for (x in cnt) {
            if (cnt[x] > m) {
                m = cnt[x]
                top = x
            }
        }
        printf "%s|%d", top, m
    }' "$FILE")
    echo -e "${GREEN}Diễn viên:${NC}"
    echo "$RESULT" | awk -F'|' '{printf "  - %s (%d phim)\n", $1, $2}'
fi
echo ""

echo -e "${YELLOW}[8/8] Thống kê số lượng phim theo thể loại${NC}"
if [ ! -z "$GENRE_COL" ]; then
    echo -e "${GREEN}Top 10 thể loại:${NC}"
    awk -F',' -v g="$GENRE_COL" '
    NR>1 && $g != "" {
        split($g, arr, "|")
        for (i in arr) {
            gsub(/^[ \t]+|[ \t]+$/, "", arr[i])
            if (arr[i] != "") {
                cnt[arr[i]]++
            }
        }
    }
    END {
        for (x in cnt) {
            printf "%d|%s\n", cnt[x], x
        }
    }' "$FILE" | sort -t'|' -k1 -rn | head -10 | awk -F'|' '{printf "  %2d. %-20s %d phim\n", NR, $2, $1}'
else
    echo -e "${RED}✗ Không tìm thấy cột genres${NC}"
fi
echo ""

echo -e "${BLUE}=== HOÀN THÀNH PHÂN TÍCH ===${NC}"
