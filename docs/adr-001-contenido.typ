// Contenido del ADR-001, común a las tres versiones (latex, apple y terminal).
// Cada versión define su estilo y llama a adr() con un diccionario de piezas:
// portada, resumen, cifras, nota, tema, sesion, veredicto, toprule, midrule y bottomrule.

#let meta = (
  codigo: "ADR-001",
  version: "1.0",
  etiqueta: [Architecture Decision Record],
  titulo: [SQLite over PostgreSQL],
  subtitulo: [How openmoody stores its data, and why],
  campos: (
    ([Status], [Accepted, pending the tutor's confirmation]),
    ([Author], [David Román López]),
    ([Decided], [16 November 2026]),
    ([Measured], [22 November 2026]),
    ([Supersedes], [PostgreSQL in Docker Compose, from the exercise plan of 4 November 2026]),
    ([Affects], [Exercises 3, 10 and 12]),
  ),
)

#let cifras = (
  (valor: [2.7×], texto: [SQLite's largest advantage, on small reads]),
  (valor: [5.7×], texto: [PostgreSQL's advantage on concurrent inserts]),
  (valor: [10×], texto: [less memory with SQLite, approximately]),
)

// Etiquetas de lenguaje para codly
#let lenguajes = (
  sql: (name: [SQL], color: rgb("#336791")),
  sh: (name: [Shell], color: rgb("#4eaa25")),
  rust: (name: [Rust], color: rgb("#b7502a")),
)

// Salida real del script de comparación del 22 de noviembre de 2026 (con 50 clientes), traducida al inglés.
// El script se llama comparar.sh en js/skel15; en el repo irá como compare.sh.
#let salida = read("datos/resultados-2026-11-22.txt")

#let adr(t) = {
  let (portada, resumen, cifras-fn, nota, tema, sesion) = (t.portada, t.resumen, t.cifras, t.nota, t.tema, t.sesion)
  let (veredicto, toprule, midrule, bottomrule) = (t.veredicto, t.toprule, t.midrule, t.bottomrule)
  [
#portada(meta)

#resumen[
openmoody stores its data in SQLite, compiled into the server through sqlx and run in WAL mode. In a benchmark of the same application on both databases, SQLite answered reads 1.4 to 2.7 times faster than PostgreSQL, and the whole server used about a tenth of the memory. PostgreSQL handled concurrent inserts 5.7 times faster than SQLite in its default mode. Each openmoody instance runs on one server and writes rarely, so the read and memory advantages apply and the write limit stays well above what the project needs. The decision will be revisited if openmoody needs more than one application server (@sec-revisit).
]

#cifras-fn(cifras)

= Context

openmoody is a moodboard that people share through links. Each deployment, whether self-hosted or our public demo, is one Rust process behind Caddy, so the database only ever has one client process.

Most of the work is reading. Opening a board lists its items and checks the token in the link. After that, the server pushes changes to the other viewers through server-sent events from an in-memory hub, so browsers never poll the database. Writes happen when someone pastes an item, comments or regenerates a link. If live cursors or live dragging are added later, positions will be relayed in memory and only the final position stored. SQLite's own documentation describes most low and medium traffic websites as a good fit for it \[2\].

Three students build the project on their own machines. Boards, links, items and real-time updates (exercises 4, 5 and 8) have to work before March 2027, the project is delivered in June 2027, and self-hosting has to stay simple enough to explain in the administration manual.

= Options considered

#figure(
  table(
    columns: (0.6fr, 1fr, 1fr),
    align: left,
    toprule,
    table.header([], [SQLite], [PostgreSQL 18]),
    midrule,
    [How it runs], [Inside the server process. The `sqlite` feature of sqlx compiles SQLite into the binary], [As a separate server, a second service in `compose.yaml`],
    [Configuration], [WAL with `synchronous = NORMAL` (@lst-pragmas)], [Defaults, reached over TCP inside the Compose network],
    [Rust code], [`SqlitePool`, `?` parameters, query macros checked against a local file], [`PgPool`, `$1` parameters, query macros checked against a running server],
    bottomrule,
  ),
  caption: [The two options.],
) <tab-options>

Exercise 3 sets the first two settings of @lst-pragmas when it opens the pool. sqlx applies the other two to every connection by default \[5\].

#figure(
```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;
```,
  caption: [SQLite settings for openmoody.],
) <lst-pragmas>

= Measurements

== Method

We built the same small application twice: a chat written for a course exercise, using axum 0.8 and sqlx 0.9. The handlers are identical. Only the connection pool, the parameter syntax and the JSON aggregate differ. Both versions build the JSON response inside the database (@lst-json-sqlite and @lst-json-pg), because sqlx's SQLite driver passes each row from its worker thread to the handler separately and that per-row cost would otherwise distort the comparison.

#figure(
```sql
SELECT json_group_array(
  json_object('id', id, 'nick', nick, 'texto', mensaje, 'fecha', instante)
  ORDER BY id)
FROM mensajes
WHERE id > ?
```,
  caption: [The read query in SQLite.],
) <lst-json-sqlite>

#figure(
```sql
SELECT coalesce(json_agg(
  json_build_object('id', id, 'nick', nick, 'texto', mensaje, 'fecha', instante)
  ORDER BY id), '[]')::text
FROM mensajes
WHERE id > $1
```,
  caption: [The same query in PostgreSQL. `json_agg` returns `NULL` when there are no rows, hence the `coalesce`.],
) <lst-json-pg>

/ Load: `ab` opens a new connection per request (HTTP/1.0, 2,000 requests per run). `wrk` keeps connections open, as browsers do (HTTP/1.1, 5 seconds per run). Both used 50 concurrent clients.
/ Databases: Default settings. PostgreSQL ran over TCP on localhost, as it would inside Compose. SQLite ran in its default rollback-journal mode with `synchronous = FULL`, its slowest mode for writes.
/ Memory: macOS `footprint` \[6\], with all PostgreSQL processes measured together so that the memory they share counts once.
/ Machine: Apple M4 Pro with 24 GB under macOS, with the load generator on the same machine.

== Reproducing the measurements

The benchmark script (`compare.sh`) and both versions of the application (`chat-rs` and `chat-rs-pg`) will be added to this repository under `bench/`. The script starts every server with a fresh database in a temporary folder, checks that all of them return the same data, runs the load and stops them. `C` sets the number of concurrent clients and `PG_SYNC` the value of PostgreSQL's `synchronous_commit` (@lst-bench).

#sesion(
  comandos: ```sh
./compare.sh                    # 10 concurrent clients
C=50 ./compare.sh               # 50 concurrent clients, as in this record
PG_SYNC=off C=50 ./compare.sh   # PostgreSQL with synchronous_commit = off
```,
  salida: salida,
) <lst-bench>

== Results

SQLite was faster in every read test, and PostgreSQL was faster at inserting (@tab-results). The largest read gap came from small reads over a connection that stays open: 66,158 requests per second against 24,810.

#figure(
  table(
    columns: (1fr, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, left),
    toprule,
    table.header([Workload], [SQLite], [p99], [PostgreSQL], [p99], [Faster]),
    midrule,
    [Read 50 rows, new connection], [*25,010*], [3 ms], [14,882], [5 ms], veredicto("SQLite", [1.7×]),
    [Read 50 rows, kept connection], [*31,982*], [1.83 ms], [22,179], [2.65 ms], veredicto("SQLite", [1.4×]),
    [Read 0 rows, new connection], [*25,391*], [4 ms], [16,430], [3 ms], veredicto("SQLite", [1.5×]),
    [Read 0 rows, kept connection], [*66,158*], [0.97 ms], [24,810], [2.64 ms], veredicto("SQLite", [2.7×]),
    [Insert one row, new connection], [2,572], [122 ms], [*14,754*], [14 ms], veredicto("PostgreSQL", [5.7×]),
    bottomrule,
  ),
  caption: [Requests per second for each database, with its 99th-percentile latency next to it, for 50 concurrent clients. The better figure is in bold, and the ratio compares requests per second. `ab` reports the percentile in whole milliseconds.],
) <tab-results>

The whole SQLite server used 9.4 MB, database included. The PostgreSQL version needed 7.0 MB for the server and 83 MB for PostgreSQL itself (@tab-memory). Those 83 MB are a floor: PostgreSQL's shared cache (`shared_buffers`, 128 MB by default) fills as the data grows.

#figure(
  table(
    columns: (1fr, auto, auto),
    align: (left, right, right),
    toprule,
    table.header([], [SQLite version], [PostgreSQL version]),
    midrule,
    [Application server], [9.4 MB], [7.0 MB],
    [Database server], [none], [83 MB],
    midrule,
    [Total], [9.4 MB], [90 MB],
    bottomrule,
  ),
  caption: [Memory footprint after the benchmark, measured with `footprint`.],
) <tab-memory>

== Discussion

#tema[Reads] SQLite answers inside the server process, while PostgreSQL needs a round trip through a socket for every query, even on the same machine. openmoody's queries are small and indexed, so the round trip takes longer than the query itself. The gap was widest on the request a browser repeats most often, a small read over a connection that stays open.

#tema[Writes] SQLite lets one writer in at a time. In rollback-journal mode every commit writes a journal, forces it to disk, updates the database and forces that too, which is why its 99th percentile rose to 122 ms with 50 clients. PostgreSQL appends to its write-ahead log and can confirm several concurrent commits with one flush. The advantage is real but small for openmoody: SQLite's slowest mode still sustained 2,572 inserts per second, about 150,000 per minute, far more than teams pasting into shared boards produce.

#tema[Memory] An openmoody instance on SQLite fits in about 10 MB plus its data, and PostgreSQL adds at least 80 MB more. That matters on a small VPS like the one that will host the public demo.

#nota("Pending measurement")[
openmoody will run SQLite in WAL mode with `synchronous = NORMAL` \[1\]. In that mode SQLite flushes only at checkpoints, not on every commit, so writes should be noticeably faster. The fair comparison pairs it with PostgreSQL's `synchronous_commit = off` \[3\], which gives the same guarantee: either database can lose its last commits in a crash or a power cut, and neither corrupts its data. That run, and a run on the Linux server from exercise 12, are still to be done.
]

= Operations

#figure(
  table(
    columns: (0.7fr, 1fr, 1fr),
    align: left,
    toprule,
    table.header([], [SQLite], [PostgreSQL]),
    midrule,
    [Development], [A file in `data/`. Nothing to install or start], [A container per developer, with credentials and a port],
    [Tests], [A fresh in-memory database per test (`sqlite::memory:`)], [A test database on a running server],
    [Deployment], [One image and one named volume], [A second service with its own volume, password and memory],
    [Backups], [Litestream \[4\] copies every change to an S3-compatible bucket, about once per second (exercise 12). `.backup` makes manual copies], [`pg_dump` and `pg_restore`. Upgrading to a new major version needs a dump and a restore],
    [Security], [No network port. The risk is serving the file by mistake, so `DATA_DIR` stays outside every served path], [A network service with credentials, whose port must stay inside the Compose network],
    [Schema changes], [`ALTER TABLE` is limited. Changing a `CHECK` means rebuilding the table], [Full `ALTER TABLE`],
    [Types], [Flexible. Constraints come from `CHECK` clauses, and dates are UTC text], [Strict, with native dates, enums and UUIDs],
    [Several app servers], [Not possible: the file lives on one machine's disk], [Supported, with `LISTEN/NOTIFY` between servers],
    bottomrule,
  ),
  caption: [Day-to-day differences for the team and for anyone self-hosting openmoody.],
) <tab-operations>

= Consequences

#figure(
  table(
    columns: (0.9fr, 1.6fr),
    align: left,
    toprule,
    table.header([Drawback of SQLite], [How the project handles it]),
    midrule,
    [Writes go one at a time], [WAL with `synchronous = NORMAL` (exercise 3), short transactions (exercises 4 and 13), and a pool with a single write connection if write waits appear],
    [The server is a single point of failure], [Litestream keeps a copy of the database off the machine, and the images are synced to the same bucket. Litestream protects the data. It adds no write concurrency and does not allow several writers],
    [One application server per instance], [Enough for the project's scope (@sec-revisit)],
    [Deleting boards does not shrink the file], [`VACUUM` or `auto_vacuum`, together with the expiry of public boards (exercise 10)],
    [Foreign keys are enabled per connection], [sqlx enables them \[5\]. The `sqlite3` shell does not, which matters when testing by hand],
    [WAL does not work on shared or network file systems], [The database lives in a named Docker volume, never in a folder mounted from the host],
    [Reviewers may doubt SQLite for a server application], [This record and its measurements. The tutor still has to confirm],
    bottomrule,
  ),
  caption: [Known drawbacks and how they are handled.],
) <tab-consequences>

= When to revisit <sec-revisit>

The project moves to PostgreSQL if any of these happens:

+ openmoody needs more than one application server, for high availability or to serve other regions.
+ Concurrent writes or long transactions make users wait.
+ The tutor does not accept SQLite as the project's relational database.
+ The project needs heavy analytical queries over large amounts of data.

The move stays cheap while the SQL is portable. It changes the parameters (`?` to `$1`), a few types (`INTEGER PRIMARY KEY` to an identity column, text dates to `timestamptz`), the JSON functions and the sqlx feature, and the handlers barely change. Real-time events already go through `hub::publish`, so spreading them across servers only changes that function. Board events are infrequent enough for PostgreSQL's `LISTEN/NOTIFY`, while high-frequency live positions would need NATS or Redis with either database.

We also looked at ways to take SQLite beyond one machine. Turso and libSQL would replace sqlx, Cloudflare D1 is built for Cloudflare Workers, and LiteFS receives limited updates, so none of them fits the project today.

= Limitations

- On macOS, `fsync` does not make the drive empty its cache, so the write figures are optimistic for both databases. On a Linux server, SQLite in rollback-journal mode should lose the most.
- The client and the server shared one machine, the dataset was tiny and neither database was tuned. Absolute figures will change on the deployment server; this record relies on the ratios between the two databases.

#heading(numbering: none)[References]

#block[
#set enum(numbering: "[1]", indent: 0pt, body-indent: 0.8em)
#set par(first-line-indent: 0pt, justify: false)
+ SQLite. _Write-Ahead Logging._ #link("https://www.sqlite.org/wal.html")
+ SQLite. _Appropriate Uses For SQLite._ #link("https://www.sqlite.org/whentouse.html")
+ PostgreSQL. _Asynchronous Commit._ #link("https://www.postgresql.org/docs/current/wal-async-commit.html")
+ Litestream. _Tips & Caveats._ #link("https://litestream.io/tips/")
+ sqlx. _Documentation._ #link("https://docs.rs/sqlx")
+ Apple. _footprint(1)._ #link("https://keith.github.io/xcode-man-pages/footprint.1.html")
]

#heading(numbering: none)[Document history]

#table(
  columns: (auto, auto, 1fr),
  align: left,
  toprule,
  table.header([Version], [Date], [Change]),
  midrule,
  [1.0], [22 November 2026], [First version, with the measurements of 22 November 2026],
  bottomrule,
)
  ]
}
