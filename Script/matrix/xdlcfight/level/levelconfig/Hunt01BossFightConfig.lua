return {
    Towers = {
        [2] = {
            placeId = 2,
            last = { 1 },
            next = { 5, 6 },
            effectPlayer = 1002,
            type = 13,
            defaultRaise = false,
        },
        [3] = {
            placeId = 3,
            last = { 1 },
            next = { 5, 7 },
            effectPlayer = 1003,
            type = 13,
            defaultRaise = false,
        },
        [4] = {
            placeId = 4,
            last = { 1 },
            next = { 6, 7 },
            effectPlayer = 1004,
            type = 13,
            defaultRaise = false,
        },
        [5] = {
            placeId = 5,
            last = { 2, 3 },
            next = { 8, 9 },
            effectPlayer = 1005,
            type = 13,
            defaultRaise = false,
        },
        [6] = {
            placeId = 6,
            last = { 2, 1 },
            next = { 10, 11 },
            effectPlayer = 1006,
            type = 13,
            defaultRaise = false,
        },
        [7] = {
            placeId = 7,
            last = { 3, 4 },
            next = { 12, 13 },
            effectPlayer = 1007,
            type = 13,
            defaultRaise = false,
        },
        [8] = {
            placeId = 8,
            last = { 5 },
            next = { 14 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
            defaultAnchorEnable = false,
        },
        [9] = {
            placeId = 9,
            last = { 5 },
            next = { 15 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
            defaultAnchorEnable = false,
        },
        [10] = {
            placeId = 10,
            last = { 6 },
            next = { 16 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
            defaultAnchorEnable = false,
        },
        [11] = {
            placeId = 11,
            last = { 6 },
            next = { 14 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
            defaultAnchorEnable = false,
        },
        [12] = {
            placeId = 12,
            last = { 7 },
            next = { 15 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
            defaultAnchorEnable = false,
        },
        [13] = {
            placeId = 13,
            last = { 7 },
            next = { 16 },
            effectPlayer = nil,
            type = 14,
            defaultRaise = true,
        },
        [14] = {
            placeId = 14,
            last = { 8, 11 },
            next = nil,
            effectPlayer = 1014,
            type = 13,
            defaultRaise = false,
        },
        [15] = {
            placeId = 15,
            last = { 9, 12 },
            next = nil,
            effectPlayer = 1015,
            type = 13,
            defaultRaise = false,
        },
        [16] = {
            placeId = 16,
            last = { 10, 13 },
            next = nil,
            effectPlayer = 1016,
            type = 13,
            defaultRaise = false,
        }
    },
    Sequence = {
      {
          delayTime = 6,
          tower = 2,
          raise = false,
      },
      {
          delayTime = 6.1,
          tower = 3,
          raise = false,
      },
      {
          delayTime = 7.2,
          tower = 4,
          raise = false,
      },
      {
          delayTime = 7.3,
          tower = 5,
          raise = false,
      },
      {
          delayTime = 6.4,
          tower = 6,
          raise = false,
      },
      {
          delayTime = 6.5,
          tower = 7,
          raise = false,
      },
      {
          delayTime = 6.6,
          tower = 14,
          raise = false,
      },
      {
          delayTime = 7.1,
          tower = 15,
          raise = false,
      },
      {
          delayTime = 7.4,
          tower = 16,
          raise = false,
      },
      {
          delayTime = 12,
          tower = 2,
          raise = true,
      },
      {
          delayTime = 12,
          tower = 3,
          raise = true,
      },
      {
          delayTime = 12,
          tower = 4,
          raise = true,
      },
      {
          delayTime = 17,
          tower = 2,
          raise = false,
      },
      {
          delayTime = 17,
          tower = 3,
          raise = false,
      },
      {
          delayTime = 17,
          tower = 4,
          raise = false,
      },
      {
          delayTime = 15,
          tower = 5,
          raise = true,
      },
      {
          delayTime = 15,
          tower = 6,
          raise = true,
      },
      {
          delayTime = 15,
          tower = 7,
          raise = true,
      },
      {
          delayTime = 20,
          tower = 5,
          raise = false,
      },
      {
          delayTime = 20,
          tower = 6,
          raise = false,
      },
      {
          delayTime = 20,
          tower = 7,
          raise = false,
      },
    },
    Guides = {
        [1] = {
            GuideId = 13000,
            Next = 2,
            Duration = 5,
        },
        [2] = {
            GuideId = 13001,
            Duration = 5,
            CallBackObj = nil,
            CallBackFuncName = "StartCountDown",
        },
    },
    Tips = {
      [1000000] = 1000000
    },
    Boss = {
        [2] = {
            --表演关
            BlackDragon = 8001,
            WightDragon = 8002,
        },
        [3] = {
            --黑龙难度1
            BlackDragon = 800101,
        },
        [4] = {
            --黑龙难度2
            BlackDragon = 800102,
        },
        [5] = {
            --黑龙难度3
            BlackDragon = 800103,
        },
        [6] = {
            --黑龙难度4
            BlackDragon = 800104,
        },
        [7] = {
            --黑龙难度5
            BlackDragon = 800105,
        },
        [8] = {
            --白龙难度1
            WightDragon = 800201,
        },
        [9] = {
            --白龙难度2
            WightDragon = 800202,
        },
        [10] = {
            --白龙难度3
            WightDragon = 800203,
        },
        [11] = {
            --白龙难度4
            WightDragon = 800204,
        },
        [12] = {
            --白龙难度5
            WightDragon = 800205,
        },
        [13] = {
            --连战难度1
            BlackDragon = 800111,
            WightDragon = 800211,
        },
        [14] = {
            --连战难度2
            BlackDragon = 800112,
            WightDragon = 800212,
        },
        [15] = {
            --连战难度3
            BlackDragon = 800113,
            WightDragon = 800213,
        },
        [16] = {
            --连战难度4
            BlackDragon = 800114,
            WightDragon = 800214,
        },
        [17] = {
            --连战难度5
            BlackDragon = 800115,
            WightDragon = 800215,
        },
        [9014] = {
            --测试关
            BlackDragon = 8001,
            WightDragon = 8002,
        },
    },
}