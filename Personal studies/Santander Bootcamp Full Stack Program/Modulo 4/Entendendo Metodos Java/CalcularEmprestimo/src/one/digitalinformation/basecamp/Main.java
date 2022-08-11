package one.digitalinformation.basecamp;

//Classe principal dos exercícios

public class Main {
    public static void main (String[] args){

        //Calculadora
        System.out.println("Exercicio Calculadora");
        Calculadora.soma(5, 5);
        Calculadora.subtracao(5,5);
        Calculadora.multiplicacao(5,5);
        Calculadora.divisao(5,5);

        //Mensagem
        System.out.println("Exercicio Mensagem");
        Mensagem.obterMensagem(5);
        Mensagem.obterMensagem(13);
        Mensagem.obterMensagem(18);

        //Empréstimo
        System.out.println("Exercico Empréstimo");
        Emprestimo.calcular(1000, Emprestimo.getDuasParcelas());
        Emprestimo.calcular(1000,Emprestimo.getTresParcelas());
        Emprestimo.calcular(1000, 5);
    }
}
