# PostgreSQL

This directory defines a single-instance CloudNativePG PostgreSQL cluster.

CloudNativePG creates the `postgres-app` Secret in the `database` namespace with the generated credentials for the `app` database owner. The primary read/write endpoint is `postgres-rw.database.svc.cluster.local:5432`.
