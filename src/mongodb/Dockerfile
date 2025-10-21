# Use official MongoDB 5.0 image from Docker Hub (no login required)
# MongoDB 5.0+ includes mongosh (the new MongoDB Shell)
FROM mongo:5.0

# Copy initialization scripts
# These scripts run automatically when container starts for the first time
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Expose MongoDB port
EXPOSE 27017

# MongoDB will use the default CMD from base image
# CMD ["mongod"]