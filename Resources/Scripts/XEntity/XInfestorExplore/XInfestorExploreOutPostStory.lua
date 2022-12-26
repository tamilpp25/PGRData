local ipairs = ipairs
local stringGsub = string.gsub

local CHARACTER_NAME_REPLACE_FLAG = "【kurocharacter】"--角色名称替换标记
local CHARACTER_HP_REPLACE_FLAG = "【kurohp】"--损失生命值替换标记

local XInfestorExploreOutPostStory = XClass(nil, "XInfestorExploreOutPostStory")

local Default = {
    Start = "", --据点信息描述

    --回合战斗内容
    --选项1
    Option1 = "",
    MyTurn1 = "", --我的回合
    HisTurnWithDamage1 = "", --他的回合（扣血）
    HisTurnInPeace1 = "", --他的回合（不扣血）
    --选项2
    Option2 = "",
    MyTurn2 = "", --我的回合
    HisTurnWithDamage2 = "", --他的回合（扣血）
    HisTurnInPeace2 = "", --他的回合（不扣血）

    End = "", --固定结果描述（需要显示扣血总数值）
}

function XInfestorExploreOutPostStory:Ctor()
    self.Start = self:LetsRoll("Start")
    self.Option1 = self:LetsRoll("Option1")
    self.Option2 = self:LetsRoll("Option2")
end

function XInfestorExploreOutPostStory:LetsRoll(key, characterName, hp)
    local str = ""

    local poolIds = XFubenInfestorExploreConfigs.GetOutPostDesPoolIds(key)
    for _, poolId in ipairs(poolIds) do
        local randomDes = XFubenInfestorExploreConfigs.GetRandomOutPostDes(poolId)
        str = str .. randomDes
    end

    if characterName then
        str = stringGsub(str, CHARACTER_NAME_REPLACE_FLAG, characterName)
    end

    if hp then
        str = stringGsub(str, CHARACTER_HP_REPLACE_FLAG, hp)
    end

    return str
end

function XInfestorExploreOutPostStory:GetStartDes()
    return self.Start
end

function XInfestorExploreOutPostStory:GetOption1Txt()
    return self.Option1
end

function XInfestorExploreOutPostStory:GetOption2Txt()
    return self.Option2
end

function XInfestorExploreOutPostStory:GetMyTurnDes(option, characterName)
    local key = "MyTurn" .. option
    local str = self:LetsRoll(key, characterName)
    return str
end

function XInfestorExploreOutPostStory:GetHisTurnDes(option, isHurt, characterName, hp)
    local key = isHurt and "HisTurnWithDamage" .. option or "HisTurnInPeace" .. option
    local str = self:LetsRoll(key, characterName, hp)
    return str
end

function XInfestorExploreOutPostStory:GetEndDes(characterName, hp)
    local key = "End"
    local str = self:LetsRoll(key, characterName, hp)
    return str
end



return XInfestorExploreOutPostStory