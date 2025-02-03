#!/bin/bash

at_PST=$( TZ="America/Los_Angeles" date +"%Y-%m-%d %I:%M:%S %p" )
echo "------------------------------------"
echo "NEW BENCHMARK"
echo "------------------------------------"
echo "db: leveling, at $at_PST PST"

# enum CompactionStyle : char {
#   // level based compaction style
#   kCompactionStyleLevel = 0x0,
#   // Universal compaction style
#   kCompactionStyleUniversal = 0x1,
#   // FIFO compaction style
#   kCompactionStyleFIFO = 0x2,
#   // Disable background compaction. Compaction jobs are submitted
#   // via CompactFiles().
#   kCompactionStyleNone = 0x3,
# };
# use above to choose compaction style 0,1,2,3
compaction_style=0

# block cache size
cache_size_mb=64
cache_size=$( python3 -c "print( int( $cache_size_mb * 2**20 ) )" )

# determine the number of keys to insert for the desire db size
db_size_gb=8
key_size=16
value_size=100
num=$( python3 -c "print( int( $db_size_gb * ( 2 ** 30 ) / \
                             ( $key_size + $value_size ) ) )" )

# number of read/seek operations
reads=$( python3 -c "print( 10 ** 6 )" )

echo "cache_size = $cache_size"
echo "num = $num"
echo "reads = $reads"

for T in 3 5 7; do
  # benchmark
  # 1. fillrandom with num keys
  # 2. readrandom (wait for compactions to finish)
  # 3. readrandom
  # 4. seekrandom
  echo "T = $T"
  echo "------------------------------------"
  ./db_bench --benchmarks="fillrandom,readrandom,stats" \
    --statistics \
    --use_direct_io_for_flush_and_compaction=true \
    --use_direct_reads=true \
    --cache_index_and_filter_blocks=true \
    --db=/db_bench \
    --cache_size=$cache_size \
    --key_size=$key_size \
    --value_size=$value_size \
    --num=$num \
    --reads=$reads \
    --compaction_style=$compaction_style \
    --max_bytes_for_level_multiplier=$T \
    --compression_type=none

  ./db_bench --benchmarks="readrandom,seekrandom" \
    --statistics \
    --use_direct_io_for_flush_and_compaction=true \
    --use_direct_reads=true \
    --cache_index_and_filter_blocks=true \
    --use_existing_db \
    --db=/db_bench \
    --cache_size=$cache_size \
    --key_size=$key_size \
    --value_size=$value_size \
    --reads=$reads \
    --compaction_style=$compaction_style \
    --max_bytes_for_level_multiplier=$T \
    --compression_type=none
done

exit 0
