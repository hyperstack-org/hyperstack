TODO: delete?

## The 5 Letter Word Game in Hyperloop

We are going to implement a simple game (that is actually quite fun to play) using HyperMesh.

In the 5 letter word game two players each secretly pick a 5 letter word that have 5 different letters.  *truck* and *knife* for example.

Each player guesses a word, and the other player responds with the number of correct letters.

Players continue to take turns until a player guesses the other players word.

Because we are playing on a computer we are going to add some additional rules.

Instead of playing until one of the players correctly guesses a word, we will play until both players correctly guess a word, or one of the players concedes.

Players win by having the *fewest* points.

Points are calculated as follows:

+ 2 points for each guess
+ 2 points for conceding
+ 1 point if a player miscalculates the number of correct letters in the other players guess.  The app will give the other player the true answer anyway.
+ 3 points if a player asks the app to guess a word.  The app will always guess an optimal word (i.e. given all the previous guesses, the app will calculate a word that could be correct.)

In addition the players agree on a time per turn.  If time runs out then the app will guess, and the player will get 3 points instead of 2 (i.e. the last rule above will apply.)

Each
