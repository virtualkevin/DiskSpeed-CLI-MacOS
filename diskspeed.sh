#!/bin/zsh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
TEST_PATH=""
SIZE_MB=1024
VERIFY=false

# Argument parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--path)
      TEST_PATH="$2"
      shift 2
      ;;
    -s|--size)
      SIZE_MB="$2"
      if ! [[ "$SIZE_MB" =~ ^[0-9]+$ ]] || (( SIZE_MB <= 0 )); then
        echo -e "${RED}❌ Size must be a positive integer (in MB).${NC}"
        exit 1
      fi
      shift 2
      ;;
    -v|--verify)
      VERIFY=true
      shift
      ;;
    *)
      echo -e "${RED}❌ Unknown argument: $1${NC}"
      echo "Usage: $0 [--path PATH] [--size SIZE_MB] [--verify]"
      exit 1
      ;;
  esac
done

cleanup() {
  if [[ -n ${TEST_FILE:-} && -f "$TEST_FILE" ]]; then
    echo -e "${BLUE}🧹 Removing temporary file...${NC}"
    rm -f "$TEST_FILE"
  fi
}

trap cleanup EXIT INT TERM

# If no path is provided, choose one through Finder
if [[ -z "$TEST_PATH" ]]; then
  echo -e "${BLUE}🖥️  Opening folder picker...${NC}"
  TEST_PATH=$(
    osascript -e '
      try
        tell application "Finder"
          set folderPath to choose folder with prompt "Choose a volume or folder for the disk speed test:"
        end tell
        POSIX path of folderPath
      on error
        return ""
      end try
    ' 2>/dev/null
  )
  if [[ -z "$TEST_PATH" ]]; then
    echo -e "${RED}❌ Selection canceled.${NC}"
    exit 1
  fi
fi

# Normalize path
TEST_PATH="${TEST_PATH%/}"
if [[ ! -d "$TEST_PATH" ]]; then
  echo -e "${RED}❌ Path does not exist: $TEST_PATH${NC}"
  exit 1
fi

# Check free space
FREE_BLOCKS=$(df "$TEST_PATH" | awk 'NR==2 {print $4}')
FREE_MB=$((FREE_BLOCKS * 512 / 1024 / 1024))
REQUIRED_MB=$((SIZE_MB + SIZE_MB / 10))  # +10% buffer

if (( FREE_MB < REQUIRED_MB )); then
  echo -e "${RED}❌ Not enough disk space.${NC}"
  echo "Required: ~${REQUIRED_MB} MB, available: ${FREE_MB} MB."
  exit 1
fi

TEST_FILE="$TEST_PATH/.io_test_temp_$$.bin"

echo -e "${GREEN}📁 Path: $TEST_PATH${NC}"
echo -e "${BLUE}📊 Size: ${SIZE_MB} MB${NC}"
if [[ "$VERIFY" == true ]]; then
  echo -e "${BLUE}🔎 Verification: enabled${NC}"
fi

# --- Write ---
if [[ "$VERIFY" == true ]]; then
  echo -e "${BLUE}✍️  Writing and checksumming ${SIZE_MB} MB...${NC}"
else
  echo -e "${BLUE}✍️  Writing ${SIZE_MB} MB...${NC}"
fi
start_write=$(date +%s)
if [[ "$VERIFY" == true ]]; then
  expected_hash=$(dd if=/dev/urandom bs=1M count="$SIZE_MB" 2>/dev/null | tee "$TEST_FILE" | shasum -a 256 | awk '{print $1}')
else
  dd if=/dev/urandom of="$TEST_FILE" bs=1M count="$SIZE_MB" 2>/dev/null
fi
end_write=$(date +%s)

# --- Read ---
if [[ "$VERIFY" == true ]]; then
  echo -e "${BLUE}📖 Reading and verifying ${SIZE_MB} MB...${NC}"
else
  echo -e "${BLUE}📖 Reading ${SIZE_MB} MB...${NC}"
fi
start_read=$(date +%s)
if [[ "$VERIFY" == true ]]; then
  actual_hash=$(shasum -a 256 "$TEST_FILE" | awk '{print $1}')
else
  dd if="$TEST_FILE" of=/dev/null bs=1M 2>/dev/null
fi
end_read=$(date +%s)

if [[ "$VERIFY" == true && "$expected_hash" != "$actual_hash" ]]; then
  echo -e "${RED}❌ Verification failed: read data does not match written data.${NC}"
  exit 1
fi

# --- Calculation ---
write_time=$((end_write - start_write))
read_time=$((end_read - start_read))

(( write_time == 0 )) && write_time=1
(( read_time == 0 )) && read_time=1

write_speed=$(awk "BEGIN {printf \"%.2f\", $SIZE_MB / $write_time}")
read_speed=$(awk "BEGIN {printf \"%.2f\", $SIZE_MB / $read_time}")

# --- Output ---
echo
echo -e "${GREEN}✅ Test complete!${NC}"
echo "  💾 Write: ${write_speed} MB/s"
echo "  📥 Read: ${read_speed} MB/s"
if [[ "$VERIFY" == true ]]; then
  echo "  🔎 Verification: passed"
fi
