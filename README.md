# openmoody

A moodboard you fill by pasting. Press Ctrl+V (Cmd+V on macOS) and the card takes the shape of what you pasted: an image, a YouTube video, a link, a color or a note. The aim is to share a board through a link, without anyone having to create an account.

The project is at an early stage. Today the board works in a single browser, and the server that will make boards shareable is being written on the `dev` branch.

## What works today

The front end is plain JavaScript, with no framework and no build step. When you paste, `js/main.js` picks the card type:

| You paste | You get |
|---|---|
| An image from the clipboard | Image card |
| A URL ending in .png, .jpg, .webp or .gif | Image card |
| A YouTube link | Embedded player |
| Any other URL | Link card |
| A hex color such as `#ff5733` | Color swatch |
| Anything else | Text note |

Cards are saved in the browser's `localStorage`, so a board can't leave the browser it was made in yet. The "Delete database." button in the footer clears it.

## Running it

The scripts are ES modules, and browsers won't load those from `file://`. Serve the folder with any static server:

```sh
python3 -m http.server 8080
```

and open http://localhost:8080.

The Rust server in `src/` doesn't run yet. When it does, `cargo run` will replace the command above. It needs rustc 1.94 or newer, because sqlx 0.9 requires it.

The Go files (`main.go`, `go.mod` and `detect_test.go`) come from the first plan, which used Go. They will go away as the Rust server takes over.

## Planned

The back end is Rust with axum and Tokio, and SQLite through sqlx. With it:

- Each board gets three links: one to view it, one to edit it and one to manage it. The link is the only access control, and the server stores only a hash of each token.
- Cards are stored in SQLite and pasted images on disk.
- Everyone who has the board open sees new cards as they arrive, through server-sent events.
- Link cards show a preview with the page's title and image. The server fetches it with protection against SSRF.
- Anyone with the link can comment under a nickname, and each card can record the nickname of whoever pasted it.
- A board can be exported as a ZIP with a JSON Canvas file (Obsidian and other canvas apps open it), a Markdown file and the original images.
- The public instance limits how long a board lives, the size of uploads and the requests per IP, and asks search engines not to index it. A self-hosted instance can require a password.
- The server ships as a single binary in a Docker image, run with Docker Compose behind Caddy for HTTPS.
