import { Pool } from "pg";

const pool = new Pool({
  user: process.env.PGUSER || "nobody",
  database: process.env.PGDATABASE || "nobody",
  host: process.env.PGHOST || "/var/run/postgresql",
});

export default pool;
