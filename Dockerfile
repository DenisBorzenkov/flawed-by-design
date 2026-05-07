# Pinning to a digest would be production-correct; tag is fine for a take-home.
FROM infrastructureascode/hello-world:latest

# /health is the route the ALB target group + ECS task-level healthcheck hit.
# Verified via `docker run … && curl localhost:8080/health -> 200`. Other
# common paths (/healthz, /status, /ping) return 404 from this base image.
EXPOSE 8080

# Ship the verify_health helper used by the ECS task healthCheck.
# --chmod=755 sets the bit at COPY time - base image is distroless-style
# and has no shell, so a separate `RUN chmod` would fail.
COPY --chmod=755 verify_health.sh /usr/local/bin/verify_health

# Container-level health probe. ECS-level healthCheck (in the task definition)
# is the more aggressive one; this one is for `docker inspect` debugging.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD /usr/local/bin/verify_health http://localhost:8080/health || exit 1
