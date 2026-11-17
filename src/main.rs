use axum::{extract::Path, routing::get};
use tokio::net::TcpListener;
use tower_http::services;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let IndexCss: axum = axum::Router::new().route_service("/", ServeFile::new("index.css"));
    let IndexHtml: axum = axum::Router::new().route_service("/", ServeFile::new("index.html"));
    let Js: axum = axum::Router::new().nest_service("/js", ServerDir::new("js"));
}
