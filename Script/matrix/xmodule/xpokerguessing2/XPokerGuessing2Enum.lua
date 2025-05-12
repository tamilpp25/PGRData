local XPokerGuessing2Enum = {
    State = {
        GameWin = 3,
        GameLose = 4,
        RoundWin = 5,
        RoundLose = 6,
        RoundDraw = 7,
    },
    Speak = {
        -- 服务器定义的
        GameWin = 3,
        GameLose = 4,
        RoundWin = 5,
        RoundLose = 6,
        RoundDraw = 7,
        -- 客户端自定义的
        RoundStart = 101,
    },
    RoundState = {
        RoundLose = -1, --回合失败
        RoundDrawn = 0, --回合平局
        RoundWin = 1, --回合胜利
    }
}
return XPokerGuessing2Enum