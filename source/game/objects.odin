package game

Object_Spawnpoint :: struct {
    x: f32,
    y: f32,
}

Object_Transition :: struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
}

Object_Enemy :: struct {
    hp: int,
    enemy_name: string,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
}

Object :: union {
    Object_Spawnpoint,
    Object_Transition,
    Object_Enemy,
}

