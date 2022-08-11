package one.digitalinformation.basecamp;

//Exercicio de sobrecargas

public class Quadrilatero {

    public static void area (double lado) {
        System.out.println("Area do quadrado é: " + lado * lado);

    }

    public static void area (double lado1, double lado2) {
        System.out.println("Area do retangulo é: " + lado1 * lado2);

    }

    public static void area (double baseMaior, double baseMenor, double altura) {
        System.out.println("Area do trapezio é: " + (baseMenor * baseMaior) * altura / 2);

    }

    public static void area (float diagonal1, double diagonal2) {
        System.out.println("Area do losango é: " + diagonal1 * diagonal2 / 2);

    }

}
