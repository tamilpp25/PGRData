local CSXAudioManager = CS.XAudioManager

XSoundManager = XSoundManager or {}

XSoundManager.SoundType = {
    BGM = 1,
    Sound = 2,
    CV = 3,
}

XSoundManager.PlayFunc = {
    [XSoundManager.SoundType.BGM] = CSXAudioManager.PlayMusic,
    [XSoundManager.SoundType.Sound] = CSXAudioManager.PlaySound,
    [XSoundManager.SoundType.CV] = CSXAudioManager.PlayCv,
}

XSoundManager.SetVolumeFunc = {
    [XSoundManager.SoundType.BGM] = CSXAudioManager.ChangeMusicVolume,
    [XSoundManager.SoundType.Sound] = CSXAudioManager.ChangeSoundVolume,
    [XSoundManager.SoundType.CV] = CSXAudioManager.ChangeCvVolume,
}

XSoundManager.GetVolumeFunc = {
    [XSoundManager.SoundType.BGM] = CSXAudioManager.GetMusicVolume,
    [XSoundManager.SoundType.Sound] = CSXAudioManager.GetSoundVolume,
    [XSoundManager.SoundType.CV] = CSXAudioManager.GetCvVolume,
}

XSoundManager.UiBasicsMusic = {
    NoSound = 0, -- 无音效
    ClickOn = 501, -- 按钮点击
    Intercept = 504, -- 点击拦截
    Success = 505, -- 成功
    Defeat = 507, -- 失败
    Promotion = 506, -- 提升
    Slide = 508,

    --添加
    Main_huge = 1011, --主界面大按钮
    Main_middle = 1012, --主界面中按钮
    Main_small = 1013, --主界面中按钮
    Main_turnOver = 1014, --主界面翻转

    --公共
    Tip_small = 1021,
    Tip_Big = 1022,
    Skip = 1023, --跳过
    Return = 1024, --返回
    Confirm = 1025, --确认
    Triangle = 1026, --三角形按钮
    Tip_Up = 1027, --数值增
    Tip_Down = 1028, --数值减

    --通用
    Common_UiPlayerUp = 1094, --指挥官升级
    Common_UiFunctionalOpen = 1099, --通讯出来
    Common_UiObtain = 1095, --奖励弹窗

    --角色
    UiCharacter_LevelUp = 1094, --升级成功
    UiCharacter_GradeUp = 1094, --晋升成功
    UiCharacter_QualityUp = 1094, --进化成功
    UiCharacter_Liberation = 1094, --解放成功
    UiCharacter_QualityFragments = 1097, --使用碎片激活
    UiCharacter_UnlockBegin = 1101, --解锁角色 动画出现时
    UiCharacter_UnlockEnd = 1094, --解锁角色  动画结束时

    --装备
    UiEquip_BreakThroughPopUp = 1094, --武器突破成功
    UiEquip_ResonanceSelectAfter = 1096, --武器共鸣成功

    --副本
    Fight_Difficult_Select = 1031, --难度选择
    Fight_PageSwitch = 1032, --页面切换
    Fight_Start_Fight = 1041, --进入作战
    Fight_PageSwitch_Up = 1042, --关卡上翻页
    Fight_PageSwitch_Down = 1043, --关卡上翻页
    Fight_Collect    = 1044, --收集率奖励入口

    Fight_Enter_Game = 1034, -- 进入游戏按钮音效
    Fight_Click_Role = 1051, -- 点击角色
    Fight_Switch_Site = 1052, --换阵位
    Fight_Click_Team = 1053, -- 点击队伍
    Fight_Open_Help = 1054, --  点击助战
    Fight_Close_Help = 1055, --  关闭助战

    Fuben_UiRoomCharacter_Fashion = 1056, --  点击队员编辑界面时装按钮音效
    Fuben_UiRoomCharacter_Equip = 1057, --  点击队员编辑界面装备按钮音效
    Fuben_UiRoomCharacter_QuitTeam = 1058, --  点击队员编辑界面移出队伍音效
    Fuben_UiRoomCharacter_JoinTeam = 1059, --  点击队员编辑界面编入队伍音效

    UiActivityBranch_SwitchBg = 1102, --极地副本切换背景图
    UiActivityBrief_Anim = 1103, --极地活动简介入场动画音效

    UiActivity_Jidi_BGM = 6, --极地暗流版本BGM
    UiActivity_ChinaBoat_BGM = 18, --中国船BGM
    UiActivity_NewYear_BGM = 11, --新年活动BGM
    UiActivity_FoolsDay_BGM = 205, --愚人节活动BGM

    --时装/仓库
    UiFashion_Click = 1060, -- 点击不同时装音效
    UiEquipReplace_Click = 1061, -- 点击选择武器
    --仓库
    UiBag_Chip_Click = 1062, -- 点击选择不同意识
    UiBag_EquipInfo_Click = 1063, -- 点击装备界面详细信息查看音效
    UiBag_EquipOn_Click = 1064, -- 点击装备界面装备按钮音效
    UiBag_EquipOff_Click = 1065, -- 点击装备界面卸下按钮音效
    UiBag_EquipSelect_Click = 1066, -- 点击装备界面功能选择按钮音效
    UiBag_EquipRes_Click = 1067, -- 点击装备界面材料按钮音效

    UiEquip_Intensify_Click = 1068, -- 点击强化按钮音效
    UiEquip_Intensify_Up_Click = 1069, -- 装备强化等级提升
    UiEquip_Awake_Click = 1070, -- 点击装备觉醒按钮音效
    UiEquip_Awake_Up_Click = 1071, -- 装备觉醒等级提升

    --抽卡
    UiDrawCard_BoxOpen = 1517, --开启宝箱音效
    UiDrawCard_GachaOpen = 1617, --开启活动魔方音效
    UiDrawCard_Type = {                             --卡片展示音效
        --普通
        Normal = {
            Start = 1518,
            Show = 1530,
        },
        --五星
        FiveStar = {
            Start = 1519,
            Show = 1531,
        },
        --六星
        SixStar = {
            Start = 1520,
            Show = 1532,
        },
    },
    UiDrawCard_Reward_Normal = 1521, --普通获得奖励音效
    UiDrawCard_Reward_Suipian = 1522, --获得奖励转为碎片音效
    UiDrawCard_Chouka_Name = 1533, --抽卡-角色名字出现

    -- 结算
    UiSettle_Win_Number = 1098, -- 战斗结算播放分数音效

    --追击玩法
    ChessPursuit_BossJump = 841,
    ChessPursuit_FightWarning = 842,

    UiLuckDraw_DragCoin = 114,  -- 元旦抽奖音效
    UiLuckDraw_Cube = 1617,  -- 元旦抽奖音效

    --2021端午活动
    RpgMakerGame_Move = 875,    --移动音效
    RpgMakerGame_Death = 876,   --死亡音效
    RpgMakerGame_EndPointOpen = 877,    --终点开启音效
    RpgMakerGame_TriggerType2 = 878, --机关类型2的触发音效
    RpgMakerGame_TriggerType3 = 879, --机关类型3的触发音效
}

local onValueTime = true
local soundTime = 0

XSoundManager.GetSoundTime = function(time)
    if onValueTime == false then
        if soundTime == 0 then
            soundTime = math.ceil(time) * 1000
            XScheduleManager.ScheduleOnce(function()
                onValueTime = true
                soundTime = 0
            end, math.ceil(time) * 1000)
        end
    end
end

function XSoundManager.PlayBtnMusic(value, type)
    if type == "onClick" then
        if value == 0 then
            return
        end
    end
    if type == "onValueChanged" then
        if onValueTime == true then
            --onValueTime = false
            if value then
                if value == 0 then
                    onValueTime = true
                    return
                end
                CSXAudioManager.PlaySound(value)
            end
        end
    end
    if type == "onEndEdit" then
        if value == nil then
            CSXAudioManager.PlaySound(XSoundManager.UiBasicsMusic.ClickOn)
        else
            if value == 0 then
                return
            end
            CSXAudioManager.PlaySound(value)
        end
    end
end

-- 延迟播放BGM（临时解决）
function XSoundManager.PlaySoundDoNotInterrupt(cueId)
    XScheduleManager.ScheduleOnce(function()
        CSXAudioManager.PlayMusic(cueId)
    end, 100)
end

function XSoundManager.PlaySoundByType(cueId, soundType)
    if not cueId then
        XLog.Error("XSoundManager.PlaySoundByType函数错误，参数cueId不能为空")
        return
    end

    local func = XSoundManager.PlayFunc[soundType]
    if not func then
        XLog.Error("XSoundManager.PlaySoundByType 函数错误, 不存在此声音类型, 类型是：" .. soundType)
        return
    end

    return func(cueId)
end

function XSoundManager.SetVolumeByType(volume, soundType)
    if not volume then
        XLog.Error("XSoundManager.SetVolumeByType 函数错误: 参数volume不能为空")
        return
    end

    local func = XSoundManager.SetVolumeFunc[soundType]
    if not func then
        XLog.Error("XSoundManager.SetVolumeByType 函数错误, 不存在此声音类型, 类型是: " .. soundType)
        return
    end

    func(volume)
end

function XSoundManager.GetVolumeByType(soundType)
    local func = XSoundManager.GetVolumeFunc[soundType]
    if not func then
        XLog.Error("XSoundManager.GetVolumeFunc 函数错误, 不存在此声音类型, 类型是: " .. soundType)
        return
    end

    return func()
end

function XSoundManager.PauseMusic()
    CSXAudioManager.PauseMusic()
end

function XSoundManager.ResumeMusic()
    CSXAudioManager.ResumeMusic()
end

function XSoundManager.GetCurrentBgmCueId()
    return CSXAudioManager.CurrentMusicId
end

function XSoundManager.Stop(cueId)
    CSXAudioManager.Stop(cueId)
end