package one.digitalinnovation.oo;

/**
 * Classe de exemplo para o exercício de Orientacao a Objetos
 */
public class Carro {
    String cor;
    String modelo;
    int capacidadeTanque;

/**Constructors*/
    Carro() {
    }

    Carro (String cor, String modelo, int capacidadeTanque){
        this.cor = cor;
        this.modelo = modelo;
        this.capacidadeTanque = capacidadeTanque;
    }

/**Métodos*/

    void setCor (String cor){
        this.cor = cor;
    }

    String getCor (){
        return cor;
    }

    void setModelo (String modelo){
        this.modelo = modelo;
    }

    String getModelo (){
        return modelo;
    }

    void setCapacidadeTanque (int capacidadeTanque){
        this.capacidadeTanque = capacidadeTanque;
    }

    int getCapacidadeTanque (){
        return capacidadeTanque;
    }

    double totalValorTanque (double valorCombustivel){
        return capacidadeTanque * valorCombustivel;
    }
}
