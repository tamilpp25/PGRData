---@class XUiMonsterCombatTeachingDetail : XLuaUi
local XUiMonsterCombatTeachingDetail = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatTeachingDetail")

function XUiMonsterCombatTeachingDetail:OnAwake()
    self:RegisterUiEvents()
    
    self.GridMonster.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    -- 默认值
    self.TxtNameDefault = self.TextName.text
end

function XUiMonsterCombatTeachingDetail:OnStart(rootUi)
    self.RootUi = rootUi
    self.GridDescList = {}
    self.GridRecommendMonsterList = {}
    self.GridUnlockMonsterList = {}
end

function XUiMonsterCombatTeachingDetail:OnEnable()
    -- 动画
    self.IsPlaying = true
    self:PlayAnimation("AnimBegin", handler(self, function()
        self.IsPlaying = false
    end))
    self.IsOpen = true

end

function XUiMonsterCombatTeachingDetail:OnDisable()
    self.IsOpen = false

end

function XUiMonsterCombatTeachingDetail:Refresh(stageId)
    self.StageId = stageId
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.StageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(stageId)
    self:UpdateCommon()
    self:UpdateMonster()
    self:UpdateReward()
end

function XUiMonsterCombatTeachingDetail:UpdateCommon()
    -- 标题
    self.TxtTitle.text = self.Stage.Name
    if self.StageEntity:CheckIsScoreModel() then
        -- 积分
        self.TextName.text = XUiHelper.GetText("UiMonsterCombatStageDetailScoreDesc", self.StageEntity:GetStageMaxScore())
    else
        self.TextName.text = self.TxtNameDefault
    end
    -- 通关提示
    local descriptions = self.StageEntity:GetDescription()
    for i = 1, 3 do
        local desc = descriptions[i]
        local ui = self["GridStageDesc" .. i]
        if string.IsNilOrEmpty(desc) then
            ui.gameObject:SetActiveEx(false)
        else
            local grid = self.GridDescList[i]
            if not grid then
                grid = XTool.InitUiObjectByUi({}, ui)
                self.GridDescList[i] = grid
            end
            grid.TxtActive.text = desc
            ui.gameObject:SetActiveEx(true)
        end
    end
end

-- 推荐怪物
function XUiMonsterCombatTeachingDetail:UpdateMonster()
    local recommendMonsters = self.StageEntity:GetRecommendMonsters()
    local count = #recommendMonsters
    for i = 1, count do
        local grid = self.GridRecommendMonsterList[i]
        if not grid then
            local go = i == 1 and self.GridMonster or XUiHelper.Instantiate(self.GridMonster, self.PanelMonsterContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridRecommendMonsterList[i] = grid
        end
        local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(recommendMonsters[i])
        grid.RImgIcon:SetRawImage(monsterEntity:GetAchieveIcon())
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridRecommendMonsterList do
        self.GridRecommendMonsterList[i].GameObject:SetActiveEx(false)
    end
end

-- 解锁怪物
function XUiMonsterCombatTeachingDetail:UpdateReward()
    local unlockMonsterIds = self.StageEntity:GetUnlockMonsterIds()
    local count = #unlockMonsterIds
    for i = 1, count do
        local grid = self.GridUnlockMonsterList[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelRewardContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridUnlockMonsterList[i] = grid
        end
        local monsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(unlockMonsterIds[i])
        grid.RImgIcon:SetRawImage(monsterEntity:GetAchieveIcon())
        grid.GameObject:SetActiveEx(true)
    end
    for i = count + 1, #self.GridUnlockMonsterList do
        self.GridUnlockMonsterList[i].GameObject:SetActiveEx(false)
    end
end

function XUiMonsterCombatTeachingDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end
    self.IsPlaying = true
    self:PlayAnimation("AnimEnd", handler(self, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.IsPlaying = false
        self:Close()
    end))
end

function XUiMonsterCombatTeachingDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
end

-- 进入编队界面
function XUiMonsterCombatTeachingDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if self.Stage == nil then
        XLog.Error("XUiMonsterCombatTeachingDetail.OnBtnEnterClick: Can not find StageCfg!")
        return
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ENTERFIGHT, self.Stage)
end

return XUiMonsterCombatTeachingDetail