# Appended to upstream's Dockerfile at build time. Adds a new final stage on
# top of "production" that grants the server binary cap_net_bind_service, so the
# non-root "sliver" user can bind privileged C2 ports (53/80/443). On the ECI
# runtime a pod securityContext capability is not propagated to a non-root
# process's effective set; a file capability is honored by the kernel at exec
# regardless of UID.
#
# Pure append (no edits to upstream lines), so bumping the submodule never
# conflicts. Build with --target production_with_cap.

# STAGE: production_with_cap
FROM production AS production_with_cap

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends libcap2-bin \
    && setcap 'cap_net_bind_service=+ep' /opt/sliver-server \
    && getcap /opt/sliver-server \
    && apt-get purge -y libcap2-bin \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
USER sliver
