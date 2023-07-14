local XUiPlayerUp = XLuaUiManager.Register(XLuaUi, "UiPlayerUp")
local WAIT_CLOSE_TIME = 2
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local LevelUpType = {
    Normal = 1,
    Honor = 2,
}

function XUiPlayerUp:OnAwake()
    self:InitAutoScript()
end

function XUiPlayerUp:OnStart(oldLevel, newLevel, levelUpType)
    self.OldLevel = oldLevel
    self.NewLevel = newLevel
    self.TevelUpType = levelUpType
    self.BtnCloseTs.gameObject:SetActive(true)
    self.IsAnimating = true
    self.Timer = nil
    
    self:Update()
end

function XUiPlayerUp:OnEnable()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Common_UiPlayerUp)
end

function XUiPlayerUp:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPlayerUp:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPlayerUp:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPlayerUp:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPlayerUp:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

--@region 界面信息
function XUiPlayerUp:Update()
    self:SetInitUi()
    self:UpdateInitText()
    self:PlayAniPlayerUpBegin()
    self:SetReward()
end

function XUiPlayerUp:SetInitUi()
    self:SetText()
    self.HonorLevelUp.gameObject:SetActiveEx(self:IsHonorLevelOpen())
    self.PlayerUp.gameObject:SetActiveEx(not self:IsHonorLevelOpen())
end

function XUiPlayerUp:SetText()
    if self:IsHonorLevelOpen() then
        self.TxtLv1 = self.TxtLv1_HonorLevelUp
        self.TxtLv2 = self.TxtLv2_HonorLevelUp
        self.TxtLevelName = self.TxtLevelName_HonorLevelUp
        self.TxtMaxFriendCount = self.TxtMaxFriendCount_HonorLevelUp
    else
        self.TxtLv1 = self.TxtLv1_PlayerUp
        self.TxtLv2 = self.TxtLv2_PlayerUp
        self.TxtLevelName = self.TxtLevelName_PlayerUp
        self.TxtMaxFriendCount = self.TxtMaxFriendCount_PlayerUp
        self.TxtFreeActionPoint = self.TxtFreeActionPoint_PlayerUp
    end
end

function XUiPlayerUp:UpdateInitText()
    local addActionPoint = self:GetMaxActionPoint(self.NewLevel) - self:GetMaxActionPoint(self.OldLevel)
    local differenceGrade = self.NewLevel - self.OldLevel
    local num = 0
    for i = 1, differenceGrade do
        num = num + self:GetFreeActionPoint(self.OldLevel + i - 1)
    end

    if not self:IsHonorLevelOpen() then
        self.TxtFreeActionPoint.text = num
    end

    self.TxtMaxFriendCount.text = CS.XTextManager.GetText("LevelActionPoint", self:GetMaxActionPoint(self.OldLevel), addActionPoint)
    self.TxtLv1.text = self.OldLevel
    self.TxtLv2.text = self.NewLevel
    self.TxtLevelName.text = self:GetTxtLevelName()
    self.TxtLevelNameFirst.text = self:StringInsertBlank(self:GetTxtLevelName())
end

function XUiPlayerUp:SetReward()
    if not self:IsHonorLevelOpen() then
        return
    end

    local rewards = self:GetRewards()
    local rewardCount = #rewards

    for i = 1, rewardCount do
        local ui = CSUnityEngineObjectInstantiate(self.PanelReward,self.UiContent)
        ui.gameObject:SetActiveEx(true)
        ui.gameObject.name = string.format("PanelReward%d", i)
        local panel = XUiGridCommon.New(self, ui)
        panel.GameObject:SetActiveEx(true)
        local reward = rewards[i]
        panel:Refresh(reward)
    end
end

--合并奖励，处理等级连升的情况
function XUiPlayerUp:GetRewards()
    local newRewards = {}
    for i=self.OldLevel,self.NewLevel-1 do
        local rewards = XRewardManager.GetRewardList(XPlayerManager.GetRewardId(i))
        for i,reward in ipairs(rewards) do
            local isInside = false
            for i,newReward in ipairs(newRewards) do
                if newReward.TemplateId == reward.TemplateId and newReward.RewardType == reward.RewardType  then
                    newReward.Count = newReward.Count + reward.Count
                    isInside = true
                    break
                end
            end

            if not isInside then
                local xReward = {}
                for k,v in pairs(reward) do
                    xReward[k] = v
                end
                table.insert(newRewards, xReward)
            end
        end
    end

    return newRewards
end
--@endregion

function XUiPlayerUp:IsHonorLevelOpen()
    return self.TevelUpType == LevelUpType.Honor
end

function XUiPlayerUp:GetMaxActionPoint(level)
    return XPlayerManager.GetMaxActionPoint(level, self:IsHonorLevelOpen())
end

function XUiPlayerUp:GetFreeActionPoint(level)
    if not self:IsHonorLevelOpen() then
        return XPlayerManager.GetFreeActionPoint(level, self:IsHonorLevelOpen())
    else
        return 0
    end
end

function XUiPlayerUp:GetTxtLevelName()
    if self:IsHonorLevelOpen() then
        return CS.XTextManager.GetText("HonorLevel") .. CS.XTextManager.GetText("Promote")
    else
        return CS.XTextManager.GetText("PlayerLevel") .. CS.XTextManager.GetText("Promote")
    end
end
--@endregion

--字符之间插入空格
function XUiPlayerUp:StringInsertBlank(s)
    local tb = {}
    local newS = ""
    local index = 1
    for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
        if index == 1 then
            newS = newS .. utfChar
        else
            newS = newS .. " " .. utfChar
        end
        index = index + 1
    end

    return newS
end

function XUiPlayerUp:PlayAniPlayerUpBegin()
    local aniName = self:GetAnimationName(true)
    self:PlayAnimation(aniName, function()
        self.IsAnimating = false

        local time = 0
        self.Timer = XScheduleManager.Schedule(function()
            time = time + 1
            if time >= WAIT_CLOSE_TIME and self.BtnCloseTs.gameObject.activeInHierarchy then
                self:OnBtnCloseClick()
            end
        end, 1000, WAIT_CLOSE_TIME)
    end)
end

function XUiPlayerUp:PlayAniPlayerUpEnd()
    local aniName = self:GetAnimationName(false)
    self:PlayAnimation(aniName, function()
        if XTool.UObjIsNil(self.BtnClose) then
            return
        end
        self.IsAnimating = false

        if self.Timer ~= nil then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        self:Close()
        XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_LEVEL_UP_ANIMATION_END)
    end)
end

function XUiPlayerUp:GetAnimationName(isBegin)
    local aniName
    if self:IsHonorLevelOpen() then
        if isBegin then
            aniName = "HonorLevelUpEnable"
        else
            aniName = "HonorLevelUpEnd"
        end
    else
        if isBegin then
            aniName = "AniPlayerUpBegin"
        else
            aniName = "AniPlayerUpEnd"
        end
    end
    return aniName
end

function XUiPlayerUp:OnBtnCloseClick()
    if self.IsAnimating then
        return
    end

    self.IsAnimating = true
    self:PlayAniPlayerUpEnd()
end

function XUiPlayerUp:OnDestroy()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    XTipManager.Execute()
end