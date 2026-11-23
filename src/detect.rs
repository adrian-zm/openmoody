use csscolorparser::Color;
use url::{Host, ParseError, Position, Url, form_urlencoded::parse};

#[derive(Debug, PartialEq, Clone, Copy)]
enum Kind {
    Text,
    Url,
    Iframe,
    Img,
    Color,
}
fn parse_url(input: &str) -> Option<(Url, String)> {
    match Url::parse(input) {
        Ok(url) => Some((url, input.to_string())),
        Err(ParseError::RelativeUrlWithoutBase) => {
            let url_wscheme = format!("https://{input}");
            let url_whscheme = Url::parse(&url_wscheme).ok()?;
            Some((url_whscheme, url_wscheme))
        }
        Err(_) => None,
    }
}

fn is_color(input: &str) -> bool {
    let css_prefix = ["#", "rgb(", "rgba(", "hsl(", "hsla("]
        .iter()
        .any(|prefix| input.starts_with(*prefix));
    css_prefix && csscolorparser::parse(input).is_ok()
}
// pub fn classify (input: &str) ->(Kind,String) {
//     if input.starts_with == '#'{
//         Ok(color:Color);
//     }
// }
// }
