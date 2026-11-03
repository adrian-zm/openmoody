import { transformYoutubeUrl, addCardToBoard, save } from './main.js';

export function fillTextCard(card, text) {
    const textElement = document.createElement("p");
    textElement.textContent = text;
    textElement.classList.add("card-text");
    card.classList.add("text")

    addCardToBoard(card);
    card.appendChild(textElement);
}

export function fillUrlCard(card, url) {
    const urlElement = document.createElement("a");
    urlElement.href = url;
    urlElement.textContent = url;
    urlElement.classList.add("card-url");
    card.classList.add("url")

    
    addCardToBoard(card,);
    card.appendChild(urlElement);
}

export function fillImgCard(card, isUrl, image) {
    let img = image;
    const imgElement = document.createElement("img");
    imgElement.classList.add("card-img");
    card.classList.add("img");

    imgElement.src = image; 
    
    addCardToBoard(card);
    card.appendChild(imgElement);

}

export function fillIframeCard(card, iframe) {
    const iframeElement = document.createElement("iframe");

    iframeElement.src = transformYoutubeUrl(iframe);
    iframeElement.classList.add("card-iframe")
    iframeElement.referrerPolicy = "strict-origin-when-cross-origin";
    iframeElement.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen";
    card.classList.add("iframe");


    addCardToBoard(card);
    card.appendChild(iframeElement);

}

export function fillColorCard(card, color) {
    const colorElement = document.createElement("div")
    colorElement.style.backgroundColor = color;
    colorElement.textContent = color;
    colorElement.classList.add("card-color");
    card.classList.add("color")

    addCardToBoard(card);
    card.appendChild(colorElement);

}