# cmpm80k Love2D project

## Project Goals
1. create a 2D map
2. intergrate .ink file
3. implement player movement/interaction
4. develop playable first build

## project structure (potential)

GameProject/
│
├── main.lua 
├── conf.lua
│
├── src/
│   ├── player.lua
│   ├── map.lua
│   ├── dialogue.lua
│   ├── interaction.lua
│   └── gameState.lua
│
├── story/
│   ├── main.ink
│   └── story.json
│
├── assets/
│   ├── images/
│   ├── maps/
│   ├── sounds/
│   └── fonts/
│
├── README.md

### main.lua (copied from professor, haven't edited yet)
initialized and run the game using love2D
### conf.lua
configure game setting
### src/
handles in game resources
### story
ink narrative 
### Assets
in game iamge,sound etc.
