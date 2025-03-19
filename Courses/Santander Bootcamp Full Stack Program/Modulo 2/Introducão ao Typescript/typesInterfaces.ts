//Types
//Interfaces

interface iAnimal {
    nome: string;
    tipo: 'Terrestre' | 'Aquatico';
    domestico: boolean;

}

interface iFelino extends iAnimal {
    visaoNoturna: boolean;
    executarRugido(alturaEmDecibeis: number): void;
}

interface iCanino extends iAnimal {
    porte: 'pequeno' | 'medio' | 'grande';
}

type iDomestico = iFelino | iCanino;

//Variaveis

const Animal: iDomestico = {
    nome: 'Elefante',
    tipo: 'Terrestre',
    domestico: true,
    porte: 'medio',

}

const Felino: iFelino = {
    nome: 'Leão',
    tipo: 'Terrestre',
    visaoNoturna: true,
    domestico: false,
    executarRugido: (alturaEmDecibeis) => (`${alturaEmDecibeis}dB`)
}
