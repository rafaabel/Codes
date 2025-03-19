package br.com.dio.exercicios.arrays;
/*
Cire um vetor de 6 números inteiros e mostre na ordem inversa
 */

public class Ex1_OrdemInversa {
    public static void main(String[] args) {
        int[] vetor = {-5, -6, 15, 50, 8, 4};

        int count = 0;
        while (count <= (vetor.length -1)){
            System.out.println(vetor[count] + " ");
            count++;

            for (int i = (vetor.length - 1); i == 0; i--){
                System.out.println(vetor[i] + " ");

            }

        }
    }
}
