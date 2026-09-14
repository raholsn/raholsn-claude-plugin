#!/bin/zsh
#
# Open-Solution - Opens a Visual Studio/Rider solution file
#
# If no pattern given: searches current directory (up to 3 levels deep)
# and opens if exactly one .sln file is found.
#
# With pattern: searches for matching .sln files.
#
# Usage: open-solution [pattern] [depth]
# Example: open-solution              # finds and opens the only .sln
# Example: open-solution MySolution   # finds MySolution.sln
# Example: open-solution MyApp 4       # search deeper
#

set -e

PATTERN="${1:-}"
DEPTH="${2:-3}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to find and open solution
find_and_open() {
    local search_pattern="$1"
    local max_depth="$2"
    
    local matches=()

    # Try .slnx first, fall back to .sln
    local extensions=("slnx" "sln")
    for ext in "${extensions[@]}"; do
        if [[ -n "$search_pattern" ]]; then
            while IFS= read -r line; do
                [[ -n "$line" ]] && matches+=("$line")
            done < <(find . -maxdepth "$max_depth" -name "*${search_pattern}*.${ext}" -type f 2>/dev/null)
        else
            while IFS= read -r line; do
                [[ -n "$line" ]] && matches+=("$line")
            done < <(find . -maxdepth "$max_depth" -name "*.${ext}" -type f 2>/dev/null)
        fi
        [[ ${#matches[@]} -gt 0 ]] && break
    done
    
    # No matches
    if [[ ${#matches[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No solution files found${NC}"
        if [[ -n "$search_pattern" ]]; then
            echo "Pattern: *${search_pattern}*.sln"
        fi
        echo "Search depth: $max_depth"
        echo ""
        echo "Try: open-solution [pattern] 5  # to search deeper"
        return 1
    fi
    
    # Exactly one match - open it
    if [[ ${#matches[@]} -eq 1 ]]; then
        local solution="${matches[1]}"  # zsh arrays are 1-indexed
        echo -e "${GREEN}Opening $(basename "$solution")...${NC}"
        echo -e "${CYAN}  $solution${NC}"
        open "$solution"
        return 0
    fi
    
    # Multiple matches - list them
    echo -e "${YELLOW}Multiple solution files found:${NC}"
    echo ""
    local i=1
    for match in "${matches[@]}"; do
        echo "  $i) $(basename "$match")"
        echo "     $match"
        ((i++))
    done
    echo ""
    echo "Please specify which one:"
    echo "  open-solution \"$(basename "${matches[1]}" .sln)\""
    return 1
}

# Check if pattern is an exact file path
if [[ -n "$PATTERN" && -f "$PATTERN" ]]; then
    echo -e "${GREEN}Opening $(basename "$PATTERN")...${NC}"
    open "$PATTERN"
    exit 0
fi

# Check for exact match first: {pattern}.sln
if [[ -n "$PATTERN" ]]; then
    EXACT_MATCH=$(find . -maxdepth "$DEPTH" -name "${PATTERN}.slnx" -type f 2>/dev/null | head -1)
    [[ -z "$EXACT_MATCH" ]] && EXACT_MATCH=$(find . -maxdepth "$DEPTH" -name "${PATTERN}.sln" -type f 2>/dev/null | head -1)
    if [[ -n "$EXACT_MATCH" ]]; then
        echo -e "${GREEN}Opening $(basename "$EXACT_MATCH")...${NC}"
        echo -e "${CYAN}  $EXACT_MATCH${NC}"
        open "$EXACT_MATCH"
        exit 0
    fi
fi

# Search for solutions
find_and_open "$PATTERN" "$DEPTH"
