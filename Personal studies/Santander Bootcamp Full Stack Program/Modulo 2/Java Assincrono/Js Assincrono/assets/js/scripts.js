const BASE_URL = 'https://api.thecatapi.com/v1/images/search/';
const catImg = document.getElementById('cat');
const catBtn = document.getElementById('change-cat');


const getCats = async () => {
    try {
        const data = await fetch(BASE_URL);
        const json = await data.json();
        return json.url;

    }
    catch (e) {
        console.log(e.message);
    }
};


const loadImg = async () => {
    catImg.src = await getCats();
}

catBtn.addEventListener('click', loadImg);
loadImg();