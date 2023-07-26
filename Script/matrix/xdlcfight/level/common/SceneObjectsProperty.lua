return {
    Switch = {
        Actions = {
            [22] = {
                Open = 2201,
                OpenIdle = 2202,
                Close = 2204,
                Trigger = 2203,
            }
        },
        ---默认设置选项
        Options = {
            autoReboot = true,
            autoRebootCoolDown = 3,
            triggerTimes = -1,
            defaultOnEnable = true,
        },
        ---配置示范
        DefaultConfig = {
            placeId = nil,
            agent = nil,
            object = nil,
            func = nil,
            param = nil,
            --{{{可选配置
            defaultEnable = true,
            autoReboot = true,
            autoRebootCoolDown = 3,
            triggerTimes = -1,
            --}}}
        }
    },
    Anchor = {
        Actions = {
            [23] = {
                Open = 2301,
                Close = 2302,
            },
            [24] = {
                Open = 2401,
                Close = 2402,
            }
        },
        ---配置示范
        DefaultConfig = {
            placeId = nil,
            agent = nil,
            defaultEnable = true,
            type = nil,
            --{{{可选配置
            defaultAnchorEnable = false,
            --}}}
        }
    },
    Tower = {
        Actions = {
            [12] = {
                Open = 2006,
                Close = 2005,
            },
            [13] = {
                Open = 2004,
                Close = 2003,
            },
            Hunt01Center = {
                Open = 2002,
                Close = 2001,
            },
        },
        ---配置示范
        DefaultConfig = {
            placeId = nil,
            effectPlayer = nil,
            type = nil,
            defaultRaise = false,
            --{{{可选配置，用于构成塔链
            last = { 1 },
            next = { 6, 7 },
            --}}}
        }
    },
    Guide = {
        ---配置示范
        DefaultConfig = {
            GuideId = nil,
            --{{{可选配置，用于配置连续对话、需要点击的强引导、执行完的回调
            Next = nil,
            ClickKey = nil, --需要确保和配置表中相同
            Pause = false,
            Duration = nil, --配置表里配置了Duration的时候，如果没有暂停、没有Next、没有回调这里也可以不配（即使用Guide系统的自动关闭，关卡脚本不做处理
            CallBackObj = nil, --暂时只能主动赋值
            CallBackFuncName = nil, --方法名的字符串
            CallBackParam = nil,
            ConversationSet = false, --UI的预设配置
            --}}}
        },
    },
}