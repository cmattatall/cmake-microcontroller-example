#include <stdio.h>

int main(void){
    int x = 5;
    while(1){
        ++x;
        if(x > 50){
            x = 0;
        }
    }
}