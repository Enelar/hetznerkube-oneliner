echo "Building image..."
docker build -f src/Dockerfile -t hko-runner src > /dev/null 2>&1
docker run -v `pwd`/keys:/keys hko-runner $1 $2 $3 $4 $5 $6 $7 $8 $9