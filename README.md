# SNAKE GAME
### Noah Call A02361280

This game was made in AArch64 ARM for a raspberry pi and should be ran on the rasperry pi as well.

## To run:

In the terminal environment of the raspberry pi: go to the directory where snakeGame.s is stored and run 

```
as -o snakeGame.o snakeGame.s
```

```
ld -o snakeGame snakeGame.o
```

```
./snakeGame
```

## How it works:

The snake game starts by printing the wall and snake with the print funciton. Then it starts a loop to keep the snake moving, checking for colisions of self, wall or food. With each loop it prints off the new screen and deletes the last one as well. When there is a collision with self or the wall, the game is ended. When there is a collision with the food, the score is incremented, the snake grows, and the food respawns. 

## My improvements

I have added a menu screen!

## course concepts applied

Memory layout and controll flow