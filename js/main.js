import { fillTextCard, fillImgCard, fillIframeCard, fillUrlCard, fillColorCard } from './fills.js';

const boardCont = document.querySelector("#board-container");
const deleteDB = document.querySelector("#deleteDb");

let boardItems = JSON.parse(localStorage.getItem("board_items") || "[]");

drawBoard(boardItems);
console.log(boardItems);

deleteDB.addEventListener("click", function(event) {
    localStorage.removeItem("board_items");
    boardItems = [];
    console.log(boardItems);
    boardCont.innerHTML = "";

})

document.addEventListener("paste", function(event) {
    const clipboardData = event.clipboardData || window.clipboardData;

    const textData = clipboardData.getData('text');
    const imageItem = Array.from(clipboardData.items).find(item => item.type.startsWith('image/'));

    const urlPattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$/;
    const imageExtensionPattern = /\.(png|jpg|webp|gif)$/i;
    const hexColorPattern = /^#([A-Fa-f0-9]{3}){1,2}$/;
    const youtubePattern = /^(https?:\/\/)?(www\.)?(youtube\.com\/(watch\?v=|embed\/|shorts\/)|youtu\.be\/)[\w-]{11}$/;

    if (!textData && !imageItem) return;
    const newCard = createCard();


    if (textData) {
    
        if (imageExtensionPattern.test(textData)) {
            fillImgCard(newCard, true, textData);
            save("img", textData);
            console.log("URL IMG")

        } else if (youtubePattern.test(textData)) {
            fillIframeCard(newCard, textData);
            save("iframe", transformYoutubeUrl(textData));
            console.log("URL IFRAME")

        }else if (urlPattern.test(textData)) {
            fillUrlCard(newCard, textData);
            console.log("URL NORMAL");
            save("url", textData);

        } else if (hexColorPattern.test(textData)) {
            fillColorCard(newCard, textData);
            save("color", textData);
            console.log("COLOR")

        } else {
            fillTextCard(newCard, textData);
            save("text", textData);
            console.log("TEXTO")
        }
    }

    if (imageItem) {
        const reader = new FileReader();
        const archivo = imageItem.getAsFile();

        reader.onload = function(e) {
        const textoDeLaImagen = e.target.result; 
        fillImgCard(newCard, false, textoDeLaImagen);
        save("img", textoDeLaImagen);
        }

        reader.readAsDataURL(archivo)
    }


})

export function createCard() {
    const newCard = document.createElement("div");
    newCard.classList.add("board-item");
    
    return newCard;
}

function drawBoard(db) {

    boardCont.innerHTML = "";

    db.forEach(item => {
        if (item.type === "text") {
            fillTextCard(createCard(), item.content)
        } else if (item.type === "url") {
            fillUrlCard(createCard(), item.content)
        } else if (item.type === "img") {
            fillImgCard(createCard(), true, item.content)
        } else if (item.type === "iframe") {
            fillIframeCard(createCard(), item.content)
        } else if (item.type === "color") {
            fillColorCard(createCard(), item.content)
        }
});
}

export function save(type, content) {

    dbPush(type,content);

    localStorage.setItem("board_items", JSON.stringify(boardItems));
    
}

export function addCardToBoard(card) {
    boardCont.appendChild(card);
}

export function dbPush(type, content) {
    const newItem = {
        type: type,
        content: content
    };

    boardItems.push(newItem);
    console.log(boardItems);
}

export function transformYoutubeUrl(url) {

    if (url.includes("youtube.com/watch?v=")) {
        return url.replace("watch?v=", "embed/");
    }
    return url;
}



