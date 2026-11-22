use tokio::net::TcpListener;
use tower_http::services::{ServeDir, ServeFile};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // let pool = SqlitePool::connect("sqlite:data/chat.db").await?;
    // let state = AppState { pool };
    let app = axum::Router::new()
        .route_service("/", ServeFile::new("index.html"))
        .route_service("/", ServeFile::new("index.css"))
        .nest_service("/js", ServeDir::new("js"))
        .fallback_service(ServeDir::new("static"));
    // .with_state(state);
    let listener = TcpListener::bind("0.0.0.0:8080").await?;
    axum::serve(listener, app).await?;
    Ok(())
}
