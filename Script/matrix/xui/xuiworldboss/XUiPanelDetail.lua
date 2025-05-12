local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelDetail = XClass(nil, "XUiPanelDetail")
local XUiGridBuff = require("XUi/XUiWorldBoss/XUiGridBuff")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelDetail:Ctor(ui, base, areaId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.AreaId = areaId
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:SetActivityInfo()
end

function XUiPanelDetail:SetButtonCallBack()
    self.BtnBoss.CallBack = function()
        self:OnBtnBossClick()
    end
end

function XUiPanelDetail:UpdateActivityInfo()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local bossArea = worldBossActivity:GetBossAreaEntityById(self.AreaId)
    local actionPointId = worldBossActivity:GetActionPointId()
    local challengeCount = bossArea:GetChallengeCount()
    local maxChallengeCount = bossArea:GetMaxChallengeCount()
    local maxActionPoint = worldBossActivity:GetMaxActionPoint()
    local powerCount = XDataCenter.ItemManager.GetCount(actionPointId)

    self.PowerText.text = CSTextManagerGetText("WorldBossActionPoint")
    self.PowerCount.text = string.format("%d/%d",powerCount,maxActionPoint)
    self.ChallengeText.text = CSTextManagerGetText("WorldBossBossChallengeText")
    self.ChallengeCount.text = string.format("%d/%d",maxChallengeCount - challengeCount,maxChallengeCount)
end

function XUiPanelDetail:SetActivityInfo()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local actionPointId = worldBossActivity:GetActionPointId()
    local bossArea = worldBossActivity:GetBossAreaEntityById(self.AreaId)
    local bossBuffList = worldBossActivity:GetBossBuffList()
    local desc = bossArea:GetAreaDesc()

    self.TxtDesc.text = desc

    local item = XUiGridCommon.New(self, self.PowerItemGrid)
    item:Refresh(actionPointId)

    local tmpGroupFlag = {}
    local tmpIdFlag = {}
    local buffList = {}
    self.BuffItem.gameObject:SetActiveEx(false)
    for _,buffId in pairs(bossBuffList) do
        local buffEntity = XDataCenter.WorldBossManager.GetWorldBossBuffById(buffId)
        local groupId = buffEntity:GetGroupId()
        local IsNotShow = buffEntity:GetIsNotShow()
        local IsGroupType = groupId and groupId > 0
        local IsCanCreate = false

        if IsGroupType then
            if not tmpGroupFlag[groupId] then
                IsCanCreate = true
            end
            tmpGroupFlag[groupId] = true
        else
            if not tmpIdFlag[buffId] then
                IsCanCreate = true
            end
            tmpIdFlag[buffId] = true
        end

        if IsCanCreate and IsNotShow ~= 1 then
            local topLevelBuff = XDataCenter.WorldBossManager.GetSameGroupToLevelpBossBuffByGroupId(groupId)
            local obj = CS.UnityEngine.Object.Instantiate(self.BuffItem, self.PanelBuffInfo)
            local grid = XUiGridBuff.New(obj,true)
            grid:UpdateData(topLevelBuff and topLevelBuff or buffEntity)
            grid.GameObject:SetActive(true)
        end
    end
    self.GridRewardList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self:UpdateRewardList()
end

function XUiPanelDetail:UpdateRewardList()
    local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
    local bossArea = worldBossActivity:GetBossAreaEntityById(self.AreaId)
    local level = XDataCenter.WorldBossManager.GetBossStageLevel()
    local stage = XDataCenter.WorldBossManager.GetBossStageGroupByIdAndLevel(bossArea:GetStageId(),level)
    local rewards = XRewardManager.GetRewardList(stage.RewardId)
    
    for _,grid in pairs(self.GridRewardList) do
        grid.GameObject:SetActiveEx(false)
    end

    if rewards then
        for index, item in pairs(rewards) do
            if not self.GridRewardList[index] then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon,self.PanelDropContent)
                local grid = XUiGridCommon.New(self.Base, obj)
                grid:Refresh(item)
                grid.GameObject:SetActive(true)
                self.GridRewardList[index] = grid 
            else
                self.GridRewardList[index]:Refresh(item)
                self.GridRewardList[index].GameObject:SetActive(true)
            end
        end
    end
end

function XUiPanelDetail:OnBtnBossClick()
    local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(self.AreaId)
    local challengeCount = bossArea:GetChallengeCount()
    local maxChallengeCount = bossArea:GetMaxChallengeCount()

    if maxChallengeCount - challengeCount == 0 then
        XUiManager.TipText("WorldBossNoChallengeCount")
        return
    end
    local data = {WorldBossTeamDatas = bossArea:GetCharacterDatas()}
    XLuaUiManager.Open("UiBattleRoleRoom", bossArea:GetStageId(), data)
end

function XUiPanelDetail:SetShow(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiPanelDetail